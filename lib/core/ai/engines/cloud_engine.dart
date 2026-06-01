import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../ai_engine.dart';

class CloudEngine implements AIEngine {
  final String apiKey;
  bool _isReady = false;
  HttpClient? _client;

  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const _model = 'gemini-2.0-flash-lite';

  CloudEngine({required this.apiKey});

  @override
  Future<void> initialize() async {
    _isReady = apiKey.isNotEmpty;
    _client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10)
      ..idleTimeout = const Duration(seconds: 30);
  }

  @override
  Future<String> generate(String prompt, {String? systemPrompt, List<MessageEntry>? history}) async {
    final body = _buildRequestBody(prompt, systemPrompt);
    final url = '$_baseUrl/$_model:generateContent';
    final client = _client;

    final request = await client!.postUrl(Uri.parse(url));
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('x-goog-api-key', apiKey);
    request.write(jsonEncode(body));

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode != 200) {
      throw Exception('Gemini API error ${response.statusCode}: $responseBody');
    }

    final json = jsonDecode(responseBody) as Map<String, dynamic>;
    return _extractText(json);
  }

  @override
  Stream<String> generateStream(String prompt, {String? systemPrompt, List<MessageEntry>? history}) async* {
    final body = _buildRequestBody(prompt, systemPrompt);
    final url = '$_baseUrl/$_model:streamGenerateContent?alt=sse';
    final client = _client;

    final request = await client!.postUrl(Uri.parse(url));
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('x-goog-api-key', apiKey);
    request.write(jsonEncode(body));

    final response = await request.close();

    if (response.statusCode != 200) {
      final errorBody = await response.transform(utf8.decoder).join();
      throw Exception('Gemini API error ${response.statusCode}: $errorBody');
    }

      // Parse SSE stream
      final lineStream = response.transform(utf8.decoder);
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
              final text = _extractText(json);
              if (text.isNotEmpty) {
                yield text;
              }
            } catch (_) {
              // Skip malformed chunks
            }
          }
      }
    }
  }

  @override
  Future<void> dispose() async {
    _client?.close();
  }

  @override
  Future<void> handleMemoryPressure() async {} // no-op for cloud

  @override
  String get engineName => 'Gemini Cloud ($_model)';

  @override
  DeviceTier get tier => DeviceTier.flagship;

  @override
  bool get isReady => _isReady;

  Map<String, dynamic> _buildRequestBody(String prompt, String? systemPrompt) {
    final contents = <Map<String, dynamic>>[];

    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      contents.add({
        'role': 'user',
        'parts': [
          {'text': systemPrompt}
        ],
      });
      contents.add({
        'role': 'model',
        'parts': [
          {'text': 'Understood. I will follow those instructions.'}
        ],
      });
    }

    contents.add({
      'role': 'user',
      'parts': [
        {'text': prompt}
      ],
    });

    return {
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 2048,
        'topP': 0.95,
        'topK': 40,
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_ONLY_HIGH',
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_ONLY_HIGH',
        },
        {
          'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
          'threshold': 'BLOCK_ONLY_HIGH',
        },
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_ONLY_HIGH',
        },
      ],
    };
  }

  String _extractText(Map<String, dynamic> json) {
    try {
      final candidates = json['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return '';

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      if (content == null) return '';

      final parts = content['parts'] as List?;
      if (parts == null || parts.isEmpty) return '';

      return parts[0]['text'] as String? ?? '';
    } catch (_) {
      return '';
    }
  }
}
