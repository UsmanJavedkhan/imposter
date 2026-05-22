/// Builds the small hint shown to imposters so they have a place to start
/// without learning the secret word.
///
/// It reveals only the first letter and the number of letters — enough to
/// bluff a believable clue, not enough to know the word. For multi-word
/// answers (e.g. "Albert Einstein") the count ignores spaces.
///
/// Examples:
///   "Lion"            -> "Starts with “L” · 4 letters"
///   "Albert Einstein" -> "Starts with “A” · 14 letters"
String buildImposterHint(String word) {
  final trimmed = word.trim();
  if (trimmed.isEmpty) return '';
  final first = trimmed[0].toUpperCase();
  final letterCount = trimmed.replaceAll(RegExp(r'\s+'), '').length;
  final unit = letterCount == 1 ? 'letter' : 'letters';
  return 'Starts with “$first” · $letterCount $unit';
}
