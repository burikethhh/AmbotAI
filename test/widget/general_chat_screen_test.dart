import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ambot_ai/features/general_chat/general_chat_screen.dart';

void main() {
  testWidgets('GeneralChatScreen renders without error', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: GeneralChatScreen()),
      ),
    );
    // Advance past MockAIEngine.initialize() 500ms timer
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(find.byType(GeneralChatScreen), findsOneWidget);
  });
}
