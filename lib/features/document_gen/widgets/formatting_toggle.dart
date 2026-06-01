import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/theme/theme_colors.dart';

class FormattingToggle extends StatelessWidget {
  final ThemeColors c;
  final String aiTone;
  final bool isAiProcessing;
  final bool hasDraft;
  final bool showPreview;
  final ValueChanged<String> onAiToneChanged;
  final VoidCallback onAiAssist;
  final VoidCallback onTogglePreview;

  const FormattingToggle({
    super.key,
    required this.c,
    required this.aiTone,
    required this.isAiProcessing,
    required this.hasDraft,
    required this.showPreview,
    required this.onAiToneChanged,
    required this.onAiAssist,
    required this.onTogglePreview,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: c.cardColor,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: c.borderColor, width: 2),
      ),
      child: Row(
        children: [
          Text('AI Tone:', style: AppTypography.bodySmall(c.textTertiary)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              border: Border.all(color: c.borderColor, width: 1),
              borderRadius: BorderRadius.circular(2),
            ),
            child: DropdownButton<String>(
              value: aiTone,
              underline: const SizedBox(),
              isDense: true,
              style: AppTypography.bodySmall(c.textPrimary),
              items: ['professional', 'casual', 'academic'].map((t) =>
                DropdownMenuItem(value: t, child: Text(t[0].toUpperCase() + t.substring(1)))
              ).toList(),
              onChanged: (v) { if (v != null) onAiToneChanged(v); },
            ),
          ),
          const Spacer(),
          if (hasDraft)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text('draft saved', style: AppTypography.labelMicro(AppColors.accent(c.isDark))),
            ),
          _fmtBtn(
            icon: Icons.auto_fix_high,
            onTap: isAiProcessing ? null : () => onAiAssist(),
            tooltip: 'AI Format Assist',
            color: AppColors.accent(c.isDark),
            label: 'AI FORMAT',
          ),
          const SizedBox(width: 4),
          _fmtBtn(
            icon: showPreview ? Icons.edit_note : Icons.visibility_outlined,
            onTap: onTogglePreview,
            tooltip: showPreview ? 'Edit mode' : 'Preview mode',
            color: showPreview ? AppColors.accent(c.isDark) : null,
            label: showPreview ? 'EDIT' : 'PREVIEW',
          ),
        ],
      ),
    );
  }
}
