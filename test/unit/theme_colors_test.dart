import 'package:flutter_test/flutter_test.dart';
import 'package:ambot_ai/shared/theme/app_colors.dart';
import 'package:ambot_ai/shared/theme/theme_colors.dart';

void main() {
  group('ThemeColors', () {
    group('dark mode', () {
      test('isDark returns true', () {
        final colors = ThemeColors.dark();
        expect(colors.isDark, isTrue);
      });

      test('text colors differ from light', () {
        final dark = ThemeColors.dark();
        final light = ThemeColors.light();
        expect(dark.textPrimary, isNot(equals(light.textPrimary)));
        expect(dark.textSecondary, isNot(equals(light.textSecondary)));
        expect(dark.textTertiary, isNot(equals(light.textTertiary)));
      });

      test('accent is white', () {
        final colors = ThemeColors.dark();
        expect(colors.accent, AppColors.white);
      });

      test('all color getters return non-null', () {
        final c = ThemeColors.dark();
        expect(c.textPrimary, isNotNull);
        expect(c.textSecondary, isNotNull);
        expect(c.textTertiary, isNotNull);
        expect(c.borderColor, isNotNull);
        expect(c.cardColor, isNotNull);
        expect(c.cardElevated, isNotNull);
        expect(c.surfaceColor, isNotNull);
        expect(c.accent, isNotNull);
      });
    });

    group('light mode', () {
      test('isDark returns false', () {
        final colors = ThemeColors.light();
        expect(colors.isDark, isFalse);
      });

      test('accent is black', () {
        final colors = ThemeColors.light();
        expect(colors.accent, AppColors.black);
      });

      test('all color getters return non-null', () {
        final c = ThemeColors.light();
        expect(c.textPrimary, isNotNull);
        expect(c.textSecondary, isNotNull);
        expect(c.textTertiary, isNotNull);
        expect(c.borderColor, isNotNull);
        expect(c.cardColor, isNotNull);
        expect(c.cardElevated, isNotNull);
        expect(c.surfaceColor, isNotNull);
        expect(c.accent, isNotNull);
      });
    });

    test('accent colors differ between dark and light modes', () {
      final dark = ThemeColors.dark();
      final light = ThemeColors.light();
      expect(dark.accent, isNot(equals(light.accent)));
    });

    test('dark mode uses dark-specific AppColors values', () {
      final c = ThemeColors.dark();
      expect(c.textPrimary, AppColors.textPrimaryDark);
      expect(c.textSecondary, AppColors.textSecondaryDark);
      expect(c.borderColor, AppColors.borderDark);
      expect(c.cardColor, AppColors.cardDark);
      expect(c.cardElevated, AppColors.cardDarkElevated);
      expect(c.surfaceColor, AppColors.surfaceDark);
    });

    test('light mode uses light-specific AppColors values', () {
      final c = ThemeColors.light();
      expect(c.textPrimary, AppColors.textPrimaryLight);
      expect(c.textSecondary, AppColors.textSecondaryLight);
      expect(c.borderColor, AppColors.borderLight);
      expect(c.cardColor, AppColors.cardLight);
      expect(c.cardElevated, AppColors.cardLightElevated);
      expect(c.surfaceColor, AppColors.surfaceLight);
    });
  });
}
