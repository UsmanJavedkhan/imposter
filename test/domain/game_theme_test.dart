import 'package:flutter_test/flutter_test.dart';
import 'package:imposter_game/domain/models/game_theme.dart';

void main() {
  group('GameTheme.fromJson', () {
    test('parses word+hint objects and exposes words + hintFor', () {
      final theme = GameTheme.fromJson({
        'id': 'household',
        'name': 'Household Items',
        'words': [
          {'word': 'Soap', 'hint': 'Water'},
          {'word': 'Lamp', 'hint': 'Light'},
        ],
      });
      expect(theme.words, ['Soap', 'Lamp']);
      expect(theme.hintFor('Soap'), 'Water');
      expect(theme.hintFor('Lamp'), 'Light');
      expect(theme.hintFor('Unknown'), '');
    });

    test('still parses legacy plain-string words (no hint)', () {
      final theme = GameTheme.fromJson({
        'id': 'x',
        'name': 'X',
        'words': ['Alpha', 'Beta'],
      });
      expect(theme.words, ['Alpha', 'Beta']);
      expect(theme.hintFor('Alpha'), '');
    });
  });
}
