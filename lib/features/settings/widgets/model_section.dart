import 'package:flutter/material.dart';
import '../../../core/ai/model_manager.dart';
import '../../../core/ai/model_registry.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import 'settings_tile.dart';

class ModelSection extends StatelessWidget {
  final ModelState modelState;
  final ModelInfo? recommendedModel;
  final bool detectingModel;
  final bool isDark;
  final VoidCallback onDownload;
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  final VoidCallback onResume;
  final VoidCallback onDismiss;

  const ModelSection({
    super.key,
    required this.modelState,
    required this.recommendedModel,
    required this.detectingModel,
    required this.isDark,
    required this.onDownload,
    required this.onCancel,
    required this.onDelete,
    required this.onResume,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final progressColor = isDark ? AppColors.white : AppColors.black;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor, width: 2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status row
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: modelState.isReady
                      ? (isDark ? AppColors.white : AppColors.black)
                      : (modelState.isDownloading || modelState.isPaused)
                          ? AppColors.silver
                          : AppColors.lightGrey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                modelState.statusLabel,
                style: AppTypography.labelMedium(textPrimary),
              ),
            ],
          ),

          // Download progress bar (downloading or paused)
          if (modelState.isDownloading || modelState.isPaused) ...[
            const SizedBox(height: 16),
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(1),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: modelState.progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: progressColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(modelState.progress * 100).toStringAsFixed(1)}%',
                  style: AppTypography.labelMedium(textSecondary),
                ),
                if (modelState.isDownloading)
                  GestureDetector(
                    onTap: onCancel,
                    child: Text(
                      'PAUSE',
                      style: AppTypography.labelMedium(AppColors.danger),
                    ),
                  ),
                if (modelState.isPaused)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: onResume,
                        child: Text(
                          'RESUME',
                          style: AppTypography.labelMedium(textPrimary),
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: onDismiss,
                        child: Text(
                          'DISMISS',
                          style: AppTypography.labelMedium(AppColors.danger),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],

          // Model info when ready
          if (modelState.isReady && modelState.modelId != null) ...[
            const SizedBox(height: 12),
            SettingsInfoRow(
              label: 'MODEL',
              value: (ModelRegistry.getById(modelState.modelId!)?.name ?? modelState.modelId!).toUpperCase(),
              labelColor: textSecondary,
              valueColor: textPrimary,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onDelete,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: BorderSide(color: AppColors.danger.withValues(alpha: 0.5)),
                ),
                child: const Text('DELETE MODEL'),
              ),
            ),
          ],

          // Download button when not downloaded
          if (modelState.status == ModelStatus.notDownloaded) ...[
            const SizedBox(height: 12),
            if (detectingModel)
              Text(
                'Detecting compatible model...',
                style: AppTypography.bodySmall(textSecondary),
              )
            else if (recommendedModel != null) ...[
              SettingsInfoRow(
                label: 'RECOMMENDED',
                value: recommendedModel!.name.toUpperCase(),
                labelColor: textSecondary,
                valueColor: textPrimary,
              ),
              const SizedBox(height: 4),
              SettingsInfoRow(
                label: 'SIZE',
                value: recommendedModel!.displaySize,
                labelColor: textSecondary,
                valueColor: textPrimary,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onDownload,
                  child: const Text('DOWNLOAD MODEL'),
                ),
              ),
            ] else
              Text(
                'No compatible model found for this device.',
                style: AppTypography.bodySmall(textSecondary),
              ),
          ],

          // Error state
          if (modelState.hasError) ...[
            const SizedBox(height: 12),
            Text(
              modelState.error ?? 'Download failed',
              style: AppTypography.bodySmall(AppColors.danger),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDownload,
                child: const Text('RETRY'),
              ),
            ),
          ],

          // Verifying
          if (modelState.status == ModelStatus.verifying) ...[
            const SizedBox(height: 12),
            Text(
              'Verifying model integrity...',
              style: AppTypography.bodySmall(textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
