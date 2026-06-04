import 'dart:ui';

import 'action.dart';

/// Platform-agnostic interface for device control.
///
/// Implementations:
///   - AndroidAccessibilityEngine: uses Accessibility Service + MethodChannel
///
/// All methods return a [DeviceActionResult] with success status and
/// optional output data. Failures include a human-readable error message.
abstract class DeviceController {
  /// Whether the controller is initialized and ready to execute actions.
  bool get isReady;

  /// Initialize the controller (opens native channels, checks permissions).
  Future<void> initialize();

  /// Whether the user has granted the necessary permissions
  /// (Accessibility Service enabled on Android).
  Future<bool> get hasPermission;

  /// Request the user to grant permissions (opens Settings on Android).
  Future<void> requestPermission();

  /// Execute a single action. Returns the result immediately.
  Future<DeviceActionResult> execute(DeviceAction action);

  /// Execute a batch of actions sequentially. Stops on first failure
  /// unless [continueOnError] is true.
  Future<List<DeviceActionResult>> executeBatch(
    List<DeviceAction> actions, {
    bool continueOnError = false,
  });

  /// Capture the current screen as text (via Accessibility or OCR).
  /// Returns the extracted text and optionally the raw image bytes.
  Future<ScreenContext> captureScreen();

  /// Get the list of installed apps the AI can launch.
  Future<List<InstalledApp>> getInstalledApps();

  /// Scroll the current screen down by a fraction (0.0-1.0).
  Future<DeviceActionResult> scrollDown({double distance = 0.5});

  /// Scroll the current screen up by a fraction (0.0-1.0).
  Future<DeviceActionResult> scrollUp({double distance = 0.5});

  /// Simulate the system back button.
  Future<DeviceActionResult> goBack();

  /// Open a deep link URI in a specific app.
  Future<DeviceActionResult> deepLinkApp(String packageName, String uri);

  /// Find and tap text visible on the current screen.
  Future<DeviceActionResult> clickText(String text);

  /// Stop any ongoing automation immediately.
  Future<void> emergencyStop();

  /// Dispose resources.
  Future<void> dispose();
}

class DeviceActionResult {
  final bool success;
  final DeviceAction action;
  final String? output;
  final String? error;
  final DateTime executedAt;

  DeviceActionResult({
    required this.success,
    required this.action,
    this.output,
    this.error,
    DateTime? executedAt,
  }) : executedAt = executedAt ?? DateTime.now();

  @override
  String toString() => success
      ? 'OK: ${action.label}'
      : 'FAIL: ${action.label} — $error';
}

class ScreenContext {
  /// Text extracted from the current screen.
  final String text;

  /// Raw screenshot bytes (null if only text extraction was requested).
  final List<int>? screenshotBytes;

  /// UI element tree from Accessibility Service (Android only).
  /// Contains view IDs, text, bounds, clickable state.
  final List<AccessibilityNode>? nodes;

  /// Timestamp of capture.
  final DateTime capturedAt;

  ScreenContext({
    required this.text,
    this.screenshotBytes,
    this.nodes = const [],
    DateTime? capturedAt,
  }) : capturedAt = capturedAt ?? DateTime.now();
}

class AccessibilityNode {
  final String? viewIdResourceName;
  final String? text;
  final String? contentDescription;
  final String? className;
  final Rect? boundsInScreen;
  final bool isClickable;
  final bool isEnabled;
  final bool isEditable;
  final List<AccessibilityNode> children;

  const AccessibilityNode({
    this.viewIdResourceName,
    this.text,
    this.contentDescription,
    this.className,
    this.boundsInScreen,
    this.isClickable = false,
    this.isEnabled = true,
    this.isEditable = false,
    this.children = const [],
  });
}

class InstalledApp {
  final String packageName;
  final String label;
  final String? activityName;

  const InstalledApp({
    required this.packageName,
    required this.label,
    this.activityName,
  });
}
