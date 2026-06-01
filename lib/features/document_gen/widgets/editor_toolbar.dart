import 'package:flutter/material.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/theme/theme_colors.dart';

const _lineSpacings = [1.0, 1.15, 1.5, 2.0, 2.5, 3.0];
const _fontSizes = [10.0, 12.0, 14.0, 16.0, 18.0, 20.0, 24.0];

class EditorToolbar extends StatelessWidget {
  final ThemeColors c;
  final double lineSpacing;
  final double fontSize;
  final TextAlign textAlign;
  final ValueChanged<double> onLineSpacingChanged;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<TextAlign> onTextAlignChanged;
  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onUnderline;
  final VoidCallback onHeading1;
  final VoidCallback onHeading2;
  final VoidCallback onHeading3;
  final VoidCallback onBullet;
  final VoidCallback onNumbered;

  const EditorToolbar({
    super.key,
    required this.c,
    required this.lineSpacing,
    required this.fontSize,
    required this.textAlign,
    required this.onLineSpacingChanged,
    required this.onFontSizeChanged,
    required this.onTextAlignChanged,
    required this.onBold,
    required this.onItalic,
    required this.onUnderline,
    required this.onHeading1,
    required this.onHeading2,
    required this.onHeading3,
    required this.onBullet,
    required this.onNumbered,
  });

  Widget _fmtBtn({required IconData icon, required VoidCallback? onTap, String? tooltip, Color? color, String? label}) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: onTap != null ? c.borderColor : c.borderColor.withValues(alpha: 0.3), width: 1),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color ?? (onTap != null ? c.textPrimary : c.textTertiary)),
              if (label != null) ...[
                const SizedBox(width: 4),
                Text(label, style: TextStyle(fontSize: 10, color: color ?? (onTap != null ? c.textPrimary : c.textTertiary))),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _alignBtn(TextAlign align, IconData icon) {
    final selected = textAlign == align;
    return GestureDetector(
      onTap: () => onTextAlignChanged(align),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? c.textPrimary : c.borderColor, width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Icon(icon, size: 14, color: selected ? c.textPrimary : c.textTertiary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: c.cardColor,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: c.borderColor, width: 2),
          ),
          child: Row(
            children: [
              Text('Spacing', style: AppTypography.bodySmall(c.textTertiary)),
              const SizedBox(width: 6),
              SizedBox(
                width: 72,
                child: DropdownButton<double>(
                  value: lineSpacing,
                  underline: const SizedBox(),
                  isDense: true,
                  style: AppTypography.bodySmall(c.textPrimary),
                  items: _lineSpacings.map((s) => DropdownMenuItem(value: s, child: Text('${s.toStringAsFixed(1)}x'))).toList(),
                  onChanged: (v) { if (v != null) onLineSpacingChanged(v); },
                ),
              ),
              const SizedBox(width: 12),
              Container(width: 1, height: 20, color: c.borderColor),
              const SizedBox(width: 12),
              _alignBtn(TextAlign.left, Icons.format_align_left),
              const SizedBox(width: 4),
              _alignBtn(TextAlign.center, Icons.format_align_center),
              const SizedBox(width: 4),
              _alignBtn(TextAlign.right, Icons.format_align_right),
              const SizedBox(width: 4),
              _alignBtn(TextAlign.justify, Icons.format_align_justify),
              const Spacer(),
              Text('Size', style: AppTypography.bodySmall(c.textTertiary)),
              const SizedBox(width: 4),
              SizedBox(
                width: 60,
                child: DropdownButton<double>(
                  value: fontSize,
                  underline: const SizedBox(),
                  isDense: true,
                  style: AppTypography.bodySmall(c.textPrimary),
                  items: _fontSizes.map((s) => DropdownMenuItem(value: s, child: Text('${s.toInt()}'))).toList(),
                  onChanged: (v) { if (v != null) onFontSizeChanged(v); },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: c.cardColor,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: c.borderColor, width: 2),
          ),
          child: Row(
            children: [
              _fmtBtn(icon: Icons.format_bold, onTap: onBold, tooltip: 'Bold (**)'),
              const SizedBox(width: 4),
              _fmtBtn(icon: Icons.format_italic, onTap: onItalic, tooltip: 'Italic (*)'),
              const SizedBox(width: 4),
              _fmtBtn(icon: Icons.format_underline, onTap: onUnderline, tooltip: 'Underline (<u>)'),
              const SizedBox(width: 8),
              Container(width: 1, height: 20, color: c.borderColor),
              const SizedBox(width: 8),
              _fmtBtn(icon: Icons.title, onTap: onHeading1, tooltip: 'Heading 1 (#)'),
              const SizedBox(width: 4),
              _fmtBtn(icon: Icons.title, onTap: onHeading2, tooltip: 'Heading 2 (##)'),
              const SizedBox(width: 4),
              _fmtBtn(icon: Icons.subscript, onTap: onHeading3, tooltip: 'Heading 3 (###)'),
              const SizedBox(width: 8),
              Container(width: 1, height: 20, color: c.borderColor),
              const SizedBox(width: 8),
              _fmtBtn(icon: Icons.format_list_bulleted, onTap: onBullet, tooltip: 'Bullet List (-)'),
              const SizedBox(width: 4),
              _fmtBtn(icon: Icons.format_list_numbered, onTap: onNumbered, tooltip: 'Numbered List (1.)'),
              const Spacer(),
            ],
          ),
        ),
      ],
    );
  }
}
