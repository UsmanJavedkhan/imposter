import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imposter_game/main.dart';

void main() {
  testWidgets('Home screen shows title and play button', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ImposterApp()));
    // Note: the background uses an infinite (repeating) animation, so we pump a
    // couple of frames rather than pumpAndSettle (which would never settle).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('IMPOSTER'), findsOneWidget);
    expect(find.text('Play Local'), findsOneWidget);
  });
}
