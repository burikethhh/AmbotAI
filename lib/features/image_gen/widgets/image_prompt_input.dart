import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/theme/theme_colors.dart';

class ImagePromptInput extends ConsumerWidget {
  final TextEditingController controller;
  final bool isGenerating;
  final VoidCallback? onGenerate;

  const ImagePromptInput({
    super.key,
    required this.controller,
    required this.isGenerating,
    this.onGenerate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(themeColorsProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: c.isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: c.cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: c.borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: AppTypography.bodyLarge(c.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Describe the image...',
                  hintStyle: AppTypography.bodyLarge(c.textTertiary),
                  border: InputBorder.none,
                  isDense: false,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                minLines: 1,
                maxLines: 3,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: isGenerating ? null : onGenerate,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isGenerating
                      ? AppColors.lightGrey
                      : (c.isDark ? AppColors.white : AppColors.black),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send,
                  color: isGenerating
                      ? (c.isDark ? AppColors.grey : AppColors.silver)
                      : (c.isDark ? AppColors.black : AppColors.white),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
