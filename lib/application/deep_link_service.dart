import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../presentation/screens/online/online_menu_screen.dart';

/// Watches for incoming deep links (Android App Links + iOS Universal Links +
/// `?code=` query strings on the web build) and routes them into the online
/// flow.
///
/// Activate once at app startup via [start], passing the global navigator key
/// used by [MaterialApp]. The service handles BOTH the cold-start case
/// ([AppLinks.getInitialLink]) and the warm-start case ([AppLinks.uriLinkStream])
/// without you needing to think about it.
class DeepLinkService {
  DeepLinkService(this._navigatorKey);

  final GlobalKey<NavigatorState> _navigatorKey;
  final AppLinks _appLinks = AppLinks();

  StreamSubscription<Uri>? _subscription;

  /// True after the very first link has been routed, so we don't replay the
  /// initial link if the OS re-fires it during a config change.
  bool _routedInitial = false;

  /// Begin listening. Safe to call multiple times — repeats are no-ops.
  Future<void> start() async {
    _subscription ??= _appLinks.uriLinkStream.listen(_handle, onError: (_) {});

    // Cold start: the OS hands us the launch URL once and only once.
    if (!_routedInitial) {
      try {
        final initial = await _appLinks.getInitialLink();
        if (initial != null) {
          // Defer the navigation a tick so the MaterialApp has had time to
          // build and the navigator key is attached.
          WidgetsBinding.instance.addPostFrameCallback((_) => _handle(initial));
        }
      } catch (_) {
        // ignore — app_links throws if no launch URL is available.
      }
      _routedInitial = true;
    }

    // On Flutter web there's no native link stream — instead we parse the
    // browser URL on startup so `?code=ABC123` on the home page still works.
    if (kIsWeb) {
      final webUri = Uri.base;
      if (extractRoomCode(webUri) != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _handle(webUri));
      }
    }
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  void _handle(Uri uri) {
    final code = extractRoomCode(uri);
    if (code == null) return;
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;
    // Push the online menu with the code pre-filled. We use pushAndRemoveUntil
    // so the user lands on a sensible back-stack (deep-link → menu → lobby).
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => OnlineMenuScreen(pendingJoinCode: code),
      ),
      (route) => route.isFirst,
    );
  }

  /// Returns the 6-character room code carried by [uri], if any. Accepts:
  ///   • `https://<host>/join?code=ABC123`
  ///   • `https://<host>/?code=ABC123`     (web build short form)
  ///   • `imposter://join?code=ABC123`     (future custom scheme)
  ///
  /// The room-code alphabet is the same one [RoomRepository._generateCode]
  /// uses: uppercase A-Z minus I/O plus 2-9, exactly six characters.
  static final RegExp _codeRe = RegExp(r'^[A-HJ-NP-Z2-9]{6}$');

  static String? extractRoomCode(Uri uri) {
    final raw = uri.queryParameters['code'];
    if (raw == null) return null;
    final upper = raw.toUpperCase().trim();
    return _codeRe.hasMatch(upper) ? upper : null;
  }

  /// Builds the canonical share URL for [roomCode]. Single source of truth so
  /// the lobby Share button and the deep-link parser never disagree.
  static String buildJoinUrl(String roomCode) =>
      'https://imposter-game-89391.web.app/join?code=$roomCode';
}
