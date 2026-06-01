import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/ai/capability_detector.dart';
import '../../core/ai/engine_selector.dart';
import '../../core/ai/model_manager.dart';
import '../../core/ai/model_registry.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/theme/theme_colors.dart';
import '../../shared/widgets/ambot_avatar.dart';
import '../../shared/widgets/app_icon.dart';
import 'widgets/setup_progress_bar.dart';
import 'widgets/setup_step_card.dart';
import 'widgets/setup_status_panel.dart';

class AISetupScreen extends ConsumerStatefulWidget {
  const AISetupScreen({super.key});

  @override
  ConsumerState<AISetupScreen> createState() => _AISetupScreenState();
}

class _AISetupScreenState extends ConsumerState<AISetupScreen> {
  DeviceCapability? _capability;
  ModelInfo? _recommendedModel;
  bool _detecting = true;
  bool _showCloudOption = false;
  final _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future(_detectCapability);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _detectCapability() async {
    final cap = await DeviceCapabilityDetector.detect();
    final model = ModelRegistry.recommendModel(
      ramMB: cap.ramMB,
      freeStorageMB: cap.freeStorageMB,
    );

    if (mounted) {
      setState(() {
        _capability = cap;
        _recommendedModel = model;
        _detecting = false;
        _showCloudOption = model == null;
      });
    }
  }

  void _startDownload() {
    if (_recommendedModel == null) return;
    final hfToken = EngineSelector.getHuggingFaceToken(
      userToken: ref.read(userHfTokenProvider),
    );
    ref.read(modelManagerProvider.notifier).downloadModel(
      _recommendedModel!,
      hfToken: hfToken,
    );
  }

  void _cancelDownload() {
    ref.read(modelManagerProvider.notifier).cancelDownload();
  }

  Future<void> _enableCloud() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) return;
    if (key.startsWith('sk-or-')) {
      await ref.read(userOpenRouterKeyProvider.notifier).set(key);
      ref.read(cloudProviderProvider.notifier).state = CloudProvider.openRouter;
    } else if (key.startsWith('sk-')) {
      await ref.read(userQwenKeyProvider.notifier).set(key);
      ref.read(cloudProviderProvider.notifier).state = CloudProvider.qwen;
    } else {
      await ref.read(userGeminiKeyProvider.notifier).set(key);
      ref.read(cloudProviderProvider.notifier).state = CloudProvider.gemini;
    }
    _navigateHome();
  }

  void _skipSetup() {
    _navigateHome();
  }

  void _navigateHome() {
    ref.read(aiSetupCompleteProvider.notifier).complete();
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(themeColorsProvider);
    final modelState = ref.watch(modelManagerProvider);

    // Auto-navigate when model is ready
    if (modelState.isReady) {
      Future(_navigateHome);
    }

    return Scaffold(
      body: SafeArea(
        child: _detecting
            ? SetupDetectingView(isDark: c.isDark)
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 16),

                  // Header
                  Center(child: AmbotAvatar(size: 56, isDark: c.isDark)),
                  const SizedBox(height: 20),
                  Text(
                    'AI ENGINE SETUP',
                    style: AppTypography.displayMedium(c.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Configuring the best AI experience for your device',
                    style: AppTypography.bodyMedium(c.textSecondary),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 28),
                  Container(
                    height: 1,
                    color: c.borderColor.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 28),

                  // Device Profile Card
                  if (_capability != null)
                    DeviceProfileCard(
                      capability: _capability!,
                      isDark: c.isDark,
                    ),

                  const SizedBox(height: 20),

                  // Model Recommendation
                  if (_recommendedModel != null && !modelState.isDownloading)
                    ModelRecommendationCard(
                      model: _recommendedModel!,
                      isDark: c.isDark,
                      onDownload: _startDownload,
                    ),

                  // Download Progress
                  if (modelState.isDownloading)
                    SetupProgressBar(
                      progress: modelState.progress,
                      statusLabel: modelState.statusLabel,
                      isDark: c.isDark,
                      onCancel: _cancelDownload,
                    ),

                  // Verifying
                  if (modelState.status == ModelStatus.verifying)
                    SetupStepCard(
                      icon: Icons.verified_outlined,
                      label: 'VERIFYING MODEL',
                      subtitle: 'Checking integrity...',
                      isDark: c.isDark,
                    ),

                  // Error
                  if (modelState.hasError)
                    ErrorCard(
                      error: modelState.error ?? 'Unknown error',
                      isDark: c.isDark,
                      onRetry: _startDownload,
                    ),

                  // No model available or show cloud option
                  if (_showCloudOption || _recommendedModel == null) ...[
                    const SizedBox(height: 20),
                    InsufficientStorageCard(isDark: c.isDark),
                    const SizedBox(height: 20),
                    _CloudOptionCard(
                      isDark: c.isDark,
                      controller: _apiKeyController,
                      onEnable: _enableCloud,
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Skip button
                  Center(
                    child: TextButton(
                      onPressed: _skipSetup,
                      child: Text(
                        'SKIP FOR NOW',
                        style: AppTypography.labelLarge(c.textTertiary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You can configure the AI engine later in Settings',
                    style: AppTypography.bodySmall(c.textTertiary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
      ),
    );
  }
}

class _CloudOptionCard extends StatelessWidget {
  final bool isDark;
  final TextEditingController controller;
  final VoidCallback onEnable;

  const _CloudOptionCard({
    required this.isDark,
    required this.controller,
    required this.onEnable,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textTertiary =
        isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor, width: 2),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(
                icon: Icons.cloud_outlined,
                size: 36,
                backgroundColor: isDark
                    ? AppColors.cardDarkElevated
                    : AppColors.surfaceLight,
                iconColor: isDark ? AppColors.silver : AppColors.grey,
                borderColor: borderColor,
                borderWidth: 1.5,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CLOUD MODE',
                      style: AppTypography.headlineSmall(textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Gemini API',
                      style: AppTypography.labelSmall(textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Privacy warning
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color: AppColors.danger.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.privacy_tip_outlined,
                    size: 16, color: AppColors.danger),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cloud mode sends your messages to Google servers for processing. '
                    'Your data will leave your device.',
                    style: AppTypography.bodySmall(textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // API Key input
          TextField(
            controller: controller,
            style: AppTypography.bodyMedium(textPrimary),
            decoration: InputDecoration(
              hintText: 'ENTER GEMINI API KEY',
              hintStyle: AppTypography.bodyMedium(textTertiary),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onEnable,
              child: const Text('ENABLE CLOUD MODE'),
            ),
          ),
        ],
      ),
    );
  }
}


