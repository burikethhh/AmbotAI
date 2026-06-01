import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ambot_ai/core/memory/memory_service.dart';
import 'package:ambot_ai/core/roles/role_domain.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late MemoryService service;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('ambot_mem_test_');
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
    service.enabled = true;
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

  group('add', () {
    test('adds a memory entry and returns it with id', () async {
      final entry = await service.add(
        scope: MemoryScope.global,
        key: 'test key',
        value: 'test value',
      );
      expect(entry.id, isNotEmpty);
      expect(entry.key, 'test key');
      expect(entry.value, 'test value');
      expect(entry.scope, MemoryScope.global);
    });

    test('does not persist when enabled is false', () async {
      service.enabled = false;
      await service.add(
        scope: MemoryScope.global,
        key: 'key',
        value: 'value',
      );
      expect(service.all(), isEmpty);
    });

    test('does not persist when scope is none', () async {
      await service.add(
        scope: MemoryScope.none,
        key: 'key',
        value: 'value',
      );
      expect(service.all(), isEmpty);
    });
  });

  group('all', () {
    test('returns all stored entries', () async {
      await service.add(scope: MemoryScope.global, key: 'k1', value: 'v1');
      await service.add(scope: MemoryScope.global, key: 'k2', value: 'v2');

      final all = service.all();
      expect(all.length, 2);
    });

    test('returns empty when nothing stored', () {
      expect(service.all(), isEmpty);
    });
  });

  group('update', () {
    test('updates an existing entry', () async {
      final entry = await service.add(
        scope: MemoryScope.global,
        key: 'original',
        value: 'original value',
      );
      final updated = entry.copyWith(value: 'updated value');
      await service.update(updated);

      final all = service.all();
      expect(all.length, 1);
      expect(all.first.value, 'updated value');
    });
  });

  group('delete', () {
    test('removes a specific entry', () async {
      final entry = await service.add(
        scope: MemoryScope.global,
        key: 'delete me',
        value: 'bye',
      );
      expect(service.all().length, 1);

      await service.delete(entry.id);
      expect(service.all(), isEmpty);
    });
  });

  group('wipeAll', () {
    test('removes all entries', () async {
      await service.add(scope: MemoryScope.global, key: 'k1', value: 'v1');
      await service.add(scope: MemoryScope.global, key: 'k2', value: 'v2');
      expect(service.all().length, 2);

      await service.wipeAll();
      expect(service.all(), isEmpty);
    });
  });

  group('wipeScope', () {
    test('removes entries matching scope and role', () async {
      await service.add(scope: MemoryScope.role, key: 'k1', value: 'v1', roleId: 'role-a');
      await service.add(scope: MemoryScope.role, key: 'k2', value: 'v2', roleId: 'role-b');
      await service.add(scope: MemoryScope.global, key: 'k3', value: 'v3');

      await service.wipeScope(scope: MemoryScope.role, roleId: 'role-a');
      final all = service.all();
      expect(all.where((e) => e.roleId == 'role-a'), isEmpty);
      expect(all.where((e) => e.roleId == 'role-b').length, 1);
    });
  });

  group('candidatesFor', () {
    test('returns global memories for any role', () async {
      await service.add(scope: MemoryScope.global, key: 'global', value: 'shared');
      await service.add(scope: MemoryScope.role, key: 'role', value: 'for role-a', roleId: 'role-a');

      final candidates = service.candidatesFor(roleId: 'role-b');
      expect(candidates.length, 1);
      expect(candidates.first.key, 'global');
    });

    test('returns role-scoped memories for matching role', () async {
      await service.add(scope: MemoryScope.role, key: 'math', value: 'studying math', roleId: 'role-1');
      await service.add(scope: MemoryScope.role, key: 'history', value: 'studying history', roleId: 'role-2');

      final candidates = service.candidatesFor(roleId: 'role-1');
      expect(candidates.length, 1);
      expect(candidates.first.key, 'math');
    });

    test('returns chat-scoped memories only for matching conversation', () async {
      await service.add(
        scope: MemoryScope.chat,
        key: 'chat key',
        value: 'chat value',
        conversationId: 'conv-1',
      );

      final withConv = service.candidatesFor(roleId: 'r', conversationId: 'conv-1');
      expect(withConv.length, 1);

      final withoutConv = service.candidatesFor(roleId: 'r', conversationId: 'conv-2');
      expect(withoutConv, isEmpty);
    });

    test('returns empty for none scope', () async {
      await service.add(scope: MemoryScope.none, key: 'k', value: 'v');
      final candidates = service.candidatesFor(roleId: 'r');
      expect(candidates, isEmpty);
    });
  });

  group('markUsed', () {
    test('increments useCount and updates lastUsedAt', () async {
      final entry = await service.add(
        scope: MemoryScope.global,
        key: 'k',
        value: 'v',
        importance: 0.5,
      );
      expect(entry.useCount, 0);

      await service.markUsed([entry.id]);
      final updated = service.all().first;
      expect(updated.useCount, 1);
    });
  });

  group('exportJson / importJson', () {
    test('exportJson returns valid JSON with entries', () async {
      await service.add(scope: MemoryScope.global, key: 'k', value: 'v');
      final json = service.exportJson();
      expect(json, contains('entries'));
      expect(json, contains('k'));
    });

    test('importJson loads entries from JSON', () async {
      await service.add(scope: MemoryScope.global, key: 'original', value: 'original');
      final json = service.exportJson();
      await service.wipeAll();
      expect(service.all(), isEmpty);

      final count = await service.importJson(json, replace: false);
      expect(count, 1);
      expect(service.all().first.key, 'original');
    });

    test('importJson with replace=true wipes existing', () async {
      await service.add(scope: MemoryScope.global, key: 'old', value: 'old');
      final freshJson = '{"version":1,"entries":[]}';

      final count = await service.importJson(freshJson, replace: true);
      expect(count, 0);
      expect(service.all(), isEmpty);
    });
  });
}
