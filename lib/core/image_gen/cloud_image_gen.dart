import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'image_gen_engine.dart';
import 'nvidia_image_gen.dart';
import '../storage/output_storage_service.dart';
import '../config/api_keys.dart';

/// Cloud-based image generation engine with fallback chain:
///   1. NVIDIA build.nvidia.com (two keys with auto-rotation on rate-limit)
///   2. Hugging Face Inference API
///   3. Error with guidance to download local model
class CloudImageGenEngine implements ImageGenEngine {
  bool _isReady = false;
  final http.Client _client = http.Client();
  final NvidiaImageGenEngine _nvidiaEngine = NvidiaImageGenEngine();
  String? _userNvidiaKey1;
  String? _userNvidiaKey2;

  static const String _defaultModel = 'stabilityai/stable-diffusion-xl-base-1.0';

  static const List<String> _fallbackModels = [
    'stabilityai/stable-diffusion-2-1',
    'runwayml/stable-diffusion-v1-5',
    'prompthero/openjourney-v4',
  ];

  @override
  Future<void> initialize() async {
    await _nvidiaEngine.initialize();
    _isReady = true;
  }

  void setNvidiaApiKeys(String key1, String? key2) {
    _userNvidiaKey1 = key1;
    _userNvidiaKey2 = key2;
    _nvidiaEngine.setApiKeys(key1, key2);
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

    final dir = await _getImagesDir();
    final actualSeed = seed >= 0 ? seed : Random().nextInt(999999);
    final filename = 'img_${DateTime.now().millisecondsSinceEpoch}_$actualSeed.png';
    final filePath = '${dir.path}/$filename';

    Uint8List? imageBytes;

    // 1. Try NVIDIA
    imageBytes = await _tryNvidia(
      prompt: prompt,
      width: width,
      height: height,
      steps: steps,
      seed: actualSeed,
      userNvidiaKey1: _userNvidiaKey1,
      userNvidiaKey2: _userNvidiaKey2,
    );

    // 2. Try Hugging Face if NVIDIA failed
    if (imageBytes == null || imageBytes.isEmpty) {
      try {
        imageBytes = await _tryCloudGeneration(
          prompt: prompt,
          negativePrompt: negativePrompt,
          width: width,
          height: height,
          steps: steps,
          guidanceScale: guidanceScale,
          seed: actualSeed,
        );
      } catch (e) {
        debugPrint('CLOUD_IMG: HuggingFace fallback failed: $e');
      }
    }

    if (imageBytes == null || imageBytes.isEmpty) {
      throw Exception(
        'All cloud image generation methods failed. '
        'Download a local Stable Diffusion model or configure a Hugging Face token in Settings.',
      );
    }

    final file = File(filePath);
    await file.writeAsBytes(imageBytes);
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

    final dir = await _getImagesDir();
    final actualSeed = seed >= 0 ? seed : Random().nextInt(999999);
    final filename = 'img_${DateTime.now().millisecondsSinceEpoch}_$actualSeed.png';
    final filePath = '${dir.path}/$filename';

    yield const ImageGenProgress(progress: 0.0, status: 'Starting image generation...');

    Uint8List? imageBytes;

    // 1. Try NVIDIA first
    yield const ImageGenProgress(progress: 0.1, status: 'Trying NVIDIA cloud AI...');
    try {
      imageBytes = await _tryNvidia(
        prompt: prompt,
        width: width,
        height: height,
        steps: steps,
        seed: actualSeed,
        userNvidiaKey1: _userNvidiaKey1,
        userNvidiaKey2: _userNvidiaKey2,
      );
      if (imageBytes != null && imageBytes.isNotEmpty) {
        yield const ImageGenProgress(progress: 0.9, status: 'Processing image...');
      }
    } catch (_) {}

    // 2. Try Hugging Face if NVIDIA failed
    if (imageBytes == null || imageBytes.isEmpty) {
      yield const ImageGenProgress(progress: 0.3, status: 'NVIDIA unavailable, trying Hugging Face...');
      try {
        imageBytes = await _tryCloudGeneration(
          prompt: prompt,
          negativePrompt: negativePrompt,
          width: width,
          height: height,
          steps: steps,
          guidanceScale: guidanceScale,
          seed: actualSeed,
        );
        if (imageBytes != null && imageBytes.isNotEmpty) {
          yield const ImageGenProgress(progress: 0.9, status: 'Processing image...');
        }
      } catch (e) {
        debugPrint('CLOUD_IMG: HuggingFace fallback failed (genWithProgress): $e');
      }
    }

    if (imageBytes == null || imageBytes.isEmpty) {
      yield const ImageGenProgress(progress: 1.0, status: 'All cloud methods failed');
      throw Exception(
        'All cloud image generation methods failed. '
        'Download a local Stable Diffusion model or configure a Hugging Face token in Settings.',
      );
    }

    final file = File(filePath);
    await file.writeAsBytes(imageBytes);

    yield ImageGenProgress(
      progress: 1.0,
      status: 'Complete!',
      imagePath: filePath,
    );
  }

