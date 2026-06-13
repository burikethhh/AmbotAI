import 'package:flutter_test/flutter_test.dart';
import 'package:ambot_ai/core/config/api_keys.dart';

void main() {
  group('ApiKeys (using fromEnvironment defaults)', () {
    test('hasNvidia returns false when no keys defined', () {
      expect(ApiKeys.hasNvidia, isFalse);
    });

    test('hasGemini returns false when GEMINI_KEY not defined', () {
      expect(ApiKeys.hasGemini, isFalse);
    });

    test('hasOpenRouter returns false when OPENROUTER_KEY not defined', () {
      expect(ApiKeys.hasOpenRouter, isFalse);
    });

    test('hasQwen returns false when QWEN_KEY not defined', () {
      expect(ApiKeys.hasQwen, isFalse);
    });

    test('hasHuggingFace returns false when HF_TOKEN not defined', () {
      expect(ApiKeys.hasHuggingFace, isFalse);
    });

    test('keys return empty string when not defined via --dart-define', () {
      expect(ApiKeys.geminiKey, isEmpty);
      expect(ApiKeys.openRouterKey, isEmpty);
      expect(ApiKeys.qwenKey, isEmpty);
      expect(ApiKeys.huggingFaceToken, isEmpty);
      expect(ApiKeys.nvidiaKey1, isEmpty);
      expect(ApiKeys.nvidiaKey2, isEmpty);
    });
  });
}
