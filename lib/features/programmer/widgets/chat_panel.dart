import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/dracula.dart';

import '../../../shared/theme/app_typography.dart';
import '../../../shared/theme/theme_colors.dart';
import '../programmer_types.dart';

class ChatPanel extends StatelessWidget {
  final List<ChatMessage> messages;
  final bool isAiResponding;
  final bool? isEngineReady;
  final TextEditingController textController;
  final ScrollController scrollController;
  final ValueChanged<String> onSend;
  final ValueChanged<String> onInsertCode;
  final ThemeColors themeColors;

  const ChatPanel({
    super.key,
    required this.messages,
    required this.isAiResponding,
    this.isEngineReady,
    required this.textController,
    required this.scrollController,
    required this.onSend,
    required this.onInsertCode,
    required this.themeColors,
  });

  @override
  Widget build(BuildContext context) {
    final c = themeColors;

    if (isEngineReady == false) {
      return Column(
        children: [
          Expanded(child: _buildEngineWarning(c)),
          _buildInputBar(c),
        ],
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? _buildEmptyState(c)
              : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (ctx, i) =>
                      _buildMessage(messages[i], c, screenWidth, ctx),
                ),
        ),
        _buildInputBar(c),
      ],
    );
  }

  Widget _buildEngineWarning(ThemeColors c) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: c.borderColor, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 32, color: c.textTertiary),
            const SizedBox(height: 12),
            Text(
              'NO AI ENGINE AVAILABLE',
              style: AppTypography.bodyMedium(c.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Configure a local model or enter a cloud API key in Settings.',
              style: AppTypography.bodySmall(c.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeColors c) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.code_outlined, size: 40, color: c.textTertiary),
          const SizedBox(height: 12),
          Text(
            'ASK THE AI TO TEACH YOU',
            style: AppTypography.bodyMedium(c.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(
      ChatMessage msg, ThemeColors c, double screenWidth, BuildContext ctx) {
    final isUser = msg.role == 'user';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            isUser ? 'YOU' : 'AI TUTOR',
            style: AppTypography.labelSmall(c.textTertiary),
          ),
          const SizedBox(height: 4),
          if (isUser)
            _buildUserBubble(msg.content, c, screenWidth)
          else
            _buildAiContent(msg.content, msg.isStreaming, c, screenWidth, ctx),
        ],
      ),
    );
  }

  Widget _buildUserBubble(String content, ThemeColors c, double screenWidth) {
    return Container(
      constraints: BoxConstraints(maxWidth: (screenWidth * 0.85).clamp(200, 600)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.cardColor,
        border: Border.all(color: c.borderColor, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(content, style: AppTypography.bodyMedium(c.textPrimary)),
    );
  }

  Widget _buildAiContent(
      String content, bool isStreaming, ThemeColors c, double screenWidth, BuildContext ctx) {
    if (content.isEmpty && isStreaming) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: c.borderColor, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: c.textTertiary,
              ),
            ),
            const SizedBox(width: 8),
            Text('Thinking...',
                style: TextStyle(color: c.textTertiary, fontSize: 12)),
          ],
        ),
      );
    }

    if (content.isEmpty) {
      return const SizedBox.shrink();
    }

    final segments = _parseSegments(content);
    return Container(
      constraints: BoxConstraints(maxWidth: (screenWidth * 0.92).clamp(200, 700)),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(color: c.borderColor, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: segments.map((seg) => _buildSegment(seg, c, ctx)).toList(),
      ),
    );
  }

  Widget _buildSegment(_Segment seg, ThemeColors c, BuildContext ctx) {
    if (seg.type == 'code') {
      final lines = '\n'.allMatches(seg.content).length + 1;
      final maxVisibleLines = 20;
      final isTruncated = lines > maxVisibleLines;
      final displayContent = isTruncated
          ? seg.content.split('\n').take(maxVisibleLines).join('\n')
          : seg.content;

      return Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: c.borderColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.borderColor, width: 1)),
              ),
              child: Row(
                children: [
                  Text(
                    (seg.language ?? 'html').toUpperCase(),
                    style: AppTypography.labelSmall(c.textTertiary),
                  ),
                  if (isTruncated) ...[
                    const Spacer(),
                    Text(
                      '+${lines - maxVisibleLines} more lines',
                      style: AppTypography.labelSmall(c.textTertiary),
                    ),
                  ],
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: HighlightView(
                displayContent,
                language: seg.language ?? 'html',
                theme: draculaTheme,
                padding: const EdgeInsets.all(12),
                textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.borderColor, width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _codeActionBtn('INSERT', Icons.edit_outlined,
                      () => onInsertCode(seg.content), c),
                  const SizedBox(width: 8),
                  _codeActionBtn('COPY', Icons.content_copy,
                      () => _copyCode(seg.content, ctx), c),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        seg.content,
        style: AppTypography.bodyMedium(c.textPrimary),
      ),
    );
  }

  void _copyCode(String code, BuildContext context) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Code copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  Widget _codeActionBtn(
      String label, IconData icon, VoidCallback onTap, ThemeColors c) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: c.accent, width: 1),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: c.accent),
            const SizedBox(width: 4),
            Text(label, style: AppTypography.labelSmall(c.accent)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(ThemeColors c) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.borderColor, width: 2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: textController,
              style: AppTypography.bodyMedium(c.textPrimary),
              decoration: InputDecoration(
                hintText: 'Ask AI to teach or generate code...',
                hintStyle: AppTypography.bodyMedium(c.textTertiary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: c.borderColor, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: c.borderColor, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: c.accent, width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: c.cardColor,
              ),
              maxLines: 3,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (v) {
                if (v.trim().isNotEmpty) onSend(v);
              },
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              final text = textController.text;
              if (text.trim().isNotEmpty) onSend(text);
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: c.accent,
                borderRadius: BorderRadius.circular(21),
              ),
              child: Icon(Icons.send, color: c.surfaceColor, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  List<_Segment> _parseSegments(String content) {
    final segments = <_Segment>[];
    final regex = RegExp(r'```(\w*)\s*\n([\s\S]*?)```');
    int lastEnd = 0;

    for (final match in regex.allMatches(content)) {
      if (match.start > lastEnd) {
        segments.add(_Segment('text', content.substring(lastEnd, match.start)));
      }
      final lang = match.group(1);
      final code = match.group(2);
      segments.add(_Segment('code', code ?? '',
          language: (lang == null || lang.isEmpty) ? 'html' : lang));
      lastEnd = match.end;
    }

    if (lastEnd < content.length) {
      segments.add(_Segment('text', content.substring(lastEnd)));
    }

    if (segments.isEmpty && content.isNotEmpty) {
      segments.add(_Segment('text', content));
    }

    return segments;
  }
}

class _Segment {
  final String type;
  final String content;
  final String? language;

  const _Segment(this.type, this.content, {this.language});
}