  /// Try NVIDIA cloud generation with primary + secondary key rotation.
  Future<Uint8List?> _tryNvidia({
    required String prompt,
    required int width,
    required int height,
    required int steps,
    required int seed,
    String? userNvidiaKey1,
    String? userNvidiaKey2,
  }) async {
    final key1 = userNvidiaKey1 ?? ApiKeys.nvidiaKey1;
    final key2 = userNvidiaKey2 ?? ApiKeys.nvidiaKey2;
    if (key1.isEmpty && key2.isEmpty) return null;
    _nvidiaEngine.setApiKeys(key1, key2);
    try {
      return await _nvidiaEngine.tryNvidiaGeneration(
        prompt: prompt,
        width: width,
        height: height,
        steps: steps,
        seed: seed,
      );
    } catch (_) {
      return null;
    }
  }

  /// Try to generate image via Hugging Face cloud API.
  /// Returns null if all attempts fail.
  Future<Uint8List?> _tryCloudGeneration({
    required String prompt,
    String? negativePrompt,
    required int width,
    required int height,
    required int steps,
    required double guidanceScale,
    required int seed,
  }) async {
    final hfToken = ApiKeys.huggingFaceToken;

    if (hfToken.isEmpty) return null;

    final models = [_defaultModel, ..._fallbackModels];

    for (final model in models) {
      try {
        final bytes = await _callHuggingFace(
          model: model,
          prompt: prompt,
          negativePrompt: negativePrompt,
          width: width,
          height: height,
          steps: steps,
          guidanceScale: guidanceScale,
          seed: seed,
          token: hfToken,
        );
        if (bytes != null && bytes.isNotEmpty) return bytes;
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  Future<Uint8List?> _callHuggingFace({
    required String model,
    required String prompt,
    String? negativePrompt,
    required int width,
    required int height,
    required int steps,
    required double guidanceScale,
    required int seed,
    required String token,
  }) async {
    final url = 'https://api-inference.huggingface.co/models/$model';

    final body = {
      'inputs': prompt,
      'parameters': {
        'negative_prompt': negativePrompt ?? 'blurry, low quality, distorted, deformed',
        'num_inference_steps': steps,
        'guidance_scale': guidanceScale,
        'width': width,
        'height': height,
        'seed': seed,
      },
    };

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await _client
        .post(Uri.parse(url), headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
      return response.bodyBytes;
    }

    if (response.statusCode == 503) {
      throw Exception('Model loading');
    }

    throw Exception('HTTP ${response.statusCode}');
  }

  Future<Directory> _getImagesDir() async {
    return OutputStorageService.instance.dir(OutputType.images);
  }

  @override
  Future<void> dispose() async {
    _client.close();
    _nvidiaEngine.dispose();
    _isReady = false;
  }

  @override
  String get engineName => 'NVIDIA + Hugging Face (Cloud)';

  @override
  bool get isReady => _isReady;

  @override
  bool get isLocal => false;
}
