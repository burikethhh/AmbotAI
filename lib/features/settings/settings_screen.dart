import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/ai/capability_detector.dart';
import '../../core/ai/engine_selector.dart';
import '../../core/ai/model_registry.dart';
import '../../core/providers/api_key_providers.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/daily_limit_tracker.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/theme/theme_colors.dart';
import '../../shared/theme/app_spacing.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_section.dart';
import 'widgets/api_key_section.dart';
import 'widgets/model_section.dart';
import 'widgets/settings_about_section.dart';
import 'widgets/settings_theme_toggle.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  ModelInfo? _recommendedModel;
  bool _detectingModel = true;
  int _imageRemainingToday = 3;
  static final _imageLimitTracker = DailyLimitTracker('image_gen');

  @override
  void initState() {
    super.initState();
    _detectModel();
    _imageLimitTracker.remaining(3).then((r) {
      if (mounted) setState(() => _imageRemainingToday = r);
    });
  }

  Future<void> _detectModel() async {
    final cap = await DeviceCapabilityDetector.detect();
    final model = ModelRegistry.recommendModel(
      ramMB: cap.ramMB,
      freeStorageMB: cap.freeStorageMB,
    );
    if (mounted) {
      setState(() {
        _recommendedModel = model;
        _detectingModel = false;
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

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final c = ref.watch(themeColorsProvider);
    final engine = ref.watch(aiEngineProvider);
    final engineSelection = ref.watch(engineSelectionProvider);

    final modeLabel = engineSelection.when(
      data: (s) {
        switch (s.mode) {
          case EngineMode.local:
            return 'OFFLINE (LOCAL)';
          case EngineMode.cloud:
            switch (s.cloudProvider) {
              case CloudProvider.openRouter:
                return 'CLOUD (OPENROUTER)';
              case CloudProvider.gemini:
                return 'CLOUD (GEMINI)';
              case CloudProvider.qwen:
                return 'CLOUD (QWEN)';
              case CloudProvider.nvidia:
                return 'CLOUD (NVIDIA)';
              case null:
                return 'CLOUD';
            }
          case EngineMode.mock:
            return 'MOCK (DEV)';
        }
      },
      loading: () => 'LOADING...',
      error: (_, _) => 'ERROR',
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'SETTINGS',
          style: AppTypography.headlineMedium(c.textPrimary),
        ),
      ),
      body: ListView(
        padding: AppSpacing.pagePadding,
        children: [
          // Appearance section
          AppSection(title: 'APPEARANCE',
            child: SettingsThemeToggle(
              isDark: c.isDark,
              textPrimary: c.textPrimary,
              textSecondary: c.textSecondary,
              borderColor: c.borderColor,
              cardColor: c.cardColor,
              onChanged: (_) {
                ref.read(themeProvider.notifier).toggle();
                ref.read(themeProvider.notifier).save();
              },
            ),
          ),

          // Privacy & Memory section
          AppSection(
            title: 'PRIVACY & MEMORY',
            child: AppCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                title: Text(
                  'MANAGE MEMORY',
                  style: AppTypography.bodyLarge(c.textPrimary),
                ),
                subtitle: Text(
                  'View, pin, and delete remembered facts',
                  style: AppTypography.bodySmall(c.textSecondary),
                ),
                trailing: Icon(Icons.chevron_right, color: c.textSecondary),
                onTap: () => context.pushNamed('memory'),
              ),
            ),
          ),

          // AI Engine section
          AppSection(
            title: 'AI ENGINE',
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: engine.isReady ? c.accent : AppColors.lightGrey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      AppSpacing.w8,
                      Text(
                        engine.isReady ? 'ACTIVE' : 'INITIALIZING',
                        style: AppTypography.labelMedium(c.textPrimary),
                      ),
                    ],
                  ),
                  AppSpacing.h12,
                  _InfoRow(label: 'ENGINE', value: engine.engineName),
                  AppSpacing.h8,
                  _InfoRow(label: 'DEVICE TIER', value: engine.tier.name.toUpperCase()),
                  AppSpacing.h8,
                  _InfoRow(label: 'MODE', value: modeLabel),
                  AppSpacing.h16,
                  // Cloud provider selector
                  Text('CLOUD PROVIDER', style: AppTypography.labelSmall(c.textSecondary)),
                  AppSpacing.h8,
                  _CloudProviderSelector(
                    current: ref.watch(cloudProviderProvider),
                    onChanged: (p) => ref.read(cloudProviderProvider.notifier).state = p,
                    textPrimary: c.textPrimary,
                    textSecondary: c.textSecondary,
                    borderColor: c.borderColor,
                    cardColor: c.cardColor,
                    isDark: c.isDark,
                  ),
                ],
              ),
            ),
          ),

          // AI Model section
          AppSection(
            title: 'AI MODEL',
            child: ModelSection(
              modelState: ref.watch(modelManagerProvider),
              recommendedModel: _recommendedModel,
              detectingModel: _detectingModel,
              isDark: c.isDark,
              onDownload: _startDownload,
              onCancel: () => ref.read(modelManagerProvider.notifier).cancelDownload(),
              onDelete: () => ref.read(modelManagerProvider.notifier).deleteModel(),
              onResume: () {
                final hfToken = EngineSelector.getHuggingFaceToken(
                  userToken: ref.read(userHfTokenProvider),
                );
                ref.read(modelManagerProvider.notifier).resumeDownload(hfToken: hfToken);
              },
              onDismiss: () => ref.read(modelManagerProvider.notifier).dismissPausedDownload(),
            ),
          ),

          // Image Generation Models section
          AppSection(title: 'IMAGE GENERATION', child: _ImageModelSection(
            remainingToday: _imageRemainingToday,
            dailyLimit: 3,
          )),

          // API Keys section
          AppSection(
            title: 'API KEYS',
            child: ApiKeySection(
              isDark: c.isDark,
              textPrimary: c.textPrimary,
              textSecondary: c.textSecondary,
              borderColor: c.borderColor,
              cardColor: c.cardColor,
              hasUserOpenRouter: ref.watch(userOpenRouterKeyProvider) != null,
              hasUserGemini: ref.watch(userGeminiKeyProvider) != null,
              hasUserQwen: ref.watch(userQwenKeyProvider) != null,
              hasUserHuggingFace: ref.watch(userHfTokenProvider) != null,
              hasUserNvidia: ref.watch(userNvidiaKeyProvider) != null,
              hasUserNvidia2: ref.watch(userNvidiaKey2Provider) != null,
            ),
          ),

          // About section
          AppSection(
            title: 'ABOUT',
            child: SettingsAboutSection(
              isDark: c.isDark,
              textPrimary: c.textPrimary,
              textSecondary: c.textSecondary,
              borderColor: c.borderColor,
              cardColor: c.cardColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodySmall(c.textSecondary)),
        Text(value, style: AppTypography.labelMedium(c.textPrimary)),
      ],
    );
  }
}

