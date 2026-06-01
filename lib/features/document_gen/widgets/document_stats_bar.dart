import 'package:flutter/material.dart';
import '../../../shared/theme/theme_colors.dart';

class _StatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _StatChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: Colors.grey),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }
}

class DocumentStatsBar extends StatelessWidget {
  final ThemeColors c;
  final int wordCount;
  final int charCount;
  final int lineCount;
  final int paraCount;

  const DocumentStatsBar({
    super.key,
    required this.c,
    required this.wordCount,
    required this.charCount,
    required this.lineCount,
    required this.paraCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: c.borderColor, width: 1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        children: [
          _StatChip(label: '$wordCount words', icon: Icons.text_fields),
          const SizedBox(width: 12),
          _StatChip(label: '$charCount chars', icon: Icons.numbers),
          const SizedBox(width: 12),
          _StatChip(label: '$lineCount lines', icon: Icons.format_line_spacing),
          const SizedBox(width: 12),
          _StatChip(label: '$paraCount paragraphs', icon: Icons.space_bar),
        ],
      ),
    );
  }
}
