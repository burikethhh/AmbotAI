import 'ai_engine.dart';

class ModelInfo {
  final String id;
  final String name;
  final String params;
  final String quantization;
  final int sizeMB;
  final int minRamMB;
  final int minStorageMB;
  final DeviceTier targetTier;
  final String huggingFaceRepo;
  final String fileName;
  final String? sha256;
  final ModelType modelType;

  const ModelInfo({
    required this.id,
    required this.name,
    required this.params,
    required this.quantization,
    required this.sizeMB,
    required this.minRamMB,
    required this.minStorageMB,
    required this.targetTier,
    required this.huggingFaceRepo,
    required this.fileName,
    this.sha256,
    this.modelType = ModelType.text,
  });

  String get downloadUrl =>
      'https://huggingface.co/$huggingFaceRepo/resolve/main/$fileName';

  String get displaySize {
    if (sizeMB >= 1024) {
      return '${(sizeMB / 1024).toStringAsFixed(1)} GB';
    }
    return '$sizeMB MB';
  }
}

/// Types of AI models supported.
enum ModelType {
  text('Text/Chat'),
  image('Image Generation'),
  document('Document Generation'),
  voice('Voice Generation');

  const ModelType(this.label);
  final String label;
}

class ModelRegistry {
  static const List<ModelInfo> all = [
    // Text/Chat models
    ModelInfo(
      id: 'llama-3.2-1b-q4',
      name: 'Llama 3.2 1B (Q4)',
      params: '1B',
      quantization: 'Q4_K_M',
      sizeMB: 750,
      minRamMB: 3072,
      minStorageMB: 1500,
      targetTier: DeviceTier.lowEnd,
      huggingFaceRepo: 'bartowski/Llama-3.2-1B-Instruct-GGUF',
      fileName: 'Llama-3.2-1B-Instruct-Q4_K_M.gguf',
    ),
    ModelInfo(
      id: 'llama-3.2-1b-q8',
      name: 'Llama 3.2 1B (Q8)',
      params: '1B',
      quantization: 'Q8_0',
      sizeMB: 1300,
      minRamMB: 4096,
      minStorageMB: 3000,
      targetTier: DeviceTier.mid,
      huggingFaceRepo: 'bartowski/Llama-3.2-1B-Instruct-GGUF',
      fileName: 'Llama-3.2-1B-Instruct-Q8_0.gguf',
    ),
    ModelInfo(
      id: 'llama-3.2-3b-q4',
      name: 'Llama 3.2 3B (Q4)',
      params: '3B',
      quantization: 'Q4_K_M',
      sizeMB: 2020,
      minRamMB: 6144,
      minStorageMB: 5000,
      targetTier: DeviceTier.flagship,
      huggingFaceRepo: 'bartowski/Llama-3.2-3B-Instruct-GGUF',
      fileName: 'Llama-3.2-3B-Instruct-Q4_K_M.gguf',
    ),
    // Additional text models
    ModelInfo(
      id: 'gemma-3-1b-q4',
      name: 'Gemma 3 1B (Q4)',
      params: '1B',
      quantization: 'Q4_K_M',
      sizeMB: 780,
      minRamMB: 3072,
      minStorageMB: 1500,
      targetTier: DeviceTier.lowEnd,
      huggingFaceRepo: 'bartowski/google_gemma-3-1b-it-GGUF',
      fileName: 'google_gemma-3-1b-it-Q4_K_M.gguf',
    ),
    ModelInfo(
      id: 'gemma-3-4b-q4',
      name: 'Gemma 3 4B (Q4)',
      params: '4B',
      quantization: 'Q4_K_M',
      sizeMB: 2540,
      minRamMB: 6144,
      minStorageMB: 5000,
      targetTier: DeviceTier.flagship,
      huggingFaceRepo: 'bartowski/google_gemma-3-4b-it-GGUF',
      fileName: 'google_gemma-3-4b-it-Q4_K_M.gguf',
    ),
    ModelInfo(
      id: 'gemma-3-4b-q8',
      name: 'Gemma 3 4B (Q8)',
      params: '4B',
      quantization: 'Q8_0',
      sizeMB: 4230,
      minRamMB: 8192,
      minStorageMB: 8000,
      targetTier: DeviceTier.flagship,
      huggingFaceRepo: 'bartowski/google_gemma-3-4b-it-GGUF',
      fileName: 'google_gemma-3-4b-it-Q8_0.gguf',
    ),
    ModelInfo(
      id: 'phi-4-mini-q4',
      name: 'Phi-4 Mini 3.8B (Q4)',
      params: '3.8B',
      quantization: 'Q4_K_M',
      sizeMB: 2490,
      minRamMB: 6144,
      minStorageMB: 5000,
      targetTier: DeviceTier.flagship,
      huggingFaceRepo: 'bartowski/microsoft_Phi-4-mini-instruct-GGUF',
      fileName: 'microsoft_Phi-4-mini-instruct-Q4_K_M.gguf',
    ),
    ModelInfo(
      id: 'phi-4-mini-q3',
      name: 'Phi-4 Mini 3.8B (Q3)',
      params: '3.8B',
      quantization: 'Q3_K_M',
      sizeMB: 2120,
      minRamMB: 4096,
      minStorageMB: 4000,
      targetTier: DeviceTier.mid,
      huggingFaceRepo: 'bartowski/microsoft_Phi-4-mini-instruct-GGUF',
      fileName: 'microsoft_Phi-4-mini-instruct-Q3_K_M.gguf',
    ),
    ModelInfo(
      id: 'qwen-2.5-1.5b-q4',
      name: 'Qwen2.5 1.5B (Q4)',
      params: '1.5B',
      quantization: 'Q4_K_M',
      sizeMB: 990,
      minRamMB: 3072,
      minStorageMB: 2000,
      targetTier: DeviceTier.lowEnd,
      huggingFaceRepo: 'Qwen/Qwen2.5-1.5B-Instruct-GGUF',
      fileName: 'qwen2.5-1.5b-instruct-q4_k_m.gguf',
    ),
    ModelInfo(
      id: 'qwen-2.5-3b-q4',
      name: 'Qwen2.5 3B (Q4)',
      params: '3B',
      quantization: 'Q4_K_M',
      sizeMB: 1980,
      minRamMB: 4096,
      minStorageMB: 4000,
      targetTier: DeviceTier.mid,
      huggingFaceRepo: 'Qwen/Qwen2.5-3B-Instruct-GGUF',
      fileName: 'qwen2.5-3b-instruct-q4_k_m.gguf',
    ),
    // Image generation models (local, GGUF format via stable-diffusion.cpp)
    // Low-End Tier: SD 1.5 Q4 (runs on 4GB+ RAM)
    ModelInfo(
      id: 'sd15-q4',
      name: 'SD 1.5 (Q4)',
      params: '860M',
      quantization: 'Q4_0',
      sizeMB: 1792,
      minRamMB: 4096,
      minStorageMB: 2500,
      targetTier: DeviceTier.lowEnd,
      huggingFaceRepo: 'gpustack/stable-diffusion-v1-5-GGUF',
      fileName: 'stable-diffusion-v1-5-Q4_0.gguf',
      modelType: ModelType.image,
    ),
    // Mid-Range Tier: SD 1.5 Q8 (better quality, 6GB+ RAM)
    ModelInfo(
      id: 'sd15-q8',
      name: 'SD 1.5 (Q8)',
      params: '860M',
      quantization: 'Q8_0',
      sizeMB: 1925,
      minRamMB: 6144,
      minStorageMB: 3500,
      targetTier: DeviceTier.mid,
      huggingFaceRepo: 'gpustack/stable-diffusion-v1-5-GGUF',
      fileName: 'stable-diffusion-v1-5-Q8_0.gguf',
      modelType: ModelType.image,
    ),
    // Flagship Tier: SDXL Turbo Q4 (1-4 step generation, 12GB+ RAM)
    ModelInfo(
      id: 'sdxl-turbo-q4',
      name: 'SDXL Turbo (Q4)',
      params: '2.6B',
      quantization: 'Q4_0',
      sizeMB: 4034,
      minRamMB: 12288,
      minStorageMB: 8000,
      targetTier: DeviceTier.flagship,
      huggingFaceRepo: 'gpustack/stable-diffusion-xl-1.0-turbo-GGUF',
      fileName: 'stable-diffusion-xl-1.0-turbo-Q4_0.gguf',
      modelType: ModelType.image,
    ),
    // TAESD autoencoder (optional, reduces memory spikes for all tiers)
    ModelInfo(
      id: 'taesd',
      name: 'TAESD (Tiny AutoEncoder)',
      params: 'N/A',
      quantization: 'FP16',
      sizeMB: 4,
      minRamMB: 0,
      minStorageMB: 10,
      targetTier: DeviceTier.lowEnd,
      huggingFaceRepo: 'madebyollin/taesd',
      fileName: 'taesd_encoder.pth',
      modelType: ModelType.image,
    ),
    // Ultra Flagship: FLUX.1-schnell Q2_K (best quality, minimal size)
    ModelInfo(
      id: 'flux-schnell-q2',
      name: 'FLUX.1-schnell (Q2_K)',
      params: '3.5B',
      quantization: 'Q2_K',
      sizeMB: 4106,
      minRamMB: 12288,
      minStorageMB: 8000,
      targetTier: DeviceTier.flagship,
      huggingFaceRepo: 'city96/FLUX.1-schnell-gguf',
      fileName: 'flux1-schnell-Q2_K.gguf',
      modelType: ModelType.image,
    ),
    // Ultra-ultra: FLUX.1-schnell Q4_K_M (best quality, needs more RAM)
    ModelInfo(
      id: 'flux-schnell-q4',
      name: 'FLUX.1-schnell (Q4_K_M)',
      params: '3.5B',
      quantization: 'Q4_K_M',
      sizeMB: 5870,
      minRamMB: 16384,
      minStorageMB: 10000,
      targetTier: DeviceTier.flagship,
      huggingFaceRepo: 'city96/FLUX.1-schnell-gguf',
      fileName: 'flux1-schnell-Q4_K_M.gguf',
      modelType: ModelType.image,
    ),
    // Voice generation models (Piper TTS)
    ModelInfo(
      id: 'piper-en-us-lessac-medium',
      name: 'English (US) - Lessac Medium',
      params: '62M',
      quantization: 'INT8',
      sizeMB: 60,
      minRamMB: 1024,
      minStorageMB: 150,
      targetTier: DeviceTier.lowEnd,
      huggingFaceRepo: 'rhasspy/piper-voices',
      fileName: 'en/en_US/lessac/medium/en_US-lessac-medium.onnx',
      modelType: ModelType.voice,
    ),
    ModelInfo(
      id: 'piper-en-us-lessac-medium-config',
      name: 'English (US) - Lessac Medium Config',
      params: 'N/A',
      quantization: 'N/A',
      sizeMB: 1,
      minRamMB: 0,
      minStorageMB: 10,
      targetTier: DeviceTier.lowEnd,
      huggingFaceRepo: 'rhasspy/piper-voices',
      fileName: 'en/en_US/lessac/medium/en_US-lessac-medium.onnx.json',
      modelType: ModelType.voice,
    ),
    ModelInfo(
      id: 'piper-en-us-amy-medium',
      name: 'English (US) - Amy Medium',
      params: '65M',
      quantization: 'INT8',
      sizeMB: 63,
      minRamMB: 1024,
      minStorageMB: 150,
      targetTier: DeviceTier.lowEnd,
      huggingFaceRepo: 'rhasspy/piper-voices',
      fileName: 'en/en_US/amy/medium/en_US-amy-medium.onnx',
      modelType: ModelType.voice,
    ),
    ModelInfo(
      id: 'piper-en-gb-semaine-medium',
      name: 'English (UK) - Semaine Medium',
      params: '74M',
      quantization: 'INT8',
      sizeMB: 72,
      minRamMB: 1024,
      minStorageMB: 150,
      targetTier: DeviceTier.lowEnd,
      huggingFaceRepo: 'rhasspy/piper-voices',
      fileName: 'en/en_GB/semaine/medium/en_GB-semaine-medium.onnx',
      modelType: ModelType.voice,
    ),
    ModelInfo(
      id: 'piper-en-us-kathleen-low',
      name: 'English (US) - Kathleen Low',
      params: '34M',
      quantization: 'INT8',
      sizeMB: 33,
      minRamMB: 1024,
      minStorageMB: 100,
      targetTier: DeviceTier.lowEnd,
      huggingFaceRepo: 'rhasspy/piper-voices',
      fileName: 'en/en_US/kathleen/low/en_US-kathleen-low.onnx',
      modelType: ModelType.voice,
    ),
    // More voice models
    ModelInfo(
      id: 'piper-en-us-amy-low',
      name: 'English (US) - Amy Low',
      params: '34M',
      quantization: 'INT8',
      sizeMB: 33,
      minRamMB: 1024,
      minStorageMB: 100,
      targetTier: DeviceTier.lowEnd,
      huggingFaceRepo: 'rhasspy/piper-voices',
      fileName: 'en/en_US/amy/low/en_US-amy-low.onnx',
      modelType: ModelType.voice,
    ),
    ModelInfo(
      id: 'piper-en-us-norman-medium',
      name: 'English (US) - Norman Medium',
      params: '63M',
      quantization: 'INT8',
      sizeMB: 62,
      minRamMB: 1024,
      minStorageMB: 150,
      targetTier: DeviceTier.lowEnd,
      huggingFaceRepo: 'rhasspy/piper-voices',
      fileName: 'en/en_US/norman/medium/en_US-norman-medium.onnx',
      modelType: ModelType.voice,
    ),
    ModelInfo(
      id: 'piper-en-gb-alan-medium',
      name: 'English (UK) - Alan Medium',
      params: '68M',
      quantization: 'INT8',
      sizeMB: 67,
      minRamMB: 1024,
      minStorageMB: 150,
      targetTier: DeviceTier.lowEnd,
      huggingFaceRepo: 'rhasspy/piper-voices',
      fileName: 'en/en_GB/alan/medium/en_GB-alan-medium.onnx',
      modelType: ModelType.voice,
    ),
    ModelInfo(
      id: 'piper-en-au-southern-medium',
      name: 'English (AU) - Southern Medium',
      params: '66M',
      quantization: 'INT8',
      sizeMB: 65,
      minRamMB: 1024,
      minStorageMB: 150,
      targetTier: DeviceTier.lowEnd,
      huggingFaceRepo: 'rhasspy/piper-voices',
      fileName: 'en/en_AU/southern/medium/en_AU-southern-medium.onnx',
      modelType: ModelType.voice,
    ),
  ];

