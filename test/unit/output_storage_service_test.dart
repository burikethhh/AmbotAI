import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ambot_ai/core/storage/output_storage_service.dart';

void main() {
  group('OutputFileInfo', () {
    test('constructor sets all fields', () {
      final now = DateTime(2026, 5, 25);
      final info = OutputFileInfo(
        path: '/tmp/test.txt',
        name: 'test.txt',
        sizeBytes: 1024,
        createdAt: now,
        type: OutputType.documents,
        tags: ['school', 'notes'],
      );
      expect(info.path, '/tmp/test.txt');
      expect(info.name, 'test.txt');
      expect(info.sizeBytes, 1024);
      expect(info.createdAt, now);
      expect(info.type, OutputType.documents);
      expect(info.tags, ['school', 'notes']);
    });

    test('tags defaults to empty list', () {
      final info = OutputFileInfo(
        path: '/tmp/test.txt',
        name: 'test.txt',
        sizeBytes: 0,
        createdAt: DateTime.now(),
        type: OutputType.images,
      );
      expect(info.tags, isEmpty);
    });

    test('extension returns uppercase extension', () {
      final info = OutputFileInfo(
        path: '/tmp/report.pdf',
        name: 'report.pdf',
        sizeBytes: 0,
        createdAt: DateTime.now(),
        type: OutputType.documents,
      );
      expect(info.extension, 'PDF');
    });

    test('extension returns empty string when no dot in name', () {
      final info = OutputFileInfo(
        path: '/tmp/readme',
        name: 'readme',
        sizeBytes: 0,
        createdAt: DateTime.now(),
        type: OutputType.documents,
      );
      expect(info.extension, '');
    });

    test('extension handles multiple dots', () {
      final info = OutputFileInfo(
        path: '/tmp/my.file.tar.gz',
        name: 'my.file.tar.gz',
        sizeBytes: 0,
        createdAt: DateTime.now(),
        type: OutputType.documents,
      );
      expect(info.extension, 'GZ');
    });

    group('sizeFormatted', () {
      test('formats bytes', () {
        final info = OutputFileInfo(
          path: '/tmp/t.txt',
          name: 't.txt',
          sizeBytes: 500,
          createdAt: DateTime.now(),
          type: OutputType.documents,
        );
        expect(info.sizeFormatted, '500 B');
      });

      test('formats kilobytes', () {
        final info = OutputFileInfo(
          path: '/tmp/t.txt',
          name: 't.txt',
          sizeBytes: 2048,
          createdAt: DateTime.now(),
          type: OutputType.documents,
        );
        expect(info.sizeFormatted, '2.0 KB');
      });

      test('formats megabytes', () {
        final info = OutputFileInfo(
          path: '/tmp/t.txt',
          name: 't.txt',
          sizeBytes: 3 * 1024 * 1024,
          createdAt: DateTime.now(),
          type: OutputType.documents,
        );
        expect(info.sizeFormatted, '3.0 MB');
      });

      test('edge case at exactly 1 KB', () {
        final info = OutputFileInfo(
          path: '/tmp/t.txt',
          name: 't.txt',
          sizeBytes: 1024,
          createdAt: DateTime.now(),
          type: OutputType.documents,
        );
        expect(info.sizeFormatted, '1.0 KB');
      });
    });
  });

  group('saveTags / loadTags', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('output_storage_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('saveTags writes tags file', () async {
      final filePath = '${tempDir.path}/doc.txt';
      File(filePath).createSync();

      await OutputStorageService.instance.saveTags(filePath, ['tag1', 'tag2']);

      final tagsFile = File('$filePath.tags');
      expect(await tagsFile.exists(), isTrue);
    });

    test('loadTags returns saved tags', () async {
      final filePath = '${tempDir.path}/doc.txt';
      File(filePath).createSync();

      await OutputStorageService.instance.saveTags(filePath, ['alpha', 'beta']);
      final loaded = await OutputStorageService.instance.loadTags(filePath);

      expect(loaded, ['alpha', 'beta']);
    });

    test('loadTags returns empty list when tags file does not exist', () async {
      final filePath = '${tempDir.path}/nope.txt';
      final loaded = await OutputStorageService.instance.loadTags(filePath);
      expect(loaded, isEmpty);
    });

    test('saveTags does nothing for empty tags list', () async {
      final filePath = '${tempDir.path}/empty.txt';
      File(filePath).createSync();

      await OutputStorageService.instance.saveTags(filePath, []);

      final tagsFile = File('$filePath.tags');
      expect(await tagsFile.exists(), isFalse);
    });

    test('saveTags and loadTags handles special characters', () async {
      final filePath = '${tempDir.path}/special.txt';
      File(filePath).createSync();

      await OutputStorageService.instance.saveTags(filePath, ['tag-one', 'tag_two', 'tag.three']);
      final loaded = await OutputStorageService.instance.loadTags(filePath);

      expect(loaded, ['tag-one', 'tag_two', 'tag.three']);
    });

    test('loadTags returns empty list for malformed tags file', () async {
      final filePath = '${tempDir.path}/bad.txt';
      File(filePath).createSync();
      File('$filePath.tags').writeAsStringSync('not valid json');

      final loaded = await OutputStorageService.instance.loadTags(filePath);
      expect(loaded, isEmpty);
    });
  });
}
