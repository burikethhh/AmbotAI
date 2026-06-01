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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: c.isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          top: BorderSide(color: c.borderColor, width: 2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: c.cardColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: c.borderColor, width: 2),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: controller,
                style: AppTypography.bodyMedium(c.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Describe the image...',
                  hintStyle: AppTypography.bodyMedium(c.textTertiary),
                  border: InputBorder.none,
                  isDense: true,
                ),
                minLines: 1,
                maxLines: 3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isGenerating ? null : onGenerate,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.isDark ? AppColors.white : AppColors.black,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.bolt,
                color: c.isDark ? AppColors.black : AppColors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
