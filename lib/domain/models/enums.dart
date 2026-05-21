// Core enums shared across the game domain.
//
// Kept in one small file so the rest of the engine can import a single
// place for the "vocabulary" of the game.

/// What a player is in a given game.
enum Role {
  /// Knows the secret word. Tries to find and vote out the imposters.
  civilian,

  /// Does NOT know the secret word (only the theme). Tries to blend in.
  imposter,
}

/// The current stage of a game. The game moves through these in order,
/// looping between [clue] and [reveal] until someone wins.
enum GamePhase {
  /// Players are being added / settings chosen. No roles assigned yet.
  lobby,

  /// Each player privately looks at their role (and word, if civilian).
  roleReveal,

  /// Players take turns giving a one-word clue.
  clue,

  /// Everyone votes for who they think the imposter is.
  voting,

  /// The result of the vote is shown (who was eliminated).
  reveal,

  /// The game is finished; [GameState.winner] holds the winning side.
  gameOver,
}

/// How the game is being played.
enum GameMode {
  /// One shared device passed around the group.
  local,

  /// Multiple devices joined to the same online room.
  online,
}
