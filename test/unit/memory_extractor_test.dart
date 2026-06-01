import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ambot_ai/core/memory/memory_extractor.dart';
import 'package:ambot_ai/core/memory/memory_service.dart';
import 'package:ambot_ai/core/roles/role_domain.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late MemoryService service;
  late MemoryExtractor extractor;
  const roleId = 'test-role';
  const conversationId = 'test-conv';

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('ambot_extract_test_');
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
    extractor = MemoryExtractor(service);
  });

  group('extractAndStore', () {
    test('extracts nothing from irrelevant text', () async {
      final entries = await extractor.extractAndStore(
        userMessage: 'What is the weather today?',
        roleId: roleId,
        defaultScope: MemoryScope.role,
      );
      expect(entries, isEmpty);
    });

    test('returns empty when scope is none', () async {
      final entries = await extractor.extractAndStore(
        userMessage: 'Remember that I like cats.',
        roleId: roleId,
        defaultScope: MemoryScope.none,
      );
      expect(entries, isEmpty);
    });

    test('extracts "remember that" facts as pinned, high importance', () async {
      final entries = await extractor.extractAndStore(
        userMessage: 'Remember that I have a meeting tomorrow at 3pm.',
        roleId: roleId,
        defaultScope: MemoryScope.role,
      );
      expect(entries.length, 1);
      expect(entries.first.pinned, isTrue);
      expect(entries.first.importance, 0.9);
      expect(entries.first.value, contains('meeting tomorrow'));
    });

    test('extracts name from "my name is" (lowercase required by regex)', () async {
      final entries = await extractor.extractAndStore(
        userMessage: 'my name is John.',
        roleId: roleId,
        defaultScope: MemoryScope.role,
      );
      expect(entries.any((e) => e.key == 'user name'), isTrue);
      expect(entries.any((e) => e.value.contains('John')), isTrue);
    });

    test('extracts name from "i am" (lowercase required by regex)', () async {
      final entries = await extractor.extractAndStore(
        userMessage: 'i am Sarah and i am studying biology.',
        roleId: roleId,
        defaultScope: MemoryScope.role,
      );
      expect(entries.any((e) => e.key == 'user name'), isTrue);
      expect(entries.any((e) => e.value.contains('Sarah')), isTrue);
    });

    test('extracts current focus from "I am studying"', () async {
      final entries = await extractor.extractAndStore(
        userMessage: 'I am studying machine learning.',
        roleId: roleId,
        defaultScope: MemoryScope.role,
      );
      expect(entries.any((e) => e.key == 'current focus'), isTrue);
      expect(entries.any((e) => e.value.contains('machine learning')), isTrue);
    });

    test('extracts preferences from "I prefer"', () async {
      final entries = await extractor.extractAndStore(
        userMessage: 'I prefer visual learning materials.',
        roleId: roleId,
        defaultScope: MemoryScope.role,
      );
      expect(entries.any((e) => e.key == 'preference'), isTrue);
    });

    test('extracts dislikes from "I don\'t like"', () async {
      final entries = await extractor.extractAndStore(
        userMessage: "I don't like multiple choice questions.",
        roleId: roleId,
        defaultScope: MemoryScope.role,
      );
      expect(entries.any((e) => e.key == 'dislike'), isTrue);
    });

    test('extracts goals from "my goal is"', () async {
      final entries = await extractor.extractAndStore(
        userMessage: 'My goal is to become a data scientist.',
        roleId: roleId,
        defaultScope: MemoryScope.role,
      );
      expect(entries.any((e) => e.key == 'goal'), isTrue);
      expect(entries.any((e) => e.value.contains('data scientist')), isTrue);
    });

    test('deduplicates facts with same value', () async {
      final entries = await extractor.extractAndStore(
        userMessage: 'my name is Alex. i am Alex.',
        roleId: roleId,
        defaultScope: MemoryScope.role,
      );
      // Should only have one "user name" entry (dedup by value)
      final nameEntries = entries.where((e) => e.key == 'user name');
      expect(nameEntries.length, 1);
    });

    test('stores with correct scope and roleId', () async {
      final entries = await extractor.extractAndStore(
        userMessage: 'note that the sky is blue and clouds are white.',
        roleId: roleId,
        conversationId: conversationId,
        defaultScope: MemoryScope.role,
        scope: MemoryScope.global,
      );
      expect(entries.length, 1);
      expect(entries.first.scope, MemoryScope.global);
      // global scope memories have roleId = null
      expect(entries.first.roleId, isNull);
    });
  });
}
