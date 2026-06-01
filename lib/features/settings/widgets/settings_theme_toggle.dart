import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';

class SettingsThemeToggle extends StatelessWidget {
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;
  final Color cardColor;
  final ValueChanged<bool> onChanged;

  const SettingsThemeToggle({
    super.key,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
    required this.cardColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: SwitchListTile(
        title: Text(
          'DARK MODE',
          style: AppTypography.bodyLarge(textPrimary),
        ),
        subtitle: Text(
          isDark ? 'Dark theme active' : 'Light theme active',
          style: AppTypography.bodySmall(textSecondary),
        ),
        value: isDark,
        onChanged: onChanged,
        activeThumbColor: AppColors.white,
        activeTrackColor: AppColors.grey,
        inactiveThumbColor: AppColors.black,
        inactiveTrackColor: AppColors.silver,
      ),
    );
  }
}
