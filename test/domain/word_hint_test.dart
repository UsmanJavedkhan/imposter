import 'package:flutter_test/flutter_test.dart';
import 'package:imposter_game/domain/word_hint.dart';

void main() {
  group('buildImposterHint', () {
    test('reveals first letter (uppercased) and letter count', () {
      expect(buildImposterHint('Lion'), 'Starts with “L” · 4 letters');
    });

    test('uppercases the first letter of a lowercase word', () {
      expect(buildImposterHint('tiger'), 'Starts with “T” · 5 letters');
    });

    test('ignores spaces when counting multi-word answers', () {
      expect(
          buildImposterHint('Albert Einstein'), 'Starts with “A” · 14 letters');
    });

    test('uses singular "letter" for a single-letter word', () {
      expect(buildImposterHint('A'), 'Starts with “A” · 1 letter');
    });

    test('trims surrounding whitespace', () {
      expect(buildImposterHint('  Cat '), 'Starts with “C” · 3 letters');
    });

    test('returns empty string for an empty/blank word', () {
      expect(buildImposterHint(''), '');
      expect(buildImposterHint('   '), '');
    });
  });
}
