import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/online/online_models.dart';
import '../data/online/room_repository.dart';

/// Low-level Firebase singletons.
final firebaseAuthProvider = Provider<FirebaseAuth>((_) => FirebaseAuth.instance);
final firestoreProvider =
    Provider<FirebaseFirestore>((_) => FirebaseFirestore.instance);

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  return RoomRepository(ref.read(firestoreProvider));
});

/// Signs the player in anonymously (no account needed) and returns the uid.
/// Cached for the app's lifetime so we reuse the same identity.
final authUidProvider = FutureProvider<String>((ref) async {
  final auth = ref.read(firebaseAuthProvider);
  final existing = auth.currentUser;
  if (existing != null) return existing.uid;
  final cred = await auth.signInAnonymously();
  return cred.user!.uid;
});

/// Live room document for a given code.
final roomStreamProvider =
    StreamProvider.family<OnlineRoom, String>((ref, code) {
  return ref.read(roomRepositoryProvider).watchRoom(code);
});

/// Live list of members in a room.
final membersStreamProvider =
    StreamProvider.family<List<OnlineMember>, String>((ref, code) {
  return ref.read(roomRepositoryProvider).watchMembers(code);
});

/// Live private role for the current player in a room.
/// The argument is the room code; we read the uid from auth.
final myRoleStreamProvider =
    StreamProvider.family<MyRole?, String>((ref, code) {
  final uid = ref.watch(authUidProvider).value;
  if (uid == null) return const Stream.empty();
  return ref.read(roomRepositoryProvider).watchMyRole(code, uid);
});
