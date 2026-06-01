import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'image_gen_engine.dart';
import '../ai/nvidia_key_manager.dart';
import '../storage/output_storage_service.dart';

class NvidiaImageGenEngine implements ImageGenEngine {
  bool _isReady = false;
  final http.Client _client = http.Client();
  final NvidiaKeyManager _keyManager = NvidiaKeyManager();

  /// Each model has its own endpoint on ai.api.nvidia.com.
  /// https://ai.api.nvidia.com/v1/genai/{owner}/{name}
  static const List<_NvidiaImageModel> _models = [
    _NvidiaImageModel(
      owner: 'black-forest-labs',
      name: 'flux.1-schnell',
      label: 'FLUX.1-schnell',
      maxSteps: 4,
      maxWidth: 1344,
      maxHeight: 1344,
    ),
    _NvidiaImageModel(
      owner: 'black-forest-labs',
      name: 'flux.2-klein-4b',
      label: 'FLUX.2-klein-4b',
      maxSteps: 4,
      maxWidth: 1344,
      maxHeight: 1344,
    ),
  ];

  void setApiKeys(String key1, String? key2) {
    _keyManager.setUserKeys(key1, key2);
  }

  @override
  Future<void> initialize() async {
    _isReady = true;
  }

  @override
  Future<String> generate({
    required String prompt,
    String? negativePrompt,
    int width = 512,
    int height = 512,
    int steps = 20,
    double guidanceScale = 7.5,
    int seed = -1,
  }) async {
    if (!_isReady) throw StateError('Engine not initialized');
    if (!_keyManager.hasAnyKey) throw Exception('No NVIDIA API keys available');

    final dir = await _getImagesDir();
    final actualSeed = seed >= 0 ? seed : Random().nextInt(999999);
    final filename = 'nvidia_${DateTime.now().millisecondsSinceEpoch}_$actualSeed.png';
    final filePath = '${dir.path}/$filename';

    final bytes = await tryNvidiaGeneration(
      prompt: prompt,
      width: width,
      height: height,
      steps: steps,
      seed: actualSeed,
    );

    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return filePath;
  }

  @override
  Stream<ImageGenProgress> generateWithProgress({
    required String prompt,
    String? negativePrompt,
    int width = 512,
    int height = 512,
    int steps = 20,
    double guidanceScale = 7.5,
    int seed = -1,
  }) async* {
    if (!_isReady) throw StateError('Engine not initialized');
    if (!_keyManager.hasAnyKey) throw Exception('No NVIDIA API keys available');

    final dir = await _getImagesDir();
    final actualSeed = seed >= 0 ? seed : Random().nextInt(999999);
    final filename = 'nvidia_${DateTime.now().millisecondsSinceEpoch}_$actualSeed.png';
    final filePath = '${dir.path}/$filename';

    yield const ImageGenProgress(progress: 0.0, status: 'Starting NVIDIA cloud generation...');

    try {
      yield const ImageGenProgress(progress: 0.2, status: 'Generating with NVIDIA AI...');
      final bytes = await tryNvidiaGeneration(
        prompt: prompt,
        width: width,
        height: height,
        steps: steps,
        seed: actualSeed,
      );

      yield const ImageGenProgress(progress: 0.9, status: 'Processing image...');

      final file = File(filePath);
      await file.writeAsBytes(bytes);

      yield ImageGenProgress(
        progress: 1.0,
        status: 'Complete!',
        imagePath: filePath,
      );
    } catch (e) {
      yield ImageGenProgress(
        progress: 1.0,
        status: 'NVIDIA failed: $e',
      );
      rethrow;
    }
  }

  Future<Uint8List> tryNvidiaGeneration({
    required String prompt,
    required int width,
    required int height,
    int steps = 4,
    int seed = 0,
  }) async {
    _keyManager.reset();
    for (int attempt = 0; attempt < 2; attempt++) {
      final key = _keyManager.activeKey;
      if (key == null) break;

      final futures = _models.map((model) async {
        try {
          return await _callNvidiaApi(
            model: model,
            prompt: prompt,
            width: width,
            height: height,
            steps: steps,
            seed: seed,
            apiKey: key,
          );
        } catch (_) {
          return Uint8List(0);
        }
      }).toList();

      final results = await Future.wait(futures);
      for (final bytes in results) {
        if (bytes.isNotEmpty) return bytes;
      }

      _keyManager.rotateOnRateLimit();
    }
    throw Exception('All NVIDIA models failed');
  }

  Future<Uint8List> _callNvidiaApi({
    required _NvidiaImageModel model,
    required String prompt,
    required int width,
    required int height,
    required int steps,
    required int seed,
    required String apiKey,
  }) async {
    final url = 'https://ai.api.nvidia.com/v1/genai/${model.owner}/${model.name}';
    final clampedSteps = steps.clamp(1, model.maxSteps);
    final clampedWidth = width.clamp(256, model.maxWidth);
    final clampedHeight = height.clamp(256, model.maxHeight);

    final body = {
      'prompt': prompt,
      'width': clampedWidth,
      'height': clampedHeight,
      'seed': seed,
      'steps': clampedSteps,
    };

    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final response = await _client
        .post(Uri.parse(url), headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 90));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final artifacts = data['artifacts'] as List<dynamic>?;
      if (artifacts != null && artifacts.isNotEmpty) {
        final artifact = artifacts[0] as Map<String, dynamic>;
        final base64Str = artifact['base64'] as String;
        return base64Decode(base64Str);
      }
    }

    if (response.statusCode == 429) {
      throw Exception('429 Rate limited');
    }

    throw Exception('NVIDIA API HTTP ${response.statusCode}: ${response.body}');
  }

  Future<Directory> _getImagesDir() async {
    return OutputStorageService.instance.dir(OutputType.images);
  }

  @override
  Future<void> dispose() async {
    _client.close();
    _isReady = false;
  }

  @override
  String get engineName => 'NVIDIA (build.nvidia.com)';

  @override
  bool get isReady => _isReady;

  @override
  bool get isLocal => false;
}

class _NvidiaImageModel {
  final String owner;
  final String name;
  final String label;
  final int maxSteps;
  final int maxWidth;
  final int maxHeight;

  const _NvidiaImageModel({
    required this.owner,
    required this.name,
    required this.label,
    required this.maxSteps,
    required this.maxWidth,
    required this.maxHeight,
  });
}
