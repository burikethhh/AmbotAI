import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';

class SystemMessageBanner extends StatelessWidget {
  final String? error;
  final bool isStreaming;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const SystemMessageBanner({
    super.key,
    this.error,
    this.isStreaming = false,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (error == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColors.danger.withValues(alpha: 0.08),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error!,
              style: AppTypography.bodySmall(AppColors.danger),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: isStreaming ? null : onRetry,
            child: const Text('RETRY'),
          ),
          TextButton(
            onPressed: onDismiss,
            child: const Text('DISMISS'),
          ),
        ],
      ),
    );
  }
}
