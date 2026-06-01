import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/voice/voice_service.dart';
import '../../core/voice/engines/android_voice_engine.dart';
import '../../core/voice_gen/piper_voice_gen.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/theme/theme_colors.dart';
import '../../shared/widgets/app_icon.dart';
import 'widgets/voice_app_bar.dart';
import 'widgets/voice_controls.dart';
import 'widgets/voice_output_list.dart';
import 'widgets/voice_status_panel.dart';
import 'widgets/voice_settings_panel.dart';

class VoiceGenScreen extends ConsumerStatefulWidget {
  const VoiceGenScreen({super.key});

  @override
  ConsumerState<VoiceGenScreen> createState() => _VoiceGenScreenState();
}

class _VoiceGenScreenState extends ConsumerState<VoiceGenScreen> {
  final _textController = TextEditingController();
  late PiperVoiceGen _engine;
  late VoiceService _voiceService;
  bool _isGenerating = false;
  bool _isPlaying = false;
  String? _generatedAudioPath;
  String? _error;
  bool _showSettings = false;
  bool _useDirectTts = false;

  String? _aiProcessedText;
  bool _isPreprocessing = false;
  bool _useAiVersion = true;
  String? _detectedEmotion;

  double _speechRate = 1.0;
  double _pitch = 1.0;
  bool _aiEmotion = false;
  bool _aiPunctuation = true;

  static const _emotionColors = {
    'happy': Color(0xFFFFD700),
    'excited': Color(0xFFFF8C00),
    'sad': Color(0xFF6A85FF),
    'angry': Color(0xFFFF4444),
    'calm': Color(0xFF00CED1),
    'serious': Color(0xFF808080),
    'whisper': Color(0xFFB0B0B0),
    'neutral': Colors.white,
  };

