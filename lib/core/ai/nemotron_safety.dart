import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';
import 'nvidia_key_manager.dart';

/// Content safety classification result.
class SafetyVerdict {
  final bool isSafe;
  final String? reason;
  final List<String> violatedCategories;

  const SafetyVerdict({
    required this.isSafe,
    this.reason,
    this.violatedCategories = const [],
  });
}

/// Nemotron Content Safety guardrail service.
///
/// Calls `nvidia/nemotron-3-nano-omni-30b-a3b-reasoning` on the
/// NVIDIA NIM OpenAI-compatible endpoint to classify whether
/// a given text is safe or violates content policies.
///
/// Usage (all roles):
/// ```dart
/// final safety = NemotronSafetyService();
/// final verdict = await safety.checkContent(userInput);
/// if (!verdict.isSafe) { /* block / warn */ }
/// ```
class NemotronSafetyService {
  final http.Client _client = http.Client();
  final NvidiaKeyManager _keyManager = NvidiaKeyManager();

  static const String _baseUrl =
      'https://integrate.api.nvidia.com/v1/chat/completions';
  static const String _model =
      'nvidia/nemotron-3-nano-omni-30b-a3b-reasoning';

  void setApiKeys(String key1, String? key2) {
    _keyManager.setUserKeys(key1, key2);
  }

  /// Check whether [text] is safe.
  /// Returns a [SafetyVerdict] with the classification result.
  Future<SafetyVerdict> checkContent(String text) async {
    final key = _keyManager.activeKey ?? ApiKeys.nvidiaKey1;
    if (key.isEmpty) {
      return const SafetyVerdict(isSafe: true, reason: 'No API key configured');
    }

    final body = {
      'model': _model,
      'messages': [
        {
          'role': 'user',
          'content':
              'You are a relaxed content moderator. Only flag as UNSAFE if the '
              'content contains: hate speech, explicit threats of violence, '
              'promotion of self-harm, or illegal activity. Be tolerant of mild '
              'language, opinions, roleplay, educational topics, jokes, and '
              'normal conversation. When in doubt, mark safe.\n\n'
              'Respond with strict JSON only: '
              '{"safe": true/false, "violated_categories": [], "reason": "..."}\n\n'
              'Content: $text',
        },
      ],
      'max_tokens': 512,
      'temperature': 0.01,
    };

    try {
      final response = await _client
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Authorization': 'Bearer $key',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final message = choices[0]['message'] as Map<String, dynamic>?;
          final content = message?['content'] as String? ?? '';
          return _parseResponse(content);
        }
      }

      if (response.statusCode == 429) {
        _keyManager.rotateOnRateLimit();
        return const SafetyVerdict(isSafe: true, reason: 'Rate limited — skipped');
      }

      return const SafetyVerdict(
        isSafe: true,
        reason: 'Safety check unavailable (HTTP ?)',
      );
    } catch (_) {
      return const SafetyVerdict(
        isSafe: true,
        reason: 'Safety check unavailable (error)',
      );
    }
  }

  SafetyVerdict _parseResponse(String content) {
    try {
      final json = jsonDecode(content) as Map<String, dynamic>;
      final safe = json['safe'] as bool? ?? true;
      final categories = (json['violated_categories'] as List<dynamic>?)
              ?.cast<String>() ??
          const <String>[];
      final reason = json['reason'] as String?;
      return SafetyVerdict(
        isSafe: safe,
        reason: reason,
        violatedCategories: categories,
      );
    } catch (_) {
      // If the model didn't return JSON, treat the raw text
      final lower = content.toLowerCase();
      final unsafe = lower.contains('unsafe') ||
          lower.contains('violation') ||
          lower.contains('harmful');
      return SafetyVerdict(
        isSafe: !unsafe,
        reason: unsafe ? content : null,
      );
    }
  }

  void dispose() {
    _client.close();
  }
}
