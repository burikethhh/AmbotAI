import 'package:flutter/services.dart';

class HapticFeedbackService {
  HapticFeedbackService._();

  static void light() => HapticFeedback.lightImpact();
  static void medium() => HapticFeedback.mediumImpact();
  static void heavy() => HapticFeedback.heavyImpact();
  static void success() => HapticFeedback.vibrate();
  static void error() => HapticFeedback.vibrate();
  static void selection() => HapticFeedback.selectionClick();
  static void tap() => HapticFeedback.lightImpact();
}
