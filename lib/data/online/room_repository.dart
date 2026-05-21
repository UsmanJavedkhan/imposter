import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/enums.dart';
import 'online_models.dart';

/// Talks to Firestore for everything online. Host-authoritative: the host's
/// device assigns roles and advances phases; other devices read and react.
class RoomRepository {
  RoomRepository(this._db);

  final FirebaseFirestore _db;
  final Random _random = Random();

  // Avoid ambiguous characters (0/O, 1/I) in room codes.
  static const _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  CollectionReference<Map<String, dynamic>> get _rooms => _db.collection('rooms');
  DocumentReference<Map<String, dynamic>> _room(String code) => _rooms.doc(code);
  CollectionReference<Map<String, dynamic>> _members(String code) =>
      _room(code).collection('members');

  String _generateCode() => List.generate(
        6,
        (_) => _codeAlphabet[_random.nextInt(_codeAlphabet.length)],
      ).join();

  // ---- Live streams the UI listens to -------------------------------------

  Stream<OnlineRoom> watchRoom(String code) =>
      _room(code).snapshots().map(OnlineRoom.fromDoc);

  Stream<List<OnlineMember>> watchMembers(String code) =>
      _members(code).snapshots().map((q) {
        final list = q.docs.map(OnlineMember.fromDoc).toList();
        // Stable order by join time (host first). Members with no timestamp
        // yet (write still propagating) sort last.
        list.sort((a, b) {
          final at = a.joinedAt;
          final bt = b.joinedAt;
          if (at == null && bt == null) return 0;
          if (at == null) return 1;
          if (bt == null) return -1;
          return at.compareTo(bt);
        });
        return List<OnlineMember>.unmodifiable(list);
      });

  Stream<MyRole?> watchMyRole(String code, String uid) => _room(code)
      .collection('private')
      .doc(uid)
      .snapshots()
      .map((d) => d.exists ? MyRole.fromDoc(d) : null);

  // ---- Lobby ---------------------------------------------------------------

