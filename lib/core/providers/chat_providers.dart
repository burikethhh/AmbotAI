import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/chat_service.dart';

final conversationsProvider =
    StateNotifierProvider<ConversationsNotifier, Map<String, List<Conversation>>>((ref) {
  return ConversationsNotifier();
});

class ConversationsNotifier extends StateNotifier<Map<String, List<Conversation>>> {
  ConversationsNotifier() : super({});

  Conversation createConversation(String roleId) {
    final conv = Conversation(roleId: roleId);
    final roleConvs = state[roleId] ?? [];
    state = {...state, roleId: [conv, ...roleConvs]};
    return conv;
  }

  void addMessage(String roleId, String conversationId, ChatMessage message) {
    final roleConvs = state[roleId] ?? [];
    state = {
      ...state,
      roleId: [
        for (final conv in roleConvs)
          if (conv.id == conversationId)
            Conversation(
              id: conv.id,
              roleId: conv.roleId,
              messages: [...conv.messages, message],
              createdAt: conv.createdAt,
              updatedAt: DateTime.now(),
            )
          else
            conv,
      ],
    };
  }

  void updateLastMessage(String roleId, String conversationId, ChatMessage message) {
    final roleConvs = state[roleId] ?? [];
    state = {
      ...state,
      roleId: [
        for (final conv in roleConvs)
          if (conv.id == conversationId)
            Conversation(
              id: conv.id,
              roleId: conv.roleId,
              messages: [
                ...conv.messages.sublist(0, conv.messages.length - 1),
                message,
              ],
              createdAt: conv.createdAt,
              updatedAt: DateTime.now(),
            )
          else
            conv,
      ],
    };
  }

  void addConversation(Conversation conversation) {
    final roleConvs = state[conversation.roleId] ?? [];
    if (roleConvs.any((c) => c.id == conversation.id)) return;
    state = {
      ...state,
      conversation.roleId: [conversation, ...roleConvs],
    };
  }

  void removeConversation(String roleId, String conversationId) {
    final roleConvs = state[roleId] ?? [];
    state = {
      ...state,
      roleId: roleConvs.where((c) => c.id != conversationId).toList(),
    };
  }
}

final isStreamingProvider = StateProvider<bool>((ref) => false);
