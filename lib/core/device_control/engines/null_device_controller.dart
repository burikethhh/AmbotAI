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
    return DeviceActionResult(
      success: false,
      action: DeviceAction(
        id: 'scroll_down',
        type: DeviceActionType.systemControl,
        label: 'Scroll Down',
        riskLevel: RiskLevel.safe,
      ),
      error: 'Not available on desktop',
    );
  }

  @override
  Future<DeviceActionResult> scrollUp({double distance = 0.5}) async {
    return DeviceActionResult(
      success: false,
      action: DeviceAction(
        id: 'scroll_up',
        type: DeviceActionType.systemControl,
        label: 'Scroll Up',
        riskLevel: RiskLevel.safe,
      ),
      error: 'Not available on desktop',
    );
  }

  @override
  Future<DeviceActionResult> goBack() async {
    return DeviceActionResult(
      success: false,
      action: DeviceAction(
        id: 'go_back',
        type: DeviceActionType.systemControl,
        label: 'Go Back',
        riskLevel: RiskLevel.safe,
      ),
      error: 'Not available on desktop',
    );
  }

  @override
  Future<DeviceActionResult> deepLinkApp(String packageName, String uri) async {
    return DeviceActionResult(
      success: false,
      action: DeviceAction(
        id: 'deep_link',
        type: DeviceActionType.navigation,
        label: 'Deep Link',
        riskLevel: RiskLevel.safe,
      ),
      error: 'Not available on desktop',
    );
  }

  @override
  Future<DeviceActionResult> clickText(String text) async {
    return DeviceActionResult(
      success: false,
      action: DeviceAction(
        id: 'click_text',
        type: DeviceActionType.uiInteraction,
        label: 'Click Text',
        riskLevel: RiskLevel.safe,
      ),
      error: 'Not available on desktop',
    );
  }

  @override
  Future<void> emergencyStop() async {}

  @override
  Future<void> dispose() async {}
}
