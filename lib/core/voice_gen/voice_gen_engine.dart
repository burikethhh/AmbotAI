abstract class VoiceGenEngine {
  Future<void> initialize();
  Future<String> generate(String text, {String? voiceId, double? rate, double? pitch});
  Future<void> dispose();
  String get engineName;
  bool get isReady;
  List<String> get availableVoices;
}
