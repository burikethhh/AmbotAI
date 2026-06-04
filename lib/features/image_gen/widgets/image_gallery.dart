import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/theme/theme_colors.dart';

class ImageGallery extends ConsumerWidget {
  final String? generatedImagePath;
  final bool isGenerating;
  final double progress;
  final String status;
  final VoidCallback? onSave;
  final VoidCallback? onShare;
  final VoidCallback? onRegenerate;
  final VoidCallback? onEdit;

  const ImageGallery({
    super.key,
    this.generatedImagePath,
    required this.isGenerating,
    required this.progress,
    required this.status,
    this.onSave,
    this.onShare,
    this.onRegenerate,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(themeColorsProvider);

    if (generatedImagePath != null && File(generatedImagePath!).existsSync()) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: c.borderColor, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
              child: Image.file(
                File(generatedImagePath!),
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionButton(
                    icon: Icons.download_outlined,
                    label: 'SAVE',
                    onTap: onSave ?? () {},
                    isDark: c.isDark,
                  ),
                  const SizedBox(width: 12),
                  _ActionButton(
                    icon: Icons.share_outlined,
                    label: 'SHARE',
                    onTap: onShare ?? () {},
                    isDark: c.isDark,
                  ),
                  const SizedBox(width: 12),
                  _ActionButton(
                    icon: Icons.refresh,
                    label: 'REGEN',
                    onTap: onRegenerate ?? () {},
                    isDark: c.isDark,
                  ),
                  const SizedBox(width: 12),
                  _ActionButton(
                    icon: Icons.edit_outlined,
                    label: 'EDIT',
                    onTap: onEdit ?? () {},
                    isDark: c.isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: c.cardColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c.borderColor, width: 1.5),
      ),
      child: Center(
        child: isGenerating
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      value: progress > 0 ? progress : null,
                      color: c.textSecondary,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(status, style: AppTypography.bodyMedium(c.textTertiary)),
                  const SizedBox(height: 8),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: AppTypography.labelLarge(c.textSecondary),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (status.startsWith('Failed') || status.startsWith('No image model'))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        status,
                        style: AppTypography.bodyMedium(Colors.red.shade300),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else ...[
                    Icon(
                      Icons.image_outlined,
                      size: 40,
                      color: c.textTertiary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      status.isNotEmpty ? status : 'ENTER A PROMPT TO GENERATE',
                      style: AppTypography.bodyMedium(c.textTertiary),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: textSecondary),
            const SizedBox(width: 6),
            Text(label, style: AppTypography.labelSmall(textSecondary)),
          ],
        ),
      ),
    );
  }
}
