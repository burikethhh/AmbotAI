import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ambot_ai/core/voice/voice_service.dart';
import 'package:ambot_ai/features/chat/widgets/chat_input_bar.dart';

void main() {
  testWidgets('ChatInputBar renders text field and send button',
      (tester) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    addTearDown(() {
      controller.dispose();
      focusNode.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatInputBar(
            controller: controller,
            focusNode: focusNode,
            isDark: false,
            isStreaming: false,
            voiceEnabled: false,
            voiceState: VoiceState.idle,
            isGeneratingImage: false,
            imageGenProgress: 0.0,
            onSend: () {},
            onVoice: () {},
            onImageGen: () {},
            onDocGen: () {},
            onAttachImage: () {},
            onAttachFile: () {},
          ),
        ),
      ),
    );

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.photo_outlined), findsOneWidget);
    expect(find.byIcon(Icons.attach_file_outlined), findsOneWidget);
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    expect(find.byIcon(Icons.description_outlined), findsOneWidget);
  });

  testWidgets('ChatInputBar shows generating image progress',
      (tester) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    addTearDown(() {
      controller.dispose();
      focusNode.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatInputBar(
            controller: controller,
            focusNode: focusNode,
            isDark: false,
            isStreaming: false,
            voiceEnabled: false,
            voiceState: VoiceState.idle,
            isGeneratingImage: true,
            imageGenProgress: 0.5,
            onSend: () {},
            onVoice: () {},
            onImageGen: () {},
            onDocGen: () {},
            onAttachImage: () {},
            onAttachFile: () {},
          ),
        ),
      ),
    );

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.hourglass_top), findsOneWidget);
  });

  testWidgets('ChatInputBar shows voice button when enabled', (tester) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    addTearDown(() {
      controller.dispose();
      focusNode.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatInputBar(
            controller: controller,
            focusNode: focusNode,
            isDark: false,
            isStreaming: false,
            voiceEnabled: true,
            voiceState: VoiceState.idle,
            isGeneratingImage: false,
            imageGenProgress: 0.0,
            onSend: () {},
            onVoice: () {},
            onImageGen: () {},
            onDocGen: () {},
            onAttachImage: () {},
            onAttachFile: () {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.mic), findsOneWidget);
  });

  testWidgets('ChatInputBar shows stop icon when listening', (tester) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    addTearDown(() {
      controller.dispose();
      focusNode.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatInputBar(
            controller: controller,
            focusNode: focusNode,
            isDark: false,
            isStreaming: false,
            voiceEnabled: true,
            voiceState: VoiceState.listening,
            isGeneratingImage: false,
            imageGenProgress: 0.0,
            onSend: () {},
            onVoice: () {},
            onImageGen: () {},
            onDocGen: () {},
            onAttachImage: () {},
            onAttachFile: () {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.stop), findsOneWidget);
  });
}
