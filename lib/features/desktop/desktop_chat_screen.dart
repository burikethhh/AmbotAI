import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/roles/role.dart';
import '../../shared/theme/theme_colors.dart';
import 'desktop_context_menu.dart';
import 'widgets/desktop_toast.dart';

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
  final FocusNode _inputFocus = FocusNode();
  final List<ChatMessage> _messages = [];
  bool _isGenerating = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.borderColor, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: c.isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              widget.role != null ? Icons.forum_outlined : Icons.chat_outlined,
              size: 18,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName.toUpperCase(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              if (widget.role != null)
                Text(
                  'Role Persona',
                  style: TextStyle(fontSize: 11, color: c.textTertiary),
                ),
            ],
          ),
          const Spacer(),
          _HeaderButton(
            icon: Icons.copy_outlined,
            tooltip: 'Copy conversation',
            onTap: () {
              final text = _messages.map((m) => '${m.isUser ? "You" : "AI"}: ${m.text}').join('\n\n');
              Clipboard.setData(ClipboardData(text: text));
              DesktopToastManager().show('Conversation copied', icon: Icons.check);
            },
          ),
          const SizedBox(width: 4),
          _HeaderButton(
            icon: Icons.delete_outline,
            tooltip: 'Clear chat',
            onTap: () {
              setState(() => _messages.clear());
              DesktopToastManager().show('Chat cleared', icon: Icons.delete_outline);
            },
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
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: c.isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.auto_awesome_outlined,
                size: 32,
                color: c.textTertiary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'START A CONVERSATION',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: c.textSecondary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Type a message below to begin',
              style: TextStyle(fontSize: 13, color: c.textTertiary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        return _buildMessageBubble(c, msg, index);
      },
    );
  }

  Widget _buildMessageBubble(ThemeColors c, ChatMessage msg, int index) {
    return DesktopContextMenu(
      onCopy: () {
        Clipboard.setData(ClipboardData(text: msg.text));
        DesktopToastManager().show('Message copied', icon: Icons.check);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!msg.isUser) _buildAvatar(c),
            if (!msg.isUser) const SizedBox(width: 10),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                decoration: BoxDecoration(
                  color: msg.isUser
                      ? (c.isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0))
                      : (c.isDark ? const Color(0xFF161616) : Colors.white),
                  borderRadius: BorderRadius.circular(msg.isUser ? 12 : 12),
                  border: Border.all(
                    color: msg.isUser
                        ? (c.isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0))
                        : c.borderColor,
                    width: 1,
                  ),
                ),
                child: Text(
                  msg.text,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: msg.isUser ? c.textPrimary : c.textPrimary,
                  ),
                ),
              ),
            ),
            if (msg.isUser) const SizedBox(width: 10),
            if (msg.isUser) _buildUserAvatar(c),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(ThemeColors c) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: c.isDark ? Colors.white : Colors.black,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          'A',
          style: TextStyle(
            color: c.isDark ? Colors.black : Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(ThemeColors c) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: c.isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(Icons.person_outline, size: 16, color: c.textSecondary),
    );
  }

  Widget _buildTypingIndicator(ThemeColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          _buildAvatar(c),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: c.isDark ? const Color(0xFF161616) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: c.borderColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TypingDot(delay: 0, c: c),
                const SizedBox(width: 4),
                _TypingDot(delay: 200, c: c),
                const SizedBox(width: 4),
                _TypingDot(delay: 400, c: c),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(ThemeColors c) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.borderColor, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: DesktopContextMenu(
              child: Container(
                decoration: BoxDecoration(
                  color: c.isDark ? const Color(0xFF111111) : const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: c.borderColor, width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _inputFocus,
                        style: TextStyle(fontSize: 14, color: c.textPrimary, height: 1.5),
                        maxLines: 5,
                        minLines: 1,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          hintText: 'Message Ambot...',
                          hintStyle: TextStyle(color: c.textTertiary, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6, right: 6),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: _isGenerating ? null : _sendMessage,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: _isGenerating || _controller.text.trim().isEmpty
                                  ? c.borderColor
                                  : (c.isDark ? Colors.white : Colors.black),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              _isGenerating ? Icons.hourglass_empty : Icons.arrow_upward,
                              size: 18,
                              color: _isGenerating || _controller.text.trim().isEmpty
                                  ? c.textTertiary
                                  : (c.isDark ? Colors.black : Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 18, color: c.textTertiary),
          ),
        ),
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;
  final ThemeColors c;

  const _TypingDot({required this.delay, required this.c});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.c.textTertiary,
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  const ChatMessage({required this.text, required this.isUser});
}