  /// Select the best text model for the device capabilities.
  /// Returns null if no model fits (cloud fallback needed).
  static ModelInfo? recommendModel({
    required int ramMB,
    required int freeStorageMB,
  }) {
    // Ultra flagship: 12GB+ RAM, 8GB+ storage → Gemma 3 4B Q8 (best quality, needs headroom)
    if (freeStorageMB >= 8000 && ramMB >= 12288) {
      return all.firstWhere((m) => m.id == 'gemma-3-4b-q8');
    }

    // Flagship: 8GB+ RAM, 5GB+ storage → Gemma 3 4B Q4 (good quality, comfy on 8GB)
    if (freeStorageMB >= 5000 && ramMB >= 8192) {
      return all.firstWhere((m) => m.id == 'gemma-3-4b-q4');
    }

    // High mid: 5GB+ storage, 6GB+ RAM → Phi-4 Mini Q3
    if (freeStorageMB >= 4000 && ramMB >= 6144) {
      return all.firstWhere((m) => m.id == 'phi-4-mini-q3');
    }

    // Mid: 3GB+ storage, 4GB+ RAM → Llama 3.2 1B Q8
    if (freeStorageMB >= 3000 && ramMB >= 4096) {
      return all.firstWhere((m) => m.id == 'llama-3.2-1b-q8');
    }

    // Low: 1.5GB+ storage, 3GB+ RAM → Gemma 3 1B Q4 (smarter than Llama 1B)
    if (freeStorageMB >= 1500 && ramMB >= 3072) {
      return all.firstWhere((m) => m.id == 'gemma-3-1b-q4');
    }

    // Not enough resources
    return null;
  }

