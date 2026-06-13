import '../voice_service.dart';

class NullVoiceEngine implements VoiceService {
  @override
  VoiceState get state => VoiceState.idle;

  @override
  Stream<SpeechResult> get onResult => const Stream.empty();

  @override
  Stream<String> get onError => const Stream.empty();

  @override
  bool get isReady => false;

  @override
  Future<bool> get isSpeechAvailable async => false;

  @override
  Future<bool> get isTtsAvailable async => false;

  @override
  Future<void> initialize() async {}

  @override
  Future<SpeechResult> listenOnce({Duration? timeout}) async {
    return const SpeechResult(text: '', confidence: 0.0);
  }

  @override
  Future<void> startListening({bool continuous = false}) async {}

  @override
  Future<void> stopListening() async {}

  @override
  Future<void> cancel() async {}

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stopSpeaking() async {}

  @override
  Future<bool> get isSpeaking async => false;

  @override
  Future<void> applySettings(VoiceSettings settings) async {}

  @override
  Future<void> dispose() async {}
}
