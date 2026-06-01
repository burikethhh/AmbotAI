import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ambot_ai/core/services/chat_service.dart';
import 'package:ambot_ai/core/services/conversation_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late ConversationStore store;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('ambot_conv_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return tempDir.path;
        }
        return null;
      },
    );
    store = ConversationStore.instance;
    await Hive.initFlutter();
    await store.init();
  });

  tearDown(() async {
    await store.deleteAll();
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {
      // Best-effort cleanup
    }
  });

  Conversation makeConv(String roleId, List<ChatMessage> messages) {
    return Conversation(roleId: roleId, messages: messages);
  }

  group('save and load', () {
    test('save persists a conversation and load retrieves it', () async {
      final conv = makeConv('role-1', [
        ChatMessage(content: 'Hello', role: MessageRole.user),
      ]);
      await store.save(conv);

      final loaded = store.load(conv.id);
      expect(loaded, isNotNull);
      expect(loaded!.id, conv.id);
      expect(loaded.roleId, 'role-1');
      expect(loaded.messages.length, 1);
    });

    test('load returns null for missing conversation', () {
      final loaded = store.load('nonexistent-id');
      expect(loaded, isNull);
    });
  });

  group('getConversationIds', () {
    test('returns empty list for role with no conversations', () {
      final ids = store.getConversationIds('empty-role');
      expect(ids, isEmpty);
    });

    test('returns ids for a role after saving conversations', () async {
      await store.save(makeConv('role-a', []));
      await store.save(makeConv('role-a', []));

      final ids = store.getConversationIds('role-a');
      expect(ids.length, 2);
    });
  });

  group('getByRole', () {
    test('returns conversations sorted by updatedAt descending', () async {
      final conv1 = makeConv('role-x', []);
      final conv2 = makeConv('role-x', []);
      await store.save(conv1);
      await store.save(conv2);

      final results = store.getByRole('role-x');
      expect(results.length, 2);
      expect(results[0].updatedAt.isAfter(results[1].updatedAt) ||
          results[0].updatedAt == results[1].updatedAt, isTrue);
    });
  });

  group('getAll', () {
    test('returns all conversations across roles', () async {
      await store.save(makeConv('role-1', []));
      await store.save(makeConv('role-2', []));

      final all = store.getAll();
      expect(all.length, 2);
    });
  });

  group('search', () {
    test('finds conversation matching message content', () async {
      await store.save(makeConv('role-s', [
        ChatMessage(content: 'The mitochondria is the powerhouse of the cell', role: MessageRole.user),
      ]));
      await store.save(makeConv('role-s', [
        ChatMessage(content: 'Quantum mechanics is fascinating', role: MessageRole.user),
      ]));

      final results = store.search('mitochondria', 'role-s');
      expect(results.length, 1);
    });

    test('returns all conversations for empty query', () async {
      await store.save(makeConv('role-e', []));
      await store.save(makeConv('role-e', []));

      final results = store.search('', 'role-e');
      expect(results.length, 2);
    });

    test('finds conversation matching title', () async {
      final conv = makeConv('role-t', [
        ChatMessage(content: 'Tell me about biology', role: MessageRole.user),
      ]);
      await store.save(conv);
      await store.setTitle(conv.id, 'Biology Lesson');

      final results = store.search('biology', 'role-t');
      expect(results.length, 1);
    });
  });

  group('delete', () {
    test('delete removes a single conversation', () async {
      final conv = makeConv('role-d', []);
      await store.save(conv);
      expect(store.load(conv.id), isNotNull);

      await store.delete(conv.id);
      expect(store.load(conv.id), isNull);
    });

    test('deleteByRole removes all conversations for a role', () async {
      await store.save(makeConv('role-dr', []));
      await store.save(makeConv('role-dr', []));
      await store.save(makeConv('other-role', []));

      await store.deleteByRole('role-dr');
      expect(store.getByRole('role-dr'), isEmpty);
      expect(store.getByRole('other-role').length, 1);
    });

    test('deleteAll removes everything', () async {
      await store.save(makeConv('role-a', []));
      await store.save(makeConv('role-b', []));

      await store.deleteAll();
      expect(store.getAll(), isEmpty);
    });
  });

  group('setTitle / getTitle', () {
    test('setTitle stores and getTitle retrieves', () async {
      final conv = makeConv('role-t', []);
      await store.save(conv);
      expect(store.getTitle(conv.id), isNull);

      await store.setTitle(conv.id, 'My Title');
      expect(store.getTitle(conv.id), 'My Title');
    });

    test('getTitle returns null for nonexistent conversation', () {
      expect(store.getTitle('no-such-id'), isNull);
    });
  });

  group('generateTitle', () {
    test('returns first 40 chars of first user message', () {
      final messages = [
        ChatMessage(content: 'Tell me about the history of ancient Rome and its empire', role: MessageRole.user),
      ];
      final title = ConversationStore.generateTitle(messages);
      expect(title, 'Tell me about the history of ancient Rom...');
    });

    test('returns full text when under 40 characters', () {
      final messages = [
        ChatMessage(content: 'What is AI?', role: MessageRole.user),
      ];
      final title = ConversationStore.generateTitle(messages);
      expect(title, 'What is AI?');
    });

    test('returns "New conversation" when no user messages', () {
      final messages = [
        ChatMessage(content: 'Hello', role: MessageRole.assistant),
      ];
      final title = ConversationStore.generateTitle(messages);
      expect(title, 'New conversation');
    });

    test('returns "New conversation" when messages empty', () {
      expect(ConversationStore.generateTitle([]), 'New conversation');
    });
  });
}
