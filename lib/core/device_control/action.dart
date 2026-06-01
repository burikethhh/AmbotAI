import 'package:flutter/material.dart';

/// Risk level of a device action. Determines which execution modes can
/// run it without explicit user confirmation.
enum ActionRisk {
  /// Safe to execute automatically. Examples: launch app, open URL,
  /// toggle WiFi, read screen, adjust volume.
  safe,

  /// Requires user confirmation in Ask mode. In Autopilot, still asks.
  /// In AI Decides, may auto-execute if trust is high.
  /// Examples: send message, send email, change DND, create note.
  moderate,

  /// Always requires explicit confirmation with countdown. Never
  /// auto-executed in any mode.
  /// Examples: delete, payment, factory reset, password change.
  dangerous,
}

/// Category of action for trust scoring and filtering.
enum ActionCategory {
  appLaunch,
  navigation,
  communication,
  systemSettings,
  media,
  calendar,
  clipboard,
  fileOperation,
  payment,
  account,
  screenCapture,
  custom,
}

/// A single action the AI can request the device to perform.
class DeviceAction {
  final String id;
  final String label;
  final String description;
  final ActionRisk risk;
  final ActionCategory category;

  /// The method name called on the native side via MethodChannel.
  final String method;

  /// Parameters passed to the native method. Must be JSON-serializable.
  final Map<String, dynamic> params;

  /// Human-readable summary shown in the confirmation dialog.
  final String confirmationMessage;

  /// Estimated time to execute (for UI feedback).
  final Duration estimatedDuration;

  /// Whether this action can be undone.
  final bool canUndo;

  const DeviceAction({
    required this.id,
    required this.label,
    required this.description,
    required this.risk,
    required this.category,
    required this.method,
    this.params = const {},
    required this.confirmationMessage,
    this.estimatedDuration = const Duration(seconds: 1),
    this.canUndo = false,
  });

  DeviceAction copyWith({
    String? id,
    String? label,
    String? description,
    ActionRisk? risk,
    ActionCategory? category,
    String? method,
    Map<String, dynamic>? params,
    String? confirmationMessage,
    Duration? estimatedDuration,
    bool? canUndo,
  }) {
    return DeviceAction(
      id: id ?? this.id,
      label: label ?? this.label,
      description: description ?? this.description,
      risk: risk ?? this.risk,
      category: category ?? this.category,
      method: method ?? this.method,
      params: params ?? this.params,
      confirmationMessage: confirmationMessage ?? this.confirmationMessage,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      canUndo: canUndo ?? this.canUndo,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'description': description,
        'risk': risk.name,
        'category': category.name,
        'method': method,
        'params': params,
        'confirmationMessage': confirmationMessage,
        'estimatedDurationMs': estimatedDuration.inMilliseconds,
        'canUndo': canUndo,
      };

  factory DeviceAction.fromJson(Map<String, dynamic> json) => DeviceAction(
        id: json['id'] as String,
        label: json['label'] as String,
        description: json['description'] as String,
        risk: ActionRisk.values.byName(json['risk'] as String),
        category: ActionCategory.values.byName(json['category'] as String),
        method: json['method'] as String,
        params: (json['params'] as Map?)?.cast<String, dynamic>() ?? {},
        confirmationMessage: json['confirmationMessage'] as String,
        estimatedDuration: Duration(
          milliseconds: json['estimatedDurationMs'] as int? ?? 1000,
        ),
        canUndo: json['canUndo'] as bool? ?? false,
      );
}

extension ActionRiskX on ActionRisk {
  String get label {
    switch (this) {
      case ActionRisk.safe:
        return 'Safe';
      case ActionRisk.moderate:
        return 'Moderate';
      case ActionRisk.dangerous:
        return 'Dangerous';
    }
  }

  Color get color {
    switch (this) {
      case ActionRisk.safe:
        return const Color(0xFF4CAF50);
      case ActionRisk.moderate:
        return const Color(0xFFFF9800);
      case ActionRisk.dangerous:
        return const Color(0xFFF44336);
    }
  }

  IconData get icon {
    switch (this) {
      case ActionRisk.safe:
        return Icons.shield_outlined;
      case ActionRisk.moderate:
        return Icons.warning_amber_outlined;
      case ActionRisk.dangerous:
        return Icons.dangerous_outlined;
    }
  }
}

extension ActionCategoryX on ActionCategory {
  String get label {
    switch (this) {
      case ActionCategory.appLaunch:
        return 'App Launch';
      case ActionCategory.navigation:
        return 'Navigation';
      case ActionCategory.communication:
        return 'Communication';
      case ActionCategory.systemSettings:
        return 'System Settings';
      case ActionCategory.media:
        return 'Media';
      case ActionCategory.calendar:
        return 'Calendar';
      case ActionCategory.clipboard:
        return 'Clipboard';
      case ActionCategory.fileOperation:
        return 'File Operation';
      case ActionCategory.payment:
        return 'Payment';
      case ActionCategory.account:
        return 'Account';
      case ActionCategory.screenCapture:
        return 'Screen Capture';
      case ActionCategory.custom:
        return 'Custom';
    }
  }
}
