import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:imposter_game/domain/engine/game_engine.dart';
import 'package:imposter_game/domain/models/enums.dart';
import 'package:imposter_game/domain/models/game_config.dart';
import 'package:imposter_game/domain/models/game_state.dart';

/// Helper that builds a config quickly.
GameConfig cfg({int imposters = 1, String theme = 'Animals'}) => GameConfig(
      mode: GameMode.local,
      themeName: theme,
      imposterCount: imposters,
    );

const fiveNames = ['Ana', 'Ben', 'Cara', 'Dan', 'Eve'];
const wordPool = ['Elephant', 'Penguin', 'Dolphin'];

/// Uses a seeded engine so role/word selection is deterministic in tests.
GameEngine seededEngine() => GameEngine(Random(42));

void main() {
  group('startGame validation', () {
    final engine = seededEngine();

    test('throws with fewer than 3 players', () {
      expect(
        () => engine.startGame(
          config: cfg(),
          names: ['Ana', 'Ben'],
          wordPool: wordPool,
        ),
        throwsA(isA<GameError>()),
      );
    });

    test('throws with more than 15 players', () {
      expect(
        () => engine.startGame(
          config: cfg(),
          names: List.generate(16, (i) => 'P$i'),
          wordPool: wordPool,
        ),
        throwsA(isA<GameError>()),
      );
    });

    test('throws on empty word pool', () {
      expect(
        () => engine.startGame(config: cfg(), names: fiveNames, wordPool: []),
        throwsA(isA<GameError>()),
      );
    });

    test('throws when imposter count is too high to be fair', () {
      expect(
        () => engine.startGame(
          config: cfg(imposters: 3), // 3 imposters of 5 = majority
          names: fiveNames,
          wordPool: wordPool,
        ),
        throwsA(isA<GameError>()),
      );
    });
  });

  group('startGame setup', () {
    test('assigns exactly the requested number of imposters', () {
      final engine = seededEngine();
      final state = engine.startGame(
        config: cfg(imposters: 2),
        names: List.generate(7, (i) => 'P$i'),
        wordPool: wordPool,
      );
      final imposters = state.players.where((p) => p.isImposter).length;
      expect(imposters, 2);
      expect(state.players.length, 7);
      expect(state.phase, GamePhase.roleReveal);
    });

    test('picks the secret word from the pool', () {
      final engine = seededEngine();
      final state = engine.startGame(
        config: cfg(),
        names: fiveNames,
        wordPool: wordPool,
      );
      expect(wordPool, contains(state.secretWord));
    });

    test('gives every player a unique id', () {
      final engine = seededEngine();
      final state = engine.startGame(
        config: cfg(),
        names: fiveNames,
        wordPool: wordPool,
      );
      final ids = state.players.map((p) => p.id).toSet();
      expect(ids.length, state.players.length);
    });
  });

  group('clue phase', () {
    late GameEngine engine;
    late GameState state;

    setUp(() {
      engine = seededEngine();
      state = engine.startGame(
        config: cfg(),
        names: fiveNames,
        wordPool: ['Elephant'], // force known secret word
      );
      state = engine.beginCluePhase(state);
    });

    test('rejects an empty clue', () {
      expect(engine.validateClue(state, '   '), isNotNull);
    });

    test('rejects a clue containing the secret word (case-insensitive)', () {
      expect(engine.validateClue(state, 'big ELEPHANT'), isNotNull);
    });

    test('accepts a normal clue', () {
      expect(engine.validateClue(state, 'trunk'), isNull);
    });

    test('submitClue stores the clue and advances the turn', () {
      final first = state.players[state.currentTurnIndex];
      final next = engine.submitClue(state, first.id, 'trunk');
      expect(next.playerById(first.id)!.clue, 'trunk');
      expect(next.currentTurnIndex, isNot(state.currentTurnIndex));
    });
  });

  group('voting and elimination', () {
    late GameEngine engine;
    late GameState state;

    setUp(() {
      engine = seededEngine();
      state = engine.startGame(
        config: cfg(),
        names: fiveNames,
        wordPool: ['Elephant'],
      );
      state = engine.beginCluePhase(state);
      state = engine.openVoting(state);
    });

    test('eliminates the player with the most votes', () {
      final target = state.players[2];
      // Four players vote for target, one (target) votes elsewhere.
      state = engine.castVote(state, state.players[0].id, target.id);
      state = engine.castVote(state, state.players[1].id, target.id);
      state = engine.castVote(state, state.players[3].id, target.id);
      state = engine.castVote(state, state.players[4].id, target.id);
      state = engine.castVote(state, target.id, state.players[0].id);

      final resolved = engine.resolveVotes(state);
      expect(resolved.lastEliminatedId, target.id);
      expect(resolved.playerById(target.id)!.isAlive, isFalse);
    });

    test('a tie eliminates nobody', () {
      // 2 votes for players[0], 2 votes for players[1], 1 abstain-ish.
      state = engine.castVote(state, state.players[2].id, state.players[0].id);
      state = engine.castVote(state, state.players[3].id, state.players[0].id);
      state = engine.castVote(state, state.players[0].id, state.players[1].id);
      state = engine.castVote(state, state.players[1].id, state.players[1].id);

      final resolved = engine.resolveVotes(state);
      expect(resolved.lastEliminatedId, isNull);
      expect(resolved.alivePlayers.length, 5);
    });
  });

  group('win conditions', () {
    test('civilians win when the last imposter is voted out', () {
      // 3 players, 1 imposter. Vote the imposter out -> civilians win.
      final engine = seededEngine();
      var state = engine.startGame(
        config: cfg(imposters: 1),
        names: ['Ana', 'Ben', 'Cara'],
        wordPool: ['Elephant'],
      );
      final imposter = state.players.firstWhere((p) => p.isImposter);
      final civilians = state.players.where((p) => !p.isImposter).toList();

      state = engine.beginCluePhase(state);
      state = engine.openVoting(state);
      state = engine.castVote(state, civilians[0].id, imposter.id);
      state = engine.castVote(state, civilians[1].id, imposter.id);
      state = engine.castVote(state, imposter.id, civilians[0].id);

      final resolved = engine.resolveVotes(state);
      expect(resolved.winner, Role.civilian);
      expect(resolved.phase, GamePhase.gameOver);
    });

    test('imposters win when they reach parity with civilians', () {
      // 3 players, 1 imposter. Vote a civilian out -> 1 imposter vs 1 civ.
      final engine = seededEngine();
      var state = engine.startGame(
        config: cfg(imposters: 1),
        names: ['Ana', 'Ben', 'Cara'],
        wordPool: ['Elephant'],
      );
      final imposter = state.players.firstWhere((p) => p.isImposter);
      final civilians = state.players.where((p) => !p.isImposter).toList();

      state = engine.beginCluePhase(state);
      state = engine.openVoting(state);
      // Everyone piles onto civilian[0].
      state = engine.castVote(state, imposter.id, civilians[0].id);
      state = engine.castVote(state, civilians[1].id, civilians[0].id);
      state = engine.castVote(state, civilians[0].id, civilians[1].id);

      final resolved = engine.resolveVotes(state);
      expect(resolved.playerById(civilians[0].id)!.isAlive, isFalse);
      expect(resolved.winner, Role.imposter);
      expect(resolved.phase, GamePhase.gameOver);
    });
  });

  group('eliminatePlayer (local tap-to-eliminate)', () {
    late GameEngine engine;
    late GameState state;

    setUp(() {
      engine = seededEngine();
      state = engine.startGame(
        config: cfg(),
        names: fiveNames,
        wordPool: ['Elephant'],
      );
      state = engine.beginCluePhase(state);
      state = engine.openVoting(state);
    });

    test('eliminates the chosen player', () {
      final victim = state.players[1];
      final resolved = engine.eliminatePlayer(state, victim.id);
      expect(resolved.playerById(victim.id)!.isAlive, isFalse);
      expect(resolved.lastEliminatedId, victim.id);
    });

    test('null means a tie / nobody out', () {
      final resolved = engine.eliminatePlayer(state, null);
      expect(resolved.lastEliminatedId, isNull);
      expect(resolved.alivePlayers.length, 5);
      expect(resolved.phase, GamePhase.reveal);
    });
  });

  group('nextRound', () {
    test('clears clues/votes and bumps the round counter', () {
      final engine = seededEngine();
      var state = engine.startGame(
        config: cfg(),
        names: fiveNames,
        wordPool: ['Elephant'],
      );
      state = engine.beginCluePhase(state);
      // Give one clue, then vote out someone who is NOT the last imposter,
      // ensuring the game continues (5 players, 1 imposter -> vote a civilian
      // leaves 1 imposter vs 3 civilians, no winner yet).
      state = engine.openVoting(state);
      final imposter = state.players.firstWhere((p) => p.isImposter);
      final civ = state.players.firstWhere((p) => !p.isImposter);
      for (final voter in state.alivePlayers) {
        if (voter.id == civ.id) {
          state = engine.castVote(state, voter.id, imposter.id);
        } else {
          state = engine.castVote(state, voter.id, civ.id);
        }
      }
      state = engine.resolveVotes(state);
      expect(state.phase, GamePhase.reveal); // game continues

      final next = engine.nextRound(state);
      expect(next.roundNumber, 2);
      expect(next.phase, GamePhase.clue);
      expect(next.players.every((p) => p.clue == null), isTrue);
      expect(next.players.every((p) => p.voteTargetId == null), isTrue);
    });
  });
}
