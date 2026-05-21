import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imposter_game/main.dart';

void main() {
  testWidgets('Home screen shows title and play button', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ImposterApp()));
    await tester.pumpAndSettle();

    expect(find.text('IMPOSTER'), findsOneWidget);
    expect(find.text('Play Local'), findsOneWidget);
  });
}
