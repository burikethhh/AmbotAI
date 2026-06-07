import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../ai_engine.dart';

class CloudEngine implements AIEngine {
  final String apiKey;
  bool _isReady = false;

  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/openai';
  static const _model = 'gemini-2.0-flash-lite';

  CloudEngine({required this.apiKey});

  @override
  Future<void> initialize() async {
    _isReady = apiKey.isNotEmpty;
  }

  @override
  Future<String> generate(String prompt, {String? systemPrompt, List<MessageEntry>? history}) async {
    final body = _buildRequestBody(prompt, systemPrompt: systemPrompt, history: history, stream: false);

    final response = await http
        .post(
          Uri.parse('$_baseUrl/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('API error ${response.statusCode}: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return _extractText(json);
  }

  @override
  Stream<String> generateStream(String prompt, {String? systemPrompt, List<MessageEntry>? history}) async* {
    final body = _buildRequestBody(prompt, systemPrompt: systemPrompt, history: history, stream: true);

    final client = http.Client();
    http.StreamedResponse? streamedResponse;
    try {
      final request = http.Request('POST', Uri.parse('$_baseUrl/chat/completions'))
        ..headers['Content-Type'] = 'application/json'
        ..headers['Authorization'] = 'Bearer $apiKey'
        ..body = jsonEncode(body);

      streamedResponse = await client.send(request).timeout(const Duration(seconds: 30));

      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        throw Exception('API error ${streamedResponse.statusCode}: $errorBody');
      }

      final lineStream = streamedResponse.stream.transform(utf8.decoder);
      String buffer = '';

      await for (final chunk in lineStream) {
        buffer += chunk;

        while (buffer.contains('\n')) {
          final newlineIndex = buffer.indexOf('\n');
          final line = buffer.substring(0, newlineIndex).trim();
          buffer = buffer.substring(newlineIndex + 1);

          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') return;

            try {
              final json = jsonDecode(data) as Map<String, dynamic>;
              final choices = json['choices'] as List?;
              if (choices != null && choices.isNotEmpty) {
                final delta = choices[0]['delta'] as Map<String, dynamic>?;
                final content = delta?['content'] as String?;
                if (content != null && content.isNotEmpty) {
                  yield content;
                }
              }
            } catch (_) {
              // Skip malformed chunks
            }
          }
        }
      }
    } finally {
      client.close();
    }
  }

  @override
  Future<void> dispose() async {}

  @override
  void cancelStream() {}

  @override
  Future<void> handleMemoryPressure() async {}

  @override
  String get engineName => 'Gemini Cloud ($_model)';

  @override
  DeviceTier get tier => DeviceTier.flagship;

  @override
  bool get isReady => _isReady;

  Map<String, dynamic> _buildRequestBody(
    String prompt, {
    String? systemPrompt,
    List<MessageEntry>? history,
    required bool stream,
  }) {
    final messages = <Map<String, dynamic>>[];

    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }

    if (history != null) {
      for (final entry in history) {
        final role = entry.role == 'ai' ? 'assistant' : entry.role;
        messages.add({'role': role, 'content': entry.content});
      }
    }

    messages.add({'role': 'user', 'content': prompt});

    return {
      'model': _model,
      'messages': messages,
      'temperature': 0.7,
      'max_tokens': 2048,
      'stream': stream,
    };
  }

  String _extractText(Map<String, dynamic> json) {
    try {
      final choices = json['choices'] as List?;
      if (choices == null || choices.isEmpty) return '';
      final message = choices[0]['message'] as Map<String, dynamic>?;
      return message?['content'] as String? ?? '';
    } catch (_) {
      return '';
    }
  }
}
