import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';

class StatusPanel extends StatelessWidget {
  final bool isDark;
  final bool isProcessing;
  final String? lastError;
  final String statusMessage;
  final double trustScore;
  final bool hasPermission;
  final VoidCallback onDismissError;
  final VoidCallback onSetupPermission;
  final AnimationController statusPulseController;
  final Color textSecondary;

  const StatusPanel({
    super.key,
    required this.isDark,
    required this.isProcessing,
    required this.lastError,
    required this.statusMessage,
    required this.trustScore,
    required this.hasPermission,
    required this.onDismissError,
    required this.onSetupPermission,
    required this.statusPulseController,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatusBar(context),
        if (lastError != null) _buildErrorBanner(context),
        if (!hasPermission) _buildPermissionBanner(context),
      ],
    );
  }

  Widget _buildStatusBar(BuildContext context) {
    return AnimatedBuilder(
      animation: statusPulseController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(12),
          color:
              isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          child: Row(
            children: [
              Icon(
                isProcessing
                    ? Icons.hourglass_top
                    : (lastError != null
                        ? Icons.error_outline
                        : Icons.check_circle_outline),
                size: 18,
                color: isProcessing
                    ? textSecondary
                    : (lastError != null
                        ? AppColors.danger
                        : AppColors.success),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusMessage,
                  style: AppTypography.labelSmall(textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TrustBadge(score: trustScore, isDark: isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColors.danger.withValues(alpha: 0.08),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              lastError!,
              style: AppTypography.bodySmall(AppColors.danger),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: onDismissError,
            child: const Text('DISMISS'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColors.warningOrange.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(Icons.warning_amber_outlined, color: AppColors.warningOrange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Accessibility Service required.',
              style: AppTypography.bodySmall(textSecondary),
            ),
          ),
          TextButton(
            onPressed: onSetupPermission,
            child: const Text('SETUP'),
          ),
        ],
      ),
    );
  }
}

class TrustBadge extends StatelessWidget {
  final double score;
  final bool isDark;

  const TrustBadge({super.key, required this.score, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = score >= 0.7
        ? AppColors.success
        : score >= 0.4
            ? AppColors.warningOrange
            : AppColors.error;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.shield_outlined, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '${(score * 100).round()}%',
          style: TextStyle(color: color, fontSize: 12),
        ),
      ],
    );
  }
}
