import 'dart:math' as math;

import 'memory_entry.dart';
import 'memory_service.dart';

/// Retrieves the most relevant memories for a given prompt.
///
/// This first pass is **keyword-only** so it runs on every device tier
/// with no model dependencies. When an on-device embedding engine is
/// wired up, the retriever will prefer cosine similarity on
/// [MemoryEntry.embedding] and fall back to keywords when absent.
class MemoryRetriever {
  MemoryRetriever(this._service);
  final MemoryService _service;

  /// Returns up to [topK] memories that are most relevant to [query] for
  /// the given role and conversation. Marks the returned memories as
  /// recently used so pruning favors keeping them.
  Future<List<MemoryEntry>> retrieve({
    required String query,
    required String roleId,
    String? conversationId,
    int topK = 5,
  }) async {
    final pool = _service.candidatesFor(
      roleId: roleId,
      conversationId: conversationId,
    );
    if (pool.isEmpty) return const [];

    final queryTokens = _tokenize(query);
    if (queryTokens.isEmpty) {
      // Fall back to most-important + most-recent.
      pool.sort(_recentImportantOrder);
      final picks = pool.take(topK).toList();
      await _service.markUsed(picks.map((e) => e.id));
      return picks;
    }

    final scored = <_Scored>[];
    for (final entry in pool) {
      final score = _score(entry, queryTokens);
      if (score > 0 || entry.pinned) {
        scored.add(_Scored(entry, score));
      }
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    final picks = scored.take(topK).map((s) => s.entry).toList();
    await _service.markUsed(picks.map((e) => e.id));
    return picks;
  }

  /// Renders selected memories as a short system-prompt block the AI can
  /// consume. Keep it compact — context windows on local models are tight.
  String renderForPrompt(List<MemoryEntry> memories) {
    if (memories.isEmpty) return '';
    final buf = StringBuffer();
    buf.writeln('Known facts about the user and this topic:');
    for (final m in memories) {
      buf.writeln('- ${m.value}');
    }
    buf.writeln(
      'Use these facts naturally when relevant. Do not mention that they '
      'were provided as context.',
    );
    return buf.toString();
  }

  // --- Scoring ------------------------------------------------------------

  double _score(MemoryEntry entry, Set<String> queryTokens) {
    final entryTokens = _tokenize('${entry.key} ${entry.value}');
    if (entryTokens.isEmpty) return 0.0;

    var overlap = 0;
    for (final t in queryTokens) {
      if (entryTokens.contains(t)) overlap++;
    }
    if (overlap == 0 && !entry.pinned) return 0.0;

    final tokenScore = overlap / math.max(queryTokens.length, 1);
    final ageDays = DateTime.now().difference(entry.lastUsedAt).inDays;
    final recency = 1.0 / (1 + ageDays);
    final pinnedBoost = entry.pinned ? 0.2 : 0.0;

    return tokenScore * 1.0 +
        entry.importance * 0.3 +
        recency * 0.2 +
        pinnedBoost;
  }

  static int _recentImportantOrder(MemoryEntry a, MemoryEntry b) {
    if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
    final ai = a.importance + 1.0 / (1 + DateTime.now().difference(a.lastUsedAt).inDays);
    final bi = b.importance + 1.0 / (1 + DateTime.now().difference(b.lastUsedAt).inDays);
    return bi.compareTo(ai);
  }

  static final RegExp _nonWord = RegExp(r'[^a-z0-9]+');
  static const _stopwords = <String>{
    'the', 'a', 'an', 'and', 'or', 'but', 'if', 'then', 'is', 'are', 'was',
    'were', 'be', 'been', 'being', 'i', 'you', 'he', 'she', 'it', 'we',
    'they', 'me', 'my', 'your', 'our', 'their', 'to', 'of', 'in', 'on',
    'at', 'for', 'with', 'by', 'as', 'this', 'that', 'these', 'those',
    'do', 'does', 'did', 'have', 'has', 'had', 'can', 'could', 'should',
    'would', 'will', 'just', 'about', 'so', 'not', 'no', 'yes',
  };

  static Set<String> _tokenize(String text) {
    final lower = text.toLowerCase();
    final parts = lower.split(_nonWord).where((t) => t.isNotEmpty && t.length > 2 && !_stopwords.contains(t));
    return parts.toSet();
  }
}

class _Scored {
  _Scored(this.entry, this.score);
  final MemoryEntry entry;
  final double score;
}
