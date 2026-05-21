import 'enums.dart';
import 'game_config.dart';
import 'player.dart';

/// A complete snapshot of a game at one moment in time.
///
/// This is the single source of truth. The engine never mutates a GameState;
/// every action returns a brand-new GameState. Given the same inputs you
/// always get the same output, which makes the whole game easy to test and
/// (later) to sync over a network.
class GameState {
  final GameConfig config;
  final List<Player> players;

  /// The word civilians can see. Imposters must not be shown this.
  final String secretWord;

  final GamePhase phase;

  /// 1-based round counter (a "round" = one clue + vote cycle).
  final int roundNumber;

  /// Index into [players] for whose turn it is to give a clue.
  final int currentTurnIndex;

  /// Who was eliminated by the most recent vote (null if a tie / nobody).
  final String? lastEliminatedId;

  /// The winning side once [phase] is [GamePhase.gameOver]; otherwise null.
  final Role? winner;

  const GameState({
    required this.config,
    required this.players,
    required this.secretWord,
    required this.phase,
    this.roundNumber = 1,
    this.currentTurnIndex = 0,
    this.lastEliminatedId,
    this.winner,
  });

  // ---- Handy read-only helpers (computed, not stored) ----

  List<Player> get alivePlayers =>
      players.where((p) => p.isAlive).toList(growable: false);

  List<Player> get aliveImposters =>
      alivePlayers.where((p) => p.isImposter).toList(growable: false);

  List<Player> get aliveCivilians =>
      alivePlayers.where((p) => !p.isImposter).toList(growable: false);

  bool get isGameOver => phase == GamePhase.gameOver;

  /// Find a player by id, or null if not present.
  Player? playerById(String id) {
    for (final p in players) {
      if (p.id == id) return p;
    }
    return null;
  }

  GameState copyWith({
    GameConfig? config,
    List<Player>? players,
    String? secretWord,
    GamePhase? phase,
    int? roundNumber,
    int? currentTurnIndex,
    String? lastEliminatedId,
    bool clearLastEliminated = false,
    Role? winner,
    bool clearWinner = false,
  }) {
    return GameState(
      config: config ?? this.config,
      players: players ?? this.players,
      secretWord: secretWord ?? this.secretWord,
      phase: phase ?? this.phase,
      roundNumber: roundNumber ?? this.roundNumber,
      currentTurnIndex: currentTurnIndex ?? this.currentTurnIndex,
      lastEliminatedId:
          clearLastEliminated ? null : (lastEliminatedId ?? this.lastEliminatedId),
      winner: clearWinner ? null : (winner ?? this.winner),
    );
  }

  @override
  String toString() =>
      'GameState(phase=$phase, round=$roundNumber, players=${players.length}, '
      'aliveImp=${aliveImposters.length}, aliveCiv=${aliveCivilians.length}, '
      'winner=$winner)';
}
