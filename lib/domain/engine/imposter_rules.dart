/// Pure functions that decide how many imposters a game should have.
///
/// These match the balancing table from the design document:
///   3-5 players  -> 1 imposter
///   6-8 players  -> 2 imposters
///   9-12 players -> 3 imposters
///   13+ players  -> ceil(players / 4)
library;

/// The minimum number of players required to start a game.
const int kMinPlayers = 3;

/// The maximum number of players we support in one game.
const int kMaxPlayers = 15;

/// Suggested imposter count for a given [playerCount].
int suggestImposterCount(int playerCount) {
  if (playerCount <= 5) return 1;
  if (playerCount <= 8) return 2;
  if (playerCount <= 12) return 3;
  return (playerCount / 4).ceil();
}

/// The largest number of imposters that is still *fair* (imposters must
/// start as a minority, otherwise they auto-win immediately).
///
/// Example: 5 players -> floor((5-1)/2) = 2.
int maxImposters(int playerCount) => ((playerCount - 1) / 2).floor();

/// Whether [imposterCount] is a legal choice for [playerCount].
bool isValidImposterCount(int playerCount, int imposterCount) {
  return imposterCount >= 1 && imposterCount <= maxImposters(playerCount);
}
