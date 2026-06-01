import 'package:flutter/material.dart';
import '../../../core/ai/capability_detector.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/app_icon.dart';

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodySmall(textSecondary)),
        Flexible(
          child: Text(
            value,
            style: AppTypography.labelMedium(textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class DeviceProfileCard extends StatelessWidget {
  final DeviceCapability capability;
  final bool isDark;

  const DeviceProfileCard({
    super.key,
    required this.capability,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('DEVICE PROFILE',
                  style: AppTypography.labelLarge(textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Text(
                  capability.tierLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InfoRow(
              label: 'DEVICE',
              value: capability.deviceModel,
              isDark: isDark),
          const SizedBox(height: 8),
          InfoRow(
              label: 'CHIPSET',
              value: capability.chipset,
              isDark: isDark),
          const SizedBox(height: 8),
          InfoRow(
              label: 'RAM',
              value: capability.ramDisplay,
              isDark: isDark),
          const SizedBox(height: 8),
          InfoRow(
              label: 'FREE STORAGE',
              value: capability.storageDisplay,
              isDark: isDark),
          if (capability.hasGoogleAICore) ...[
            const SizedBox(height: 8),
            InfoRow(label: 'AI CORE', value: 'AVAILABLE', isDark: isDark),
          ],
        ],
      ),
    );
  }
}

class InsufficientStorageCard extends StatelessWidget {
  final bool isDark;

  const InsufficientStorageCard({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
            color: AppColors.danger.withValues(alpha: 0.4), width: 2),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(
            icon: Icons.warning_amber_outlined,
            size: 36,
            backgroundColor: Colors.transparent,
            iconColor: AppColors.danger,
            borderColor: AppColors.danger.withValues(alpha: 0.4),
            borderWidth: 1.5,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INSUFFICIENT RESOURCES',
                  style: AppTypography.headlineSmall(textPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your device does not have enough storage or RAM to run a local AI model. '
                  'Free up space or use cloud mode below.',
                  style: AppTypography.bodySmall(textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ErrorCard extends StatelessWidget {
  final String error;
  final bool isDark;
  final VoidCallback onRetry;

  const ErrorCard({
    super.key,
    required this.error,
    required this.isDark,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
            color: AppColors.danger.withValues(alpha: 0.5), width: 2),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DOWNLOAD FAILED',
              style: AppTypography.headlineSmall(textPrimary)),
          const SizedBox(height: 8),
          Text(error,
              style: AppTypography.bodySmall(textSecondary), maxLines: 3),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onRetry,
              child: const Text('RETRY'),
            ),
          ),
        ],
      ),
    );
  }
}
