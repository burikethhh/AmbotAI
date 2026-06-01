import 'package:flutter_test/flutter_test.dart';
import 'package:ambot_ai/core/providers/chat_providers.dart';
import 'package:ambot_ai/core/services/chat_service.dart';

void main() {
  group('ConversationsNotifier', () {
    late ConversationsNotifier notifier;

    setUp(() {
      notifier = ConversationsNotifier();
    });

    test('starts with empty map', () {
      expect(notifier.state, isEmpty);
    });

    group('createConversation', () {
      test('adds a conversation for the role', () {
        final conv = notifier.createConversation('tutor');
        expect(notifier.state['tutor'], hasLength(1));
        expect(notifier.state['tutor']!.first.id, conv.id);
      });

      test('prepends new conversations', () {
        notifier.createConversation('tutor');
        final conv2 = notifier.createConversation('tutor');
        expect(notifier.state['tutor']!.first.id, conv2.id);
        expect(notifier.state['tutor']!, hasLength(2));
      });

      test('keeps different roles separate', () {
        notifier.createConversation('tutor');
        notifier.createConversation('quiz_craft');
        expect(notifier.state['tutor'], hasLength(1));
        expect(notifier.state['quiz_craft'], hasLength(1));
      });
    });

    group('addMessage', () {
      test('appends a message to the conversation', () {
        final conv = notifier.createConversation('tutor');
        final msg = ChatMessage(content: 'Hello', role: MessageRole.user);
        notifier.addMessage('tutor', conv.id, msg);
        final messages = notifier.state['tutor']!.first.messages;
        expect(messages, hasLength(1));
        expect(messages.first.content, 'Hello');
      });

      test('appends multiple messages in order', () {
        final conv = notifier.createConversation('tutor');
        notifier.addMessage('tutor', conv.id,
            ChatMessage(content: 'First', role: MessageRole.user));
        notifier.addMessage('tutor', conv.id,
            ChatMessage(content: 'Second', role: MessageRole.assistant));
        final messages = notifier.state['tutor']!.first.messages;
        expect(messages, hasLength(2));
        expect(messages[0].content, 'First');
        expect(messages[1].content, 'Second');
      });
    });

    group('removeConversation', () {
      test('removes a conversation by id', () {
        final conv = notifier.createConversation('tutor');
        notifier.createConversation('tutor');
        expect(notifier.state['tutor'], hasLength(2));
        notifier.removeConversation('tutor', conv.id);
        expect(notifier.state['tutor'], hasLength(1));
        expect(notifier.state['tutor']!.any((c) => c.id == conv.id), isFalse);
      });

      test('does nothing when conversation does not exist', () {
        notifier.createConversation('tutor');
        notifier.removeConversation('tutor', 'nonexistent');
        expect(notifier.state['tutor'], hasLength(1));
      });
    });

    group('state immutability', () {
      test('original state is not mutated after createConversation', () {
        final original = notifier.state;
        notifier.createConversation('tutor');
        expect(original, isEmpty);
        expect(notifier.state, isNot(same(original)));
      });

      test('original map is not mutated after addMessage', () {
        final conv = notifier.createConversation('tutor');
        final stateBeforeAdd = notifier.state;
        notifier.addMessage('tutor', conv.id,
            ChatMessage(content: 'Hi', role: MessageRole.user));
        expect(stateBeforeAdd['tutor']!.first.messages, isEmpty);
        expect(notifier.state, isNot(same(stateBeforeAdd)));
      });

      test('original map is not mutated after removeConversation', () {
        notifier.createConversation('tutor');
        final conv2 = notifier.createConversation('tutor');
        final stateBeforeRemove = notifier.state;
        notifier.removeConversation('tutor', conv2.id);
        expect(stateBeforeRemove['tutor'], hasLength(2));
        expect(notifier.state, isNot(same(stateBeforeRemove)));
      });
    });
  });
}
