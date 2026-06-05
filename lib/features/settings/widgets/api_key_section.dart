import 'package:flutter/material.dart';
import '../../../core/config/api_keys.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import 'settings_tile.dart';

class ApiKeySection extends StatelessWidget {
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;
  final Color cardColor;
  final bool hasUserOpenRouter;
  final bool hasUserGemini;
  final bool hasUserQwen;
  final bool hasUserHuggingFace;
  final bool hasUserNvidia;
  final bool hasUserNvidia2;
  final VoidCallback? onEdit;

  const ApiKeySection({
    super.key,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
    required this.cardColor,
    required this.hasUserOpenRouter,
    required this.hasUserGemini,
    required this.hasUserQwen,
    required this.hasUserHuggingFace,
    required this.hasUserNvidia,
    required this.hasUserNvidia2,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final dotActive = isDark ? AppColors.white : AppColors.black;
    final dotInactive = AppColors.lightGrey;

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
          SettingsKeyStatusRow(
            label: 'OPENROUTER',
            hasBuiltIn: ApiKeys.hasOpenRouter,
            hasUser: hasUserOpenRouter,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            dotActive: dotActive,
            dotInactive: dotInactive,
          ),
          const SizedBox(height: 8),
          SettingsKeyStatusRow(
            label: 'GEMINI',
            hasBuiltIn: ApiKeys.hasGemini,
            hasUser: hasUserGemini,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            dotActive: dotActive,
            dotInactive: dotInactive,
          ),
          const SizedBox(height: 8),
          SettingsKeyStatusRow(
            label: 'QWEN',
            hasBuiltIn: ApiKeys.hasQwen,
            hasUser: hasUserQwen,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            dotActive: dotActive,
            dotInactive: dotInactive,
          ),
          const SizedBox(height: 8),
          SettingsKeyStatusRow(
            label: 'HUGGING FACE',
            hasBuiltIn: ApiKeys.hasHuggingFace,
            hasUser: hasUserHuggingFace,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            dotActive: dotActive,
            dotInactive: dotInactive,
          ),
          const SizedBox(height: 8),
          SettingsKeyStatusRow(
            label: 'NVIDIA BUILD (KEY 1)',
            hasBuiltIn: ApiKeys.hasNvidia,
            hasUser: hasUserNvidia,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            dotActive: dotActive,
            dotInactive: dotInactive,
          ),
          const SizedBox(height: 8),
          SettingsKeyStatusRow(
            label: 'NVIDIA BUILD (KEY 2)',
            hasBuiltIn: false,
            hasUser: hasUserNvidia2,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            dotActive: dotActive,
            dotInactive: dotInactive,
          ),
          const SizedBox(height: 16),
          Text(
            ApiKeys.hasAnyCloudKey
                ? 'Built-in keys active. Cloud AI is available as fallback.'
                : 'No API keys configured. Add keys in api_keys.dart or paste above.',
            style: AppTypography.bodySmall(textSecondary),
          ),
          if (onEdit != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 16),
                label: Text('EDIT API KEYS',
                    style: AppTypography.labelSmall(textPrimary)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
