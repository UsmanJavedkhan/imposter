import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/enums.dart';

/// Helpers to safely turn stored strings back into our enums.
GamePhase _phaseFromString(String? s) {
  for (final p in GamePhase.values) {
    if (p.name == s) return p;
  }
  return GamePhase.lobby;
}

Role? _roleFromString(String? s) {
  if (s == null) return null;
  for (final r in Role.values) {
    if (r.name == s) return r;
  }
  return null;
}

/// Mirror of a `rooms/{code}` document.
class OnlineRoom {
  final String code;
  final String hostId;

  /// "lobby" | "playing" | "finished".
  final String status;

  final GamePhase phase;
  final String themeName;
  final int imposterCount;
  final int roundNumber;

  /// Winning side, only set when the game is over.
  final Role? winner;

  /// Who the last vote eliminated (null = tie / nobody).
  final String? lastEliminatedId;

  /// The role of the last eliminated player (revealed to everyone).
  final Role? lastEliminatedRole;

  /// Stable join order of player uids (used for clue turn order).
  final List<String> playerOrder;

  /// Revealed only at game over so everyone can see the truth.
  final String? revealedSecretWord;
  final Map<String, String> revealedRoles;

  const OnlineRoom({
    required this.code,
    required this.hostId,
    required this.status,
    required this.phase,
    required this.themeName,
    required this.imposterCount,
    required this.roundNumber,
    required this.winner,
    required this.lastEliminatedId,
    required this.lastEliminatedRole,
    required this.playerOrder,
    required this.revealedSecretWord,
    required this.revealedRoles,
  });

  bool get isGameOver => phase == GamePhase.gameOver;

  factory OnlineRoom.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return OnlineRoom(
      code: doc.id,
      hostId: d['hostId'] as String? ?? '',
      status: d['status'] as String? ?? 'lobby',
      phase: _phaseFromString(d['phase'] as String?),
      themeName: d['themeName'] as String? ?? '',
      imposterCount: (d['imposterCount'] as num?)?.toInt() ?? 1,
      roundNumber: (d['roundNumber'] as num?)?.toInt() ?? 1,
      winner: _roleFromString(d['winner'] as String?),
      lastEliminatedId: d['lastEliminatedId'] as String?,
      lastEliminatedRole: _roleFromString(d['lastEliminatedRole'] as String?),
      playerOrder:
          (d['playerOrder'] as List<dynamic>? ?? const []).cast<String>(),
      revealedSecretWord: d['revealedSecretWord'] as String?,
      revealedRoles:
          (d['revealedRoles'] as Map<String, dynamic>? ?? const {})
              .map((k, v) => MapEntry(k, v.toString())),
    );
  }
}

/// Mirror of a `rooms/{code}/members/{uid}` document.
class OnlineMember {
  final String uid;
  final String name;
  final bool isAlive;
  final bool isConnected;
  final bool isHost;
  final String? voteTargetId;

  /// When the player joined — used to order players (e.g. clue turn order).
  final DateTime? joinedAt;

  const OnlineMember({
    required this.uid,
    required this.name,
    required this.isAlive,
    required this.isConnected,
    required this.isHost,
    required this.voteTargetId,
    required this.joinedAt,
  });

  factory OnlineMember.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    final ts = d['joinedAt'];
    return OnlineMember(
      uid: doc.id,
      name: d['name'] as String? ?? 'Player',
      isAlive: d['isAlive'] as bool? ?? true,
      isConnected: d['isConnected'] as bool? ?? true,
      isHost: d['isHost'] as bool? ?? false,
      voteTargetId: d['voteTargetId'] as String?,
      joinedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

/// The current player's private role info (from `private/{uid}`).
class MyRole {
  final Role role;
  final String? secretWord; // null for imposters
  final String themeName;

  const MyRole({
    required this.role,
    required this.secretWord,
    required this.themeName,
  });

  bool get isImposter => role == Role.imposter;

  factory MyRole.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return MyRole(
      role: _roleFromString(d['role'] as String?) ?? Role.civilian,
      secretWord: d['secretWord'] as String?,
      themeName: d['themeName'] as String? ?? '',
    );
  }
}
