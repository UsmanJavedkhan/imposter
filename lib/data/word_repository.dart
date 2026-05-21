import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

import '../domain/models/game_theme.dart';

/// Loads the bundled word library and helps pick secret words.
///
/// Loading from the asset bundle is kept separate from JSON parsing so the
/// parsing logic ([parseThemes]) can be unit-tested without Flutter.
class WordRepository {
  static const String assetPath = 'assets/words/themes.json';

  final Random _random;
  List<GameTheme>? _cache;

  WordRepository([Random? random]) : _random = random ?? Random();

  /// Pure function: turn the raw JSON string into a list of themes.
  /// Throws [FormatException] if the JSON is malformed.
  static List<GameTheme> parseThemes(String jsonString) {
    final decoded = json.decode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('themes.json root must be an object');
    }
    final themes = decoded['themes'];
    if (themes is! List) {
      throw const FormatException('themes.json must have a "themes" array');
    }
    return themes
        .map((t) => GameTheme.fromJson(t as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// Loads (and caches) the themes from the asset bundle.
  Future<List<GameTheme>> loadThemes() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(assetPath);
    final themes = parseThemes(raw);
    _cache = themes;
    return themes;
  }

  /// Picks a random word from [theme], trying to avoid any word in [recent].
  ///
  /// If every word is in [recent] (small theme / long history), it falls back
  /// to a fully random pick so we never get stuck.
  String randomWord(GameTheme theme, {Set<String> recent = const {}}) {
    if (theme.words.isEmpty) {
      throw StateError('Theme "${theme.name}" has no words.');
    }
    final candidates =
        theme.words.where((w) => !recent.contains(w)).toList(growable: false);
    final pool = candidates.isNotEmpty ? candidates : theme.words;
    return pool[_random.nextInt(pool.length)];
  }
}
