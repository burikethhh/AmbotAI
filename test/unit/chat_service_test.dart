import 'package:flutter_test/flutter_test.dart';
import 'package:ambot_ai/core/services/chat_service.dart';

void main() {
  group('MessageAttachment', () {
    test('constructor sets all fields', () {
      final attachment = MessageAttachment(
        type: MessageAttachmentType.image,
        path: '/path/to/image.png',
        caption: 'A sample image',
        width: 800,
        height: 600,
        metadata: {'size': 'large'},
      );
      expect(attachment.type, MessageAttachmentType.image);
      expect(attachment.path, '/path/to/image.png');
      expect(attachment.caption, 'A sample image');
      expect(attachment.width, 800);
      expect(attachment.height, 600);
      expect(attachment.metadata, {'size': 'large'});
    });

    test('toJson and fromJson round-trip', () {
      final original = MessageAttachment(
        type: MessageAttachmentType.document,
        path: '/path/to/doc.pdf',
        caption: 'Report',
        width: null,
        height: null,
        metadata: null,
      );
      final json = original.toJson();
      final restored = MessageAttachment.fromJson(json);
      expect(restored.type, original.type);
      expect(restored.path, original.path);
      expect(restored.caption, original.caption);
      expect(restored.width, original.width);
      expect(restored.height, original.height);
      expect(restored.metadata, original.metadata);
    });

    test('toJson omits nullable fields when null', () {
      final attachment = MessageAttachment(
        type: MessageAttachmentType.image,
        path: '/path.png',
      );
      final json = attachment.toJson();
      expect(json.containsKey('caption'), isFalse);
      expect(json.containsKey('width'), isFalse);
      expect(json.containsKey('height'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
    });
  });

  group('ChatMessage', () {
    test('constructor generates id and timestamp', () {
      final message = ChatMessage(content: 'Hello', role: MessageRole.user);
      expect(message.id, isNotEmpty);
      expect(message.content, 'Hello');
      expect(message.role, MessageRole.user);
      expect(message.isStreaming, isFalse);
      expect(message.thinking, isNull);
      expect(message.planSteps, isNull);
      expect(message.attachments, isNull);
    });

    test('copyWith updates selected fields', () {
      final original = ChatMessage(content: 'Hello', role: MessageRole.user);
      final copy = original.copyWith(
        content: 'Updated',
        isStreaming: true,
      );
      expect(copy.id, original.id);
      expect(copy.content, 'Updated');
      expect(copy.isStreaming, isTrue);
      expect(copy.role, MessageRole.user);
    });

    test('copyWith preserves original when no arguments', () {
      final original = ChatMessage(content: 'Test', role: MessageRole.assistant);
      final copy = original.copyWith();
      expect(copy.content, 'Test');
      expect(copy.role, MessageRole.assistant);
    });

    test('toJson and fromJson round-trip with all fields', () {
      final original = ChatMessage(
        content: 'Test message',
        role: MessageRole.assistant,
        thinking: 'Hmm...',
        planSteps: ['Step 1', 'Step 2'],
        attachments: [
          MessageAttachment(type: MessageAttachmentType.image, path: '/img.png'),
        ],
      );
      final json = original.toJson();
      final restored = ChatMessage.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.content, original.content);
      expect(restored.role, original.role);
      expect(restored.thinking, original.thinking);
      expect(restored.planSteps, original.planSteps);
      expect(restored.attachments!.length, 1);
      expect(restored.attachments!.first.path, '/img.png');
    });

    test('toJson omits optional fields when null', () {
      final message = ChatMessage(content: 'Hi', role: MessageRole.user);
      final json = message.toJson();
      expect(json.containsKey('thinking'), isFalse);
      expect(json.containsKey('planSteps'), isFalse);
      expect(json.containsKey('attachments'), isFalse);
    });
  });

  group('Conversation', () {
    test('constructor generates id and timestamps', () {
      final conv = Conversation(roleId: 'role-1');
      expect(conv.id, isNotEmpty);
      expect(conv.roleId, 'role-1');
      expect(conv.messages, isEmpty);
      expect(conv.createdAt, isNotNull);
      expect(conv.updatedAt, isNotNull);
    });

    group('preview', () {
      test('returns placeholder for empty conversation', () {
        final conv = Conversation(roleId: 'r1');
        expect(conv.preview, 'New conversation');
      });

      test('returns short content verbatim', () {
        final conv = Conversation(
          roleId: 'r1',
          messages: [
            ChatMessage(content: 'What is AI?', role: MessageRole.user),
          ],
        );
        expect(conv.preview, 'What is AI?');
      });

      test('truncates long content with ellipsis', () {
        final longText = 'A' * 100;
        final conv = Conversation(
          roleId: 'r1',
          messages: [
            ChatMessage(content: longText, role: MessageRole.user),
          ],
        );
        expect(conv.preview, endsWith('...'));
        expect(conv.preview.length, 83); // 80 + '...'
      });
    });

    test('toJson and fromJson round-trip with messages', () {
      final original = Conversation(
        roleId: 'role-abc',
        messages: [
          ChatMessage(content: 'Hi', role: MessageRole.user),
          ChatMessage(content: 'Hello!', role: MessageRole.assistant),
        ],
      );
      final json = original.toJson();
      final restored = Conversation.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.roleId, original.roleId);
      expect(restored.messages.length, 2);
      expect(restored.messages[0].content, 'Hi');
      expect(restored.messages[1].content, 'Hello!');
      expect(restored.createdAt.toIso8601String(), original.createdAt.toIso8601String());
      expect(restored.updatedAt.toIso8601String(), original.updatedAt.toIso8601String());
    });
  });
}
