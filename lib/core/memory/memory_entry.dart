import '../roles/role_domain.dart';

/// A single durable fact the AI learned about the user or the subject
/// matter. Memory entries are injected into the system prompt on
/// subsequent turns, giving local models a form of continuity without
/// bloating the context window with full chat transcripts.
class MemoryEntry {
  final String id;

  /// Where this memory lives. See [MemoryScope].
  final MemoryScope scope;

  /// Role this memory belongs to. Null when [scope] is [MemoryScope.global].
  final String? roleId;

  /// Conversation this memory belongs to. Non-null only when
  /// [scope] is [MemoryScope.chat].
  final String? conversationId;

  /// Short human-readable key used for keyword retrieval and display.
  /// Example: "learning style", "current goal", "allergies".
  final String key;

  /// The actual memorized statement. Example:
  /// "User is preparing for the MCAT in August 2026."
  final String value;

  /// Optional embedding for semantic retrieval. Low-end devices will
  /// leave this null and fall back to keyword search.
  final List<double>? embedding;

  /// 0..1 importance weight. Used to bias retrieval and to decide what
  /// to keep when the store hits its size cap.
  final double importance;

  final DateTime createdAt;
  final DateTime lastUsedAt;

  /// Number of times this memory has been retrieved. Helps keep
  /// frequently useful memories around when pruning.
  final int useCount;

  /// True if the user has pinned this memory; pinned memories are never
  /// pruned and always candidates for retrieval.
  final bool pinned;

  const MemoryEntry({
    required this.id,
    required this.scope,
    required this.key,
    required this.value,
    required this.createdAt,
    required this.lastUsedAt,
    this.roleId,
    this.conversationId,
    this.embedding,
    this.importance = 0.5,
    this.useCount = 0,
    this.pinned = false,
  });

  MemoryEntry copyWith({
    MemoryScope? scope,
    String? roleId,
    String? conversationId,
    String? key,
    String? value,
    List<double>? embedding,
    double? importance,
    DateTime? lastUsedAt,
    int? useCount,
    bool? pinned,
  }) {
    return MemoryEntry(
      id: id,
      scope: scope ?? this.scope,
      roleId: roleId ?? this.roleId,
      conversationId: conversationId ?? this.conversationId,
      key: key ?? this.key,
      value: value ?? this.value,
      embedding: embedding ?? this.embedding,
      importance: importance ?? this.importance,
      createdAt: createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      useCount: useCount ?? this.useCount,
      pinned: pinned ?? this.pinned,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'scope': scope.name,
        'roleId': roleId,
        'conversationId': conversationId,
        'key': key,
        'value': value,
        'embedding': embedding,
        'importance': importance,
        'createdAt': createdAt.toIso8601String(),
        'lastUsedAt': lastUsedAt.toIso8601String(),
        'useCount': useCount,
        'pinned': pinned,
      };

  factory MemoryEntry.fromJson(Map<String, dynamic> json) => MemoryEntry(
        id: json['id'] as String,
        scope: MemoryScope.values.byName(json['scope'] as String),
        roleId: json['roleId'] as String?,
        conversationId: json['conversationId'] as String?,
        key: json['key'] as String,
        value: json['value'] as String,
        embedding: (json['embedding'] as List?)?.cast<num>().map((e) => e.toDouble()).toList(),
        importance: (json['importance'] as num?)?.toDouble() ?? 0.5,
        createdAt: DateTime.parse(json['createdAt'] as String),
        lastUsedAt: DateTime.parse(json['lastUsedAt'] as String),
        useCount: json['useCount'] as int? ?? 0,
        pinned: json['pinned'] as bool? ?? false,
      );
}
