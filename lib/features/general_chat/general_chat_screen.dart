import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/theme/theme_colors.dart';
import '../../shared/widgets/ambot_avatar.dart';

class GeneralChatScreen extends ConsumerStatefulWidget {
  const GeneralChatScreen({super.key});

  @override
  ConsumerState<GeneralChatScreen> createState() => _GeneralChatScreenState();
}

class _GeneralChatScreenState extends ConsumerState<GeneralChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final _messages = <_ChatMessage>[];
  bool _isStreaming = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isStreaming) return;

    final engine = ref.read(aiEngineProvider);
    if (!engine.isReady) {
      setState(() {
        _messages.add(_ChatMessage(
          content: 'AI engine is not ready. Please check your settings and ensure a model or API key is configured.',
          isUser: false,
        ));
      });
      _scrollToBottom();
      return;
    }

    _controller.clear();

    final userMessage = _ChatMessage(content: text, isUser: true);
    setState(() {
      _messages.add(userMessage);
      _isStreaming = true;
    });
    _scrollToBottom();

    final aiMessage = _ChatMessage(content: '', isUser: false, isStreaming: true);
    setState(() => _messages.add(aiMessage));
    _scrollToBottom();

    final buffer = StringBuffer();

    try {
      await for (final chunk in engine.generateStream(
        text,
        systemPrompt: 'You are Ambot AI, a general-purpose helpful assistant. '
            'Answer the user\'s questions clearly and concisely. '
            'If asked about capabilities, explain you can chat about any topic, '
            'generate images, documents, voice, and more.',
      )) {
        buffer.write(chunk);
        if (mounted) {
          setState(() {
            _messages.last = _ChatMessage(
              content: buffer.toString(),
              isUser: false,
              isStreaming: true,
            );
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      buffer.write('\n\n*Error: ${e.toString().replaceFirst("Exception: ", "")}*');
    }

    if (mounted) {
      setState(() {
        _messages.last = _ChatMessage(
          content: buffer.toString().trim(),
          isUser: false,
          isStreaming: false,
        );
        _isStreaming = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(themeColorsProvider);
    final engine = ref.watch(aiEngineProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            AmbotAvatar(size: 28, isDark: c.isDark),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AMBOT AI', style: AppTypography.headlineMedium(c.textPrimary)),
                Text(
                  engine.isReady ? 'READY' : 'INITIALIZING',
                  style: AppTypography.labelMicro(c.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildWelcome(c)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, i) => _buildMessageBubble(_messages[i], c),
                  ),
          ),
          _buildInputBar(c),
        ],
      ),
    );
  }

  Widget _buildWelcome(ThemeColors c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AmbotAvatar(size: 72, isDark: c.isDark),
            const SizedBox(height: 20),
            Text('ASK ME ANYTHING',
              style: AppTypography.headlineSmall(c.textPrimary)),
            const SizedBox(height: 8),
            Text('Chat about any topic, get help with tasks,\n'
                'or ask me to create images and documents.',
              style: AppTypography.bodyMedium(c.textTertiary),
              textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'What can you do?',
                'Explain quantum computing',
                'Help me study history',
                'Write a poem about AI',
              ].map((suggestion) => GestureDetector(
                onTap: () {
                  _controller.text = suggestion;
                  _sendMessage();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: c.cardColor,
                    border: Border.all(color: c.borderColor, width: 2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(suggestion,
                    style: AppTypography.labelSmall(c.textSecondary)),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg, ThemeColors c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!msg.isUser) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 4),
              child: AmbotAvatar(size: 24, isDark: c.isDark),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: msg.isUser
                    ? (c.isDark ? AppColors.white : AppColors.black)
                    : c.cardColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: msg.isUser
                      ? (c.isDark ? AppColors.white : AppColors.black)
                      : c.borderColor,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.isUser ? 'YOU' : 'AMBOT',
                    style: AppTypography.labelMicro(
                      msg.isUser
                          ? (c.isDark ? AppColors.black : AppColors.white)
                          : c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    msg.content.isEmpty && msg.isStreaming ? '...' : msg.content,
                    style: AppTypography.bodyMedium(
                      msg.isUser
                          ? (c.isDark ? AppColors.black : AppColors.white)
                          : c.textPrimary,
                    ),
                  ),
                  if (msg.isStreaming)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: SizedBox(
                        width: 12, height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (msg.isUser) ...[
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildInputBar(ThemeColors c) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16, 8, 16, MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: c.isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(top: BorderSide(color: c.borderColor, width: 2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: c.cardColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: c.borderColor, width: 2),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: !_isStreaming,
                style: AppTypography.bodyMedium(c.textPrimary),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: _isStreaming ? 'Thinking...' : 'Ask anything...',
                  hintStyle: AppTypography.bodyMedium(c.textTertiary),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isStreaming ? null : _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _isStreaming
                    ? AppColors.lightGrey
                    : (c.isDark ? AppColors.white : AppColors.black),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.arrow_upward,
                color: _isStreaming
                    ? (c.isDark ? AppColors.grey : AppColors.silver)
                    : (c.isDark ? AppColors.black : AppColors.white),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String content;
  final bool isUser;
  final bool isStreaming;

  const _ChatMessage({
    required this.content,
    required this.isUser,
    this.isStreaming = false,
  });
}
