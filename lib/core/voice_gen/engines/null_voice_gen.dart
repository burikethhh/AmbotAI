import '../voice_gen_engine.dart';

class NullVoiceGenEngine implements VoiceGenEngine {
  @override
  bool get isReady => false;

  @override
  String get engineName => 'Desktop TTS (not available)';

  @override
  List<String> get availableVoices => [];

  @override
  Future<void> initialize() async {}

  @override
  Future<String> generate(
    String text, {
    String? voiceId,
    double? rate,
    double? pitch,
  }) async {
    return '';
  }

  @override
  Future<void> dispose() async {}
}
