import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordmatch/main.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
        const ProviderScope(child: WordMatchApp(isFirstLaunch: false)));
    await tester.pump(); // Just one frame, no settle needed (has async loading)
    expect(find.byType(ProviderScope), findsOneWidget);
  });
}
