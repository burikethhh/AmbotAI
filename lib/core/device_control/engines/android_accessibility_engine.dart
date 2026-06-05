import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../action.dart';
import '../device_controller.dart';

/// Android implementation of [DeviceController] that communicates with
/// the native Accessibility Service and Screen Capture service via
/// Flutter MethodChannel.
///
/// The native side handles:
///   - Reading the UI element tree (Accessibility Service)
///   - Performing taps, swipes, text input (Accessibility Service)
///   - Capturing screenshots (MediaProjection API)
///   - Launching apps, opening URLs, toggling settings (standard Android APIs)
class AndroidAccessibilityEngine implements DeviceController {
  static const _channel = MethodChannel('ambot_ai/device_control');
  static const _captureChannel = MethodChannel('ambot_ai/screen_capture');

  bool _initialized = false;
  bool? _hasPermission;
  bool _captureReady = false;

  @override
  bool get isReady => _initialized;

  @override
  Future<bool> get hasPermission async {
    if (_hasPermission != null) return _hasPermission!;
    try {
      final result = await _channel.invokeMethod<bool>('checkPermission');
      _hasPermission = result ?? false;
      return _hasPermission!;
    } catch (_) {
      _hasPermission = false;
      return false;
    }
  }

  @override
  Future<void> requestPermission() async {
    await _channel.invokeMethod('requestPermission');
    _hasPermission = null;
  }

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await _channel.invokeMethod('initialize');
      _initialized = true;
    } catch (e) {
      _initialized = false;
    }
  }

  /// Start the MediaProjection screen capture session.
  /// This will prompt the user for permission on Android.
  Future<bool> startScreenCapture() async {
    try {
      await _captureChannel.invokeMethod('startCapture');
      _captureReady = true;
      return true;
    } catch (_) {
      _captureReady = false;
      return false;
    }
  }

  /// Stop the screen capture session.
  Future<void> stopScreenCapture() async {
    try {
      await _captureChannel.invokeMethod('stopCapture');
      _captureReady = false;
    } catch (e) {
      debugPrint('ACCESS_ENGINE: stopScreenCapture failed: $e');
    }
  }

  @override
  Future<DeviceActionResult> execute(DeviceAction action) async {
    try {
      final result = await _channel.invokeMethod<String>(
        action.method,
        action.params,
      );
      return DeviceActionResult(
        success: true,
        action: action,
        output: result,
      );
    } on PlatformException catch (e) {
      return DeviceActionResult(
        success: false,
        action: action,
        error: e.message ?? e.code,
      );
    } catch (e) {
      return DeviceActionResult(
        success: false,
        action: action,
        error: e.toString(),
      );
    }
  }

  @override
  Future<List<DeviceActionResult>> executeBatch(
    List<DeviceAction> actions, {
    bool continueOnError = false,
  }) async {
    final results = <DeviceActionResult>[];
    for (final action in actions) {
      final result = await execute(action);
      results.add(result);
      if (!result.success && !continueOnError) break;
    }
    return results;
  }

  @override
  Future<ScreenContext> captureScreen() async {
    try {
      // Get text + nodes from Accessibility Service
      final data = await _channel.invokeMethod<Map>('readScreen');
      final text = data?['text'] as String? ?? '';
      final nodes = (data?['nodes'] as List?)
          ?.map((n) => _parseNode(n as Map))
          .toList();

      // Try to get screenshot from MediaProjection if available
      List<int>? screenshotBytes;
      if (_captureReady) {
        try {
          final bytes = await _captureChannel.invokeMethod<Uint8List>('captureScreenshot');
          screenshotBytes = bytes?.toList();
        } catch (_) {
          // Screenshot failed but text is still available
        }
      }

      return ScreenContext(
        text: text,
        screenshotBytes: screenshotBytes,
        nodes: nodes,
      );
    } catch (e) {
      return ScreenContext(text: 'Screen capture unavailable: $e');
    }
  }

  @override
  Future<List<InstalledApp>> getInstalledApps() async {
    try {
      final data = await _channel.invokeMethod<List>('getInstalledApps');
      return (data ?? [])
          .map((item) {
            final map = item as Map;
            return InstalledApp(
              packageName: map['packageName'] as String,
              label: map['label'] as String,
              activityName: map['activity'] as String?,
            );
          })
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<DeviceActionResult> scrollDown({double distance = 0.5}) async {
    return execute(DeviceAction(
      id: 'scroll_down',
      label: 'Scroll Down',
      description: '',
      risk: ActionRisk.safe,
      category: ActionCategory.navigation,
      method: 'scrollDown',
      params: {'distance': distance},
      confirmationMessage: 'Scroll down?',
    ));
  }

  @override
  Future<DeviceActionResult> scrollUp({double distance = 0.5}) async {
    return execute(DeviceAction(
      id: 'scroll_up',
      label: 'Scroll Up',
      description: '',
      risk: ActionRisk.safe,
      category: ActionCategory.navigation,
      method: 'scrollUp',
      params: {'distance': distance},
      confirmationMessage: 'Scroll up?',
    ));
  }

  @override
  Future<DeviceActionResult> goBack() async {
    return execute(DeviceAction(
      id: 'go_back',
      label: 'Go Back',
      description: '',
      risk: ActionRisk.safe,
      category: ActionCategory.navigation,
      method: 'goBack',
      params: {},
      confirmationMessage: 'Go back?',
    ));
  }

  @override
  Future<DeviceActionResult> deepLinkApp(String packageName, String uri) async {
    return execute(DeviceAction(
      id: 'deep_link',
      label: 'Deep Link',
      description: '',
      risk: ActionRisk.safe,
      category: ActionCategory.appLaunch,
      method: 'deepLinkApp',
      params: {'packageName': packageName, 'uri': uri},
      confirmationMessage: 'Open deep link?',
    ));
  }

  @override
  Future<DeviceActionResult> clickText(String text) async {
    return execute(DeviceAction(
      id: 'click_screen_text',
      label: 'Click Text',
      description: '',
      risk: ActionRisk.moderate,
      category: ActionCategory.navigation,
      method: 'clickText',
      params: {'text': text},
      confirmationMessage: 'Tap "$text"?',
    ));
  }

  @override
  Future<void> emergencyStop() async {
    await _channel.invokeMethod('emergencyStop');
  }

  @override
  Future<void> dispose() async {
    await _channel.invokeMethod('dispose');
    _initialized = false;
  }

  AccessibilityNode _parseNode(Map<dynamic, dynamic> raw) {
    return AccessibilityNode(
      viewIdResourceName: raw['viewId'] as String?,
      text: raw['text'] as String?,
      contentDescription: raw['contentDesc'] as String?,
      className: raw['className'] as String?,
      isClickable: raw['clickable'] as bool? ?? false,
      isEnabled: raw['enabled'] as bool? ?? true,
      isEditable: raw['editable'] as bool? ?? false,
      children: (raw['children'] as List?)
              ?.map((c) => _parseNode(c as Map))
              .toList() ??
          [],
    );
  }
}
