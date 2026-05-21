import 'dart:math';

import '../models/enums.dart';
import '../models/game_config.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import 'imposter_rules.dart';

/// Thrown when the engine is asked to do something illegal (e.g. start a
/// game with too few players). Carries a human-readable [message].
class GameError implements Exception {
  final String message;
  const GameError(this.message);
  @override
  String toString() => 'GameError: $message';
}

/// The brain of the game.
///
/// Every method takes the current [GameState] and returns a NEW one — the
/// engine never edits state in place. It has no UI and no networking, so it
/// can be unit-tested in milliseconds and reused by both local and online
/// modes.
///
/// Randomness (word pick + role assignment) goes through an injectable
/// [Random] so tests can pass a seeded Random and get deterministic results.
class GameEngine {
  final Random _random;

  GameEngine([Random? random]) : _random = random ?? Random();

  /// Creates and sets up a fresh game.
  ///
  /// - [names] are the player display names (3..12).
  /// - [wordPool] is the list of candidate secret words for the chosen theme.
  /// - [config.imposterCount] must be valid for the number of players.
  ///
  /// Resulting phase is [GamePhase.roleReveal].
  GameState startGame({
    required GameConfig config,
    required List<String> names,
    required List<String> wordPool,
  }) {
    if (names.length < kMinPlayers) {
      throw GameError('Need at least $kMinPlayers players to start.');
    }
    if (names.length > kMaxPlayers) {
      throw GameError('At most $kMaxPlayers players are supported.');
    }
    if (wordPool.isEmpty) {
      throw GameError('The chosen theme has no words.');
    }
    if (!isValidImposterCount(names.length, config.imposterCount)) {
      throw GameError(
        'Imposter count ${config.imposterCount} is invalid for '
        '${names.length} players (max ${maxImposters(names.length)}).',
      );
    }

    // Pick the secret word.
    final secretWord = wordPool[_random.nextInt(wordPool.length)];

    // Choose which player indices are imposters.
    final imposterIndices = _pickImposterIndices(
      playerCount: names.length,
      imposterCount: config.imposterCount,
    );

    // Build the player list with assigned roles and stable ids.
    final players = <Player>[
      for (var i = 0; i < names.length; i++)
        Player(
          id: 'p$i',
          name: names[i],
          role: imposterIndices.contains(i) ? Role.imposter : Role.civilian,
        ),
    ];

    return GameState(
      config: config,
      players: players,
      secretWord: secretWord,
      phase: GamePhase.roleReveal,
      roundNumber: 1,
      currentTurnIndex: 0,
    );
  }

  /// Moves from role reveal into the clue-giving phase.
  GameState beginCluePhase(GameState state) {
    _expectPhase(state, GamePhase.roleReveal);
    return state.copyWith(
      phase: GamePhase.clue,
      currentTurnIndex: _firstAliveIndex(state.players),
    );
  }

  /// Validates a clue. Returns an error message, or null if the clue is fine.
  ///
  /// Rules: must be non-empty, and must not contain the secret word
  /// (case-insensitive, ignoring surrounding spaces).
  String? validateClue(GameState state, String clue) {
    final trimmed = clue.trim();
    if (trimmed.isEmpty) return 'Clue cannot be empty.';
    final normalizedClue = trimmed.toLowerCase();
    final normalizedWord = state.secretWord.trim().toLowerCase();
    if (normalizedClue.contains(normalizedWord)) {
      return 'Your clue cannot contain the secret word.';
    }
    return null;
  }

  /// Records a clue for [playerId] and advances the turn to the next alive
  /// player. Throws if the clue is invalid (see [validateClue]).
  GameState submitClue(GameState state, String playerId, String clue) {
    _expectPhase(state, GamePhase.clue);
    final error = validateClue(state, clue);
    if (error != null) throw GameError(error);

    final player = state.playerById(playerId);
    if (player == null) throw GameError('Unknown player: $playerId');
    if (!player.isAlive) throw GameError('Eliminated players cannot give clues.');

    final updated = _replacePlayer(
      state.players,
      playerId,
      (p) => p.copyWith(clue: clue.trim()),
    );

    final nextIndex = _nextAliveIndex(updated, state.currentTurnIndex);
    return state.copyWith(players: updated, currentTurnIndex: nextIndex);
  }

  /// Opens voting. Clears any previous votes from the players.
  GameState openVoting(GameState state) {
    _expectPhase(state, GamePhase.clue);
    final cleared = state.players
        .map((p) => p.copyWith(clearVote: true))
        .toList(growable: false);
    return state.copyWith(phase: GamePhase.voting, players: cleared);
  }

  /// Records that [voterId] voted for [targetId]. Both must be alive.
  GameState castVote(GameState state, String voterId, String targetId) {
    _expectPhase(state, GamePhase.voting);
    final voter = state.playerById(voterId);
    final target = state.playerById(targetId);
    if (voter == null || !voter.isAlive) {
      throw GameError('Only living players can vote.');
    }
    if (target == null || !target.isAlive) {
      throw GameError('You can only vote for a living player.');
    }
    final updated = _replacePlayer(
      state.players,
      voterId,
      (p) => p.copyWith(voteTargetId: targetId),
    );
    return state.copyWith(players: updated);
  }

