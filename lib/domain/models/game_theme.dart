/// A single secret word together with the related-word hint shown to the
/// imposter (e.g. word "Soap", hint "Water").
class ThemeWord {
  final String word;
  final String hint;

  const ThemeWord({required this.word, required this.hint});
}

/// A category of secret words, e.g. "Animals".
///
/// Named `GameTheme` (not `Theme`) to avoid clashing with Flutter's built-in
/// `Theme` widget.
class GameTheme {
  final String id;
  final String name;
  final List<ThemeWord> entries;

  const GameTheme({
    required this.id,
    required this.name,
    required this.entries,
  });

  /// Just the words, e.g. for the engine's random word pool.
  List<String> get words =>
      entries.map((e) => e.word).toList(growable: false);

  /// The imposter hint for [word], or empty string if unknown.
  String hintFor(String word) {
    for (final e in entries) {
      if (e.word == word) return e.hint;
    }
    return '';
  }

  /// Builds a GameTheme from one entry of the themes.json file.
  ///
  /// Supports both the current format (each word is an object with `word` and
  /// `hint`) and the legacy format (each word is a plain string, no hint).
  factory GameTheme.fromJson(Map<String, dynamic> json) {
    final rawWords = (json['words'] as List<dynamic>? ?? const []);
    final entries = rawWords.map((w) {
      if (w is Map) {
        return ThemeWord(
          word: (w['word'] ?? '').toString(),
          hint: (w['hint'] ?? '').toString(),
        );
      }
      return ThemeWord(word: w.toString(), hint: '');
    }).toList(growable: false);
    return GameTheme(
      id: json['id'] as String,
      name: json['name'] as String,
      entries: entries,
    );
  }

  @override
  String toString() => 'GameTheme($id, $name, ${entries.length} words)';
}
