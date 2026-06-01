/// Voice state for the speech recognition pipeline.
enum VoiceState {
  /// Not listening. Idle.
  idle,

  /// Microphone is active, waiting for speech.
  listening,

  /// Speech detected, processing audio.
  recognizing,

  /// Recognition complete, result available.
  done,

  /// Error occurred during recognition.
  error,
}

/// Result from speech recognition.
class SpeechResult {
  /// The recognized text.
  final String text;

  /// Confidence score (0.0 to 1.0).
  final double confidence;

  /// Whether this is a partial (in-progress) result.
  final bool isPartial;

  /// All alternative hypotheses.
  final List<String> alternatives;

  const SpeechResult({
    required this.text,
    this.confidence = 0.0,
    this.isPartial = false,
    this.alternatives = const [],
  });

  @override
  String toString() => 'SpeechResult("$text", confidence: $confidence)';
}

/// Voice settings for TTS customization.
class VoiceSettings {
  /// Language code (e.g., "en-US", "fil-PH").
  final String language;

  /// Speech rate (0.5 = slow, 1.0 = normal, 2.0 = fast).
  final double speechRate;

  /// Pitch (0.5 = low, 1.0 = normal, 2.0 = high).
  final double pitch;

  /// Whether to use offline voice data only.
  final bool offlineOnly;

  /// Whether Ambot speaks action confirmations and results.
  final bool voiceFeedback;

  const VoiceSettings({
    this.language = 'en-US',
    this.speechRate = 1.0,
    this.pitch = 1.0,
    this.offlineOnly = false,
    this.voiceFeedback = true,
  });

  VoiceSettings copyWith({
    String? language,
    double? speechRate,
    double? pitch,
    bool? offlineOnly,
    bool? voiceFeedback,
  }) {
    return VoiceSettings(
      language: language ?? this.language,
      speechRate: speechRate ?? this.speechRate,
      pitch: pitch ?? this.pitch,
      offlineOnly: offlineOnly ?? this.offlineOnly,
      voiceFeedback: voiceFeedback ?? this.voiceFeedback,
    );
  }

  Map<String, dynamic> toJson() => {
        'language': language,
        'speechRate': speechRate,
        'pitch': pitch,
        'offlineOnly': offlineOnly,
        'voiceFeedback': voiceFeedback,
      };

  factory VoiceSettings.fromJson(Map<String, dynamic> json) => VoiceSettings(
        language: json['language'] as String? ?? 'en-US',
        speechRate: (json['speechRate'] as num?)?.toDouble() ?? 1.0,
        pitch: (json['pitch'] as num?)?.toDouble() ?? 1.0,
        offlineOnly: json['offlineOnly'] as bool? ?? false,
        voiceFeedback: json['voiceFeedback'] as bool? ?? true,
      );
}

/// Abstract interface for voice services (STT + TTS).
///
/// Implementations:
///   - AndroidVoiceEngine: SpeechRecognizer + TextToSpeech via MethodChannel
abstract class VoiceService {
  /// Current state of the speech recognition pipeline.
  VoiceState get state;

  /// Stream of partial and final speech results while listening.
  Stream<SpeechResult> get onResult;

  /// Stream of error messages when recognition fails.
  Stream<String> get onError;

  /// Whether the service is initialized and ready.
  bool get isReady;

  /// Whether speech recognition is available on this device.
  Future<bool> get isSpeechAvailable;

  /// Whether text-to-speech is available on this device.
  Future<bool> get isTtsAvailable;

  /// Initialize the voice service.
  Future<void> initialize();

  /// Start listening for speech. Returns when recognition is complete.
  Future<SpeechResult> listenOnce({Duration? timeout});

  /// Start continuous listening. Results stream via [onResult].
  /// Call [stopListening] to end.
  Future<void> startListening({bool continuous = false});

  /// Stop listening.
  Future<void> stopListening();

  /// Cancel the current recognition session.
  Future<void> cancel();

  /// Speak text aloud using TTS. Returns when speech is complete.
  Future<void> speak(String text);

  /// Stop any ongoing speech.
  Future<void> stopSpeaking();

  /// Check if TTS is currently speaking.
  Future<bool> get isSpeaking;

  /// Apply voice settings.
  Future<void> applySettings(VoiceSettings settings);

  /// Dispose resources.
  Future<void> dispose();
}
