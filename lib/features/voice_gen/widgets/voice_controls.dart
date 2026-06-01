import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/theme/theme_colors.dart';

class VoiceControls extends ConsumerWidget {
  final TextEditingController controller;
  final int wordCount;
  final int charCount;
  final bool aiEnabled;
  final bool isPreprocessing;
  final bool isGenerating;
  final bool voiceReady;
  final ValueChanged<String>? onTextChanged;
  final VoidCallback? onPreviewAi;
  final VoidCallback? onGenerate;
  final VoidCallback onClear;

  const VoiceControls({
    super.key,
    required this.controller,
    required this.wordCount,
    required this.charCount,
    required this.aiEnabled,
    required this.isPreprocessing,
    required this.isGenerating,
    required this.voiceReady,
    this.onTextChanged,
    this.onPreviewAi,
    this.onGenerate,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(themeColorsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.cardColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c.borderColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('TEXT TO SPEAK', style: AppTypography.labelMedium(c.textPrimary)),
              const Spacer(),
              Text('$wordCount words · $charCount chars',
                  style: AppTypography.bodySmall(c.textTertiary)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: c.borderColor, width: 2),
              borderRadius: BorderRadius.circular(2),
            ),
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: controller,
              style: AppTypography.bodyMedium(c.textPrimary),
              decoration: InputDecoration(
                hintText: 'Type or paste text to convert to speech...',
                hintStyle: AppTypography.bodyMedium(c.textTertiary),
                border: InputBorder.none,
                isDense: true,
              ),
              maxLines: 6,
              onChanged: onTextChanged,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (aiEnabled)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        (isPreprocessing || controller.text.trim().isEmpty) ? null : onPreviewAi,
                    icon: isPreprocessing
                        ? const SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.preview, size: 16),
                    label: Text(isPreprocessing ? 'PREVIEWING...' : 'AI PREVIEW'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent(c.isDark),
                      side: BorderSide(color: AppColors.accent(c.isDark), width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                  ),
                ),
              if (aiEnabled) const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (isGenerating || !voiceReady || controller.text.trim().isEmpty)
                      ? null
                      : onGenerate,
                  icon: isGenerating
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.volume_up, size: 18),
                  label: Text(isGenerating ? 'GENERATING...' : 'GENERATE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent(c.isDark),
                    foregroundColor: const Color(0xFF000000),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                ),
              ),
              if (controller.text.isNotEmpty) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.clear, color: c.textTertiary, size: 18),
                  onPressed: onClear,
                  tooltip: 'Clear text',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
