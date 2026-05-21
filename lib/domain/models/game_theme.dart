/// A category of secret words, e.g. "Animals".
///
/// Named `GameTheme` (not `Theme`) to avoid clashing with Flutter's built-in
/// `Theme` widget.
class GameTheme {
  final String id;
  final String name;
  final List<String> words;

  const GameTheme({
    required this.id,
    required this.name,
    required this.words,
  });

  /// Builds a GameTheme from one entry of the themes.json file.
  factory GameTheme.fromJson(Map<String, dynamic> json) {
    final rawWords = (json['words'] as List<dynamic>? ?? const []);
    return GameTheme(
      id: json['id'] as String,
      name: json['name'] as String,
      words: rawWords.map((w) => w.toString()).toList(growable: false),
    );
  }

  @override
  String toString() => 'GameTheme($id, $name, ${words.length} words)';
}
