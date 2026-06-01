import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ambot_ai/features/image_gen/image_gen_screen.dart';

void main() {
  testWidgets('ImageGenScreen renders without error', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ImageGenScreen()),
      ),
    );
    // Pump long enough to clear MockAIEngine's 500ms init timer
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(find.text('IMAGE GEN'), findsOneWidget);
  });
}
