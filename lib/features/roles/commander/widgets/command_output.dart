import 'package:flutter/material.dart';

import '../../../../core/device_control/device_controller.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';

class CommandOutput extends StatelessWidget {
  final bool isDark;
  final ScreenContext? screenContext;
  final bool showScreenContent;
  final VoidCallback onHide;
  final VoidCallback onReadAloud;
  final VoidCallback onCopy;

  const CommandOutput({
    super.key,
    required this.isDark,
    required this.screenContext,
    required this.showScreenContent,
    required this.onHide,
    required this.onReadAloud,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'SCREEN CONTENT',
                style: AppTypography.labelSmall(textSecondary),
              ),
              const Spacer(),
              TextButton(
                onPressed: onHide,
                child: const Text('HIDE'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardColor,
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Text(
                screenContext?.text ?? '',
                style: AppTypography.bodySmall(textPrimary),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReadAloud,
                  icon: const Icon(Icons.volume_up, size: 18),
                  label: const Text('Read Aloud'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
