import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../ai_engine.dart';

/// OpenAI-compatible cloud engine.
/// Works with OpenAI, OpenRouter, NVIDIA, and any API that follows the
/// OpenAI chat completions format.
class OpenAIEngine implements AIEngine {
  final String apiKey;
  final String baseUrl;
  final String model;
  final String _label;
  final Map<String, String> _extraHeaders;
  final int maxTokens;
  bool _isReady = false;
  late final http.Client _client;

  OpenAIEngine({
    required this.apiKey,
    this.baseUrl = 'https://api.openai.com/v1/chat/completions',
    this.model = 'gpt-4o-mini',
    this.maxTokens = 2048,
    String? label,
    Map<String, String>? extraHeaders,
  })  : _label = label ?? 'OpenAI ($model)',
        _extraHeaders = extraHeaders ?? {},
        _client = http.Client();

  /// Pre-configured for OpenRouter.
  factory OpenAIEngine.openRouter({
    required String apiKey,
    String model = 'meta-llama/llama-3.1-8b-instruct:free',
  }) {
    return OpenAIEngine(
      apiKey: apiKey,
      baseUrl: 'https://openrouter.ai/api/v1/chat/completions',
      model: model,
      label: 'OpenRouter ($model)',
      extraHeaders: {
        'HTTP-Referer': 'https://ambot-ai.app',
        'X-Title': 'Ambot AI',
      },
    );
  }

  /// Pre-configured for Qwen via DashScope (OpenAI-compatible).
  factory OpenAIEngine.qwen({
    required String apiKey,
    String model = 'qwen-turbo',
  }) {
    return OpenAIEngine(
      apiKey: apiKey,
      baseUrl:
          'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions',
      model: model,
      label: 'Qwen ($model)',
    );
  }

  /// Pre-configured for NVIDIA build.nvidia.com (OpenAI-compatible).
  factory OpenAIEngine.nvidia({
    required String apiKey,
    String model = 'meta/llama-3.1-8b-instruct',
  }) {
    return OpenAIEngine(
      apiKey: apiKey,
      baseUrl: 'https://integrate.api.nvidia.com/v1/chat/completions',
      model: model,
      label: 'NVIDIA ($model)',
    );
  }

  @override
  Future<void> initialize() async {
    _isReady = apiKey.isNotEmpty;
  }

  @override
  Future<String> generate(String prompt, {String? systemPrompt, List<MessageEntry>? history}) async {
    final body = _buildRequestBody(prompt, systemPrompt, history: history, stream: false);

    final response = await _client
        .post(Uri.parse(baseUrl),
            headers: _buildHeaders(), body: jsonEncode(body))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('API error ${response.statusCode}: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return _extractText(json);
  }

  @override
  Stream<String> generateStream(String prompt, {String? systemPrompt, List<MessageEntry>? history}) async* {
    final body = _buildRequestBody(prompt, systemPrompt, history: history, stream: true);

    final request =
        http.Request('POST', Uri.parse(baseUrl))
          ..headers.addAll(_buildHeaders())
          ..body = jsonEncode(body);

    final streamedResponse =
        await _client.send(request).timeout(const Duration(seconds: 30));

    if (streamedResponse.statusCode != 200) {
      final errorBody = await streamedResponse.stream.bytesToString();
      throw Exception('API error ${streamedResponse.statusCode}: $errorBody');
    }

    // Parse SSE stream
    final lineStream =
        streamedResponse.stream.transform(utf8.decoder);
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
  }

  Map<String, String> _buildHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
      ..._extraHeaders,
    };
  }

  @override
  Future<void> dispose() async {
    _client.close();
  }

  @override
  Future<void> handleMemoryPressure() async {} // no-op for cloud

  @override
  String get engineName => _label;

  @override
  DeviceTier get tier => DeviceTier.flagship;

  @override
  bool get isReady => _isReady;

  Map<String, dynamic> _buildRequestBody(
    String prompt,
    String? systemPrompt, {
    List<MessageEntry>? history,
    required bool stream,
  }) {
    final messages = <Map<String, dynamic>>[];

    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }

    if (history != null && history.isNotEmpty) {
      for (final entry in history) {
        messages.add({'role': entry.role, 'content': entry.content});
      }
    }

    messages.add({'role': 'user', 'content': prompt});

    return {
      'model': model,
      'messages': messages,
      'temperature': 0.7,
      'max_tokens': maxTokens,
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
