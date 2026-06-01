import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambot_ai/app.dart';

void main() {
  testWidgets('App renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: AmbotApp()),
    );
    // Let the WelcomeScreen delayed navigation timer fire
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ProviderScope), findsOneWidget);
  });
}
