import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ambot_ai/core/services/chat_service.dart';
import 'package:ambot_ai/features/chat/widgets/message_bubble.dart';
import 'package:ambot_ai/features/chat/widgets/typing_indicator.dart';

void main() {
  testWidgets('ChatMessageBubble renders user message', (tester) async {
    final message = ChatMessage(
      content: 'Hello from user',
      role: MessageRole.user,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageBubble(message: message, isDark: false),
        ),
      ),
    );

    expect(find.text('Hello from user'), findsOneWidget);
  });

  testWidgets('ChatMessageBubble renders AI message without avatar error',
      (tester) async {
    final message = ChatMessage(
      content: 'AI response here',
      role: MessageRole.assistant,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChatMessageBubble(message: message, isDark: true),
          ),
        ),
      ),
    );

    expect(find.text('AI response here'), findsOneWidget);
  });

  testWidgets('ChatMessageBubble shows typing indicator when streaming empty',
      (tester) async {
    final message = ChatMessage(
      content: '',
      role: MessageRole.assistant,
      isStreaming: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChatMessageBubble(message: message, isDark: false),
          ),
        ),
      ),
    );

    expect(find.byType(TypingIndicator), findsOneWidget);
  });

  testWidgets('ChatMessageBubble shows thinking block', (tester) async {
    final message = ChatMessage(
      content: 'Answer',
      role: MessageRole.assistant,
      thinking: 'Step-by-step reasoning',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChatMessageBubble(message: message, isDark: false),
          ),
        ),
      ),
    );

    expect(find.text('Thinking'), findsOneWidget);
    expect(find.text('Answer'), findsOneWidget);
  });

  testWidgets('ChatMessageBubble shows plan block', (tester) async {
    final message = ChatMessage(
      content: 'Plan result',
      role: MessageRole.assistant,
      planSteps: ['Step 1', 'Step 2'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChatMessageBubble(message: message, isDark: false),
          ),
        ),
      ),
    );

    expect(find.text('Plan'), findsOneWidget);
    expect(find.text('Plan result'), findsOneWidget);
  });

  testWidgets('ChatMessageBubble renders web fetch SOURCE content', (tester) async {
    final message = ChatMessage(
      content: 'According to SOURCE (https://example.com):\nThe sky is blue.',
      role: MessageRole.assistant,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChatMessageBubble(message: message, isDark: true),
          ),
        ),
      ),
    );

    expect(find.textContaining('SOURCE (https://example.com)'), findsOneWidget);
    expect(find.textContaining('The sky is blue.'), findsOneWidget);
  });

  testWidgets('ChatMessageBubble renders web fetch error message', (tester) async {
    final message = ChatMessage(
      content: 'FETCH ERROR (https://example.com): HTTP 404\nCould not retrieve the page.',
      role: MessageRole.assistant,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChatMessageBubble(message: message, isDark: false),
          ),
        ),
      ),
    );

    expect(find.textContaining('FETCH ERROR (https://example.com)'), findsOneWidget);
    expect(find.textContaining('HTTP 404'), findsOneWidget);
  });

  testWidgets('ChatMessageBubble renders fetch status message', (tester) async {
    final message = ChatMessage(
      content: '[Fetching web data from 2 sources...]\n\nWhat is the weather?',
      role: MessageRole.assistant,
      isStreaming: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChatMessageBubble(message: message, isDark: false),
          ),
        ),
      ),
    );

    expect(find.textContaining('Fetching web data from 2 sources'), findsOneWidget);
    expect(find.textContaining('What is the weather?'), findsOneWidget);
  });
}
