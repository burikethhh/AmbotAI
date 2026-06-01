import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextStyle _base({
    double size = 16,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.white,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // Display
  static TextStyle displayLarge(Color color) =>
      _base(size: 32, weight: FontWeight.w700, color: color, letterSpacing: -0.5);
  static TextStyle displayMedium(Color color) =>
      _base(size: 24, weight: FontWeight.w700, color: color, letterSpacing: -0.3);

  // Headings
  static TextStyle headlineLarge(Color color) =>
      _base(size: 22, weight: FontWeight.w700, color: color);
  static TextStyle headlineMedium(Color color) =>
      _base(size: 18, weight: FontWeight.w700, color: color);
  static TextStyle headlineSmall(Color color) =>
      _base(size: 16, weight: FontWeight.w700, color: color);

  // Body
  static TextStyle bodyLarge(Color color) =>
      _base(size: 16, weight: FontWeight.w400, color: color, height: 1.5);
  static TextStyle bodyMedium(Color color) =>
      _base(size: 14, weight: FontWeight.w400, color: color, height: 1.5);
  static TextStyle bodySmall(Color color) =>
      _base(size: 12, weight: FontWeight.w400, color: color, height: 1.4);

  // Labels
  static TextStyle labelLarge(Color color) =>
      _base(size: 14, weight: FontWeight.w600, color: color, letterSpacing: 1.0);
  static TextStyle labelMedium(Color color) =>
      _base(size: 12, weight: FontWeight.w600, color: color, letterSpacing: 1.2);
  static TextStyle labelSmall(Color color) =>
      _base(size: 10, weight: FontWeight.w600, color: color, letterSpacing: 1.5);
  static TextStyle labelMicro(Color color) =>
      _base(size: 8, weight: FontWeight.w600, color: color, letterSpacing: 1.0);

  // Mono (for code / AI output)
  static TextStyle mono(Color color) => GoogleFonts.jetBrainsMono(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.6,
      );
}
