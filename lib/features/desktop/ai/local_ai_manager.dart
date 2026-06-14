import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../core/ai/engines/llama_engine.dart';
import '../../../core/ai/ai_engine.dart';
import '../../../core/ai/capability_detector.dart';
import 'model_download_manager.dart';
import 'model_recommendation_engine.dart';
import 'performance_monitor.dart';

enum ModelState { idle, loading, ready, error, switching }

class LocalAIManager extends ChangeNotifier {
  final ModelDownloadManager downloadManager;
  final ModelRecommendationEngine recommendationEngine;
  final PerformanceMonitor performanceMonitor;

  LlamaEngine? _engine;
  LocalModelInfo? _currentModel;
  ModelState _state = ModelState.idle;
  String? _error;

  LlamaEngine? get engine => _engine;
  LocalModelInfo? get currentModel => _currentModel;
  ModelState get state => _state;
  String? get error => _error;
  bool get isReady => _state == ModelState.ready;

  final _stateController = StreamController<ModelState>.broadcast();
  Stream<ModelState> get stateStream => _stateController.stream;

  LocalAIManager({
    ModelDownloadManager? downloadManager,
    ModelRecommendationEngine? recommendationEngine,
    PerformanceMonitor? performanceMonitor,
  })  : downloadManager = downloadManager ?? ModelDownloadManager(),
        performanceMonitor = performanceMonitor ?? PerformanceMonitor(),
        recommendationEngine = recommendationEngine ??
            ModelRecommendationEngine(downloadManager ??= ModelDownloadManager());

  Future<void> initialize() async {
    try {
      _setState(ModelState.loading);

      final downloaded = await downloadManager.getDownloadedModels();
      if (downloaded.isNotEmpty) {
        await loadModel(downloaded.first);
      } else {
        _setState(ModelState.idle);
      }
    } catch (e) {
      _error = e.toString();
      _setState(ModelState.error);
    }
  }

  Future<void> loadModel(LocalModelInfo model) async {
    try {
      _setState(ModelState.loading);
      _error = null;

      await _engine?.dispose();
      _engine = null;

      final capability = await DeviceCapabilityDetector.detect();

      final stopwatch = Stopwatch()..start();

      _engine = LlamaEngine(
        modelPath: await _getModelPath(model),
        capability: capability,
      );

      await _engine!.initialize();
      stopwatch.stop();

      _currentModel = model;
      _setState(ModelState.ready);

      performanceMonitor.recordGeneration(
        promptTokens: 0,
        completionTokens: 0,
        loadTime: stopwatch.elapsed,
        generationTime: Duration.zero,
      );
    } catch (e) {
      _error = e.toString();
      _setState(ModelState.error);
    }
  }

  Future<void> switchModel(LocalModelInfo newModel) async {
    if (_currentModel?.id == newModel.id) return;

    _setState(ModelState.switching);

    await _engine?.dispose();
    _engine = null;

    await loadModel(newModel);
  }

  Future<String> _getModelPath(LocalModelInfo model) async {
    try {
      final file = await downloadManager.getModelFile(model.id);
      return file.path;
    } catch (e) {
      throw FileSystemException('Model not downloaded', model.id);
    }
  }

  Future<void> downloadAndLoadModel(
    LocalModelInfo model, {
    Function(DownloadProgress)? onProgress,
  }) async {
    final isDownloaded = await downloadManager.isModelDownloaded(model.id);

    if (!isDownloaded) {
      await downloadManager.downloadModel(
        model,
        onProgress: onProgress,
        onComplete: (_) async {
          await loadModel(model);
        },
        onError: (error) {
          _error = error;
          _setState(ModelState.error);
        },
      );
    } else {
      await loadModel(model);
    }
  }

  Future<String> generate(
    String prompt, {
    String? systemPrompt,
    List<MessageEntry>? history,
  }) async {
    if (_engine == null || !isReady) {
      throw StateError('No model loaded');
    }

    final stopwatch = Stopwatch()..start();

    final result = await _engine!.generate(
      prompt,
      systemPrompt: systemPrompt,
      history: history,
    );

    stopwatch.stop();

    performanceMonitor.recordGeneration(
      promptTokens: (prompt.length / 4).round(),
      completionTokens: (result.length / 4).round(),
      loadTime: Duration.zero,
      generationTime: stopwatch.elapsed,
    );

    return result;
  }

  Stream<String> generateStream(
    String prompt, {
    String? systemPrompt,
    List<MessageEntry>? history,
  }) async* {
    if (_engine == null || !isReady) {
      throw StateError('No model loaded');
    }

    final stopwatch = Stopwatch()..start();
    int tokens = 0;

    await for (final chunk in _engine!.generateStream(
      prompt,
      systemPrompt: systemPrompt,
      history: history,
    )) {
      tokens++;
      yield chunk;
    }

    stopwatch.stop();

    performanceMonitor.recordGeneration(
      promptTokens: (prompt.length / 4).round(),
      completionTokens: tokens,
      loadTime: Duration.zero,
      generationTime: stopwatch.elapsed,
    );
  }

  void cancelStream() {
    _engine?.cancelStream();
  }

  void _setState(ModelState newState) {
    _state = newState;
    _stateController.add(newState);
    notifyListeners();
  }

  Future<List<ModelRecommendation>> getRecommendations() async {
    return recommendationEngine.getRecommendations();
  }

  HardwareInfo? _cachedHardwareInfo;

  Future<HardwareInfo> getHardwareInfo() async {
    _cachedHardwareInfo ??= await recommendationEngine.detectHardware();
    return _cachedHardwareInfo!;
  }

  @override
  void dispose() {
    _engine?.dispose();
    downloadManager.dispose();
    performanceMonitor.dispose();
    _stateController.close();
    super.dispose();
  }
}