  /// Tallies the votes, eliminates the most-voted player (if no tie), checks
  /// for a winner, and moves to [GamePhase.reveal] or [GamePhase.gameOver].
  ///
  /// Tie rule: if two or more players tie for the most votes, NOBODY is
  /// eliminated this round ([GameState.lastEliminatedId] becomes null).
  GameState resolveVotes(GameState state) {
    _expectPhase(state, GamePhase.voting);

    // Count votes for each target among living voters.
    final tally = <String, int>{};
    for (final p in state.alivePlayers) {
      final target = p.voteTargetId;
      if (target != null) {
        tally[target] = (tally[target] ?? 0) + 1;
      }
    }

    String? eliminatedId;
    if (tally.isNotEmpty) {
      final maxVotes = tally.values.reduce(max);
      final topTargets = tally.entries
          .where((e) => e.value == maxVotes)
          .map((e) => e.key)
          .toList();
      // Only eliminate when there is a single clear leader (no tie).
      if (topTargets.length == 1) {
        eliminatedId = topTargets.first;
      }
    }

    var players = state.players;
    if (eliminatedId != null) {
      players = _replacePlayer(
        players,
        eliminatedId,
        (p) => p.copyWith(isAlive: false),
      );
    }

    final winner = _checkWinner(players);
    return state.copyWith(
      players: players,
      lastEliminatedId: eliminatedId,
      clearLastEliminated: eliminatedId == null,
      phase: winner != null ? GamePhase.gameOver : GamePhase.reveal,
      winner: winner,
      clearWinner: winner == null,
    );
  }

  /// Directly eliminates one player chosen by the group (used by local
  /// pass-and-play, where voting happens out loud and the group simply taps
  /// who is out). Pass `null` for [playerId] to represent a tie / no
  /// elimination. Then checks for a winner like [resolveVotes] does.
  GameState eliminatePlayer(GameState state, String? playerId) {
    _expectPhase(state, GamePhase.voting);

    var players = state.players;
    if (playerId != null) {
      final target = state.playerById(playerId);
      if (target == null || !target.isAlive) {
        throw GameError('Can only eliminate a living player.');
      }
      players = _replacePlayer(players, playerId, (p) => p.copyWith(isAlive: false));
    }

    final winner = _checkWinner(players);
    return state.copyWith(
      players: players,
      lastEliminatedId: playerId,
      clearLastEliminated: playerId == null,
      phase: winner != null ? GamePhase.gameOver : GamePhase.reveal,
      winner: winner,
      clearWinner: winner == null,
    );
  }

  /// Starts the next clue round (used after a [GamePhase.reveal] with no
  /// winner yet). Clears clues and votes, bumps the round counter.
  GameState nextRound(GameState state) {
    _expectPhase(state, GamePhase.reveal);
    if (state.winner != null) {
      throw GameError('The game is already over.');
    }
    final reset = state.players
        .map((p) => p.copyWith(clearClue: true, clearVote: true))
        .toList(growable: false);
    return state.copyWith(
      players: reset,
      phase: GamePhase.clue,
      roundNumber: state.roundNumber + 1,
      currentTurnIndex: _firstAliveIndex(reset),
      clearLastEliminated: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Decides the winning side, or null if the game should continue.
  ///
  /// - Civilians win when every imposter is eliminated.
  /// - Imposters win when they equal or outnumber the living civilians.
  Role? _checkWinner(List<Player> players) {
    final alive = players.where((p) => p.isAlive);
    final imposters = alive.where((p) => p.isImposter).length;
    final civilians = alive.length - imposters;
    if (imposters == 0) return Role.civilian;
    if (imposters >= civilians) return Role.imposter;
    return null;
  }

  Set<int> _pickImposterIndices({
    required int playerCount,
    required int imposterCount,
  }) {
    final indices = List<int>.generate(playerCount, (i) => i);
    indices.shuffle(_random);
    return indices.take(imposterCount).toSet();
  }

  List<Player> _replacePlayer(
    List<Player> players,
    String id,
    Player Function(Player) update,
  ) {
    return players
        .map((p) => p.id == id ? update(p) : p)
        .toList(growable: false);
  }

  int _firstAliveIndex(List<Player> players) {
    final i = players.indexWhere((p) => p.isAlive);
    return i == -1 ? 0 : i;
  }

  /// Returns the index of the next alive player after [fromIndex], wrapping
  /// around the list. Falls back to [fromIndex] if none found.
  int _nextAliveIndex(List<Player> players, int fromIndex) {
    for (var step = 1; step <= players.length; step++) {
      final idx = (fromIndex + step) % players.length;
      if (players[idx].isAlive) return idx;
    }
    return fromIndex;
  }

  void _expectPhase(GameState state, GamePhase expected) {
    if (state.phase != expected) {
      throw GameError(
        'Action requires phase $expected but game is in ${state.phase}.',
      );
    }
  }
}
