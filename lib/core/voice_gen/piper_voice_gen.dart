import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'voice_gen_engine.dart';

class PiperVoiceGen implements VoiceGenEngine {
  static const MethodChannel _channel = MethodChannel('com.ambot.ambot_ai/voice_gen');

  bool _isReady = false;
  String? _currentVoicePath;
  String? _currentConfigPath;
  final List<String> _voices = [];

  /// Set the downloaded voice model files before generate.
  void setVoiceModel(String onnxPath, {String? configPath}) {
    _currentVoicePath = onnxPath;
    _currentConfigPath = configPath;
    final name = onnxPath.split(Platform.pathSeparator).last.replaceAll('.onnx', '');
    if (!_voices.contains(name)) {
      _voices.add(name);
    }
  }

  @override
  Future<void> initialize() async {
    _isReady = true;
  }

  @override
  Future<String> generate(String text, {String? voiceId, double? rate, double? pitch}) async {
    if (_currentVoicePath == null) {
      return '';
    }
    try {
      final result = await _channel.invokeMethod('synthesize', {
        'text': text,
        'modelPath': _currentVoicePath,
        'configPath': _currentConfigPath,
        'rate': rate,
        'pitch': pitch,
      });
      if (result != null) {
        final data = Map<String, dynamic>.from(result);
        return data['path'] as String? ?? '';
      }
    } catch (e) {
      debugPrint('VOICE_GEN: generate failed: $e');
    }
    return '';
  }

  @override
  Future<void> dispose() async {
    try {
      await _channel.invokeMethod('dispose');
    } catch (_) {}
    _isReady = false;
  }

  @override
  String get engineName => 'Android TTS';

  @override
  bool get isReady => _isReady && _currentVoicePath != null;

  @override
  List<String> get availableVoices => List.unmodifiable(_voices);
}

class AudioPlaybackService {
  static const MethodChannel _channel = MethodChannel('com.ambot.ambot_ai/audio_playback');

  static Future<void> play(String filePath) async {
    try {
      await _channel.invokeMethod('play', {'path': filePath});
    } catch (_) {}
  }

  static Future<void> stop() async {
    try {
      await _channel.invokeMethod('stop');
    } catch (_) {}
  }

  static Future<bool> isPlaying() async {
    try {
      final result = await _channel.invokeMethod('isPlaying');
      return result == true;
    } catch (_) {
      return false;
    }
  }
}
