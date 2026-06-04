import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class SdServerClient {
  static const MethodChannel _pluginChannel = MethodChannel('com.ambot.ambot_ai/sd_server');

  final http.Client _httpClient = http.Client();
  String? _baseUrl;
  bool _started = false;

  bool get isRunning => _started;

  Future<void> start({required String modelPath}) async {
    if (_started) return;

    final result = await _pluginChannel.invokeMethod('start', {
      'modelPath': modelPath,
    });

    if (result == null) {
      throw Exception('Failed to start sd-server: null response');
    }

    final data = Map<String, dynamic>.from(result);
    if (data['success'] != true) {
      throw Exception('Failed to start sd-server: ${data['error']}');
    }

    _baseUrl = data['url'] as String?;
    if (_baseUrl == null) {
      throw Exception('Failed to start sd-server: no URL returned');
    }

    _started = true;
  }

  Future<void> stop() async {
    _started = false;
    _baseUrl = null;
    _httpClient.close();
    try {
      await _pluginChannel.invokeMethod('stop');
    } catch (_) {}
  }

  Future<Map<String, dynamic>> getCapabilities() async {
    if (_baseUrl == null) throw Exception('SD server not started');
    final response = await _httpClient.get(Uri.parse('$_baseUrl/sdcpp/v1/capabilities'));
    if (response.statusCode != 200) {
      throw Exception('Failed to get capabilities: ${response.statusCode}');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  Future<String> generate({
    required String prompt,
    String? negativePrompt,
    int width = 512,
    int height = 512,
    int steps = 4,
    double guidanceScale = 7.0,
    int seed = -1,
    required String cancelToken,
  }) async {
    if (_baseUrl == null) throw StateError('Server not started');

    final body = {
      'prompt': prompt,
      'negative_prompt': negativePrompt ?? '',
      'width': width,
      'height': height,
      'sample_params': {
        'sample_steps': steps,
        'guidance': {
          'txt_cfg': guidanceScale,
        },
      },
      'seed': seed,
      'batch_count': 1,
      'output_format': 'png',
      'output_compression': 100,
    };

    final submitResponse = await _httpClient.post(
      Uri.parse('$_baseUrl/sdcpp/v1/img_gen'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (submitResponse.statusCode != 202) {
      final errBody = submitResponse.body.isNotEmpty ? submitResponse.body : 'status ${submitResponse.statusCode}';
      throw Exception('Failed to submit generation job: $errBody');
    }

    final submitData = json.decode(submitResponse.body) as Map<String, dynamic>;
    final jobId = submitData['id'] as String;

    final deadline = DateTime.now().add(const Duration(minutes: 5));
    while (DateTime.now().isBefore(deadline)) {
      if (cancelToken == 'cancelled') {
        await _cancelJob(jobId);
        throw JobCancelledException();
      }

      final pollResponse = await _httpClient.get(
        Uri.parse('$_baseUrl/sdcpp/v1/jobs/$jobId'),
      );

      if (pollResponse.statusCode != 200) {
        throw Exception('Failed to poll job: ${pollResponse.statusCode}');
      }

      final pollData = json.decode(pollResponse.body) as Map<String, dynamic>;
      final status = pollData['status'] as String;

      switch (status) {
        case 'completed':
          final resultData = pollData['result'] as Map<String, dynamic>;
          final images = resultData['images'] as List<dynamic>;
          if (images.isEmpty) throw Exception('No images in result');
          final imageData = images[0] as Map<String, dynamic>;
          final b64 = imageData['b64_json'] as String;
          return await _saveBase64Image(b64);
        case 'failed':
          final errorData = pollData['error'] as Map<String, dynamic>?;
          final message = errorData?['message'] as String? ?? 'Unknown error';
          throw Exception('Generation failed: $message');
        case 'cancelled':
          throw JobCancelledException();
        case 'queued':
        case 'generating':
          await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    throw TimeoutException('Image generation timed out after 5 minutes');
  }

  Future<void> _cancelJob(String jobId) async {
    try {
      await _httpClient.post(
        Uri.parse('$_baseUrl/sdcpp/v1/jobs/$jobId/cancel'),
      );
    } catch (_) {}
  }

  Future<String> _saveBase64Image(String b64) async {
    final bytes = base64.decode(b64);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/sd_gen_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}

class JobCancelledException implements Exception {
  @override
  String toString() => 'Job was cancelled';
}
