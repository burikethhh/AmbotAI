import 'package:package_info_plus/package_info_plus.dart';

class AppVersion {
  static String _version = '1.6.6';
  static String _buildNumber = '21';
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      final info = await PackageInfo.fromPlatform();
      _version = info.version;
      _buildNumber = info.buildNumber;
      _initialized = true;
    } catch (_) {
      _initialized = true;
    }
  }

  static String get version => _version;
  static String get buildNumber => _buildNumber;
  static String get displayVersion => 'v$_version';
  static String get fullVersion => 'v$_version (build $_buildNumber)';
}
