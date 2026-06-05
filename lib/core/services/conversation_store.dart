import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/chat_service.dart';

/// Persistent conversation storage backed by Hive.
///
/// Conversations are stored as JSON strings keyed by conversation ID.
/// A separate index box maps roleId to a list of conversation IDs for
/// fast lookup per role.
class ConversationStore {
  ConversationStore._();
  static final ConversationStore instance = ConversationStore._();

  static const String _boxName = 'ambot_conversations_v1';
  static const String _indexBoxName = 'ambot_conversation_index_v1';

  Box<String>? _box;
  Box<String>? _indexBox;

  Future<void> init() async {
    if (_box != null) return;
    _box = await Hive.openBox<String>(_boxName);
    _indexBox = await Hive.openBox<String>(_indexBoxName);
  }

  /// Save a conversation to persistent storage.
  Future<void> save(Conversation conversation) async {
    await _box?.put(conversation.id, jsonEncode(conversation.toJson()));
    await _addToIndex(conversation.roleId, conversation.id);
  }

  /// Load a specific conversation by ID.
  Conversation? load(String conversationId) {
    final raw = _box?.get(conversationId);
    if (raw == null) return null;
    try {
      return Conversation.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  /// Load all conversation IDs for a given role.
  List<String> getConversationIds(String roleId) {
    final raw = _indexBox?.get(roleId);
    if (raw == null) return [];
    try {
      final list = (jsonDecode(raw) as List).cast<String>();
      return list.where((id) => _box?.get(id) != null).toList();
    } catch (_) {
      return [];
    }
  }

  /// Load all conversations for a given role, sorted by updatedAt.
  List<Conversation> getByRole(String roleId) {
    final ids = getConversationIds(roleId);
    if (ids.isEmpty) return [];
    final box = _box;
    if (box == null) return [];
    // Note: Hive 2.2.3 does not support getAll(). Iterate individually.
    final conversations = <Conversation>[];
    for (final id in ids) {
      final raw = box.get(id);
      if (raw == null) continue;
      try {
        conversations.add(Conversation.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        ));
      } catch (e) {
        debugPrint('CONV_STORE: failed to decode conversation: $e');
      }
    }
    conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return conversations;
  }

  /// Load all conversations across all roles.
  List<Conversation> getAll() {
    final all = <Conversation>[];
    final box = _box;
    if (box == null) return all;
    for (final raw in box.values) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          all.add(Conversation.fromJson(decoded));
        }
      } catch (e) {
        debugPrint('CONV_STORE: failed to decode conversation in getAll: $e');
      }
    }
    all.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return all;
  }

  /// Search conversations by substring match on message content and title.
  List<Conversation> search(String query, String roleId) {
    if (query.trim().isEmpty) return getByRole(roleId);
    final lower = query.toLowerCase();
    final ids = getConversationIds(roleId);
    final matched = <Conversation>[];
    for (final id in ids) {
      final conv = load(id);
      if (conv == null) continue;
      final title = (getTitle(conv.id) ?? '').toLowerCase();
      if (title.contains(lower)) {
        matched.add(conv);
        continue;
      }
      for (final msg in conv.messages) {
        if (msg.content.toLowerCase().contains(lower)) {
          matched.add(conv);
          break;
        }
      }
    }
    matched.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return matched;
  }

  /// Delete a conversation.
  Future<void> delete(String conversationId) async {
    final conv = load(conversationId);
    if (conv != null) {
      await _removeFromIndex(conv.roleId, conversationId);
    }
    await _box?.delete(conversationId);
  }

  /// Delete all conversations for a role.
  Future<void> deleteByRole(String roleId) async {
    final ids = getConversationIds(roleId);
    for (final id in ids) {
      await _box?.delete(id);
    }
    await _indexBox?.delete(roleId);
  }

  /// Delete all conversations.
  Future<void> deleteAll() async {
    await _box?.clear();
    await _indexBox?.clear();
  }

  /// Rename a conversation (auto-generated title).
  Future<void> setTitle(String conversationId, String title) async {
    final conv = load(conversationId);
    if (conv == null) return;
    // We store the title in a separate metadata field
    final metaKey = '${conversationId}_meta';
    final metaRaw = _box?.get(metaKey);
    final meta = metaRaw != null
        ? (jsonDecode(metaRaw) as Map<String, dynamic>)
        : <String, dynamic>{};
    meta['title'] = title;
    await _box?.put(metaKey, jsonEncode(meta));
  }

  /// Get the title for a conversation.
  String? getTitle(String conversationId) {
    final metaKey = '${conversationId}_meta';
    final metaRaw = _box?.get(metaKey);
    if (metaRaw == null) return null;
    try {
      final meta = jsonDecode(metaRaw) as Map<String, dynamic>;
      return meta['title'] as String?;
    } catch (_) {
      return null;
    }
  }

  // --- Internal ---

  Future<void> _addToIndex(String roleId, String conversationId) async {
    final ids = getConversationIds(roleId);
    if (!ids.contains(conversationId)) {
      ids.insert(0, conversationId);
      await _indexBox?.put(roleId, jsonEncode(ids));
    }
  }

  Future<void> _removeFromIndex(String roleId, String conversationId) async {
    final ids = getConversationIds(roleId);
    ids.remove(conversationId);
    if (ids.isEmpty) {
      await _indexBox?.delete(roleId);
    } else {
      await _indexBox?.put(roleId, jsonEncode(ids));
    }
  }

  /// Auto-generate a title from the first user message.
  static String generateTitle(List<ChatMessage> messages) {
    final firstUser = messages
        .where((m) => m.role == MessageRole.user)
        .firstOrNull;
    if (firstUser == null) return 'New conversation';
    final text = firstUser.content.trim();
    if (text.length <= 40) return text;
    return '${text.substring(0, 40)}...';
  }
}
