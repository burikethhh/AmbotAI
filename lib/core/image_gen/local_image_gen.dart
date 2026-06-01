import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'image_gen_engine.dart';
import 'sd_server_client.dart';
import '../ai/ai_engine.dart';
import '../ai/model_registry.dart';

class LocalImageGenEngine implements ImageGenEngine {
  final SdServerClient _server = SdServerClient();

  bool _isReady = true;
  bool _isGenerating = false;
  String? _currentModel;
  String? _currentModelPath;
  AIEngine? _llmEngine;
  String _cancelToken = '';

  final Map<String, String> _generationCache = {};
  static const int _maxCacheSize = 50;

  static const int _maxRetries = 2;
  static const Duration _retryDelay = Duration(seconds: 2);

  void setLlmEngine(AIEngine engine) {
    _llmEngine = engine;
  }

  bool get isGenerating => _isGenerating;
  int get cacheSize => _generationCache.length;

  void clearCache() {
    _generationCache.clear();
  }

  Future<Map<String, dynamic>> getCapabilities() async {
    if (!_server.isRunning) return {'error': 'Server not running'};
    try {
      return await _server.getCapabilities();
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  @override
  Future<void> initialize() async {
    try {
      final hasModel = await hasLocalModel();
      if (hasModel) {
        final modelsDir = await _getModelsDir();
        await for (final entity in modelsDir.list()) {
          if (entity is File && _isSdModelFile(entity.path)) {
            _currentModelPath = entity.path;
            _currentModel = _resolveModelId(entity.path);
            break;
          }
        }

        if (_currentModelPath != null) {
          await _server.start(modelPath: _currentModelPath!);
        }
      }
    } catch (e) {
      _isReady = true;
    }
    _isReady = true;
  }

  @override
  Future<String> generate({
    required String prompt,
    String? negativePrompt,
    int width = 512,
    int height = 512,
    int steps = 4,
    double guidanceScale = 7.0,
    int seed = -1,
  }) async {
    if (!_isReady) throw StateError('Engine not initialized');
    if (_isGenerating) throw StateError('Generation already in progress');
    if (!_server.isRunning) throw Exception('SD server not running');

    final cacheKey = _buildCacheKey(prompt, negativePrompt, width, height, steps, seed);
    if (_generationCache.containsKey(cacheKey)) {
      final cachedPath = _generationCache[cacheKey]!;
      if (await File(cachedPath).exists()) {
        return cachedPath;
      }
      _generationCache.remove(cacheKey);
    }

    _isGenerating = true;
    _cancelToken = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      String enhancedPrompt = prompt;
      if (_llmEngine != null && _llmEngine!.isReady) {
        enhancedPrompt = await _expandPrompt(prompt);
      }

      final model = _currentModel != null
          ? ModelRegistry.getById(_currentModel!)
          : null;

      final actualSteps = model != null
          ? ModelRegistry.getRecommendedSteps(_currentModel!)
          : steps;

      String? resultPath;
      String? lastError;

      for (int attempt = 0; attempt <= _maxRetries; attempt++) {
        if (attempt > 0) {
          await Future.delayed(_retryDelay * attempt);
        }

        try {
          resultPath = await _server.generate(
            prompt: enhancedPrompt,
            negativePrompt: negativePrompt,
            width: width,
            height: height,
            steps: actualSteps,
            guidanceScale: guidanceScale,
            seed: seed < 0 ? Random().nextInt(999999999) : seed,
            cancelToken: _cancelToken,
          );
          if (resultPath.isNotEmpty) break;
        } on JobCancelledException {
          rethrow;
        } catch (e) {
          lastError = e.toString();
        }
      }

      if (resultPath == null || resultPath.isEmpty) {
        throw Exception('Generation failed after ${_maxRetries + 1} attempts. Last error: $lastError');
      }

      _cacheResult(cacheKey, resultPath);
      return resultPath;
    } finally {
      _isGenerating = false;
    }
  }

  @override
  Stream<ImageGenProgress> generateWithProgress({
    required String prompt,
    String? negativePrompt,
    int width = 512,
    int height = 512,
    int steps = 4,
    double guidanceScale = 7.0,
    int seed = -1,
  }) async* {
    if (!_isReady) throw StateError('Engine not initialized');
    if (_isGenerating) throw StateError('Generation already in progress');
    if (!_server.isRunning) throw Exception('SD server not running');

    final cacheKey = _buildCacheKey(prompt, negativePrompt, width, height, steps, seed);
    if (_generationCache.containsKey(cacheKey)) {
      final cachedPath = _generationCache[cacheKey]!;
      if (await File(cachedPath).exists()) {
        yield ImageGenProgress(
          progress: 1.0,
          status: 'Loaded from cache',
          imagePath: cachedPath,
        );
        return;
      }
      _generationCache.remove(cacheKey);
    }

    _isGenerating = true;
    _cancelToken = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      final model = _currentModel != null
          ? ModelRegistry.getById(_currentModel!)
          : null;

      final actualSteps = model != null
          ? ModelRegistry.getRecommendedSteps(_currentModel!)
          : steps;

      yield const ImageGenProgress(progress: 0.0, status: 'Preparing generation...');

      String enhancedPrompt = prompt;
      if (_llmEngine != null && _llmEngine!.isReady) {
        yield const ImageGenProgress(progress: 0.05, status: 'Enhancing prompt...');
        try {
          enhancedPrompt = await _expandPrompt(prompt);
          yield const ImageGenProgress(progress: 0.10, status: 'Prompt enhanced');
        } catch (_) {
          yield const ImageGenProgress(progress: 0.10, status: 'Using original prompt');
        }
      }

      String? resultPath;
      String? lastError;

      yield ImageGenProgress(progress: 0.20, status: 'Starting generation ($actualSteps steps)...');

      for (int attempt = 0; attempt <= _maxRetries; attempt++) {
        if (attempt > 0) {
          await Future.delayed(_retryDelay * attempt);
          yield ImageGenProgress(progress: 0.20, status: 'Retry ${attempt + 1}/$_maxRetries...');
        }

        try {
          resultPath = await _server.generate(
            prompt: enhancedPrompt,
            negativePrompt: negativePrompt ?? 'blurry, low quality, distorted, deformed, watermark, text, bad anatomy',
            width: width,
            height: height,
            steps: actualSteps,
            guidanceScale: guidanceScale,
            seed: seed < 0 ? Random().nextInt(999999999) : seed,
            cancelToken: _cancelToken,
          );
          if (resultPath.isNotEmpty) break;
        } on JobCancelledException {
          yield const ImageGenProgress(progress: 0.0, status: 'Cancelled');
          return;
        } catch (e) {
          lastError = e.toString();
        }
      }

      if (resultPath == null || resultPath.isEmpty) {
        throw Exception('Generation failed after ${_maxRetries + 1} attempts. Last error: $lastError');
      }

      _cacheResult(cacheKey, resultPath);

      yield ImageGenProgress(
        progress: 1.0,
        status: 'Complete!',
        imagePath: resultPath,
      );
    } finally {
      _isGenerating = false;
    }
  }

