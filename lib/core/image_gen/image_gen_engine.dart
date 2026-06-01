/// Abstract interface for AI image generation engines.
///
/// Implementations can use local models (Stable Diffusion via MLC),
/// cloud APIs, or mock generators for development.
abstract class ImageGenEngine {
  /// Initialize the engine (load models, establish connections).
  Future<void> initialize();

  /// Generate an image from a text prompt.
  /// Returns the path to the generated image file.
  Future<String> generate({
    required String prompt,
    String? negativePrompt,
    int width = 512,
    int height = 512,
    int steps = 20,
    double guidanceScale = 7.5,
    int seed = -1,
  });

  /// Generate images with progress streaming.
  Stream<ImageGenProgress> generateWithProgress({
    required String prompt,
    String? negativePrompt,
    int width = 512,
    int height = 512,
    int steps = 20,
    double guidanceScale = 7.5,
    int seed = -1,
  });

  /// Dispose of resources.
  Future<void> dispose();

  /// Human-readable engine name.
  String get engineName;

  /// Whether the engine is ready to generate.
  bool get isReady;

  /// Whether this engine runs locally (no network required).
  bool get isLocal;
}

/// Progress update during image generation.
class ImageGenProgress {
  final double progress; // 0.0 to 1.0
  final String status;
  final String? imagePath; // Non-null when complete

  const ImageGenProgress({
    required this.progress,
    required this.status,
    this.imagePath,
  });

  bool get isComplete => imagePath != null;
}


