import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/voice/engines/android_voice_engine.dart';
import '../../../core/voice/voice_service.dart';

typedef VoiceResultCallback = void Function(String text);

mixin VoiceMixin<T extends StatefulWidget> on State<T> {
  final VoiceService _voiceService = AndroidVoiceEngine();
  VoiceState _voiceState = VoiceState.idle;
  bool _voiceEnabled = false;
  StreamSubscription? _voiceResultSub;
  StreamSubscription? _voiceErrorSub;

  VoiceState get voiceMixinState => _voiceState;
  bool get voiceMixinEnabled => _voiceEnabled;

  Future<void> initVoice(VoiceResultCallback onResult) async {
    await _voiceService.initialize();
    final available = await _voiceService.isSpeechAvailable;
    if (!mounted) return;
    setState(() => _voiceEnabled = available);
    if (available) {
      _voiceResultSub = _voiceService.onResult.listen((result) {
        if (!mounted || result.isPartial || result.text.isEmpty) return;
        setState(() {
          _voiceState = VoiceState.idle;
        });
        onResult(result.text);
      });
      _voiceErrorSub = _voiceService.onError.listen((_) {
        if (mounted) setState(() => _voiceState = VoiceState.idle);
      });
    }
  }

  Future<void> toggleVoice() async {
    if (_voiceState == VoiceState.listening) {
      await _voiceService.stopListening();
      if (mounted) setState(() => _voiceState = VoiceState.idle);
    } else {
      await _voiceService.startListening(continuous: false);
      if (mounted) setState(() => _voiceState = VoiceState.listening);
    }
  }

  void disposeVoice() {
    _voiceResultSub?.cancel();
    _voiceErrorSub?.cancel();
    _voiceService.dispose();
  }
}
