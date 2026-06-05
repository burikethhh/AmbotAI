import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

enum OutputType { documents, images, voice }

class OutputFileInfo {
  final String path;
  final String name;
  final int sizeBytes;
  final DateTime createdAt;
  final OutputType type;
  final List<String> tags;

  const OutputFileInfo({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.createdAt,
    required this.type,
    this.tags = const [],
  });

  String get extension => name.contains('.') ? name.split('.').last.toUpperCase() : '';
  String get sizeFormatted {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class OutputStorageService {
  OutputStorageService._();
  static final OutputStorageService instance = OutputStorageService._();

  Directory? _root;

  Future<Directory> get root async {
    if (_root != null) return _root!;
    final appDir = await getApplicationDocumentsDirectory();
    _root = Directory('${appDir.path}/ambot_output');
    if (!await _root!.exists()) await _root!.create(recursive: true);
    return _root!;
  }

  Future<Directory> dir(OutputType type) async {
    final r = await root;
    final sub = Directory('${r.path}/${type.name}');
    if (!await sub.exists()) await sub.create(recursive: true);
    return sub;
  }

  Future<String> generatePath(OutputType type, String extension) async {
    final d = await dir(type);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final name = '${type.name.substring(0, 3)}_$timestamp.$extension';
    return '${d.path}/$name';
  }

  Future<List<OutputFileInfo>> listAll({OutputType? type}) async {
    final results = <OutputFileInfo>[];
    final types = type != null ? [type] : OutputType.values;
    for (final t in types) {
      try {
        final d = await dir(t);
        if (!await d.exists()) continue;
        final entities = await d.list().toList();
        final fileFutures = <Future<OutputFileInfo?>>[];
        for (final entity in entities) {
          if (entity is File && !entity.path.endsWith('.tags')) {
            fileFutures.add(_buildFileInfo(entity, t));
          }
        }
        final files = await Future.wait(fileFutures);
        results.addAll(files.whereType<OutputFileInfo>());
      } catch (e) {
        debugPrint('OUTPUT_STORE: failed to list files: $e');
      }
    }
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  Future<OutputFileInfo?> _buildFileInfo(File entity, OutputType type) async {
    try {
      final stat = await entity.stat();
      final tags = await loadTags(entity.path);
      return OutputFileInfo(
        path: entity.path,
        name: entity.uri.pathSegments.last,
        sizeBytes: stat.size,
        createdAt: stat.modified,
        type: type,
        tags: tags,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
    final tagsFile = File('$path.tags');
    if (await tagsFile.exists()) await tagsFile.delete();
  }

  /// Save tags alongside a file via companion `.tags` file.
  Future<void> saveTags(String filePath, List<String> tags) async {
    if (tags.isEmpty) return;
    final tagsFile = File('$filePath.tags');
    await tagsFile.writeAsString(jsonEncode(tags));
  }

  /// Load tags saved alongside a file. Returns empty list if none.
  Future<List<String>> loadTags(String filePath) async {
    final tagsFile = File('$filePath.tags');
    if (!await tagsFile.exists()) return [];
    try {
      final raw = await tagsFile.readAsString();
      return (jsonDecode(raw) as List).map((e) => e as String).toList();
    } catch (_) {
      return [];
    }
  }

  Future<int> totalSize({OutputType? type}) async {
    int total = 0;
    final types = type != null ? [type] : OutputType.values;
    for (final t in types) {
      try {
        final d = await dir(t);
        if (!await d.exists()) continue;
        await for (final entity in d.list()) {
          if (entity is File) total += await entity.length();
        }
      } catch (e) {
        debugPrint('OUTPUT_STORE: failed to calculate total size: $e');
      }
    }
    return total;
  }
}
