import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core palette — monochrome
  static const Color black = Color(0xFF0A0A0A);
  static const Color darkGrey = Color(0xFF1A1A1A);
  static const Color midGrey = Color(0xFF2A2A2A);
  static const Color grey = Color(0xFF3A3A3A);
  static const Color lightGrey = Color(0xFF8A8A8A);
  static const Color silver = Color(0xFFB0B0B0);
  static const Color offWhite = Color(0xFFF0F0F0);
  static const Color white = Color(0xFFFFFFFF);

  // Surface colors — dark mode
  static const Color surfaceDark = Color(0xFF111111);
  static const Color cardDark = Color(0xFF1A1A1A);
  static const Color cardDarkElevated = Color(0xFF222222);

  // Surface colors — light mode
  static const Color surfaceLight = Color(0xFFF5F5F5);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardLightElevated = Color(0xFFFFFFFF);

  // Text colors
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFF8A8A8A);
  static const Color textTertiaryDark = Color(0xFF5A5A5A);

  static const Color textPrimaryLight = Color(0xFF0A0A0A);
  static const Color textSecondaryLight = Color(0xFF6A6A6A);
  static const Color textTertiaryLight = Color(0xFF9A9A9A);

  // Borders
  static const Color borderDark = Color(0xFF2A2A2A);
  static const Color borderLight = Color(0xFFE0E0E0);

  // Subtle accent for interactive elements
  static const Color accentSubtle = Color(0xFF4A4A4A);

  // Danger — muted red for destructive actions only
  static const Color danger = Color(0xFF8A0000);

  // Semantic status colors (used extensively throughout the app)
  static const Color error = Color(0xFFFF4444);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color warningOrange = Color(0xFFFF9800);

  /// Pure white in dark mode, pure black in light mode — sole accent.
  static Color accent(bool isDark) => isDark ? white : black;
}
