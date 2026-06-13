import 'package:flutter_test/flutter_test.dart';
import 'package:ambot_ai/core/ai/ai_engine.dart';
import 'package:ambot_ai/core/ai/engine_selector.dart';
import 'package:ambot_ai/core/ai/capability_detector.dart';
import 'package:ambot_ai/core/ai/model_manager.dart';

void main() {
  group('EngineSelector', () {
    group('getHuggingFaceToken', () {
      test('returns user token when provided', () {
        final token = EngineSelector.getHuggingFaceToken(userToken: 'my-token');
        expect(token, 'my-token');
      });

      test('returns null when no token provided and no built-in', () {
        final token = EngineSelector.getHuggingFaceToken();
        expect(token, isNull);
      });
    });

    group('select', () {
      test('selects mock engine when device has Google AI Core', () async {
        final selection = await EngineSelector.select(
          capability: const DeviceCapability(
            ramMB: 8192,
            freeStorageMB: 50000,
            chipset: 'tensor g3',
            deviceModel: 'Pixel 8',
            hasGoogleAICore: true,
            recommendedTier: DeviceTier.flagship,
          ),
          modelState: const ModelState(),
        );
        expect(selection.mode, EngineMode.local);
        expect(selection.reason, contains('Google AI Core'));
      });

      test('selects cloud Gemini when Gemini key is provided and preferred', () async {
        final selection = await EngineSelector.select(
          capability: const DeviceCapability(
            ramMB: 4096,
            freeStorageMB: 10000,
            chipset: 'unknown',
            deviceModel: 'Test Device',
            hasGoogleAICore: false,
            recommendedTier: DeviceTier.mid,
          ),
          modelState: const ModelState(),
          userGeminiKey: 'test-gemini-key',
          preferredCloudProvider: CloudProvider.gemini,
        );
        expect(selection.mode, EngineMode.cloud);
        expect(selection.cloudProvider, CloudProvider.gemini);
      });

      test('selects cloud OpenRouter when OpenRouter key is provided and preferred', () async {
        final selection = await EngineSelector.select(
          capability: const DeviceCapability(
            ramMB: 4096,
            freeStorageMB: 10000,
            chipset: 'unknown',
            deviceModel: 'Test',
            hasGoogleAICore: false,
            recommendedTier: DeviceTier.mid,
          ),
          modelState: const ModelState(),
          userOpenRouterKey: 'test-or-key',
          preferredCloudProvider: CloudProvider.openRouter,
        );
        expect(selection.mode, EngineMode.cloud);
        expect(selection.cloudProvider, CloudProvider.openRouter);
      });

      test('selects cloud Qwen when Qwen key is provided and preferred', () async {
        final selection = await EngineSelector.select(
          capability: const DeviceCapability(
            ramMB: 4096,
            freeStorageMB: 10000,
            chipset: 'unknown',
            deviceModel: 'Test',
            hasGoogleAICore: false,
            recommendedTier: DeviceTier.mid,
          ),
          modelState: const ModelState(),
          userQwenKey: 'test-qwen-key',
          preferredCloudProvider: CloudProvider.qwen,
        );
        expect(selection.mode, EngineMode.cloud);
        expect(selection.cloudProvider, CloudProvider.qwen);
      });

      test('falls back to cloud NVIDIA when user NVIDIA key is provided', () async {
        final selection = await EngineSelector.select(
          capability: const DeviceCapability(
            ramMB: 2048,
            freeStorageMB: 500,
            chipset: 'unknown',
            deviceModel: 'Low-end',
            hasGoogleAICore: false,
            recommendedTier: DeviceTier.lowEnd,
          ),
          modelState: const ModelState(),
          userNvidiaKey: 'test-nvidia-key',
        );
        // User NVIDIA key provided, so cloud is preferred
        expect(selection.mode, EngineMode.cloud);
        expect(selection.cloudProvider, CloudProvider.nvidia);
      });

      test('preferred provider is respected over fallback ordering', () async {
        // User has both Gemini and OpenRouter keys but prefers Gemini
        final selection = await EngineSelector.select(
          capability: const DeviceCapability(
            ramMB: 4096,
            freeStorageMB: 10000,
            chipset: 'unknown',
            deviceModel: 'Test',
            hasGoogleAICore: false,
            recommendedTier: DeviceTier.mid,
          ),
          modelState: const ModelState(),
          userGeminiKey: 'test-gemini-key',
          userOpenRouterKey: 'test-or-key',
          preferredCloudProvider: CloudProvider.gemini,
        );
        expect(selection.mode, EngineMode.cloud);
        expect(selection.cloudProvider, CloudProvider.gemini);
      });

      test('falls back to Gemini when OpenRouter preferred but no OpenRouter key', () async {
        final selection = await EngineSelector.select(
          capability: const DeviceCapability(
            ramMB: 4096,
            freeStorageMB: 10000,
            chipset: 'unknown',
            deviceModel: 'Test',
            hasGoogleAICore: false,
            recommendedTier: DeviceTier.mid,
          ),
          modelState: const ModelState(),
          userGeminiKey: 'test-gemini-key',
          preferredCloudProvider: CloudProvider.openRouter,
        );
        expect(selection.mode, EngineMode.cloud);
        // Falls back to Gemini since no NVIDIA or OpenRouter keys available
        expect(selection.cloudProvider, CloudProvider.gemini);
        expect(selection.reason, contains('fallback'));
      });
    });
  });
}
