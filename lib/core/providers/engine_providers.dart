import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ai/ai_engine.dart';
import '../ai/capability_detector.dart';
import '../ai/engine_selector.dart' show EngineSelection, EngineSelector;
import '../ai/engines/mock_engine.dart';
import '../ai/model_manager.dart';
import '../config/api_keys.dart';
import 'api_key_providers.dart';
import 'model_manager_providers.dart';

final deviceCapabilityProvider = FutureProvider<DeviceCapability>((ref) async {
  return DeviceCapabilityDetector.detect();
});

final engineSelectionProvider = FutureProvider<EngineSelection>((ref) async {
  final capability = await ref.watch(deviceCapabilityProvider.future);
  final isReady = ref.watch(modelManagerProvider.select((s) => s.isReady));
  final localPath = ref.watch(modelManagerProvider.select((s) => s.localPath));
  final modelId = ref.watch(modelManagerProvider.select((s) => s.modelId));
  final modelState = ModelState(
    status: isReady ? ModelStatus.ready : ModelStatus.notDownloaded,
    progress: isReady ? 1.0 : 0.0,
    modelId: modelId,
    localPath: localPath,
  );
  final geminiKey = ref.watch(userGeminiKeyProvider);
  final openRouterKey = ref.watch(userOpenRouterKeyProvider);
  final qwenKey = ref.watch(userQwenKeyProvider);
  final nvidiaKey = ref.watch(userNvidiaKeyProvider);
  final preferred = ref.watch(cloudProviderProvider);
  return EngineSelector.select(
    capability: capability,
    modelState: modelState,
    userGeminiKey: geminiKey,
    userOpenRouterKey: openRouterKey,
    userQwenKey: qwenKey,
    userNvidiaKey: nvidiaKey ?? ApiKeys.nvidiaKey1,
    preferredCloudProvider: preferred,
  );
});

final aiEngineProvider = Provider<AIEngine>((ref) {
  final selection = ref.watch(engineSelectionProvider);
  return selection.when(
    data: (s) => s.engine,
    loading: () => _sharedMock,
    error: (_, _) => _sharedMock,
  );
});

final _sharedMock = MockAIEngine()..initialize();
