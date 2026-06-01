import 'package:flutter/material.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/theme/theme_colors.dart';
import '../../../shared/widgets/app_icon.dart';

class GuideSection {
  final String title;
  final IconData icon;
  final List<String> items;
  const GuideSection({required this.title, required this.icon, required this.items});
}

class DocumentGuide extends StatelessWidget {
  final ThemeColors c;
  final bool showGuide;
  final VoidCallback onToggleGuide;
  final List<GuideSection> sections;

  const DocumentGuide({
    super.key,
    required this.c,
    required this.showGuide,
    required this.onToggleGuide,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: c.borderColor, width: 2),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggleGuide,
            child: Container(
              padding: const EdgeInsets.all(12),
              color: c.cardColor,
              child: Row(
                children: [
                  AppIcon(icon: Icons.help_outline, iconColor: c.textSecondary, backgroundColor: Colors.transparent, size: 16),
                  const SizedBox(width: 8),
                  Text('HOW TO USE THE EDITOR', style: AppTypography.labelSmall(c.textPrimary)),
                  const Spacer(),
                  Icon(showGuide ? Icons.expand_less : Icons.expand_more, color: c.textTertiary, size: 18),
                ],
              ),
            ),
          ),
          if (showGuide)
            Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: sections.map((section) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(section.icon, size: 14, color: c.textPrimary),
                          const SizedBox(width: 6),
                          Text(section.title, style: AppTypography.labelSmall(c.textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ...section.items.map((item) => Padding(
                        padding: const EdgeInsets.only(left: 20, top: 2),
                        child: Text(item, style: AppTypography.bodySmall(c.textTertiary)),
                      )),
                    ],
                  ),
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
