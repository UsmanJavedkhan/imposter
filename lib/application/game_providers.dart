import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/word_repository.dart';
import '../domain/engine/game_engine.dart';
import '../domain/models/enums.dart';
import '../domain/models/game_config.dart';
import '../domain/models/game_state.dart';
import '../domain/models/game_theme.dart';

/// Single shared word repository for the whole app.
final wordRepositoryProvider = Provider<WordRepository>((ref) {
  return WordRepository();
});

/// Loads the themes once and exposes them to the UI (loading/error/data).
final themesProvider = FutureProvider<List<GameTheme>>((ref) {
  return ref.read(wordRepositoryProvider).loadThemes();
});

/// Bundles the game with a little local-only UI state (which player is
/// currently revealing their role during pass-and-play).
class GameSession {
  /// Null before a game has started.
  final GameState? game;

  /// Index of the player currently looking at their role in roleReveal.
  final int revealIndex;

  const GameSession({this.game, this.revealIndex = 0});

  GameSession copyWith({GameState? game, int? revealIndex}) => GameSession(
        game: game ?? this.game,
        revealIndex: revealIndex ?? this.revealIndex,
      );
}

/// Drives the game by calling the pure engine and publishing new states.
///
/// The UI never touches the engine directly — it calls these methods, and
/// rebuilds whenever the published [GameSession] changes.
class GameController extends Notifier<GameSession> {
  final GameEngine _engine = GameEngine();
  final List<String> _recentWords = [];

  @override
  GameSession build() => const GameSession();

  /// Convenience getter for the current game (may be null).
  GameState? get _game => state.game;

  /// Sets up a brand-new local game.
  void startLocalGame({
    required List<String> names,
    required GameTheme theme,
    required int imposterCount,
  }) {
    final repo = ref.read(wordRepositoryProvider);
    final word = repo.randomWord(theme, recent: _recentWords.toSet());
    _rememberWord(word);

    final config = GameConfig(
      mode: GameMode.local,
      themeName: theme.name,
      imposterCount: imposterCount,
    );

    // Pass a single-word pool so the engine uses the word we picked
    // (which already honours the "avoid recent repeats" rule).
    final game = _engine.startGame(
      config: config,
      names: names,
      wordPool: [word],
    );
    state = GameSession(game: game, revealIndex: 0);
  }

  /// Advance to the next player during the role-reveal pass-around.
  void nextReveal() {
    state = state.copyWith(revealIndex: state.revealIndex + 1);
  }

  /// All players have seen their role -> start giving clues.
  void beginClues() {
    final g = _game;
    if (g == null) return;
    state = state.copyWith(game: _engine.beginCluePhase(g));
  }

  /// Move from clue-giving into the voting phase.
  void openVoting() {
    final g = _game;
    if (g == null) return;
    state = state.copyWith(game: _engine.openVoting(g));
  }

  /// The group decided who is out (or null for a tie / no elimination).
  void eliminate(String? playerId) {
    final g = _game;
    if (g == null) return;
    state = state.copyWith(game: _engine.eliminatePlayer(g, playerId));
  }

  /// Start another clue round when nobody has won yet.
  void nextRound() {
    final g = _game;
    if (g == null) return;
    state = state.copyWith(game: _engine.nextRound(g), revealIndex: 0);
  }

  /// Clear everything and return to the lobby/home.
  void reset() {
    state = const GameSession();
  }

  void _rememberWord(String word) {
    _recentWords.add(word);
    // Keep the recent list small so we don't block too many words.
    while (_recentWords.length > 20) {
      _recentWords.removeAt(0);
    }
  }
}

/// The provider the UI watches/reads to play the game.
final gameControllerProvider =
    NotifierProvider<GameController, GameSession>(GameController.new);
