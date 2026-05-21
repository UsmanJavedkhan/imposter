import 'enums.dart';

/// A single participant in a game.
///
/// This class is *immutable*: once created, its fields never change.
/// To "change" a player we make a new copy with [copyWith]. This makes the
/// game state predictable and easy to test, which is the whole point of
/// keeping the engine pure.
class Player {
  /// Stable identifier (e.g. "p0", "p1", or an auth id online).
  final String id;

  /// Display name shown in the UI.
  final String name;

  /// Whether this player is a civilian or an imposter.
  final Role role;

  /// False once the player has been voted out.
  final bool isAlive;

  /// The clue this player gave in the current clue round (null if not yet).
  final String? clue;

  /// The id of the player this player voted for (null if not yet voted).
  final String? voteTargetId;

  const Player({
    required this.id,
    required this.name,
    required this.role,
    this.isAlive = true,
    this.clue,
    this.voteTargetId,
  });

  /// Convenience: is this player an imposter?
  bool get isImposter => role == Role.imposter;

  /// Returns a new Player with the given fields replaced.
  ///
  /// Note: because `clue` and `voteTargetId` are nullable, we use small
  /// "clear" flags so callers can explicitly reset them back to null.
  Player copyWith({
    String? name,
    Role? role,
    bool? isAlive,
    String? clue,
    bool clearClue = false,
    String? voteTargetId,
    bool clearVote = false,
  }) {
    return Player(
      id: id,
      name: name ?? this.name,
      role: role ?? this.role,
      isAlive: isAlive ?? this.isAlive,
      clue: clearClue ? null : (clue ?? this.clue),
      voteTargetId: clearVote ? null : (voteTargetId ?? this.voteTargetId),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Player &&
      other.id == id &&
      other.name == name &&
      other.role == role &&
      other.isAlive == isAlive &&
      other.clue == clue &&
      other.voteTargetId == voteTargetId;

  @override
  int get hashCode =>
      Object.hash(id, name, role, isAlive, clue, voteTargetId);

  @override
  String toString() =>
      'Player($id, $name, $role, alive=$isAlive, clue=$clue, vote=$voteTargetId)';
}
