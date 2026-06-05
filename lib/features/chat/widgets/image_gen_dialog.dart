import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/haptic_feedback_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/theme/theme_colors.dart';

typedef ImageGenCallback = void Function({
  required String prompt,
  required int width,
  required int height,
  required int steps,
  required int seed,
});

void showImageGenDialog({
  required BuildContext context,
  required WidgetRef ref,
  required int remainingToday,
  required int dailyLimit,
  required ImageGenCallback onGenerate,
}) {
  HapticFeedbackService.tap();
  final c = ref.read(themeColorsProvider);

  final promptController = TextEditingController();
  String selectedResolution = '512x512';
  int selectedSteps = 4;
  int selectedSeed = -1;
  final resolutions = ['512x512', '512x768', '768x512', '768x768', '1024x1024'];

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: c.isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        title: Row(
          children: [
            Icon(Icons.image_outlined, color: c.textPrimary),
            const SizedBox(width: 8),
            Text('Generate Image', style: AppTypography.headlineSmall(c.textPrimary)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (remainingToday < dailyLimit)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 14, color: c.textSecondary),
                      const SizedBox(width: 6),
                      Text('$remainingToday/$dailyLimit cloud today',
                        style: AppTypography.labelSmall(c.textSecondary)),
                    ],
                  ),
                ),
              TextField(
                controller: promptController,
                decoration: InputDecoration(
                  hintText: 'Describe the image you want to create...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: c.cardColor,
                ),
                maxLines: 3,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Row(children: [
                Icon(Icons.aspect_ratio, size: 18, color: c.textSecondary),
                const SizedBox(width: 8),
                Text('Resolution', style: AppTypography.labelMedium(c.textSecondary)),
              ]),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: resolutions.map((res) => Material(
                  color: selectedResolution == res ? c.accent.withValues(alpha: 0.2) : c.cardColor,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () => setDialogState(() => selectedResolution = res),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Text(res, style: AppTypography.labelMedium(
                        selectedResolution == res ? c.accent : c.textSecondary,
                      )),
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Icon(Icons.speed, size: 18, color: c.textSecondary),
                const SizedBox(width: 8),
                Text('Steps: $selectedSteps', style: AppTypography.labelMedium(c.textSecondary)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove, size: 20),
                  tooltip: 'Decrease steps',
                  onPressed: selectedSteps > 1 ? () => setDialogState(() => selectedSteps--) : null,
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  tooltip: 'Increase steps',
                  onPressed: selectedSteps < 20 ? () => setDialogState(() => selectedSteps++) : null,
                ),
              ]),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'A futuristic city at sunset',
                  'A cute robot reading a book',
                  'Abstract colorful patterns',
                  'A peaceful mountain landscape',
                ].map((suggestion) => Material(
                  color: c.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () {
                      promptController.text = suggestion;
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Text(suggestion, style: AppTypography.labelSmall(c.textSecondary)),
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: c.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final prompt = promptController.text.trim();
              if (prompt.isNotEmpty) {
                Navigator.pop(ctx);
                final parts = selectedResolution.split('x');
                final width = int.parse(parts[0]);
                final height = int.parse(parts[1]);
                onGenerate(
                  prompt: prompt,
                  width: width,
                  height: height,
                  steps: selectedSteps,
                  seed: selectedSeed,
                );
              }
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    ),
  );
}
