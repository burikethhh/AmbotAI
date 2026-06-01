import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/theme_colors.dart';

class EditorBody extends StatelessWidget {
  final ThemeColors c;
  final TextEditingController contentController;
  final FocusNode focusNode;
  final double fontSize;
  final double lineSpacing;
  final TextAlign textAlign;
  final bool showPreview;

  const EditorBody({
    super.key,
    required this.c,
    required this.contentController,
    required this.focusNode,
    required this.fontSize,
    required this.lineSpacing,
    required this.textAlign,
    required this.showPreview,
  });

  @override
  Widget build(BuildContext context) {
    if (showPreview) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.cardColor,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: AppColors.accent(c.isDark), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.visibility, size: 12, color: AppColors.accent(c.isDark)),
                const SizedBox(width: 6),
                Text('PREVIEW', style: TextStyle(fontSize: 9, color: AppColors.accent(c.isDark), letterSpacing: 1)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: MarkdownBody(
                data: contentController.text.isNotEmpty ? contentController.text : '*No content to preview*',
                styleSheet: MarkdownStyleSheet(
                  h1: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: c.textPrimary),
                  h2: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: c.textPrimary),
                  h3: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.textPrimary),
                  p: TextStyle(fontSize: fontSize, height: lineSpacing, color: c.textPrimary),
                  listBullet: TextStyle(fontSize: fontSize, color: c.textPrimary),
                  strong: TextStyle(fontWeight: FontWeight.bold, color: c.textPrimary),
                  em: TextStyle(fontStyle: FontStyle.italic, color: c.textPrimary),
                  code: TextStyle(backgroundColor: c.cardColor, color: c.textPrimary, fontSize: fontSize - 2),
                  codeblockDecoration: BoxDecoration(
                    color: c.cardColor,
                    border: Border.all(color: c.borderColor, width: 1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  blockquoteDecoration: BoxDecoration(
                    border: Border(left: BorderSide(color: c.textPrimary, width: 3)),
                    color: c.cardColor,
                  ),
                  horizontalRuleDecoration: BoxDecoration(
                    border: Border(top: BorderSide(color: c.borderColor, width: 1)),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.cardColor,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: c.borderColor, width: 2),
      ),
      child: TextField(
        controller: contentController,
        focusNode: focusNode,
        style: TextStyle(
          color: c.textPrimary,
          fontSize: fontSize,
          height: lineSpacing,
        ),
        textAlign: textAlign,
        decoration: InputDecoration(
          hintText: 'Start writing...\n\nUse the toolbar above to format your text.\nSelect text then tap Bold, Italic, etc.\nTap AI FORMAT to auto-organize.',
          hintStyle: TextStyle(color: c.textTertiary, fontSize: fontSize, height: lineSpacing),
          border: InputBorder.none,
          isDense: true,
        ),
        maxLines: null,
        keyboardType: TextInputType.multiline,
      ),
    );
  }
}
