import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'ai_engine.dart';

class DeviceCapability {
  final int ramMB;
  final int freeStorageMB;
  final String chipset;
  final String deviceModel;
  final bool hasGoogleAICore;
  final DeviceTier recommendedTier;

  const DeviceCapability({
    required this.ramMB,
    required this.freeStorageMB,
    required this.chipset,
    required this.deviceModel,
    required this.hasGoogleAICore,
    required this.recommendedTier,
  });

  String get ramDisplay {
    if (ramMB >= 1024) {
      return '${(ramMB / 1024).toStringAsFixed(1)} GB';
    }
    return '$ramMB MB';
  }

  String get storageDisplay {
    if (freeStorageMB >= 1024) {
      return '${(freeStorageMB / 1024).toStringAsFixed(1)} GB';
    }
    return '$freeStorageMB MB';
  }

  String get tierLabel {
    switch (recommendedTier) {
      case DeviceTier.flagship:
        return 'FLAGSHIP';
      case DeviceTier.mid:
        return 'MID-RANGE';
      case DeviceTier.lowEnd:
        return 'LOW-END';
    }
  }
}

class DeviceCapabilityDetector {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Detect device capabilities. Safe to call on all platforms.
  static Future<DeviceCapability> detect() async {
    if (kIsWeb) {
      return _webCapability();
    }

    if (Platform.isAndroid) {
      return _androidCapability();
    }

    if (Platform.isIOS) {
      return _iosCapability();
    }

    // Desktop / other fallback
    return _desktopCapability();
  }

  static Future<DeviceCapability> _androidCapability() async {
    final info = await _deviceInfo.androidInfo;

    final ramMB = info.systemFeatures.contains('android.hardware.ram.normal')
        ? 4096
        : 6144;

    // Try to get actual total RAM from /proc/meminfo
    int actualRamMB = ramMB;
    try {
      final memInfo = await File('/proc/meminfo').readAsString();
      final match = RegExp(r'MemTotal:\s+(\d+)\s+kB').firstMatch(memInfo);
      if (match != null) {
        actualRamMB = int.parse(match.group(1)!) ~/ 1024;
      }
    } catch (_) {
      // Fall back to estimate
    }

    final chipset = info.hardware;
    final model = '${info.brand} ${info.model}';

    final freeStorageMB = await _getFreeStorage();

    // Check for flagship SoCs that support Google AI Core
    final hasAICore = _checkAndroidAICore(chipset, info.version.sdkInt);

    final tier = _determineTier(
      ramMB: actualRamMB,
      hasAICore: hasAICore,
      chipset: chipset,
    );

    return DeviceCapability(
      ramMB: actualRamMB,
      freeStorageMB: freeStorageMB,
      chipset: chipset,
      deviceModel: model,
      hasGoogleAICore: hasAICore,
      recommendedTier: tier,
    );
  }

  static Future<DeviceCapability> _iosCapability() async {
    final info = await _deviceInfo.iosInfo;
    final model = info.utsname.machine;

    // Estimate RAM from device model
    final ramMB = _estimateIosRam(model);
    final freeStorageMB = await _getFreeStorage();

    final tier = _determineTier(
      ramMB: ramMB,
      hasAICore: false,
      chipset: model,
    );

    return DeviceCapability(
      ramMB: ramMB,
      freeStorageMB: freeStorageMB,
      chipset: model,
      deviceModel: info.name,
      hasGoogleAICore: false,
      recommendedTier: tier,
    );
  }

  static DeviceCapability _webCapability() {
    // Web can't do local LLM, always cloud
    return const DeviceCapability(
      ramMB: 0,
      freeStorageMB: 0,
      chipset: 'Web Browser',
      deviceModel: 'Web',
      hasGoogleAICore: false,
      recommendedTier: DeviceTier.lowEnd,
    );
  }

  static Future<DeviceCapability> _desktopCapability() async {
    final freeStorageMB = await _getFreeStorage();
    // Most desktops have plenty of RAM
    return DeviceCapability(
      ramMB: 8192,
      freeStorageMB: freeStorageMB,
      chipset: Platform.operatingSystem,
      deviceModel: Platform.localHostname,
      hasGoogleAICore: false,
      recommendedTier: DeviceTier.mid,
    );
  }

  static Future<int> _getFreeStorage() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final stat = await FileStat.stat(dir.path);
      // dart:io doesn't directly expose free space, so we use a workaround
      // On Android/iOS, we'll use a platform-aware approach
      if (Platform.isAndroid || Platform.isIOS) {
        return await _getPlatformFreeStorage(dir.path);
      }
      // Desktop fallback: assume generous storage
      return stat.type == FileSystemEntityType.directory ? 50000 : 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<int> _getPlatformFreeStorage(String path) async {
    try {
      if (Platform.isAndroid) {
        // Use StatFs via process
        final result = await Process.run('df', [path]);
        if (result.exitCode == 0) {
          final lines = (result.stdout as String).split('\n');
          if (lines.length >= 2) {
            final parts = lines[1].split(RegExp(r'\s+'));
            if (parts.length >= 4) {
              // Available space in 1K blocks
              final availKB = int.tryParse(parts[3]) ?? 0;
              return availKB ~/ 1024;
            }
          }
        }
      }
      // iOS: use FileManager attribute
      final dir = Directory(path);
      final stat = await dir.stat();
      if (stat.type == FileSystemEntityType.directory) {
        // Rough estimate: check parent volume
        return 10000; // 10GB fallback for iOS
      }
    } catch (_) {
      // Fallback
    }
    return 5000; // 5GB conservative fallback
  }

  /// Check if device likely supports Google AI Core (Gemini Nano).
  /// Requires Android 14+ and specific Tensor/Snapdragon chipsets.
  static bool _checkAndroidAICore(String chipset, int sdkInt) {
    if (sdkInt < 34) return false; // Android 14+

    final lower = chipset.toLowerCase();
    // Google Tensor G3+ (Pixel 8+)
    if (lower.contains('tensor') && !lower.contains('g1') && !lower.contains('g2')) {
      return true;
    }
    // Qualcomm Snapdragon 8 Gen 3+
    if (lower.contains('8gen3') || lower.contains('8 gen 3')) {
      return true;
    }
    // Samsung Exynos 2400+
    if (lower.contains('exynos') && lower.contains('2400')) {
      return true;
    }
    return false;
  }

  static DeviceTier _determineTier({
    required int ramMB,
    required bool hasAICore,
    required String chipset,
  }) {
    if (hasAICore) return DeviceTier.flagship;
    if (ramMB >= 6144) return DeviceTier.mid;
    return DeviceTier.lowEnd;
  }

  /// Exposed for testing.
  @visibleForTesting
  static bool checkAndroidAICore(String chipset, int sdkInt) =>
      _checkAndroidAICore(chipset, sdkInt);

  /// Exposed for testing.
  @visibleForTesting
  static int estimateIosRam(String machine) => _estimateIosRam(machine);

  /// Rough RAM estimates for iOS devices by machine identifier.
  static int _estimateIosRam(String machine) {
    final lower = machine.toLowerCase();
    // iPhone 15 Pro / 16 Pro = 8GB
    if (lower.contains('iphone16') || lower.contains('iphone17')) return 8192;
    // iPhone 14 Pro / 15 = 6GB
    if (lower.contains('iphone15') || lower.contains('iphone14')) return 6144;
    // iPhone 13 and below
    if (lower.contains('iphone13') || lower.contains('iphone12')) return 4096;
    // iPad Pro = 8-16GB
    if (lower.contains('ipad') && lower.contains('pro')) return 8192;
    // Default
    return 4096;
  }
}
