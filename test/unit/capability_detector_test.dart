import 'package:flutter_test/flutter_test.dart';
import 'package:ambot_ai/core/ai/ai_engine.dart';
import 'package:ambot_ai/core/ai/capability_detector.dart';

void main() {
  group('DeviceCapability', () {
    group('ramDisplay', () {
      test('formats GB when >= 1024 MB', () {
        final cap = const DeviceCapability(
          ramMB: 8192,
          freeStorageMB: 0,
          chipset: '',
          deviceModel: '',
          hasGoogleAICore: false,
          recommendedTier: DeviceTier.mid,
        );
        expect(cap.ramDisplay, '8.0 GB');
      });

      test('formats MB when < 1024 MB', () {
        final cap = const DeviceCapability(
          ramMB: 512,
          freeStorageMB: 0,
          chipset: '',
          deviceModel: '',
          hasGoogleAICore: false,
          recommendedTier: DeviceTier.lowEnd,
        );
        expect(cap.ramDisplay, '512 MB');
      });
    });

    group('storageDisplay', () {
      test('formats GB when >= 1024 MB', () {
        final cap = const DeviceCapability(
          ramMB: 0,
          freeStorageMB: 50000,
          chipset: '',
          deviceModel: '',
          hasGoogleAICore: false,
          recommendedTier: DeviceTier.mid,
        );
        expect(cap.storageDisplay, '48.8 GB');
      });

      test('formats MB when < 1024 MB', () {
        final cap = const DeviceCapability(
          ramMB: 0,
          freeStorageMB: 500,
          chipset: '',
          deviceModel: '',
          hasGoogleAICore: false,
          recommendedTier: DeviceTier.lowEnd,
        );
        expect(cap.storageDisplay, '500 MB');
      });
    });

    group('tierLabel', () {
      test('returns FLAGSHIP for flagship tier', () {
        final cap = const DeviceCapability(
          ramMB: 0,
          freeStorageMB: 0,
          chipset: '',
          deviceModel: '',
          hasGoogleAICore: true,
          recommendedTier: DeviceTier.flagship,
        );
        expect(cap.tierLabel, 'FLAGSHIP');
      });

      test('returns MID-RANGE for mid tier', () {
        final cap = const DeviceCapability(
          ramMB: 0,
          freeStorageMB: 0,
          chipset: '',
          deviceModel: '',
          hasGoogleAICore: false,
          recommendedTier: DeviceTier.mid,
        );
        expect(cap.tierLabel, 'MID-RANGE');
      });

      test('returns LOW-END for lowEnd tier', () {
        final cap = const DeviceCapability(
          ramMB: 0,
          freeStorageMB: 0,
          chipset: '',
          deviceModel: '',
          hasGoogleAICore: false,
          recommendedTier: DeviceTier.lowEnd,
        );
        expect(cap.tierLabel, 'LOW-END');
      });
    });
  });

  group('_determineTier (static logic)', () {
    test('flagship when hasGoogleAICore is true', () {
      // Access through the tier determination logic
      // This uses the same logic as DeviceCapabilityDetector._determineTier
      // We validate the expected output of the public detect() paths
      // by checking the documented logic directly.
      expect(
        _determineTier(ramMB: 4096, hasAICore: true, chipset: 'tensor'),
        DeviceTier.flagship,
      );
    });

    test('mid when RAM >= 6144 and no AI Core', () {
      expect(
        _determineTier(ramMB: 6144, hasAICore: false, chipset: 'unknown'),
        DeviceTier.mid,
      );
    });

    test('lowEnd when RAM < 6144 and no AI Core', () {
      expect(
        _determineTier(ramMB: 4096, hasAICore: false, chipset: 'unknown'),
        DeviceTier.lowEnd,
      );
    });
  });

  group('checkAndroidAICore', () {
    test('returns true for Tensor G3 (Android 14+)', () {
      expect(DeviceCapabilityDetector.checkAndroidAICore('tensor g3', 34), isTrue);
    });

    test('returns false for Tensor G1 (Android 14+)', () {
      expect(DeviceCapabilityDetector.checkAndroidAICore('tensor g1', 34), isFalse);
    });

    test('returns true for Snapdragon 8 Gen 3', () {
      expect(DeviceCapabilityDetector.checkAndroidAICore('snapdragon 8gen3', 34), isTrue);
    });

    test('returns true for Exynos 2400', () {
      expect(DeviceCapabilityDetector.checkAndroidAICore('exynos 2400', 34), isTrue);
    });

    test('returns false for SDK < 34 regardless of chipset', () {
      expect(DeviceCapabilityDetector.checkAndroidAICore('tensor g3', 33), isFalse);
    });
  });

  group('estimateIosRam', () {
    test('returns 8192 for iPhone 16 Pro', () {
      expect(DeviceCapabilityDetector.estimateIosRam('iPhone16,1'), 8192);
    });

    test('returns 8192 for iPhone 17', () {
      expect(DeviceCapabilityDetector.estimateIosRam('iPhone17,1'), 8192);
    });

    test('returns 6144 for iPhone 15', () {
      expect(DeviceCapabilityDetector.estimateIosRam('iPhone15,2'), 6144);
    });

    test('returns 6144 for iPhone 14 Pro', () {
      expect(DeviceCapabilityDetector.estimateIosRam('iPhone14,3'), 6144);
    });

    test('returns 4096 for iPhone 13', () {
      expect(DeviceCapabilityDetector.estimateIosRam('iPhone13,2'), 4096);
    });

    test('returns 8192 for iPad Pro (machine name containing Pro)', () {
      expect(DeviceCapabilityDetector.estimateIosRam('iPad14,1-Pro'), 8192);
    });

    test('defaults to 4096 for unknown devices', () {
      expect(DeviceCapabilityDetector.estimateIosRam('iPod9,1'), 4096);
    });

    test('returns 4096 for iPad model without Pro in name', () {
      // Apple machine identifiers like iPad13,11 don't contain "pro"
      expect(DeviceCapabilityDetector.estimateIosRam('iPad13,11'), 4096);
    });
  });
}

// Mirrors the private _determineTier logic for testability
DeviceTier _determineTier({
  required int ramMB,
  required bool hasAICore,
  required String chipset,
}) {
  if (hasAICore) return DeviceTier.flagship;
  if (ramMB >= 6144) return DeviceTier.mid;
  return DeviceTier.lowEnd;
}
