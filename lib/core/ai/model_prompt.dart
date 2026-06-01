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

  // If model is already ready, no prompt needed
  if (modelState.isReady) return true;

  // If currently downloading, tell user to wait
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
  bool _showCloudOption = false;

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
          _showCloudOption = model == null;
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

    // Close dialog and let the feature wait for model to be ready
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
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: c.isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: c.borderColor, width: 2),
                  ),
                  child: Icon(
                    Icons.download_outlined,
                    color: c.textPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MODEL REQUIRED',
                        style: AppTypography.headlineSmall(c.textPrimary),
                      ),
                      Text(
                        '${widget.featureName} needs an AI model',
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
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            c.isDark ? AppColors.white : AppColors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Detecting device capabilities...',
                        style: AppTypography.bodySmall(c.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else if (_downloading)
              _DownloadingState(isDark: c.isDark, textSecondary: c.textSecondary)
            else if (_recommendedModel != null)
              _ModelOption(
                model: _recommendedModel!,
                capability: _capability,
                isDark: c.isDark,
                textPrimary: c.textPrimary,
                textSecondary: c.textSecondary,
                cardColor: c.cardColor,
                borderColor: c.borderColor,
                onDownload: _startDownload,
                onDismiss: _dismiss,
              )
            else
              _NoModelOption(
                isDark: c.isDark,
                textPrimary: c.textPrimary,
                textSecondary: c.textSecondary,
                textTertiary: c.textTertiary,
                cardColor: c.cardColor,
                borderColor: c.borderColor,
                showCloudOption: _showCloudOption,
                onDismiss: _dismiss,
              ),
          ],
        ),
      ),
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

class _ModelOption extends StatelessWidget {
  final ModelInfo model;
  final DeviceCapability? capability;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardColor;
  final Color borderColor;
  final VoidCallback onDownload;
  final VoidCallback onDismiss;

  const _ModelOption({
    required this.model,
    required this.capability,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardColor,
    required this.borderColor,
    required this.onDownload,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    model.name.toUpperCase(),
                    style: AppTypography.bodyLarge(textPrimary),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      model.displaySize,
                      style: AppTypography.labelSmall(textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (capability != null)
                Text(
                  'Recommended for your ${capability!.tierLabel} device',
                  style: AppTypography.labelSmall(textSecondary),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Privacy note
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.white : AppColors.black).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Row(
            children: [
              Icon(Icons.lock_outline, size: 16, color: textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Runs entirely on your device. No data leaves your phone.',
                  style: AppTypography.labelSmall(textSecondary),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onDismiss,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: borderColor),
                ),
                child: Text('LATER', style: AppTypography.labelMedium(textPrimary)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: onDownload,
                child: const Text('DOWNLOAD'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NoModelOption extends StatelessWidget {
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color cardColor;
  final Color borderColor;
  final bool showCloudOption;
  final VoidCallback onDismiss;

  const _NoModelOption({
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.cardColor,
    required this.borderColor,
    required this.showCloudOption,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.danger.withValues(alpha: 0.3), width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber, size: 20, color: AppColors.danger),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No compatible model found for this device.',
                  style: AppTypography.bodySmall(textPrimary),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Text(
          'Options:',
          style: AppTypography.labelMedium(textSecondary),
        ),

        const SizedBox(height: 8),

        if (showCloudOption)
          _OptionTile(
            icon: Icons.cloud_outlined,
            title: 'Use Cloud Mode',
            subtitle: 'Requires API key (Settings)',
            isDark: isDark,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            cardColor: cardColor,
            borderColor: borderColor,
            onTap: () {
              Navigator.of(context).pop(false);
            },
          ),

        _OptionTile(
          icon: Icons.settings_outlined,
          title: 'Configure Later',
          subtitle: 'Set up in Settings',
          isDark: isDark,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          cardColor: cardColor,
          borderColor: borderColor,
          onTap: onDismiss,
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.bodyMedium(textPrimary)),
                    Text(subtitle, style: AppTypography.labelSmall(textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