  Future<String> _expandPrompt(String prompt) async {
    if (_llmEngine == null) return prompt;

    try {
      final systemPrompt = '''
You are an expert Stable Diffusion prompt enhancer. Convert simple prompts into detailed, 
professional image generation prompts. 

Rules:
- Keep the core subject intact
- Add lighting, composition, style, and quality descriptors
- Use comma-separated tags
- Keep it under 100 words
- Do NOT add disclaimers or explanations
- Output ONLY the enhanced prompt, nothing else

Examples:
"a dog" → "golden retriever sitting in autumn leaves, warm afternoon light, shallow depth of field, professional pet photography, natural colors, 4k"
"a futuristic car" → "sleek cyberpunk sports car, neon reflections, wet asphalt, hyper-detailed 3d render, synthwave aesthetic, dramatic lighting, 8k resolution"
''';

      final enhanced = await _llmEngine!.generate(
        'Enhance this image prompt: $prompt',
        systemPrompt: systemPrompt,
      );

      final cleaned = enhanced
          .replaceAll(RegExp(r'^.*?:\s*'), '')
          .replaceAll(RegExp(r'[\n\r"]'), ' ')
          .trim();

      return cleaned.isNotEmpty && cleaned.length > prompt.length
          ? cleaned
          : prompt;
    } catch (_) {
      return prompt;
    }
  }

  String _buildCacheKey(
    String prompt,
    String? negativePrompt,
    int width,
    int height,
    int steps,
    int seed,
  ) {
    final seedValue = seed < 0 ? 'random' : seed.toString();
    return '${prompt.hashCode}_${negativePrompt?.hashCode ?? 0}_${width}x${height}_${steps}_$seedValue';
  }

  void _cacheResult(String key, String path) {
    if (_generationCache.length >= _maxCacheSize) {
      _generationCache.remove(_generationCache.keys.first);
    }
    _generationCache[key] = path;
  }

  String? _resolveModelId(String path) {
    final fileName = path.split('/').last.toLowerCase();
    final model = ModelRegistry.findByFileName(fileName);
    return model?.id;
  }

  Future<Directory> _getModelsDir() async {
    final extDir = await getExternalStorageDirectory();
    final dir = Directory('${extDir?.path ?? ''}/models');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  bool _isSdModelFile(String path) {
    final fileName = path.split('/').last.toLowerCase();
    if (!fileName.endsWith('.gguf')) return false;
    return fileName.contains('sd') || fileName.contains('stable') || fileName.contains('turbo');
  }

  Future<bool> hasLocalModel() async {
    try {
      final modelsDir = await _getModelsDir();
      if (!await modelsDir.exists()) return false;

      await for (final entity in modelsDir.list()) {
        if (entity is File && _isSdModelFile(entity.path)) {
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> cancel() async {
    _cancelToken = 'cancelled';
    _isGenerating = false;
  }

  @override
  Future<void> dispose() async {
    _cancelToken = 'cancelled';
    await _server.stop();
    _generationCache.clear();
    _isReady = false;
    _isGenerating = false;
  }

  @override
  String get engineName => 'Local SD (stable-diffusion.cpp server)';

  @override
  bool get isReady => _isReady;

  @override
  bool get isLocal => true;
}