  @override
  void initState() {
    super.initState();
    _engine = PiperVoiceGen();
    _voiceService = AndroidVoiceEngine();
    _engine.initialize().then((_) {
      if (mounted) setState(() {});
    }).catchError((_) {
      // Engine init failed — UI will show disabled state
    });
    _voiceService.initialize().then((_) {
      _voiceService.isTtsAvailable.then((available) {
        if (mounted) setState(() => _useDirectTts = available);
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _engine.dispose();
    super.dispose();
  }

  void _loadVoiceModel() {
    final voiceState = ref.read(voiceModelManagerProvider);
    if (voiceState.isReady && voiceState.onnxPath != null) {
      _engine.setVoiceModel(voiceState.onnxPath!, configPath: voiceState.configPath);
    }
  }

  Future<String> _preprocessWithAI(String text) async {
    final engine = ref.read(aiEngineProvider);

    final parts = <String>[];
    if (_aiPunctuation) parts.add('Add punctuation. Fix sentence breaks.');
    if (_aiEmotion) parts.add('Tag overall mood: [happy], [sad], [angry], [calm], [excited], [serious], [whisper], [neutral]. Use punctuation for emotion (! ? ...)');

    final prompt = 'Improve for TTS. ${parts.join(' ')}\n\n$text';

    try {
      return await engine.generate(
        prompt,
        systemPrompt: 'Output ONLY the improved text.',
      ).timeout(const Duration(seconds: 45));
    } catch (_) {
      return text;
    }
  }

  Future<void> _previewAi() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isPreprocessing = true;
      _error = null;
      _aiProcessedText = null;
      _detectedEmotion = null;
    });

    final processed = await _preprocessWithAI(text);
    if (!mounted) return;

    final emotionMatch = RegExp(r'\[(happy|sad|angry|calm|excited|serious|whisper|neutral)\]', caseSensitive: false).firstMatch(processed);
    final emotion = emotionMatch?.group(1)?.toLowerCase();

    setState(() {
      _aiProcessedText = processed;
      _detectedEmotion = emotion;
      _isPreprocessing = false;
      _useAiVersion = true;
    });
  }

  String _stripEmotionMarkers(String text) {
    return text.replaceAll(RegExp(r'\[(happy|sad|angry|calm|excited|serious|neutral|whisper|shout)\]', caseSensitive: false), '').trim();
  }

  double _emotionPitch(String? emotion) {
    return switch (emotion) {
      'happy' || 'excited' => 1.3,
      'sad' => 0.8,
      'angry' || 'shout' => 1.2,
      'calm' || 'serious' => 0.9,
      'whisper' => 0.7,
      _ => _pitch,
    };
  }

  double _emotionRate(String? emotion) {
    return switch (emotion) {
      'happy' || 'excited' => 1.2,
      'sad' => 0.85,
      'angry' || 'shout' => 1.15,
      'calm' || 'serious' => 0.9,
      'whisper' => 0.75,
      _ => _speechRate,
    };
  }

  Future<void> _generate() async {
    final voiceState = ref.read(voiceModelManagerProvider);
    setState(() {
      _isGenerating = true;
      _error = null;
      _generatedAudioPath = null;
    });

    try {
      final rawText = _textController.text.trim();
      final useAi = (_aiEmotion || _aiPunctuation) && _aiProcessedText != null && _useAiVersion;
      final sourceText = useAi ? _aiProcessedText! : rawText;

      final emotion = useAi ? _detectedEmotion : null;
      final effectivePitch = emotion != null ? _emotionPitch(emotion) : _pitch;
      final effectiveRate = emotion != null ? _emotionRate(emotion) : _speechRate;

      final cleanText = emotion != null ? _stripEmotionMarkers(sourceText) : sourceText;

      if (cleanText.trim().isEmpty) {
        setState(() => _error = 'No text to synthesize. Enter some text first.');
        return;
      }

      // Try Piper native TTS first
      if (voiceState.isReady && voiceState.onnxPath != null) {
        _loadVoiceModel();
        final audioPath = await _engine.generate(cleanText, rate: effectiveRate, pitch: effectivePitch);
        if (audioPath.isNotEmpty) {
          setState(() => _generatedAudioPath = audioPath);
          return;
        }
      }

      // Fallback: use Android built-in TTS via VoiceService
      if (_useDirectTts) {
        await _voiceService.speak(cleanText);
        setState(() {
          _isPlaying = true;
          _error = null;
        });
        // Poll until done
        await Future.delayed(const Duration(milliseconds: 500));
        while (mounted) {
          final speaking = await _voiceService.isSpeaking;
          if (!speaking) break;
          await Future.delayed(const Duration(milliseconds: 200));
        }
        if (mounted) setState(() => _isPlaying = false);
      } else {
        setState(() => _error = 'No voice model available. Download one in Models, or check that device TTS is enabled.');
      }
    } catch (e) {
      setState(() => _error = 'Generation failed: $e');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _play() async {
    if (_generatedAudioPath == null) {
      // Fallback: speak directly
      if (_useDirectTts) {
        setState(() => _isPlaying = true);
        await _voiceService.speak(_textController.text.trim());
        await Future.delayed(const Duration(milliseconds: 500));
        while (mounted) {
          final speaking = await _voiceService.isSpeaking;
          if (!speaking) break;
          await Future.delayed(const Duration(milliseconds: 200));
        }
        if (mounted) setState(() => _isPlaying = false);
      }
      return;
    }
    setState(() => _isPlaying = true);
    await AudioPlaybackService.play(_generatedAudioPath!);
    setState(() => _isPlaying = false);
  }

  Future<void> _stopPlayback() async {
    await AudioPlaybackService.stop();
    await _voiceService.stopSpeaking();
    setState(() => _isPlaying = false);
  }

  int _wordCount(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(themeColorsProvider);
    final voiceState = ref.watch(voiceModelManagerProvider);

    final wordCount = _wordCount(_textController.text);
    final charCount = _textController.text.length;
    final hasAiPreview = _aiProcessedText != null;
    final aiEnabled = _aiEmotion || _aiPunctuation;

    return Scaffold(
      appBar: VoiceAppBar(
        showSettings: _showSettings,
        onToggleSettings: () => setState(() => _showSettings = !_showSettings),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VoiceStatusPanel(
                    error: _error,
                    hasAiPreview: hasAiPreview,
                    aiProcessedText: _aiProcessedText,
                    detectedEmotion: _detectedEmotion,
                    useAiVersion: _useAiVersion,
                    onUseAiVersionChanged: (v) => setState(() => _useAiVersion = v),
                    originalText: _textController.text.trim(),
                  ),
                  const SizedBox(height: 16),
                  VoiceControls(
                    controller: _textController,
                    wordCount: wordCount,
                    charCount: charCount,
                    aiEnabled: aiEnabled,
                    isPreprocessing: _isPreprocessing,
                    isGenerating: _isGenerating,
                    voiceReady: voiceState.isReady,
                    onTextChanged: (_) {
                      setState(() {
                        _aiProcessedText = null;
                        _detectedEmotion = null;
                      });
                    },
                    onPreviewAi: _previewAi,
                    onGenerate: _generate,
                    onClear: () {
                      _textController.clear();
                      setState(() {
                        _aiProcessedText = null;
                        _detectedEmotion = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_showSettings)
                    VoiceSettingsPanel(
                      speechRate: _speechRate,
                      pitch: _pitch,
                      aiPunctuation: _aiPunctuation,
                      aiEmotion: _aiEmotion,
                      onSpeechRateChanged: (v) => setState(() => _speechRate = v),
                      onPitchChanged: (v) => setState(() => _pitch = v),
                      onAiPunctuationChanged: (v) {
                        setState(() {
                          _aiPunctuation = v;
                          _aiProcessedText = null;
                          _detectedEmotion = null;
                        });
                      },
                      onAiEmotionChanged: (v) {
                        setState(() {
                          _aiEmotion = v;
                          _aiProcessedText = null;
                          _detectedEmotion = null;
                        });
                      },
                    ),
                  const SizedBox(height: 12),
                  VoiceOutputList(
                    generatedAudioPath: _generatedAudioPath,
                    isPlaying: _isPlaying,
                    detectedEmotion: _detectedEmotion,
                    useAiVersion: _useAiVersion,
                    emotionPitch: _detectedEmotion != null ? _emotionPitch(_detectedEmotion) : _pitch,
                    emotionRate: _detectedEmotion != null ? _emotionRate(_detectedEmotion) : _speechRate,
                    emotionColor: _detectedEmotion != null
                        ? (_emotionColors[_detectedEmotion] ?? AppColors.accent(c.isDark))
                        : null,
                    onPlay: _play,
                    onStop: _stopPlayback,
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.borderColor, width: 2)),
            ),
            child: Row(
              children: [
                AppIcon(icon: Icons.info_outline, iconColor: c.textTertiary, backgroundColor: Colors.transparent, size: 14),
                const SizedBox(width: 8),
                Text('Android TTS · Offline', style: AppTypography.bodySmall(c.textTertiary)),
                const Spacer(),
                if (hasAiPreview && _useAiVersion)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.accent(c.isDark), width: 1),
                    ),
                    child: Text(
                      'AI ENHANCED',
                      style: AppTypography.labelMicro(AppColors.accent(c.isDark)).copyWith(letterSpacing: 1),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
