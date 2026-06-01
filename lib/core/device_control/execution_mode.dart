import 'package:flutter/material.dart';

/// How the AI is allowed to execute device actions.
enum ExecutionMode {
  /// Every action requires explicit user confirmation.
  /// Default for all new users. Safest mode.
  ask,

  /// SAFE actions execute immediately. MODERATE actions still require
  /// confirmation. DANGEROUS actions are always blocked with explanation.
  autopilot,

  /// AI decides based on risk level and user trust history. Can escalate
  /// to Ask if confidence is low or the action is unusual for this user.
  /// DANGEROUS actions always require confirmation.
  aiDecides,
}

extension ExecutionModeX on ExecutionMode {
  String get label {
    switch (this) {
      case ExecutionMode.ask:
        return 'Ask Before Execution';
      case ExecutionMode.autopilot:
        return 'Autopilot';
      case ExecutionMode.aiDecides:
        return 'Ambot Decides';
    }
  }

  String get shortLabel {
    switch (this) {
      case ExecutionMode.ask:
        return 'Ask';
      case ExecutionMode.autopilot:
        return 'Auto';
      case ExecutionMode.aiDecides:
        return 'AI';
    }
  }

  String get description {
    switch (this) {
      case ExecutionMode.ask:
        return 'Confirm every action before Ambot executes it.';
      case ExecutionMode.autopilot:
        return 'Safe actions run immediately. Moderate actions ask first.';
      case ExecutionMode.aiDecides:
        return 'Ambot decides based on trust and context. Dangerous actions always ask.';
    }
  }

  IconData get icon {
    switch (this) {
      case ExecutionMode.ask:
        return Icons.gavel_outlined;
      case ExecutionMode.autopilot:
        return Icons.auto_awesome_outlined;
      case ExecutionMode.aiDecides:
        return Icons.psychology_outlined;
    }
  }
}
