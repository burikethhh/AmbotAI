import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/dracula.dart';

class CodeBlockSegment {
  final String type;
  final String content;
  final String? language;

  const CodeBlockSegment(this.type, this.content, {this.language});
}

List<CodeBlockSegment> parseCodeBlocks(String content) {
  final segments = <CodeBlockSegment>[];
  final regex = RegExp(r'```(\w*)\s*\n([\s\S]*?)```');
  int lastEnd = 0;

  for (final match in regex.allMatches(content)) {
    if (match.start > lastEnd) {
      segments.add(CodeBlockSegment('text', content.substring(lastEnd, match.start)));
    }
    final lang = match.group(1);
    final code = match.group(2);
    segments.add(CodeBlockSegment('code', code ?? '',
        language: (lang == null || lang.isEmpty) ? 'html' : lang));
    lastEnd = match.end;
  }

  if (lastEnd < content.length) {
    segments.add(CodeBlockSegment('text', content.substring(lastEnd)));
  }

  if (segments.isEmpty && content.isNotEmpty) {
    segments.add(CodeBlockSegment('text', content));
  }

  return segments;
}

class CodeBlock extends StatelessWidget {
  final String code;
  final String language;
  final Color borderColor;
  final Color textTertiary;
  final Color accent;

  const CodeBlock({
    super.key,
    required this.code,
    this.language = 'html',
    required this.borderColor,
    required this.textTertiary,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final lines = '\n'.allMatches(code).length + 1;
    const maxVisibleLines = 20;
    final isTruncated = lines > maxVisibleLines;
    final displayContent = isTruncated
        ? code.split('\n').take(maxVisibleLines).join('\n')
        : code;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor, width: 1)),
            ),
            child: Row(
              children: [
                Text(
                  language.toUpperCase(),
                  style: TextStyle(color: textTertiary, fontSize: 10),
                ),
                if (isTruncated) ...[
                  const Spacer(),
                  Text(
                    '+${lines - maxVisibleLines} more lines',
                    style: TextStyle(color: textTertiary, fontSize: 10),
                  ),
                ],
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: HighlightView(
              displayContent,
              language: language,
              theme: draculaTheme,
              padding: const EdgeInsets.all(12),
              textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: borderColor, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _actionBtn('COPY', Icons.content_copy, () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Code copied'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    ),
                  );
                }, accent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, VoidCallback onTap, Color accent) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: accent, width: 1),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: accent),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: accent, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