class _CloudProviderSelector extends StatelessWidget {
  final CloudProvider current;
  final ValueChanged<CloudProvider> onChanged;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;
  final Color cardColor;
  final bool isDark;

  const _CloudProviderSelector({
    required this.current,
    required this.onChanged,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
    required this.cardColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: CloudProvider.values.map((p) {
        final isSelected = current == p;
        return GestureDetector(
          onTap: () => onChanged(p),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? AppColors.white : AppColors.black)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color: isSelected
                    ? (isDark ? AppColors.white : AppColors.black)
                    : borderColor,
                width: 2,
              ),
            ),
            child: Text(
              p.name.toUpperCase(),
              style: AppTypography.labelSmall(
                isSelected
                    ? (isDark ? AppColors.black : AppColors.white)
                    : textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ImageModelSection extends StatelessWidget {
  final int remainingToday;
  final int dailyLimit;

  const _ImageModelSection({
    required this.remainingToday,
    required this.dailyLimit,
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final imageModels = ModelRegistry.getImageModels();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.image_outlined, color: c.textSecondary, size: 18),
              AppSpacing.w8,
              Text(
                'Cloud-Based (No Download Required)',
                style: AppTypography.labelSmall(c.textSecondary),
              ),
            ],
          ),
          AppSpacing.h12,
          ...imageModels.map((model) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(model.name, style: AppTypography.bodyMedium(c.textPrimary)),
                          Text(
                            '${model.params} parameters • ${model.huggingFaceRepo.split('/').last}',
                            style: AppTypography.labelSmall(c.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: c.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('CLOUD', style: AppTypography.labelSmall(c.textSecondary)),
                    ),
                  ],
                ),
              )),
          AppSpacing.h12,
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 14, color: c.textSecondary),
              AppSpacing.w8,
              Text(
                '$remainingToday/$dailyLimit daily generations remaining',
                style: AppTypography.labelSmall(remainingToday > 0 ? c.textSecondary : AppColors.danger),
              ),
            ],
          ),
          AppSpacing.h8,
          Text(
            'Image generation uses NVIDIA NIM (free), then Hugging Face Inference API. '
            'Add API keys in Settings for cloud fallback when local AI is unavailable.',
            style: AppTypography.bodySmall(c.textSecondary),
          ),
        ],
      ),
    );
  }
}
