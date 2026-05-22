import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/online/online_models.dart';
import 'online_providers.dart';

/// Shared presence + host-migration logic for the online screens.
///
/// Mix this into a [ConsumerState] that also `with WidgetsBindingObserver`.
/// The host of a room is the only device allowed to advance the game, so if
/// the host disconnects we promote the earliest-still-connected member to
/// host. Presence itself is best-effort, driven by the app lifecycle.
mixin RoomPresenceMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// The room code the screen is showing.
  String get roomCode;

  bool _claimingHost = false;

  /// Call from `initState` (after `super.initState()`).
  void startPresence() {
    WidgetsBinding.instance.addObserver(this as WidgetsBindingObserver);
    _setConnected(true);
  }

  /// Call from `dispose` (before `super.dispose()`).
  void stopPresence() {
    WidgetsBinding.instance.removeObserver(this as WidgetsBindingObserver);
    _setConnected(false);
  }

  /// Wire this up from `didChangeAppLifecycleState`.
  void handleLifecycle(AppLifecycleState state) {
    _setConnected(state == AppLifecycleState.resumed);
  }

  void _setConnected(bool connected) {
    final uid = ref.read(authUidProvider).value;
    if (uid == null) return;
    ref.read(roomRepositoryProvider).setConnected(roomCode, uid, connected);
  }

  /// If the host is missing/disconnected, the earliest connected member claims
  /// the host role. Safe to call on every build — it self-guards and the
  /// security rules reject all but the first concurrent claim. Call with the
  /// latest [room] and [members] (members must be sorted by join time).
  void maybeMigrateHost(OnlineRoom room, List<OnlineMember> members) {
    if (_claimingHost) return;
    final uid = ref.read(authUidProvider).value;
    if (uid == null || room.hostId == uid) return;

    final host = members.where((m) => m.uid == room.hostId).firstOrNull;
    final hostAbsent = host == null || !host.isConnected;
    if (!hostAbsent) return;

    // Earliest connected member that isn't the absent host wins the election.
    final candidate = members
        .where((m) => m.isConnected && m.uid != room.hostId)
        .firstOrNull;
    if (candidate == null || candidate.uid != uid) return;

    _claimingHost = true;
    ref.read(roomRepositoryProvider).claimHost(roomCode, uid).whenComplete(() {
      _claimingHost = false;
    });
  }
}
