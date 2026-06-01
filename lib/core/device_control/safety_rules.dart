import 'action.dart';
import 'execution_mode.dart';

/// Guardrails that determine whether an action can be executed
/// automatically or requires user confirmation.
class SafetyRules {
  SafetyRules._();

  /// Whether an action can be auto-executed in the given mode.
  /// Returns a [SafetyDecision] with the required user interaction.
  static SafetyDecision canExecute({
    required DeviceAction action,
    required ExecutionMode mode,
    double trustScore = 0.5,
    bool isUnusual = false,
  }) {
    switch (action.risk) {
      case ActionRisk.safe:
        return _safeDecision(mode, trustScore, isUnusual);
      case ActionRisk.moderate:
        return _moderateDecision(mode, trustScore, isUnusual);
      case ActionRisk.dangerous:
        return const SafetyDecision(
          allowed: true,
          requiresConfirmation: true,
          requiresCountdown: true,
          countdownSeconds: 5,
          reason: 'Dangerous actions always require explicit confirmation.',
        );
    }
  }

  static SafetyDecision _safeDecision(
    ExecutionMode mode,
    double trustScore,
    bool isUnusual,
  ) {
    switch (mode) {
      case ExecutionMode.ask:
        return const SafetyDecision(
          allowed: true,
          requiresConfirmation: true,
          requiresCountdown: false,
          reason: 'Ask mode: all actions require confirmation.',
        );
      case ExecutionMode.autopilot:
        return const SafetyDecision(
          allowed: true,
          requiresConfirmation: false,
          requiresCountdown: false,
          reason: 'Autopilot: safe actions execute immediately.',
        );
      case ExecutionMode.aiDecides:
        if (isUnusual && trustScore < 0.7) {
          return const SafetyDecision(
            allowed: true,
            requiresConfirmation: true,
            requiresCountdown: false,
            reason: 'Unusual action with low trust — confirming.',
          );
        }
        return const SafetyDecision(
          allowed: true,
          requiresConfirmation: false,
          requiresCountdown: false,
          reason: 'AI Decides: safe action auto-executed.',
        );
    }
  }

  static SafetyDecision _moderateDecision(
    ExecutionMode mode,
    double trustScore,
    bool isUnusual,
  ) {
    switch (mode) {
      case ExecutionMode.ask:
        return const SafetyDecision(
          allowed: true,
          requiresConfirmation: true,
          requiresCountdown: false,
          reason: 'Ask mode: all actions require confirmation.',
        );
      case ExecutionMode.autopilot:
        return const SafetyDecision(
          allowed: true,
          requiresConfirmation: true,
          requiresCountdown: false,
          reason: 'Autopilot: moderate actions require confirmation.',
        );
      case ExecutionMode.aiDecides:
        if (trustScore >= 0.8 && !isUnusual) {
          return const SafetyDecision(
            allowed: true,
            requiresConfirmation: false,
            requiresCountdown: false,
            reason: 'High trust, normal pattern — auto-executing moderate action.',
          );
        }
        return const SafetyDecision(
          allowed: true,
          requiresConfirmation: true,
          requiresCountdown: false,
          reason: 'Moderate action requires confirmation.',
        );
    }
  }

  /// Whether an action is completely blocked regardless of mode.
  static bool isBlocked(DeviceAction action) {
    // Currently no actions are permanently blocked. In the future,
    // this could include a user-configurable blocklist.
    return false;
  }

  /// Generate a warning message for dangerous actions.
  static String dangerWarning(DeviceAction action) {
    return 'This action is irreversible and could result in data loss. '
        'Ambot will wait 5 seconds before executing so you can cancel.';
  }
}

class SafetyDecision {
  final bool allowed;
  final bool requiresConfirmation;
  final bool requiresCountdown;
  final int countdownSeconds;
  final String reason;

  const SafetyDecision({
    required this.allowed,
    required this.requiresConfirmation,
    required this.requiresCountdown,
    this.countdownSeconds = 5,
    required this.reason,
  });
}
