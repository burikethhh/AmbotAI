import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

/// Stores conversation summaries for recycling into future conversations.
///
/// When a conversation reaches a certain length or is explicitly closed,
/// this service extracts a compact summary that can be injected into
/// new conversations with the same role to provide continuity.
class ConversationSummaryStore {
  ConversationSummaryStore._();
  static final ConversationSummaryStore instance = ConversationSummaryStore._();

  static const String _boxName = 'ambot_conv_summaries_v1';
  static const String _indexBoxName = 'ambot_conv_summary_index_v1';
  static const _uuid = Uuid();

  static const int _maxSummariesPerRole = 50;

  Box<String>? _box;
  Box<String>? _indexBox;

  Future<void> init() async {
    if (_box != null) return;
    _box = await Hive.openBox<String>(_boxName);
    _indexBox = await Hive.openBox<String>(_indexBoxName);
  }

  Box<String> get _boxOrThrow {
    final b = _box;
    if (b == null) {
      throw StateError('ConversationSummaryStore.init() must be called before use.');
    }
    return b;
  }

  Future<void> addSummary({
    required String roleId,
    required String conversationId,
    required String summary,
    required List<String> topics,
    double importance = 0.5,
  }) async {
    final entry = SummaryEntry(
      id: _uuid.v4(),
      roleId: roleId,
      conversationId: conversationId,
      summary: summary,
      topics: topics,
      importance: importance,
      createdAt: DateTime.now(),
      usedCount: 0,
    );
    await _boxOrThrow.put(entry.id, jsonEncode(entry.toJson()));
    await _addToIndex(roleId, entry.id);
    await _maybePrune(roleId);
  }

  List<SummaryEntry> getSummariesForRole(String roleId, {int limit = 5}) {
    final ids = _getIndexedIds(roleId);
    if (ids.isEmpty) return [];
    final box = _boxOrThrow;
    final out = <SummaryEntry>[];
    for (final id in ids) {
      final raw = box.get(id);
      if (raw == null) continue;
      try {
        out.add(SummaryEntry.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        ));
      } catch (_) {}
    }
    out.sort((a, b) {
      final scoreA = _score(a);
      final scoreB = _score(b);
      return scoreB.compareTo(scoreA);
    });
    return out.take(limit).toList();
  }

  List<SummaryEntry> getSummariesByTopic(String roleId, String topic, {int limit = 3}) {
    final all = getSummariesForRole(roleId, limit: _maxSummariesPerRole);
    final lower = topic.toLowerCase();
    final matched = all.where((e) {
      return e.topics.any((t) => t.toLowerCase().contains(lower)) ||
          e.summary.toLowerCase().contains(lower);
    }).toList();
    return matched.take(limit).toList();
  }

  Future<void> markUsed(String id) async {
    final raw = _boxOrThrow.get(id);
    if (raw == null) return;
    final entry = SummaryEntry.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    final updated = entry.copyWith(usedCount: entry.usedCount + 1);
    await _boxOrThrow.put(id, jsonEncode(updated.toJson()));
  }

  Future<void> delete(String id) async {
    await _boxOrThrow.delete(id);
  }

  Future<void> clearRole(String roleId) async {
    final ids = _getIndexedIds(roleId);
    await _boxOrThrow.deleteAll(ids);
    await _indexBox?.delete(roleId);
  }

  String renderForPrompt(String roleId, String query, {int limit = 3}) {
    final summaries = getSummariesByTopic(roleId, query, limit: limit);
    if (summaries.isEmpty) return '';
    final lines = summaries.map((s) {
      return '- Previous context: ${s.summary}';
    }).join('\n');
    return 'Relevant past conversations:\n$lines';
  }



  List<String> _getIndexedIds(String roleId) {
    final raw = _indexBox?.get(roleId);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).cast<String>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _addToIndex(String roleId, String id) async {
    final ids = _getIndexedIds(roleId);
    if (!ids.contains(id)) {
      ids.add(id);
      await _indexBox?.put(roleId, jsonEncode(ids));
    }
  }

  double _score(SummaryEntry e) {
    final recency = 1.0 / (1 + DateTime.now().difference(e.createdAt).inDays);
    return e.importance * 0.4 + recency * 0.3 + (e.usedCount * 0.1).clamp(0.0, 0.3);
  }

  Future<void> _maybePrune(String roleId) async {
    final ids = _getIndexedIds(roleId);
    if (ids.length <= _maxSummariesPerRole) return;
    final box = _boxOrThrow;
    final entries = <SummaryEntry>[];
    for (final id in ids) {
      final raw = box.get(id);
      if (raw == null) continue;
      try {
        entries.add(SummaryEntry.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (_) {}
    }
    entries.sort((a, b) => _score(a).compareTo(_score(b)));
    final overflow = entries.length - _maxSummariesPerRole;
    final toDelete = entries.take(overflow).map((e) => e.id).toList();
    await _boxOrThrow.deleteAll(toDelete);
    // Update index
    final remaining = _getIndexedIds(roleId).where((id) => !toDelete.contains(id)).toList();
    await _indexBox?.put(roleId, jsonEncode(remaining));
  }
}

class SummaryEntry {
  final String id;
  final String roleId;
  final String conversationId;
  final String summary;
  final List<String> topics;
  final double importance;
  final DateTime createdAt;
  final int usedCount;

  const SummaryEntry({
    required this.id,
    required this.roleId,
    required this.conversationId,
    required this.summary,
    required this.topics,
    required this.importance,
    required this.createdAt,
    required this.usedCount,
  });

  SummaryEntry copyWith({
    int? usedCount,
  }) {
    return SummaryEntry(
      id: id,
      roleId: roleId,
      conversationId: conversationId,
      summary: summary,
      topics: topics,
      importance: importance,
      createdAt: createdAt,
      usedCount: usedCount ?? this.usedCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'roleId': roleId,
        'conversationId': conversationId,
        'summary': summary,
        'topics': topics,
        'importance': importance,
        'createdAt': createdAt.toIso8601String(),
        'usedCount': usedCount,
      };

  factory SummaryEntry.fromJson(Map<String, dynamic> json) => SummaryEntry(
        id: json['id'] as String,
        roleId: json['roleId'] as String,
        conversationId: json['conversationId'] as String,
        summary: json['summary'] as String,
        topics: (json['topics'] as List).map((e) => e as String).toList(),
        importance: (json['importance'] as num?)?.toDouble() ?? 0.5,
        createdAt: DateTime.parse(json['createdAt'] as String),
        usedCount: json['usedCount'] as int? ?? 0,
      );
}
