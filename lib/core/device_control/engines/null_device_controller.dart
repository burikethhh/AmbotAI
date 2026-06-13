import '../device_controller.dart';
import '../action.dart';

class NullDeviceController implements DeviceController {
  @override
  bool get isReady => false;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> get hasPermission async => false;

  @override
  Future<void> requestPermission() async {}

  DeviceAction _stub(String id, String label) {
    return DeviceAction(
      id: id,
      label: label,
      description: 'Not available on desktop',
      risk: ActionRisk.safe,
      category: ActionCategory.systemSettings,
      method: 'none',
      confirmationMessage: 'Not available on desktop',
    );
  }

  @override
  Future<DeviceActionResult> execute(DeviceAction action) async {
    return DeviceActionResult(
      success: false,
      action: action,
      error: 'Device control not available on desktop',
    );
  }

  @override
  Future<List<DeviceActionResult>> executeBatch(
    List<DeviceAction> actions, {
    bool continueOnError = false,
  }) async {
    return actions
        .map((a) => DeviceActionResult(
              success: false,
              action: a,
              error: 'Device control not available on desktop',
            ))
        .toList();
  }

  @override
  Future<ScreenContext> captureScreen() async {
    return ScreenContext(text: 'Screen capture not available on desktop');
  }

  @override
  Future<List<InstalledApp>> getInstalledApps() async => [];

  @override
  Future<DeviceActionResult> scrollDown({double distance = 0.5}) async {
    return DeviceActionResult(success: false, action: _stub('scroll_down', 'Scroll Down'), error: 'Not available on desktop');
  }

  @override
  Future<DeviceActionResult> scrollUp({double distance = 0.5}) async {
    return DeviceActionResult(success: false, action: _stub('scroll_up', 'Scroll Up'), error: 'Not available on desktop');
  }

  @override
  Future<DeviceActionResult> goBack() async {
    return DeviceActionResult(success: false, action: _stub('go_back', 'Go Back'), error: 'Not available on desktop');
  }

  @override
  Future<DeviceActionResult> deepLinkApp(String packageName, String uri) async {
    return DeviceActionResult(success: false, action: _stub('deep_link', 'Deep Link'), error: 'Not available on desktop');
  }

  @override
  Future<DeviceActionResult> clickText(String text) async {
    return DeviceActionResult(success: false, action: _stub('click_text', 'Click Text'), error: 'Not available on desktop');
  }

  @override
  Future<void> emergencyStop() async {}

  @override
  Future<void> dispose() async {}
}