  /// Get all available image generation models (local GGUF).
  static List<ModelInfo> getImageModels() {
    return all.where((m) => m.modelType == ModelType.image && m.id != 'taesd').toList();
  }

  /// Get all available voice generation models (filters out config-only entries).
  static List<ModelInfo> getVoiceModels() {
    return all.where((m) => m.modelType == ModelType.voice && m.sizeMB > 10).toList();
  }

  /// Get TAESD autoencoder model (reduces memory spikes).
  static ModelInfo? getTaesdModel() {
    return all.firstWhereOrNull((m) => m.id == 'taesd');
  }

  /// Recommend the best image model for the device capabilities.
  /// Uses hardware tiering matrix for optimal performance.
  static ModelInfo? recommendImageModel({
    required int ramMB,
    required int freeStorageMB,
  }) {
    // Ultra: 16GB+ RAM, 10GB+ storage → FLUX.1-schnell Q4
    if (freeStorageMB >= 10000 && ramMB >= 16384) {
      return all.firstWhereOrNull((m) => m.id == 'flux-schnell-q4');
    }

    // Flagship: 12GB+ RAM, 8GB+ storage → FLUX.1-schnell Q2
    if (freeStorageMB >= 8000 && ramMB >= 12288) {
      return all.firstWhereOrNull((m) => m.id == 'flux-schnell-q2');
    }

    // High mid: 6GB+ RAM, 8GB+ storage → SDXL Turbo Q4
    if (freeStorageMB >= 8000 && ramMB >= 8192) {
      return all.firstWhereOrNull((m) => m.id == 'sdxl-turbo-q4');
    }

    // Mid-Range: 3.5GB+ storage → SD 1.5 Q8
    if (freeStorageMB >= 3500 && ramMB >= 6144) {
      return all.firstWhereOrNull((m) => m.id == 'sd15-q8');
    }

    // Low-End: 2.5GB+ storage → SD 1.5 Q4
    if (freeStorageMB >= 2500 && ramMB >= 4096) {
      return all.firstWhereOrNull((m) => m.id == 'sd15-q4');
    }

    // Not enough resources for local image generation
    return null;
  }

  /// Get recommended steps for an image model based on architecture.
  static int getRecommendedSteps(String modelId) {
    switch (modelId) {
      case 'sd15-q4':
      case 'sd15-q8':
        return 15; // SD 1.5 + Euler Karras (15 steps is sufficient)
      case 'sdxl-turbo-q4':
        return 4; // SDXL Turbo: 1-4 steps
      case 'flux-schnell-q2':
      case 'flux-schnell-q4':
        return 4; // FLUX schnell: 1-4 steps
      default:
        return 20;
    }
  }

  /// Get VRAM mode for native engine based on device RAM.
  static int getVramMode(int ramMB) {
    if (ramMB >= 12288) return 3; // High (12GB+)
    if (ramMB >= 6144) return 2;  // Medium (6-8GB)
    return 1;                      // Low (4-6GB)
  }

  static ModelInfo? getById(String id) {
    try {
      return all.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Find a model by its file name (e.g., after reinstall when prefs are gone).
  static ModelInfo? findByFileName(String fileName) {
    try {
      return all.firstWhere((m) => m.fileName.toLowerCase() == fileName.toLowerCase());
    } catch (_) {
      return null;
    }
  }
}

extension _FirstWhereOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
