import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/haptic_feedback_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/theme/theme_colors.dart';
import 'context_panel.dart';

typedef DocGenCallback = void Function(String text);

void showDocGenDialog({
  required BuildContext context,
  required WidgetRef ref,
  required DocGenCallback onSelect,
}) {
  HapticFeedbackService.tap();
  final c = ref.read(themeColorsProvider);

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: c.isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      title: Row(
        children: [
          Icon(Icons.description_outlined, color: c.textPrimary),
          const SizedBox(width: 8),
          Text('Generate Document', style: AppTypography.headlineSmall(c.textPrimary)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DocTypeTile(
            icon: Icons.menu_book,
            label: 'Study Guide',
            description: 'Create a structured study guide',
            isDark: c.isDark,
            onTap: () {
              Navigator.pop(ctx);
              onSelect('Generate study guide: ');
            },
          ),
          DocTypeTile(
            icon: Icons.quiz,
            label: 'Quiz',
            description: 'Generate quiz questions',
            isDark: c.isDark,
            onTap: () {
              Navigator.pop(ctx);
              onSelect('Generate quiz: ');
            },
          ),
          DocTypeTile(
            icon: Icons.style,
            label: 'Flashcards',
            description: 'Create flashcards for studying',
            isDark: c.isDark,
            onTap: () {
              Navigator.pop(ctx);
              onSelect('Generate flashcards: ');
            },
          ),
          DocTypeTile(
            icon: Icons.summarize,
            label: 'Summary',
            description: 'Generate a concise summary',
            isDark: c.isDark,
            onTap: () {
              Navigator.pop(ctx);
              onSelect('Generate summary: ');
            },
          ),
          DocTypeTile(
            icon: Icons.school,
            label: 'Lesson Plan',
            description: 'Create a lesson plan',
            isDark: c.isDark,
            onTap: () {
              Navigator.pop(ctx);
              onSelect('Generate lesson plan: ');
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Cancel', style: TextStyle(color: c.textSecondary)),
        ),
      ],
    ),
  );
}
