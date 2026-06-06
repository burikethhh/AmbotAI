import 'package:flutter/foundation.dart';
import 'ai_engine.dart';
import 'capability_detector.dart';
import 'engines/cloud_engine.dart';
import 'engines/llama_engine.dart';
import 'engines/mock_engine.dart';
import 'engines/openai_engine.dart';
import 'model_manager.dart';
import 'model_registry.dart';
import 'nvidia_key_manager.dart';
import '../config/api_keys.dart';

enum EngineMode { local, cloud, mock }

enum CloudProvider { gemini, openRouter, qwen, nvidia }

class EngineSelection {
  final AIEngine engine;
  final EngineMode mode;
  final CloudProvider? cloudProvider;
  final ModelInfo? model;
  final String reason;

  const EngineSelection({
    required this.engine,
    required this.mode,
    this.cloudProvider,
    this.model,
    required this.reason,
  });
}

class EngineSelector {
  /// Select the best engine for the given device capability and model state.
  ///
  /// Priority: local model > user cloud key > built-in cloud key > mock.
  static Future<EngineSelection> select({
    required DeviceCapability capability,
    required ModelState modelState,
    String? userGeminiKey,
    String? userOpenRouterKey,
    String? userQwenKey,
    String? userNvidiaKey,
    CloudProvider preferredCloudProvider = CloudProvider.nvidia,
  }) async {
    // Resolve effective keys: user-provided keys override built-in ones
    final geminiKey = _pickKey(userGeminiKey, ApiKeys.geminiKey);
    final openRouterKey = _pickKey(userOpenRouterKey, ApiKeys.openRouterKey);
    final qwenKey = _pickKey(userQwenKey, ApiKeys.qwenKey);
    final nvidiaKey = _pickKey(userNvidiaKey, ApiKeys.nvidiaKey1);

    // Web always uses cloud or mock
    if (kIsWeb) {
      final cloudResult = await _tryCloudEngine(
        geminiKey: geminiKey,
        openRouterKey: openRouterKey,
        qwenKey: qwenKey,
        nvidiaKey: nvidiaKey,
        preferred: preferredCloudProvider,
        reason: 'Web platform',
      );
      if (cloudResult != null) return cloudResult;

      final engine = MockAIEngine();
      await engine.initialize();
      return EngineSelection(
        engine: engine,
        mode: EngineMode.mock,
        reason: 'Web platform - no API keys available',
      );
    }

    // 1. Flagship: Google AI Core (Gemini Nano)
    if (capability.hasGoogleAICore) {
      final engine = MockAIEngine();
      await engine.initialize();
      return EngineSelection(
        engine: engine,
        mode: EngineMode.local,
        reason: 'Google AI Core detected - Gemini Nano (scaffolded)',
      );
    }

    // 2. Model is downloaded and ready → always prefer local
    if (modelState.isReady && modelState.localPath != null) {
      final modelInfo = ModelRegistry.getById(modelState.modelId ?? '');
      final engine = _createLocalEngine(
        capability: capability,
        modelPath: modelState.localPath!,
        modelInfo: modelInfo,
      );
      await engine.initialize();
      return EngineSelection(
        engine: engine,
        mode: EngineMode.local,
        model: modelInfo,
        reason: 'Local model ready: ${modelInfo?.name ?? modelState.modelId}',
      );
    }

    // 3. Cloud fallback (user key > built-in key)
    final cloudResult = await _tryCloudEngine(
      geminiKey: geminiKey,
      openRouterKey: openRouterKey,
      qwenKey: qwenKey,
      nvidiaKey: nvidiaKey,
      preferred: preferredCloudProvider,
      reason: 'No local model',
    );
    if (cloudResult != null) return cloudResult;

    // 4. No model, no cloud key → mock
    final engine = MockAIEngine();
    await engine.initialize();
    return EngineSelection(
      engine: engine,
      mode: EngineMode.mock,
      reason: 'No model downloaded and no API keys available',
    );
  }

