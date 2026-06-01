import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../roles/role_domain.dart';
import 'memory_entry.dart';

/// Persistent long-term memory store backed by Hive.
///
/// Stores each [MemoryEntry] as a JSON string keyed by its id. All reads
/// are synchronous once the box is open, which keeps the hot path (prompt
/// assembly) fast. Writes are async and fire-and-forget friendly.
///
/// Scopes:
///   - global   : shared across every role
///   - role     : per-role
///   - chat     : per-conversation
///   - none     : memories never written (ChatService will short-circuit)
class MemoryService {
  MemoryService._();
  static final MemoryService instance = MemoryService._();

  static const String _boxName = 'ambot_memory_v1';
  static const _uuid = Uuid();

  /// Hard cap on the total number of memories. When exceeded, the lowest
  /// scoring non-pinned entries are evicted. Tunable from settings later.
  static const int _maxEntries = 2000;

  Box<String>? _box;

  /// Master kill-switch. When false, all writes are ignored and reads
  /// return empty. Useful for a "private mode" toggle.
  bool enabled = true;

  Future<void> init() async {
    if (_box != null) return;
    _box = await Hive.openBox<String>(_boxName);
  }

  Box<String> get _boxOrThrow {
    final b = _box;
    if (b == null) {
      throw StateError('MemoryService.init() must be called before use.');
    }
    return b;
  }

  // --- Write path ---------------------------------------------------------

  Future<MemoryEntry> add({
    required MemoryScope scope,
    required String key,
    required String value,
    String? roleId,
    String? conversationId,
    List<double>? embedding,
    double importance = 0.5,
    bool pinned = false,
  }) async {
    if (!enabled || scope == MemoryScope.none) {
      return MemoryEntry(
        id: _uuid.v4(),
        scope: scope,
        key: key,
        value: value,
        createdAt: DateTime.now(),
        lastUsedAt: DateTime.now(),
        roleId: roleId,
        conversationId: conversationId,
        embedding: embedding,
        importance: importance,
        pinned: pinned,
      );
    }
    final entry = MemoryEntry(
      id: _uuid.v4(),
      scope: scope,
      key: key,
      value: value,
      createdAt: DateTime.now(),
      lastUsedAt: DateTime.now(),
      roleId: roleId,
      conversationId: conversationId,
      embedding: embedding,
      importance: importance,
      pinned: pinned,
    );
    await _boxOrThrow.put(entry.id, jsonEncode(entry.toJson()));
    await _maybePrune();
    return entry;
  }

  Future<void> update(MemoryEntry entry) async {
    if (!enabled) return;
    await _boxOrThrow.put(entry.id, jsonEncode(entry.toJson()));
  }

  Future<void> delete(String id) async {
    await _boxOrThrow.delete(id);
  }

  Future<void> wipeAll() async {
    await _boxOrThrow.clear();
  }

  Future<void> wipeScope({
    required MemoryScope scope,
    String? roleId,
    String? conversationId,
  }) async {
    final toDelete = all().where((e) {
      if (e.scope != scope) return false;
      if (scope == MemoryScope.role && roleId != null && e.roleId != roleId) {
        return false;
      }
      if (scope == MemoryScope.chat && conversationId != null && e.conversationId != conversationId) {
        return false;
      }
      return true;
    }).map((e) => e.id).toList();
    await _boxOrThrow.deleteAll(toDelete);
  }

  // --- Read path ----------------------------------------------------------

  List<MemoryEntry> all() {
    if (!enabled) return const [];
    final box = _boxOrThrow;
    final out = <MemoryEntry>[];
    for (final raw in box.values) {
      try {
        out.add(MemoryEntry.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        ));
      } catch (_) {
        // Skip corrupt entry.
      }
    }
    return out;
  }

  /// Every memory that could legitimately be shown to the given role in
  /// the given conversation. This is the retrieval pool; ranking happens
  /// in [MemoryRetriever].
  List<MemoryEntry> candidatesFor({
    required String roleId,
    String? conversationId,
  }) {
    if (!enabled) return const [];
    return all().where((e) {
      switch (e.scope) {
        case MemoryScope.global:
          return true;
        case MemoryScope.role:
          return e.roleId == roleId;
        case MemoryScope.chat:
          return conversationId != null && e.conversationId == conversationId;
        case MemoryScope.none:
          return false;
      }
    }).toList();
  }

  /// Mark memories as recently used. Called by [MemoryRetriever] after
  /// it injects them into a prompt so that pruning favors keeping them.
  Future<void> markUsed(Iterable<String> ids) async {
    if (!enabled || ids.isEmpty) return;
    final now = DateTime.now();
    final puts = <Future<void>>[];
    for (final id in ids) {
      final raw = _boxOrThrow.get(id);
      if (raw == null) continue;
      try {
        final memory = MemoryEntry.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
        final updated = memory.copyWith(
          lastUsedAt: now,
          useCount: memory.useCount + 1,
        );
        puts.add(_boxOrThrow.put(id, jsonEncode(updated.toJson())));
      } catch (_) {}
    }
    if (puts.isNotEmpty) await Future.wait(puts);
  }

  // --- Export / import ----------------------------------------------------

  String exportJson() {
    return jsonEncode({
      'version': 1,
      'entries': all().map((e) => e.toJson()).toList(),
    });
  }

  Future<int> importJson(String raw, {bool replace = false}) async {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final entries = (data['entries'] as List)
        .map((e) => MemoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    if (replace) await wipeAll();
    for (final e in entries) {
      await _boxOrThrow.put(e.id, jsonEncode(e.toJson()));
    }
    return entries.length;
  }

  // --- Pruning ------------------------------------------------------------

  Future<void> _maybePrune() async {
    final entries = all();
    if (entries.length <= _maxEntries) return;
    entries.sort(_pruneOrder);
    final overflow = entries.length - _maxEntries;
    final toDelete = entries.take(overflow).map((e) => e.id).toList();
    await _boxOrThrow.deleteAll(toDelete);
  }

  /// Lower score = evict first. Pinned memories always come last.
  static int _pruneOrder(MemoryEntry a, MemoryEntry b) {
    if (a.pinned != b.pinned) return a.pinned ? 1 : -1;
    final aScore = _pruneScore(a);
    final bScore = _pruneScore(b);
    return aScore.compareTo(bScore);
  }

  static double _pruneScore(MemoryEntry e) {
    final ageDays = DateTime.now().difference(e.lastUsedAt).inDays;
    final recency = 1.0 / (1 + ageDays);
    return e.importance * 0.5 + recency * 0.3 + (e.useCount * 0.05);
  }
}
