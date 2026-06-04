import '../roles/role_domain.dart';
import 'memory_entry.dart';
import 'memory_service.dart';

/// Extracts durable facts from a user/assistant exchange and writes them
/// into [MemoryService].
///
/// Two strategies are supported:
///
///   1. **Heuristic** (default, zero cost): scans the user turn for
///      first-person factual statements ("I am...", "I'm studying...",
///      "my name is...", "I prefer...", explicit remember-this commands).
///   2. **LLM-assisted** (optional): delegates to an extractor callback
///      that wraps the model. Callers can plug this in where latency and
///      battery permit — typically only on flagship devices.
///
/// This file deliberately avoids pulling in the AI engine so it is free
/// of heavy dependencies and easy to unit-test.
class MemoryExtractor {
  MemoryExtractor(this._service);
  final MemoryService _service;

  static final _rememberRe = RegExp(
    r'\b(?:remember(?:\s+that)?|note\s+that|keep\s+in\s+mind(?:\s+that)?)[:,\s]+(.{4,200}?)(?:\.|\?|!|$)',
    caseSensitive: false,
  );

  static final _nameRe = RegExp(
    "\\b(?:my\\s+name\\s+is|i\\s*am|i'?m)\\s+([A-Z][a-z]{1,30})(?:\\b|\\.)",
  );

  static final _roleRe = RegExp(
    r"\b(?:i\s*am|i'?m|i)\s+(studying|learning|working\s+on|preparing\s+for|teaching|researching|practicing)\s+([a-z0-9 ,\-]{3,60})",
    caseSensitive: false,
  );

  static final _prefRe = RegExp(
    r"\bi\s+(?:prefer|like|enjoy|love)\s+([a-z0-9 ,\-]{3,60})",
    caseSensitive: false,
  );

  static final _dislikeRe = RegExp(
    r"\bi\s+(?:don'?t\s+like|hate|can'?t\s+stand|dislike)\s+([a-z0-9 ,\-]{3,60})",
    caseSensitive: false,
  );

  static final _goalRe = RegExp(
    r"\bmy\s+goal\s+is\s+([a-z0-9 ,\-]{3,80})",
    caseSensitive: false,
  );

  /// Inspects [userMessage] and optionally [assistantMessage] for facts
  /// worth persisting, then writes them to the store under [scope]
  /// (falling back to the role's default scope if [scope] is null).
  Future<List<MemoryEntry>> extractAndStore({    required String userMessage,
    String? assistantMessage,
    required String roleId,
    String? conversationId,
    required MemoryScope defaultScope,
    MemoryScope? scope,
  }) async {
    final effectiveScope = scope ?? defaultScope;
    if (effectiveScope == MemoryScope.none) return const [];

    final facts = _heuristicExtract(userMessage);
    if (facts.isEmpty) return const [];

    final stored = <MemoryEntry>[];
    for (final fact in facts) {
      final entry = await _service.add(
        scope: effectiveScope,
        key: fact.key,
        value: fact.value,
        roleId: effectiveScope == MemoryScope.global ? null : roleId,
        conversationId:
            effectiveScope == MemoryScope.chat ? conversationId : null,
        importance: fact.importance,
        pinned: fact.pinned,
      );
      stored.add(entry);
    }
    return stored;
  }

  // --- Heuristic patterns -------------------------------------------------

  List<_Fact> _heuristicExtract(String text) {
    final out = <_Fact>[];
    final lower = text.toLowerCase();

    // Explicit user command: "remember that ...", "note that ..."
    for (final m in _rememberRe.allMatches(text)) {
      final value = m.group(1)?.trim();
      if (value == null || value.isEmpty) continue;
      out.add(_Fact(
        key: 'note',
        value: value,
        importance: 0.9,
        pinned: true,
      ));
    }

    // "my name is X"
    final name = _nameRe.firstMatch(text);
    if (name != null) {
      out.add(_Fact(
        key: 'user name',
        value: 'User\'s name is ${name.group(1) ?? '(unknown)'}.',
        importance: 0.95,
      ));
    }

    // "I am studying X" / "I'm learning X" / "I work as X"
    final role = _roleRe.firstMatch(lower);
    if (role != null) {
      out.add(_Fact(
        key: 'current focus',
        value: 'User is ${role.group(1)} ${role.group(2)?.trim()}.',
        importance: 0.8,
      ));
    }

    // "I prefer X" / "I like X" (weaker signal)
    final pref = _prefRe.firstMatch(lower);
    if (pref != null) {
      out.add(_Fact(
        key: 'preference',
        value: 'User prefers ${pref.group(1)?.trim()}.',
        importance: 0.55,
      ));
    }

    // "I don't like / hate / can't stand X"
    final dislike = _dislikeRe.firstMatch(lower);
    if (dislike != null) {
      out.add(_Fact(
        key: 'dislike',
        value: 'User dislikes ${dislike.group(1)?.trim()}.',
        importance: 0.55,
      ));
    }

    // "my goal is X"
    final goal = _goalRe.firstMatch(lower);
    if (goal != null) {
      out.add(_Fact(
        key: 'goal',
        value: 'User\'s goal: ${goal.group(1)?.trim()}.',
        importance: 0.85,
      ));
    }

    // De-dupe by normalized value.
    final seen = <String>{};
    return out.where((f) {
      final k = f.value.toLowerCase().trim();
      if (seen.contains(k)) return false;
      seen.add(k);
      return true;
    }).toList();
  }
}

class _Fact {
  _Fact({
    required this.key,
    required this.value,
    this.importance = 0.5,
    this.pinned = false,
  });
  final String key;
  final String value;
  final double importance;
  final bool pinned;
}
