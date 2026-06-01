import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ai/engine_selector.dart';
import '../../core/providers/app_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// A slim global banner that shows model download progress.
/// Visible across all screens (Home, Chat, Settings) while downloading.
class DownloadBanner extends ConsumerWidget {
  const DownloadBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelState = ref.watch(modelManagerProvider);
    final isDark = ref.watch(themeProvider);

    // Only show when downloading or paused
    if (!modelState.isDownloading && !modelState.isPaused) {
      return const SizedBox.shrink();
    }

    final bgColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final progressColor = isDark ? AppColors.white : AppColors.black;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status row
            Row(
              children: [
                Expanded(
                  child: Text(
                    modelState.isPaused
                        ? 'DOWNLOAD PAUSED'
                        : 'DOWNLOADING MODEL',
                    style: AppTypography.labelSmall(textSecondary),
                  ),
                ),
                if (modelState.isDownloading)
                  Text(
                    '${(modelState.progress * 100).toStringAsFixed(1)}%',
                    style: AppTypography.labelMedium(textPrimary),
                  ),
                const SizedBox(width: 12),
                if (modelState.isDownloading)
                  Semantics(
                    button: true,
                    label: 'Pause download',
                    child: GestureDetector(
                      onTap: () =>
                          ref.read(modelManagerProvider.notifier).cancelDownload(),
                      child: Text(
                        'PAUSE',
                        style: AppTypography.labelSmall(AppColors.danger),
                      ),
                    ),
                  ),
                if (modelState.isPaused) ...[
                  Semantics(
                    button: true,
                    label: 'Resume download',
                    child: GestureDetector(
                      onTap: () {
                        final hfToken = EngineSelector.getHuggingFaceToken(
                          userToken: ref.read(userHfTokenProvider),
                        );
                        ref
                            .read(modelManagerProvider.notifier)
                            .resumeDownload(hfToken: hfToken);
                      },
                      child: Text(
                        'RESUME',
                        style: AppTypography.labelSmall(textPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Semantics(
                    button: true,
                    label: 'Dismiss download',
                    child: GestureDetector(
                      onTap: () => ref
                          .read(modelManagerProvider.notifier)
                          .dismissPausedDownload(),
                      child: Text(
                        'DISMISS',
                        style: AppTypography.labelSmall(AppColors.danger),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            // Progress bar
            Container(
              height: 4,
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
                    color: modelState.isPaused
                        ? textSecondary
                        : progressColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
