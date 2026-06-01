import '../ai/engines/openai_engine.dart';
import '../config/api_keys.dart';

class ImagePromptEnhancer {
  OpenAIEngine? _engine;

  void initialize({String? userNvidiaKey}) {
    final key = userNvidiaKey ?? ApiKeys.nvidiaKey1;
    if (key.isNotEmpty) {
      _engine = OpenAIEngine.nvidia(apiKey: key);
      _engine!.initialize();
    }
  }

  Future<String> enhance(String prompt) async {
    if (_engine == null || prompt.isEmpty) return prompt;
    try {
      final enhanced = await _engine!.generate(
        prompt,
        systemPrompt: _systemPrompt,
      );
      final trimmed = enhanced.trim();
      return trimmed.isNotEmpty ? trimmed : prompt;
    } catch (_) {
      return prompt;
    }
  }

  static const _systemPrompt =
    'You are an expert at writing image generation prompts. '
    'Enhance the short user description into a detailed, vivid prompt '
    'for AI image generation. Add visual details about lighting, '
    'composition, colors, textures, and mood. Keep it to 2-3 sentences. '
    'Return ONLY the enhanced prompt with no explanations, quotes, or prefixes.';

  void dispose() {
    _engine?.dispose();
    _engine = null;
  }
}
