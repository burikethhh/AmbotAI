import 'package:flutter/material.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/theme/theme_colors.dart';

class PendingAttachmentBar extends StatelessWidget {
  final String? pendingImagePath;
  final String? pendingFileName;
  final ThemeColors colors;
  final VoidCallback onClear;

  const PendingAttachmentBar({
    super.key,
    required this.pendingImagePath,
    required this.pendingFileName,
    required this.colors,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: colors.cardColor,
        border: Border(top: BorderSide(color: colors.borderColor)),
      ),
      child: Row(children: [
        Icon(pendingImagePath != null ? Icons.image : Icons.attach_file, size: 16, color: colors.textSecondary),
        const SizedBox(width: 8),
        Expanded(child: Text(
          pendingImagePath != null ? 'Image attached' : 'File: ${pendingFileName ?? ''}',
          style: AppTypography.labelSmall(colors.textSecondary), overflow: TextOverflow.ellipsis)),
        GestureDetector(onTap: onClear, child: Icon(Icons.close, size: 16, color: colors.textSecondary)),
      ]),
    );
  }
}
