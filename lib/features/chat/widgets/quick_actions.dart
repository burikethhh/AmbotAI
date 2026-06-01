import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';

class QuickActions extends StatelessWidget {
  final bool isDark;
  final ValueChanged<String> onAction;

  const QuickActions({
    super.key,
    required this.isDark,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final chipBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final chipText = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _buildChip('Help me study', Icons.school, chipBg, chipText, borderColor),
        _buildChip('Summarize this', Icons.summarize, chipBg, chipText, borderColor),
        _buildChip('Create a quiz', Icons.quiz, chipBg, chipText, borderColor),
        _buildChip('Explain clearly', Icons.lightbulb, chipBg, chipText, borderColor),
      ],
    );
  }

  Widget _buildChip(String label, IconData icon, Color bg, Color textColor, Color borderColor) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => onAction(label),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 6),
              Text(label, style: AppTypography.labelMedium(textColor)),
            ],
          ),
        ),
      ),
    );
  }
}
