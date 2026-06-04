import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/image_gen/cloud_image_gen.dart';
import '../../core/image_gen/local_image_gen.dart';
import '../../core/image_gen/prompt_enhancer.dart';
import '../../core/image_gen/image_template.dart';
import '../../core/config/api_keys.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/connectivity.dart';
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

  static const int _dailyImageLimit = 10;
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
              color: c.isDark ? const Color(0xFF2A1515) : const Color(0xFFFFF5F5),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: c.isDark ? Colors.red.shade300 : Colors.red.shade700),
                  const SizedBox(width: 8),
                  Text('$_remainingToday cloud generation${_remainingToday == 1 ? '' : 's'} remaining today',
                    style: AppTypography.labelSmall(c.isDark ? Colors.red.shade200 : Colors.red.shade800)),
                ],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ImageGallery(
                    generatedImagePath: _generatedImagePath,
                    isGenerating: _isGenerating,
                    progress: _progress,
                    status: _status,
                    onSave: _saveImage,
                    onShare: _shareImage,
                    onRegenerate: _regenerate,
                    onEdit: _editImage,
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
        final errorText = e.toString().replaceFirst('Exception: ', '');
        final online = await hasInternetConnection();

        String message;
        if (!online && _source == 'cloud') {
          message = 'No internet connection. Cloud image generation needs internet.\n\n'
              'Options:\n'
              '1. Connect to the internet and try again.\n'
              '2. Download a local Stable Diffusion model to generate offline '
              '(see Settings → AI MODEL).';
        } else if (!online && _source == 'local') {
          message = 'Local generation failed and you\'re offline.\n'
              'Make sure the model is properly downloaded in Settings → AI MODEL.';
        } else if (errorText.contains('All cloud methods failed') ||
            errorText.contains('All cloud image generation methods failed')) {
          message = 'Cloud image generation is currently unavailable.\n\n'
              'To generate images, you can:\n'
              '1. Try again later (NVIDIA cloud may be temporarily down).\n'
              '2. Download a local Stable Diffusion model in Settings → AI MODEL '
              'for offline generation.\n'
              '3. Add a Hugging Face token in Settings → API KEYS.';
        } else {
          message = 'Failed: $errorText';
        }

        setState(() => _status = message);
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

  Future<void> _saveImage() async {
    if (_generatedImagePath == null) return;
    final savedPath = await ImageTemplate.saveToGallery(_generatedImagePath!);
    if (savedPath.isEmpty || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved: ${savedPath.split('/').last}')),
    );
  }

  Future<void> _shareImage() async {
    if (_generatedImagePath == null) return;
    final file = File(_generatedImagePath!);
    if (!await file.exists()) return;
    final watermarked = await ImageTemplate.applyWatermark(_generatedImagePath!);
    if (mounted) {
      await Share.shareXFiles(
        [XFile(watermarked)],
        subject: 'Ambot AI Image',
      );
    }
  }

  Future<void> _editImage() async {
    if (_generatedImagePath == null) return;
    if (!mounted) return;
    final c = ref.read(themeColorsProvider);
    final editController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
        title: Text('Edit Image', style: TextStyle(color: c.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Describe what you want to change:', style: TextStyle(color: c.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: editController,
              autofocus: true,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Make it more vibrant, add a sunset...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                filled: true,
                fillColor: c.cardColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: c.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, editController.text.trim()),
            child: Text('Edit', style: TextStyle(color: c.textPrimary)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      _promptController.text = result;
      await _generate();
    }
  }

  Future<void> _regenerate() => _generate();
}