  /// Try to create a cloud engine from available keys.
  /// Returns null if no keys are available.
  static Future<EngineSelection?> _tryCloudEngine({
    required String? geminiKey,
    required String? openRouterKey,
    required String? qwenKey,
    required String? nvidiaKey,
    required CloudProvider preferred,
    required String reason,
  }) async {
    // Try preferred provider first
    if (preferred == CloudProvider.nvidia && nvidiaKey != null) {
      final keyManager = NvidiaKeyManager();
      keyManager.setUserKeys(nvidiaKey, ApiKeys.nvidiaKey2);
      final engine = OpenAIEngine.nvidia(apiKey: nvidiaKey, keyManager: keyManager);
      await engine.initialize();
      return EngineSelection(
        engine: engine,
        mode: EngineMode.cloud,
        cloudProvider: CloudProvider.nvidia,
        reason: '$reason - NVIDIA',
      );
    }

    if (preferred == CloudProvider.openRouter && openRouterKey != null) {
      final engine = OpenAIEngine.openRouter(apiKey: openRouterKey);
      await engine.initialize();
      return EngineSelection(
        engine: engine,
        mode: EngineMode.cloud,
        cloudProvider: CloudProvider.openRouter,
        reason: '$reason - OpenRouter',
      );
    }

    if (preferred == CloudProvider.gemini && geminiKey != null) {
      final engine = CloudEngine(apiKey: geminiKey);
      await engine.initialize();
      return EngineSelection(
        engine: engine,
        mode: EngineMode.cloud,
        cloudProvider: CloudProvider.gemini,
        reason: '$reason - Gemini',
      );
    }

    if (preferred == CloudProvider.qwen && qwenKey != null) {
      final engine = OpenAIEngine.qwen(apiKey: qwenKey);
      await engine.initialize();
      return EngineSelection(
        engine: engine,
        mode: EngineMode.cloud,
        cloudProvider: CloudProvider.qwen,
        reason: '$reason - Qwen',
      );
    }

    // Fall back to whichever key is available (priority: NVIDIA > OpenRouter > Gemini > Qwen)
    if (nvidiaKey != null) {
      final keyManager = NvidiaKeyManager();
      keyManager.setUserKeys(nvidiaKey, ApiKeys.nvidiaKey2);
      final engine = OpenAIEngine.nvidia(apiKey: nvidiaKey, keyManager: keyManager);
      await engine.initialize();
      return EngineSelection(
        engine: engine,
        mode: EngineMode.cloud,
        cloudProvider: CloudProvider.nvidia,
        reason: '$reason - NVIDIA (fallback)',
      );
    }

    if (openRouterKey != null) {
      final engine = OpenAIEngine.openRouter(apiKey: openRouterKey);
      await engine.initialize();
      return EngineSelection(
        engine: engine,
        mode: EngineMode.cloud,
        cloudProvider: CloudProvider.openRouter,
        reason: '$reason - OpenRouter (fallback)',
      );
    }

    if (geminiKey != null) {
      final engine = CloudEngine(apiKey: geminiKey);
      await engine.initialize();
      return EngineSelection(
        engine: engine,
        mode: EngineMode.cloud,
        cloudProvider: CloudProvider.gemini,
        reason: '$reason - Gemini (fallback)',
      );
    }

    if (qwenKey != null) {
      final engine = OpenAIEngine.qwen(apiKey: qwenKey);
      await engine.initialize();
      return EngineSelection(
        engine: engine,
        mode: EngineMode.cloud,
        cloudProvider: CloudProvider.qwen,
        reason: '$reason - Qwen (fallback)',
      );
    }

    return null;
  }

  /// Pick the first non-empty key: user override > built-in.
  static String? _pickKey(String? userKey, String builtInKey) {
    if (userKey != null && userKey.isNotEmpty) return userKey;
    if (builtInKey.isNotEmpty) return builtInKey;
    return null;
  }

  /// Resolve the Hugging Face token for model downloads.
  static String? getHuggingFaceToken({String? userToken}) {
    return _pickKey(userToken, ApiKeys.huggingFaceToken);
  }

  /// Create the local engine — uses LlamaEngine (llamadart) for all tiers.
  static AIEngine _createLocalEngine({
    required DeviceCapability capability,
    required String modelPath,
    ModelInfo? modelInfo,
  }) {
    return LlamaEngine(
      modelPath: modelPath,
      capability: capability,
      modelInfo: modelInfo,
    );
  }
}
