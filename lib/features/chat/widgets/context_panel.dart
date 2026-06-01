import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/theme/theme_colors.dart';
import '../../../core/rag/document_qa_service.dart';

class ContextPanel extends StatelessWidget {
  final DocumentQaService qaService;
  final bool isDark;
  final VoidCallback onClose;

  const ContextPanel({
    super.key,
    required this.qaService,
    required this.isDark,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final c = isDark ? ThemeColors.dark() : ThemeColors.light();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight,
      child: Row(
        children: [
          Icon(Icons.quiz, size: 14, color: c.textSecondary),
          const SizedBox(width: 6),
          Text(
            qaService.hasContent
                ? 'Q&A MODE · ${qaService.chunkCount} paragraphs loaded'
                : 'Q&A MODE · Paste text first, then ask questions',
            style: AppTypography.labelSmall(c.textSecondary),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onClose,
            child: Icon(Icons.close, size: 16, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

class DocTypeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool isDark;
  final VoidCallback onTap;

  const DocTypeTile({
    super.key,
    required this.icon,
    required this.label,
    required this.description,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: isDark ? AppColors.silver : AppColors.grey, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTypography.bodyMedium(textPrimary)),
                    Text(description, style: AppTypography.labelSmall(textSecondary)),
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
