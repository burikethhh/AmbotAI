import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/image_gen/cloud_image_gen.dart';
import '../../core/image_gen/local_image_gen.dart';
import '../../core/image_gen/prompt_enhancer.dart';
import '../../core/config/api_keys.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/daily_limit_tracker.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/theme/theme_colors.dart';
import 'widgets/image_app_bar.dart';
import 'widgets/image_prompt_input.dart';
import 'widgets/image_gallery.dart';

class ImageGenScreen extends ConsumerStatefulWidget {
  const ImageGenScreen({super.key});

  @override
  ConsumerState<ImageGenScreen> createState() => _ImageGenScreenState();
}

class _ImageGenScreenState extends ConsumerState<ImageGenScreen> {
  late LocalImageGenEngine _localEngine;
  late CloudImageGenEngine _cloudEngine;
  late ImagePromptEnhancer _promptEnhancer;

  final _promptController = TextEditingController();
  bool _isGenerating = false;
  double _progress = 0.0;
  String _status = '';
  String? _generatedImagePath;
  String _source = 'local';
  int _remainingToday = 3;
  bool _enhancing = false;

  static const int _dailyImageLimit = 3;
  static final _imageLimitTracker = DailyLimitTracker('image_gen');

  @override
  void initState() {
    super.initState();
    _localEngine = LocalImageGenEngine();
    _cloudEngine = CloudImageGenEngine();
    _promptEnhancer = ImagePromptEnhancer();
    _initEngines();
    _loadDailyQuota();
  }

  Future<void> _loadDailyQuota() async {
    final remaining = await _imageLimitTracker.remaining(_dailyImageLimit);
    if (mounted) setState(() => _remainingToday = remaining);
  }

  Future<void> _initEngines() async {
    await _localEngine.initialize();
    await _cloudEngine.initialize();
    final llm = ref.read(aiEngineProvider);
    if (llm.isReady) _localEngine.setLlmEngine(llm);

    final nvidiaKey1 = ref.read(userNvidiaKeyProvider);
    final nvidiaKey2 = ref.read(userNvidiaKey2Provider);
    _cloudEngine.setNvidiaApiKeys(
      nvidiaKey1 ?? ApiKeys.nvidiaKey1,
      nvidiaKey2 ?? ApiKeys.nvidiaKey2,
    );

    final enhancerKey = nvidiaKey1 ?? ApiKeys.nvidiaKey1;
    _promptEnhancer.initialize(userNvidiaKey: enhancerKey);
  }

  @override
  void dispose() {
    _cancelled = true;
    _localEngine.cancel().ignore();
    _promptController.dispose();
    _localEngine.dispose();
    _cloudEngine.dispose();
    _promptEnhancer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(themeColorsProvider);

    return Scaffold(
      appBar: const ImageAppBar(),
      body: Column(
        children: [
          if (_enhancing)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: c.cardColor,
              child: Text('ENHANCING PROMPT...',
                style: AppTypography.labelSmall(c.textTertiary)),
            ),
          if (_source == 'cloud' && _remainingToday <= 1)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: c.isDark ? Colors.red.shade900 : Colors.red.shade50,
              child: Text('$_remainingToday cloud generation${_remainingToday == 1 ? '' : 's'} remaining today',
                style: AppTypography.labelSmall(c.isDark ? Colors.red.shade200 : Colors.red.shade800)),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_source == 'cloud')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_remainingToday < _dailyImageLimit)
                            Chip(
                              avatar: Icon(Icons.auto_awesome, size: 14, color: c.textPrimary),
                              label: Text('$_remainingToday/$_dailyImageLimit today',
                                style: AppTypography.labelSmall(c.textPrimary)),
                              backgroundColor: c.cardColor,
                              side: BorderSide.none,
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    ),
                  ImageGallery(
                    generatedImagePath: _generatedImagePath,
                    isGenerating: _isGenerating,
                    progress: _progress,
                    status: _status,
                    onRegenerate: _regenerate,
                  ),
                ],
              ),
            ),
          ),
          ImagePromptInput(
            controller: _promptController,
            isGenerating: _isGenerating,
            onGenerate: _generate,
          ),
        ],
      ),
    );
  }

  Future<void> _generate() async {
    final rawPrompt = _promptController.text.trim();
    if (rawPrompt.isEmpty) return;

    _cancelled = false;

    setState(() {
      _isGenerating = true;
      _progress = 0.0;
      _status = 'Preparing...';
      _generatedImagePath = null;
    });

    String prompt = rawPrompt;

    setState(() => _enhancing = true);
    prompt = await _promptEnhancer.enhance(rawPrompt);
    if (mounted) setState(() => _enhancing = false);

    bool localSuccess = false;
    try {
      final imageModelState = ref.read(imageModelManagerProvider);

      if (imageModelState.isReady && imageModelState.localPath != null) {
        setState(() {
          _status = 'Loading local model...';
          _source = 'local';
        });
        localSuccess = await _tryLocalGeneration(
          prompt: prompt,
          modelPath: imageModelState.localPath!,
        );
      }

      if (!localSuccess && !_cancelled) {
        setState(() {
          _source = 'cloud';
          _status = 'Cloud generation...';
        });

        if (!(await _imageLimitTracker.canIncrement(_dailyImageLimit))) {
          if (mounted) {
            setState(() {
              _status = 'Daily limit reached ($_dailyImageLimit images). Upgrade or wait until tomorrow.';
            });
          }
          return;
        }

        setState(() => _status = 'Cloud generation...');
        await _tryCloudGeneration(prompt: prompt);

        if (_generatedImagePath != null) {
          await _imageLimitTracker.increment();
          await _loadDailyQuota();
        }
      }
    } catch (e) {
      if (mounted && !_cancelled) {
        setState(() {
          _status = 'Failed: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  bool _cancelled = false;

  Future<bool> _tryLocalGeneration({
    required String prompt,
    required String modelPath,
  }) async {
    try {
      setState(() => _status = 'Starting generation...');
      _source = 'local';

      await for (final progress in _localEngine.generateWithProgress(
        prompt: prompt,
        width: 1024,
        height: 1024,
        steps: 4,
      )) {
        if (_cancelled || !mounted) {
          await _localEngine.cancel();
          return false;
        }
        setState(() {
          _progress = progress.progress;
          _status = progress.status;
          if (progress.isComplete) {
            _generatedImagePath = progress.imagePath;
          }
        });
      }
      return _generatedImagePath != null;
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'Local failed, trying cloud...');
      }
      return false;
    }
  }

  Future<void> _tryCloudGeneration({
    required String prompt,
  }) async {
    await for (final progress in _cloudEngine.generateWithProgress(
      prompt: prompt,
      width: 1024,
      height: 1024,
      steps: 4,
    )) {
      if (_cancelled || !mounted) return;
      setState(() {
        _progress = progress.progress;
        _status = progress.status;
        if (progress.isComplete) {
          _generatedImagePath = progress.imagePath;
        }
      });
    }
  }

  Future<void> _regenerate() => _generate();
}
