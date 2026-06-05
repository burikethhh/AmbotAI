import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../voice_service.dart';

/// Android implementation using SpeechRecognizer (STT) and TextToSpeech (TTS)
/// via MethodChannel.
///
/// SpeechRecognizer:
///   - Android 12+: fully on-device, works offline
///   - Android 11 and below: may require Google cloud
///
/// TextToSpeech:
///   - Uses Android's built-in TTS engine
///   - Offline voices can be downloaded in system settings
class AndroidVoiceEngine implements VoiceService {
  static const _channel = MethodChannel('ambot_ai/voice');

  VoiceState _state = VoiceState.idle;
  bool _initialized = false;
  VoiceSettings _settings = const VoiceSettings();

  final _resultController = StreamController<SpeechResult>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  @override
  VoiceState get state => _state;

  @override
  Stream<SpeechResult> get onResult => _resultController.stream;

  @override
  Stream<String> get onError => _errorController.stream;

  @override
  bool get isReady => _initialized;

  @override
  Future<bool> get isSpeechAvailable async {
    try {
      return await _channel.invokeMethod<bool>('isSpeechAvailable') ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> get isTtsAvailable async {
    try {
      return await _channel.invokeMethod<bool>('isTtsAvailable') ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> get isSpeaking async {
    try {
      return await _channel.invokeMethod<bool>('isSpeaking') ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    _channel.setMethodCallHandler(_handleMethodCall);

    try {
      await _channel.invokeMethod('initialize');
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onSpeechResult':
        final args = call.arguments as Map;
        _resultController.add(SpeechResult(
          text: args['text'] as String,
          confidence: (args['confidence'] as num?)?.toDouble() ?? 0.0,
          isPartial: args['isPartial'] as bool? ?? false,
        ));
        break;
      case 'onSpeechError':
        _errorController.add(call.arguments as String? ?? 'Unknown error');
        break;
      case 'onStateChanged':
        final stateName = call.arguments as String?;
        switch (stateName) {
          case 'idle':
            _state = VoiceState.idle;
            break;
          case 'listening':
            _state = VoiceState.listening;
            break;
          case 'recognizing':
            _state = VoiceState.recognizing;
            break;
          case 'done':
            _state = VoiceState.done;
            break;
          case 'error':
            _state = VoiceState.error;
            break;
        }
        break;
    }
  }

  @override
  Future<SpeechResult> listenOnce({Duration? timeout}) async {
    final completer = Completer<SpeechResult>();
    SpeechResult? finalResult;

    final sub = onResult.listen((result) {
      if (!result.isPartial) {
        finalResult = result;
        if (!completer.isCompleted) completer.complete(result);
      }
    });

    await startListening(continuous: false);

    if (timeout != null) {
      await Future.delayed(timeout);
      if (!completer.isCompleted) {
        await stopListening();
        completer.complete(
          finalResult ?? const SpeechResult(text: ''),
        );
      }
    }

    final result = await completer.future;
    sub.cancel();
    return result;
  }

  @override
  Future<void> startListening({bool continuous = false}) async {
    try {
      await _channel.invokeMethod('startListening', {
        'continuous': continuous,
        'language': _settings.language,
        'offlineOnly': _settings.offlineOnly,
      });
    } catch (e) {
      _errorController.add('Failed to start listening: $e');
    }
  }

  @override
  Future<void> stopListening() async {
    try {
      await _channel.invokeMethod('stopListening');
    } catch (e) {
      debugPrint('VOICE_ENGINE: stopListening failed: $e');
    }
  }

  @override
  Future<void> cancel() async {
    try {
      await _channel.invokeMethod('cancelListening');
    } catch (e) {
      debugPrint('VOICE_ENGINE: cancel failed: $e');
    }
  }

  @override
  Future<void> speak(String text) async {
    try {
      await _channel.invokeMethod('speak', {
        'text': text,
        'rate': _settings.speechRate,
        'pitch': _settings.pitch,
      });
    } catch (e) {
      _errorController.add('Failed to speak: $e');
    }
  }

  @override
  Future<void> stopSpeaking() async {
    try {
      await _channel.invokeMethod('stopSpeaking');
    } catch (e) {
      debugPrint('VOICE_ENGINE: stopSpeaking failed: $e');
    }
  }

  @override
  Future<void> applySettings(VoiceSettings settings) async {
    _settings = settings;
    try {
      await _channel.invokeMethod('applySettings', {
        'language': settings.language,
        'speechRate': settings.speechRate,
        'pitch': settings.pitch,
        'offlineOnly': settings.offlineOnly,
      });
    } catch (e) {
      debugPrint('VOICE_ENGINE: applySettings failed: $e');
    }
  }

  @override
  Future<void> dispose() async {
    await stopListening();
    await stopSpeaking();
    try {
      await _channel.invokeMethod('dispose');
    } catch (e) {
      debugPrint('VOICE_ENGINE: dispose failed: $e');
    }
    _resultController.close();
    _errorController.close();
    _initialized = false;
  }
}
