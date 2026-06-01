import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/ambot_avatar.dart';

class SetupProgressBar extends StatelessWidget {
  final double progress;
  final String statusLabel;
  final bool isDark;
  final VoidCallback? onCancel;

  const SetupProgressBar({
    super.key,
    required this.progress,
    required this.statusLabel,
    required this.isDark,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final progressColor = isDark ? AppColors.white : AppColors.black;

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
          Text(
            statusLabel,
            style: AppTypography.headlineSmall(textPrimary),
          ),
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
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: AppTypography.labelMedium(textSecondary),
              ),
              if (onCancel != null)
                GestureDetector(
                  onTap: onCancel,
                  child: Text(
                    'CANCEL',
                    style: AppTypography.labelMedium(AppColors.danger),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class SetupDetectingView extends StatelessWidget {
  final bool isDark;

  const SetupDetectingView({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AmbotAvatar(size: 72, isDark: isDark),
          const SizedBox(height: 32),
          Text(
            'DETECTING DEVICE',
            style: AppTypography.headlineMedium(textPrimary),
          ),
          const SizedBox(height: 12),
          Text(
            'Analyzing hardware capabilities...',
            style: AppTypography.bodyMedium(textSecondary),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 120,
            child: LinearProgressIndicator(
              backgroundColor:
                  isDark ? AppColors.borderDark : AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? AppColors.white : AppColors.black,
              ),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
