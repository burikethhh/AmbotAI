enum DeviceTier { lowEnd, mid, flagship }

class MessageEntry {
  final String role;
  final String content;

  const MessageEntry({required this.role, required this.content});
}

abstract class AIEngine {
  Future<void> initialize();
  Future<String> generate(String prompt, {String? systemPrompt, List<MessageEntry>? history});
  Stream<String> generateStream(String prompt, {String? systemPrompt, List<MessageEntry>? history});
  Future<void> dispose();
  String get engineName;
  DeviceTier get tier;
  bool get isReady;

  /// Called when the OS signals low memory. Engines should free
  /// non-essential resources (KV cache, temporary buffers).
  Future<void> handleMemoryPressure() async {}
}
