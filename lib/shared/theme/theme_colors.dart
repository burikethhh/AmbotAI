import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_colors.dart';
import '../../core/providers/app_providers.dart';

/// Resolved theme colors for the current dark/light mode.
/// Use [themeColorsProvider] in Riverpod widgets or [ThemeColors.of(context)]
/// in plain BuildContext access.
class ThemeColors {
  /// Convenience accessor for non-Riverpod contexts.
  static ThemeColors of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? ThemeColors.dark() : ThemeColors.light();
  }

  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color borderColor;
  final Color cardColor;
  final Color cardElevated;
  final Color surfaceColor;
  final Color accent;

  const ThemeColors({
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.borderColor,
    required this.cardColor,
    required this.cardElevated,
    required this.surfaceColor,
    required this.accent,
  });

  factory ThemeColors.dark() => const ThemeColors(
        isDark: true,
        textPrimary: AppColors.textPrimaryDark,
        textSecondary: AppColors.textSecondaryDark,
        textTertiary: AppColors.textTertiaryDark,
        borderColor: AppColors.borderDark,
        cardColor: AppColors.cardDark,
        cardElevated: AppColors.cardDarkElevated,
        surfaceColor: AppColors.surfaceDark,
        accent: AppColors.white,
      );

  factory ThemeColors.light() => const ThemeColors(
        isDark: false,
        textPrimary: AppColors.textPrimaryLight,
        textSecondary: AppColors.textSecondaryLight,
        textTertiary: AppColors.textTertiaryLight,
        borderColor: AppColors.borderLight,
        cardColor: AppColors.cardLight,
        cardElevated: AppColors.cardLightElevated,
        surfaceColor: AppColors.surfaceLight,
        accent: AppColors.black,
      );
}

/// Single provider that resolves all theme colors for the current mode.
/// Screens should use this instead of manually computing colors.
final themeColorsProvider = Provider<ThemeColors>((ref) {
  final isDark = ref.watch(themeProvider);
  return isDark ? ThemeColors.dark() : ThemeColors.light();
});