  /// Creates a new room and returns its code. Retries on code collisions.
  Future<String> createRoom({
    required String uid,
    required String hostName,
    required String themeName,
    required int imposterCount,
  }) async {
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = _generateCode();
      final ref = _room(code);
      final exists = (await ref.get()).exists;
      if (exists) continue;

      await ref.set({
        'hostId': uid,
        'status': 'lobby',
        'phase': GamePhase.lobby.name,
        'themeName': themeName,
        'imposterCount': imposterCount,
        'roundNumber': 1,
        'winner': null,
        'lastEliminatedId': null,
        'playerOrder': [uid],
        'revealedSecretWord': null,
        'revealedRoles': <String, String>{},
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _members(code).doc(uid).set({
        'name': hostName,
        'isAlive': true,
        'isConnected': true,
        'isHost': true,
        'voteTargetId': null,
        'joinedAt': FieldValue.serverTimestamp(),
      });
      return code;
    }
    throw Exception('Could not create a room. Please try again.');
  }

  /// Joins an existing lobby. Throws if missing or already started.
  Future<void> joinRoom({
    required String code,
    required String uid,
    required String name,
  }) async {
    final snap = await _room(code).get();
    if (!snap.exists) {
      throw Exception('Room "$code" not found.');
    }
    final room = OnlineRoom.fromDoc(snap);
    if (room.status != 'lobby') {
      throw Exception('That game has already started.');
    }
    // Only write our OWN member doc. Guests may not write the room doc.
    await _members(code).doc(uid).set({
      'name': name,
      'isAlive': true,
      'isConnected': true,
      'isHost': false,
      'voteTargetId': null,
      'joinedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Mark presence (called on connect/disconnect-ish lifecycle changes).
  Future<void> setConnected(String code, String uid, bool connected) =>
      _members(code).doc(uid).update({'isConnected': connected});

  /// A player leaves the lobby (only deletes their own member doc).
  Future<void> leave(String code, String uid) async {
    await _members(code).doc(uid).delete();
  }

  // ---- Host: start the game ------------------------------------------------

  /// HOST ONLY. Assigns roles, writes each player's private role/word, stores
  /// a host-only secret map, and moves the room into role reveal.
  Future<void> startGame({
    required String code,
    required String secretWord,
  }) async {
    final roomSnap = await _room(code).get();
    final room = OnlineRoom.fromDoc(roomSnap);
    final memberDocs = await _members(code).get();
    final uids = memberDocs.docs.map((d) => d.id).toList();

    // Choose imposters.
    final shuffled = [...uids]..shuffle(_random);
    final imposters = shuffled.take(room.imposterCount).toSet();

    final batch = _db.batch();
    final roleMap = <String, String>{};

    for (final uid in uids) {
      final isImposter = imposters.contains(uid);
      final role = isImposter ? Role.imposter : Role.civilian;
      roleMap[uid] = role.name;
      batch.set(_room(code).collection('private').doc(uid), {
        'role': role.name,
        // Only civilians get the word; imposters never receive it.
        'secretWord': isImposter ? null : secretWord,
        'themeName': room.themeName,
      });
    }

    // Host-only copy so the host can detect winners later.
    batch.set(_room(code).collection('secret').doc('state'), {
      'roles': roleMap,
      'secretWord': secretWord,
    });

    batch.update(_room(code), {
      'status': 'playing',
      'phase': GamePhase.roleReveal.name,
      'roundNumber': 1,
      'winner': null,
      'lastEliminatedId': null,
      'lastEliminatedRole': null,
      'revealedSecretWord': null,
      'revealedRoles': <String, String>{},
    });

    await batch.commit();
  }

  // ---- Host: phase transitions --------------------------------------------

  Future<void> setPhase(String code, GamePhase phase) =>
      _room(code).update({'phase': phase.name});

  /// HOST ONLY. Opens voting and clears everyone's previous vote.
  Future<void> openVoting(String code) async {
    final members = await _members(code).get();
    final batch = _db.batch();
    for (final m in members.docs) {
      batch.update(m.reference, {'voteTargetId': null});
    }
    batch.update(_room(code), {'phase': GamePhase.voting.name});
    await batch.commit();
  }

  /// Any living player records their vote.
  Future<void> castVote(String code, String uid, String targetId) =>
      _members(code).doc(uid).update({'voteTargetId': targetId});

  /// HOST ONLY. Tallies votes, eliminates the top (tie = nobody), checks the
  /// winner using the host-only role map, and advances the phase.
  Future<void> resolveVotes(String code) async {
    final membersSnap = await _members(code).get();
    final members = membersSnap.docs.map(OnlineMember.fromDoc).toList();
    final secretSnap = await _room(code).collection('secret').doc('state').get();
    final secret = secretSnap.data() ?? const {};
    final roleMap = (secret['roles'] as Map<String, dynamic>? ?? const {})
        .map((k, v) => MapEntry(k, v.toString()));
    final secretWord = secret['secretWord'] as String?;

    // Tally votes among living players.
    final tally = <String, int>{};
    for (final m in members.where((m) => m.isAlive)) {
      final t = m.voteTargetId;
      if (t != null) tally[t] = (tally[t] ?? 0) + 1;
    }

    String? eliminatedId;
    if (tally.isNotEmpty) {
      final maxVotes = tally.values.reduce(max);
      final top = tally.entries.where((e) => e.value == maxVotes).toList();
      if (top.length == 1) eliminatedId = top.first.key;
    }

    // Compute alive counts AFTER the (possible) elimination.
    final aliveAfter = <OnlineMember>[
      for (final m in members)
        if (m.isAlive && m.uid != eliminatedId) m,
    ];
    final aliveImposters =
        aliveAfter.where((m) => roleMap[m.uid] == Role.imposter.name).length;
    final aliveCivilians = aliveAfter.length - aliveImposters;

    Role? winner;
    if (aliveImposters == 0) {
      winner = Role.civilian;
    } else if (aliveImposters >= aliveCivilians) {
      winner = Role.imposter;
    }

    final batch = _db.batch();
    if (eliminatedId != null) {
      batch.update(_members(code).doc(eliminatedId), {'isAlive': false});
    }
    final update = <String, dynamic>{
      'lastEliminatedId': eliminatedId,
      'lastEliminatedRole':
          eliminatedId != null ? roleMap[eliminatedId] : null,
      'phase': (winner != null ? GamePhase.gameOver : GamePhase.reveal).name,
      'winner': winner?.name,
    };
    if (winner != null) {
      // Reveal the truth to everyone now that the game is over.
      update['revealedSecretWord'] = secretWord;
      update['revealedRoles'] = roleMap;
      update['status'] = 'finished';
    }
    batch.update(_room(code), update);
    await batch.commit();
  }

  /// HOST ONLY. Starts the next clue round (roles persist).
  Future<void> nextRound(String code) async {
    final roomSnap = await _room(code).get();
    final room = OnlineRoom.fromDoc(roomSnap);
    final members = await _members(code).get();
    final batch = _db.batch();
    for (final m in members.docs) {
      batch.update(m.reference, {'voteTargetId': null});
    }
    batch.update(_room(code), {
      'phase': GamePhase.clue.name,
      'roundNumber': room.roundNumber + 1,
      'lastEliminatedId': null,
      'lastEliminatedRole': null,
    });
    await batch.commit();
  }
}
