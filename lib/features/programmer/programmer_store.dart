import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'programmer_types.dart';

class ProgrammerStore {
  ProgrammerStore._();
  static final ProgrammerStore instance = ProgrammerStore._();

  static const String _boxName = 'ambot_programmer_v1';

  Box<String>? _box;

  Future<void> init() async {
    if (_box != null) return;
    _box = await Hive.openBox<String>(_boxName);
  }

  Box<String> get _boxOrThrow {
    final b = _box;
    if (b == null) {
      throw StateError('ProgrammerStore.init() must be called before use.');
    }
    return b;
  }

  Future<void> saveCurrentProject(List<ProjectFile> files) async {
    final data = jsonEncode(files.map((f) => f.toJson()).toList());
    await _boxOrThrow.put('current', data);
  }

  List<ProjectFile>? loadCurrentProject() {
    final raw = _boxOrThrow.get('current');
    if (raw == null) return null;
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => ProjectFile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> clearCurrentProject() async {
    await _boxOrThrow.delete('current');
  }
}
