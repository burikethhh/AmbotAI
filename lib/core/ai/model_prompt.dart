import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ai/capability_detector.dart';
import '../../core/ai/engine_selector.dart';
import '../../core/ai/model_manager.dart';
import '../../core/ai/model_registry.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/theme/theme_colors.dart';

/// Shows a model download prompt when a feature is used without a local model.
/// Returns true if the user initiated a download, false if they dismissed.
Future<bool> showModelRequiredPrompt({
  required BuildContext context,
  required WidgetRef ref,
  String featureName = 'This feature',
}) async {
  final modelState = ref.read(modelManagerProvider);

  if (modelState.isReady) return true;

  if (modelState.isDownloading || modelState.isPaused) {
    _showDownloadingSnackbar(context, ref, modelState);
    return false;
  }

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _ModelRequiredDialog(
      featureName: featureName,
    ),
  );

  return result == true;
}

void _showDownloadingSnackbar(BuildContext context, WidgetRef ref, ModelState state) {
  final c = ref.read(themeColorsProvider);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Model download in progress: ${(state.progress * 100).toStringAsFixed(0)}%',
        style: AppTypography.bodySmall(c.textPrimary),
      ),
      backgroundColor: c.cardColor,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ),
  );
}

class _ModelRequiredDialog extends ConsumerStatefulWidget {
  final String featureName;

  const _ModelRequiredDialog({required this.featureName});

  @override
  ConsumerState<_ModelRequiredDialog> createState() => _ModelRequiredDialogState();
}

class _ModelRequiredDialogState extends ConsumerState<_ModelRequiredDialog> {
  DeviceCapability? _capability;
  ModelInfo? _recommendedModel;
  bool _loading = true;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _detectCapability();
  }

  Future<void> _detectCapability() async {
    try {
      final cap = await DeviceCapabilityDetector.detect();
      final model = ModelRegistry.recommendModel(
        ramMB: cap.ramMB,
        freeStorageMB: cap.freeStorageMB,
      );
      if (mounted) {
        setState(() {
          _capability = cap;
          _recommendedModel = model;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _startDownload() {
    if (_recommendedModel == null) return;
    setState(() => _downloading = true);

    final hfToken = EngineSelector.getHuggingFaceToken(
      userToken: ref.read(userHfTokenProvider),
    );
    ref.read(modelManagerProvider.notifier).downloadModel(
      _recommendedModel!,
      hfToken: hfToken,
    );

    Navigator.of(context).pop(true);
  }

  void _dismiss() {
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(themeColorsProvider);

    return Dialog(
      backgroundColor: c.isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: c.isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: c.borderColor, width: 2),
                  ),
                  child: Icon(Icons.smart_toy_outlined, color: c.textPrimary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI ENGINE REQUIRED',
                        style: AppTypography.headlineSmall(c.textPrimary),
                      ),
                      Text(
                        '${widget.featureName} needs an AI engine',
                        style: AppTypography.bodySmall(c.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (_loading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 32, height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            c.isDark ? AppColors.white : AppColors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Detecting device capabilities...',
                        style: AppTypography.bodySmall(c.textSecondary)),
                    ],
                  ),
                ),
              )
            else if (_downloading)
              _DownloadingState(isDark: c.isDark, textSecondary: c.textSecondary)
            else ...[
              _OptionWedge(
                icon: Icons.wifi,
                title: 'Option 1: Use Cloud AI (Recommended)',
                body: 'Ambot AI comes with built-in NVIDIA cloud AI keys. '
                    'Just connect to the internet and start chatting — no download needed. '
                    'Works automatically with no setup required.',
                isDark: c.isDark,
                textPrimary: c.textPrimary,
                textSecondary: c.textSecondary,
                cardColor: c.cardColor,
                borderColor: c.borderColor,
              ),

              const SizedBox(height: 12),

              if (_recommendedModel != null)
                _LocalModelOption(
                  model: _recommendedModel!,
                  capability: _capability,
                  isDark: c.isDark,
                  textPrimary: c.textPrimary,
                  textSecondary: c.textSecondary,
                  cardColor: c.cardColor,
                  borderColor: c.borderColor,
                  onDownload: _startDownload,
                )
              else
                _OptionWedge(
                  icon: Icons.warning_amber,
                  title: 'Cannot download a local model',
                  body: 'Your device doesn\'t meet the minimum requirements for any '
                      'available model (needs at least 4 GB RAM and 500 MB free storage). '
                      'Use Cloud AI (Option 1) instead — just connect to the internet.',
                  isDark: c.isDark,
                  textPrimary: c.textPrimary,
                  textSecondary: c.textSecondary,
                  cardColor: c.cardColor,
                  borderColor: c.borderColor,
                  isWarning: true,
                ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _dismiss,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: c.borderColor),
                    foregroundColor: c.textPrimary,
                    textStyle: AppTypography.labelMedium(c.textPrimary),
                  ),
                  child: const Text('GOT IT'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OptionWedge extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardColor;
  final Color borderColor;
  final bool isWarning;

  const _OptionWedge({
    required this.icon,
    required this.title,
    required this.body,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardColor,
    required this.borderColor,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWarning
            ? AppColors.danger.withValues(alpha: 0.08)
            : cardColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isWarning
              ? AppColors.danger.withValues(alpha: 0.3)
              : borderColor,
          width: isWarning ? 1 : 2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: isWarning ? AppColors.danger : textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.labelMedium(textPrimary)),
                const SizedBox(height: 4),
                Text(body, style: AppTypography.bodySmall(textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalModelOption extends StatelessWidget {
  final ModelInfo model;
  final DeviceCapability? capability;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardColor;
  final Color borderColor;
  final VoidCallback onDownload;

  const _LocalModelOption({
    required this.model,
    required this.capability,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardColor,
    required this.borderColor,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OptionWedge(
          icon: Icons.phone_android,
          title: 'Option 2: Download a Local Model (Offline)',
          body: '${model.name} (${model.displaySize}) — '
              '${capability != null ? 'Fits your ${capability!.tierLabel} device. ' : ''}'
              'Runs entirely on-device. No internet required after download.',
          isDark: isDark,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          cardColor: cardColor,
          borderColor: borderColor,
        ),

        const SizedBox(height: 8),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onDownload,
            child: Text('DOWNLOAD ${model.name.toUpperCase()}'),
          ),
        ),
      ],
    );
  }
}

class _DownloadingState extends StatelessWidget {
  final bool isDark;
  final Color textSecondary;

  const _DownloadingState({required this.isDark, required this.textSecondary});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        LinearProgressIndicator(
          minHeight: 4,
          backgroundColor: isDark ? AppColors.borderDark : AppColors.borderLight,
          valueColor: AlwaysStoppedAnimation<Color>(
            isDark ? AppColors.white : AppColors.black,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Download started. You can continue using the app.',
          style: AppTypography.bodySmall(textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
