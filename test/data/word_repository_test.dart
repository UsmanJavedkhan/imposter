import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:imposter_game/data/word_repository.dart';

void main() {
  // Needed so rootBundle can read the bundled asset inside tests.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('parseThemes (pure)', () {
    test('parses themes and their words', () {
      const sample = '''
      { "version": 1, "themes": [
        { "id": "x", "name": "X", "words": ["A", "B"] },
        { "id": "y", "name": "Y", "words": ["C"] }
      ]}''';
      final themes = WordRepository.parseThemes(sample);
      expect(themes.length, 2);
      expect(themes.first.name, 'X');
      expect(themes.first.words, ['A', 'B']);
      expect(themes[1].words, ['C']);
    });

    test('throws on malformed JSON', () {
      expect(
        () => WordRepository.parseThemes('not json'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('bundled themes.json', () {
    test('loads and contains 10 non-empty themes', () async {
      final repo = WordRepository();
      final themes = await repo.loadThemes();
      expect(themes.length, 10);
      for (final t in themes) {
        expect(t.words, isNotEmpty, reason: '${t.name} should have words');
        expect(t.words.length, greaterThanOrEqualTo(40),
            reason: '${t.name} should have a healthy word count');
      }
    });
  });

  group('randomWord', () {
    test('avoids words that were used recently', () {
      final repo = WordRepository(Random(1));
      final themes = WordRepository.parseThemes(
        '{ "themes": [ {"id":"t","name":"T","words":["A","B","C"]} ] }',
      );
      final theme = themes.first;
      // With A and B recent, the only allowed pick is C.
      final picked = repo.randomWord(theme, recent: {'A', 'B'});
      expect(picked, 'C');
    });

    test('falls back to any word when all are recent', () {
      final repo = WordRepository(Random(1));
      final themes = WordRepository.parseThemes(
        '{ "themes": [ {"id":"t","name":"T","words":["A","B"]} ] }',
      );
      final picked = repo.randomWord(themes.first, recent: {'A', 'B'});
      expect(['A', 'B'], contains(picked));
    });
  });
}
