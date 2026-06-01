import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ambot_ai/features/chat/widgets/typing_indicator.dart';

void main() {
  testWidgets('TypingIndicator renders without error', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: TypingIndicator())),
      ),
    );

    expect(find.byType(TypingIndicator), findsOneWidget);
  });

  testWidgets('TypingIndicator animates', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: TypingIndicator())),
      ),
    );

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(TypingIndicator), findsOneWidget);
  });
}
