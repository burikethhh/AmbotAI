import 'package:flutter/material.dart';
import '../../../core/ai/model_registry.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/app_icon.dart';

class SetupStepCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isDark;

  const SetupStepCard({
    super.key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor, width: 2),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          AppIcon(
            icon: icon,
            size: 40,
            backgroundColor:
                isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight,
            iconColor: isDark ? AppColors.silver : AppColors.grey,
            borderColor: borderColor,
            borderWidth: 1.5,
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.headlineSmall(textPrimary)),
              const SizedBox(height: 4),
              Text(subtitle, style: AppTypography.bodySmall(textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class ModelRecommendationCard extends StatelessWidget {
  final ModelInfo model;
  final bool isDark;
  final VoidCallback onDownload;

  const ModelRecommendationCard({
    super.key,
    required this.model,
    required this.isDark,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

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
            children: [
AppIcon(
                icon: Icons.download_outlined,
                size: 36,
                backgroundColor:
                    isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight,
                iconColor: isDark ? AppColors.silver : AppColors.grey,
                borderColor: borderColor,
                borderWidth: 1.5,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RECOMMENDED MODEL',
                      style: AppTypography.labelSmall(textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      model.name.toUpperCase(),
                      style: AppTypography.headlineSmall(textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(
              label: 'PARAMETERS',
              value: model.params,
              textPrimary: textPrimary,
              textSecondary: textSecondary),
          const SizedBox(height: 6),
          _InfoRow(
              label: 'QUANTIZATION',
              value: model.quantization,
              textPrimary: textPrimary,
              textSecondary: textSecondary),
          const SizedBox(height: 6),
          _InfoRow(
              label: 'DOWNLOAD SIZE',
              value: model.displaySize,
              textPrimary: textPrimary,
              textSecondary: textSecondary),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onDownload,
              child: const Text('DOWNLOAD MODEL'),
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
  final Color textPrimary;
  final Color textSecondary;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
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
