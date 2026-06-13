import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ai/engine_selector.dart';
import '../../core/config/api_keys.dart';
import '../../core/document_gen/pdf_generator.dart';
import '../../core/memory/memory_manager.dart';
import '../../core/providers/app_providers.dart';
import '../../core/rag/rag_engine.dart';
import '../../core/roles/role.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/theme/theme_colors.dart';
import '../general_chat/general_chat_screen.dart';
import 'desktop_context_menu.dart';

class DesktopChatScreen extends ConsumerStatefulWidget {
  final Role? role;
  final String? title;

  const DesktopChatScreen({
    super.key,
    this.role,
    this.title,
  });

  @override
  ConsumerState<DesktopChatScreen> createState() => _DesktopChatScreenState();
}

class _DesktopChatScreenState extends ConsumerState<DesktopChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isGenerating = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty || _isGenerating) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isGenerating = true;
    });
    _controller.clear();
    _scrollToBottom();

    // Simulate AI response
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: 'AI response for: $text',
            isUser: false,
          ));
          _isGenerating = false;
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(themeColorsProvider);
    final displayName = widget.role?.name ?? widget.title ?? 'General';

    return Column(
      children: [
        _buildHeader(c, displayName),
        Expanded(child: _buildMessageList(c)),
        if (_isGenerating) _buildTypingIndicator(c),
        _buildInputArea(c),
      ],
    );
  }

  Widget _buildHeader(ThemeColors c, String displayName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.borderColor, width: 1)),
      ),
      child: Row(
        children: [
          Icon(Icons.chat_outlined, size: 20, color: c.textSecondary),
          const SizedBox(width: 10),
          Text(
            displayName.toUpperCase(),
            style: AppTypography.titleMedium(c.textPrimary),
          ),
          const Spacer(),
          if (widget.role != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: c.borderColor, width: 1),
              ),
              child: Text('ROLE', style: AppTypography.labelSmall(c.textTertiary)),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageList(ThemeColors c) {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: c.textTertiary),
            const SizedBox(height: 16),
            Text('START A CONVERSATION', style: AppTypography.headlineSmall(c.textSecondary)),
            const SizedBox(height: 8),
            Text('Type a message below to begin', style: AppTypography.bodySmall(c.textTertiary)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        return _buildMessageBubble(c, msg);
      },
    );
  }

  Widget _buildMessageBubble(ThemeColors c, ChatMessage msg) {
    return DesktopContextMenu(
      onCopy: () {
        Clipboard.setData(ClipboardData(text: msg.text));
      },
      child: Align(
        alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
          decoration: BoxDecoration(
            color: msg.isUser
                ? (c.isDark ? AppColors.primaryDark : AppColors.primaryLight)
                : (c.isDark ? AppColors.cardDark : AppColors.cardLight),
            border: Border.all(color: c.borderColor, width: 1),
          ),
          child: Text(
            msg.text,
            style: AppTypography.bodyMedium(msg.isUser ? Colors.white : c.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(c.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          Text('Thinking...', style: AppTypography.bodySmall(c.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildInputArea(ThemeColors c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.borderColor, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: DesktopContextMenu(
              onPaste: () async {
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                if (data?.text != null) {
                  _controller.text += data!.text!;
                }
              },
              child: TextField(
                controller: _controller,
                style: AppTypography.bodyMedium(c.textPrimary),
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Type a message... (Enter to send, Shift+Enter for new line)',
                  hintStyle: AppTypography.bodyMedium(c.textTertiary),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: c.borderColor, width: 1),
                    borderRadius: BorderRadius.zero,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: c.borderColor, width: 1),
                    borderRadius: BorderRadius.zero,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.accentColor, width: 1),
                    borderRadius: BorderRadius.zero,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _isGenerating ? null : _sendMessage,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _isGenerating ? c.textTertiary : AppColors.accentColor,
                ),
                child: Text(
                  'SEND',
                  style: AppTypography.labelSmall(Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  const ChatMessage({required this.text, required this.isUser});
}
