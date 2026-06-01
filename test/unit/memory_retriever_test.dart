import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ambot_ai/core/memory/memory_retriever.dart';
import 'package:ambot_ai/core/memory/memory_service.dart';
import 'package:ambot_ai/core/memory/memory_entry.dart';
import 'package:ambot_ai/core/roles/role_domain.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late MemoryService service;
  late MemoryRetriever retriever;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('ambot_retriever_test_');
    Hive.init(tempDir.path);
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
    service = MemoryService.instance;
    await service.init();
  });

  tearDown(() async {
    await service.wipeAll();
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

  setUp(() {
    retriever = MemoryRetriever(service);
  });

  group('retrieve', () {
    test('returns empty list when pool is empty', () async {
      final results = await retriever.retrieve(
        query: 'anything',
        roleId: 'role-empty',
      );
      expect(results, isEmpty);
    });

    test('returns memories matching keywords', () async {
      await service.add(
        scope: MemoryScope.global,
        key: 'math',
        value: 'User likes algebra',
        importance: 0.5,
      );
      await service.add(
        scope: MemoryScope.global,
        key: 'biology',
        value: 'User studies cells',
        importance: 0.5,
      );

      final results = await retriever.retrieve(
        query: 'algebra math',
        roleId: 'role-1',
        topK: 5,
      );
      expect(results.length, 1);
      expect(results.first.key, 'math');
    });

    test('returns pinned memories even without keyword match', () async {
      await service.add(
        scope: MemoryScope.global,
        key: 'important',
        value: 'Always remember this',
        pinned: true,
      );
      await service.add(
        scope: MemoryScope.global,
        key: 'unrelated',
        value: 'Some other fact',
        pinned: false,
      );

      final results = await retriever.retrieve(
        query: 'zzzzz',
        roleId: 'role-pinned',
        topK: 5,
      );
      expect(results.length, 1);
      expect(results.first.pinned, isTrue);
    });

    test('returns topK memories limited by count', () async {
      for (var i = 0; i < 10; i++) {
        await service.add(
          scope: MemoryScope.global,
          key: 'key$i',
          value: 'matching value $i',
          importance: 0.5,
        );
      }

      final results = await retriever.retrieve(
        query: 'matching',
        roleId: 'role-topk',
        topK: 3,
      );
      expect(results.length, 3);
    });

    test('falls back to importance order for empty query', () async {
      await service.add(
        scope: MemoryScope.global,
        key: 'low',
        value: 'low importance',
        importance: 0.1,
      );
      await service.add(
        scope: MemoryScope.global,
        key: 'high',
        value: 'high importance',
        importance: 0.9,
      );

      final results = await retriever.retrieve(
        query: '',
        roleId: 'role-imp',
        topK: 5,
      );
      expect(results.length, 2);
      expect(results.first.key, 'high');
    });
  });

  group('renderForPrompt', () {
    test('returns empty string for empty list', () {
      expect(retriever.renderForPrompt([]), '');
    });

    test('formats memories with bullet points and instruction', () {
      final entries = [
        MemoryEntry(
          id: '1',
          scope: MemoryScope.global,
          key: 'pref',
          value: 'User likes Python',
          createdAt: DateTime.now(),
          lastUsedAt: DateTime.now(),
        ),
        MemoryEntry(
          id: '2',
          scope: MemoryScope.global,
          key: 'goal',
          value: 'User aims to learn ML',
          createdAt: DateTime.now(),
          lastUsedAt: DateTime.now(),
        ),
      ];

      final rendered = retriever.renderForPrompt(entries);
      expect(rendered, contains('Known facts about the user'));
      expect(rendered, contains('- User likes Python'));
      expect(rendered, contains('- User aims to learn ML'));
      expect(rendered, contains('Do not mention'));
    });
  });
}
