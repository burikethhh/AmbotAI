import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import '../config/api_keys.dart';
import 'nvidia_key_manager.dart';

class NvidiaVisionService {
  final http.Client _client = http.Client();
  final NvidiaKeyManager _keyManager = NvidiaKeyManager.shared;

  void setApiKeys(String key1, String? key2) {
    _keyManager.setUserKeys(key1, key2);
  }

  Future<String> analyzeImage(String imagePath, {int retryCount = 0}) async {
    final key = _keyManager.activeKey ?? ApiKeys.nvidiaKey1;
    if (key.isEmpty) return '__ERROR__:No NVIDIA API key configured.';

    final file = File(imagePath);
    if (!await file.exists()) return '__ERROR__:Image file not found.';

    final bytes = await file.readAsBytes();
    final base64Image = base64Encode(bytes);
    final ext = imagePath.split('.').last.toLowerCase();
    final mimeExt = switch (ext) {
      'jpg' || 'jpeg' => 'jpeg',
      'png' => 'png',
      'gif' => 'gif',
      'webp' => 'webp',
      _ => 'png',
    };

    final body = {
      'model': 'meta/llama-3.2-11b-vision-instruct',
      'messages': [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': 'Describe this image in detail. What do you see?'},
            {'type': 'image_url', 'image_url': {'url': 'data:image/$mimeExt;base64,$base64Image'}},
          ],
        },
      ],
      'max_tokens': 1024,
    };

    try {
      final response = await _client
          .post(
            Uri.parse('https://integrate.api.nvidia.com/v1/chat/completions'),
            headers: {
              'Authorization': 'Bearer $key',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final choice = choices[0] as Map<String, dynamic>;
          final message = choice['message'] as Map<String, dynamic>?;
          if (message != null) {
            return message['content'] as String? ?? 'No description generated.';
          }
        }
      }

      if (response.statusCode == 429) {
        if (retryCount >= 1) return '__ERROR__:NVIDIA vision rate-limited. Both API keys exhausted.';
        _keyManager.rotateOnRateLimit();
        return analyzeImage(imagePath, retryCount: retryCount + 1);
      }
      return '__ERROR__:Vision analysis failed (HTTP ${response.statusCode}).';
    } catch (e) {
      return '__ERROR__:Vision analysis error: $e';
    }
  }

  Future<String> analyzeDocument(String text) async {
    final key = _keyManager.activeKey ?? ApiKeys.nvidiaKey1;
    if (key.isEmpty) return 'No NVIDIA API key configured.';

    final truncated = text.length > 8000 ? '${text.substring(0, 8000)}\n\n[...truncated]' : text;

    final body = {
      'model': 'meta/llama-3.1-8b-instruct',
      'messages': [
        {
          'role': 'user',
          'content': 'Analyze the following document content and provide a summary, '
              'key topics, and important details:\n\n$truncated',
        },
      ],
      'max_tokens': 1024,
    };

    try {
      final response = await _client
          .post(
            Uri.parse('https://integrate.api.nvidia.com/v1/chat/completions'),
            headers: {
              'Authorization': 'Bearer $key',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final choice = choices[0] as Map<String, dynamic>;
          final message = choice['message'] as Map<String, dynamic>?;
          if (message != null) {
            return message['content'] as String? ?? 'No analysis generated.';
          }
        }
      }

      if (response.statusCode == 429) {
        _keyManager.rotateOnRateLimit();
        return analyzeDocument(text);
      }
      return 'Document analysis failed (HTTP ${response.statusCode}).';
    } catch (e) {
      return 'Document analysis error: $e';
    }
  }

  void dispose() {
    _client.close();
  }
}
