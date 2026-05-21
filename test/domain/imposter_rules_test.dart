import 'package:flutter_test/flutter_test.dart';
import 'package:imposter_game/domain/engine/imposter_rules.dart';

void main() {
  group('suggestImposterCount', () {
    test('3 to 5 players -> 1 imposter', () {
      expect(suggestImposterCount(3), 1);
      expect(suggestImposterCount(4), 1);
      expect(suggestImposterCount(5), 1);
    });

    test('6 to 8 players -> 2 imposters', () {
      expect(suggestImposterCount(6), 2);
      expect(suggestImposterCount(7), 2);
      expect(suggestImposterCount(8), 2);
    });

    test('9 to 12 players -> 3 imposters', () {
      expect(suggestImposterCount(9), 3);
      expect(suggestImposterCount(12), 3);
    });

    test('13+ players -> ceil(players / 4)', () {
      expect(suggestImposterCount(13), 4);
      expect(suggestImposterCount(16), 4);
      expect(suggestImposterCount(17), 5);
    });
  });

  group('maxImposters / isValidImposterCount', () {
    test('imposters must stay a minority at game start', () {
      expect(maxImposters(3), 1); // floor(2/2)
      expect(maxImposters(5), 2); // floor(4/2)
      expect(maxImposters(8), 3); // floor(7/2)
    });

    test('rejects 0 or too-many imposters', () {
      expect(isValidImposterCount(5, 0), isFalse);
      expect(isValidImposterCount(5, 1), isTrue);
      expect(isValidImposterCount(5, 2), isTrue);
      expect(isValidImposterCount(5, 3), isFalse); // would be majority
    });
  });
}
