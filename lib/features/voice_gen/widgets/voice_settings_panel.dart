import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/theme/theme_colors.dart';

class VoiceSettingsPanel extends ConsumerWidget {
  final double speechRate;
  final double pitch;
  final bool aiPunctuation;
  final bool aiEmotion;
  final ValueChanged<double> onSpeechRateChanged;
  final ValueChanged<double> onPitchChanged;
  final ValueChanged<bool> onAiPunctuationChanged;
  final ValueChanged<bool> onAiEmotionChanged;

  const VoiceSettingsPanel({
    super.key,
    required this.speechRate,
    required this.pitch,
    required this.aiPunctuation,
    required this.aiEmotion,
    required this.onSpeechRateChanged,
    required this.onPitchChanged,
    required this.onAiPunctuationChanged,
    required this.onAiEmotionChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(themeColorsProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: c.cardColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c.borderColor, width: 2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('VOICE SETTINGS', style: AppTypography.labelMedium(c.textPrimary)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.accent(c.isDark), width: 1),
                      ),
                      child: Text(
                        '${speechRate.toStringAsFixed(1)}x · ${pitch.toStringAsFixed(1)}x',
                        style: TextStyle(fontSize: 9, color: AppColors.accent(c.isDark)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSlider(
                  c: c,
                  label: 'RATE',
                  value: speechRate,
                  min: 0.5,
                  max: 2.0,
                  lowLabel: 'Slow',
                  highLabel: 'Fast',
                  onChanged: onSpeechRateChanged,
                ),
                const SizedBox(height: 4),
                _buildSlider(
                  c: c,
                  label: 'PITCH',
                  value: pitch,
                  min: 0.5,
                  max: 2.0,
                  lowLabel: 'Low',
                  highLabel: 'High',
                  onChanged: onPitchChanged,
                ),
                const SizedBox(height: 12),
                Divider(color: c.borderColor, height: 1, thickness: 1),
                const SizedBox(height: 8),
                Text('AI ENHANCEMENTS',
                    style: TextStyle(fontSize: 10, color: c.textTertiary, letterSpacing: 1)),
                const SizedBox(height: 8),
                _buildToggle(
                  c: c,
                  title: 'AI Punctuation',
                  subtitle: 'Add periods, commas, and proper sentence breaks',
                  value: aiPunctuation,
                  onChanged: onAiPunctuationChanged,
                ),
                const SizedBox(height: 4),
                _buildToggle(
                  c: c,
                  title: 'AI Emotion',
                  subtitle: 'Detect mood and adjust tone: happy, sad, angry, calm, excited',
                  value: aiEmotion,
                  onChanged: onAiEmotionChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required ThemeColors c,
    required String label,
    required double value,
    required double min,
    required double max,
    required String lowLabel,
    required String highLabel,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Text(label,
            style: TextStyle(fontSize: 10, color: c.textTertiary, letterSpacing: 1)),
        const SizedBox(width: 8),
        Text(lowLabel, style: TextStyle(fontSize: 9, color: c.textTertiary)),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: 15,
            activeColor: AppColors.accent(c.isDark),
            inactiveColor: c.borderColor,
            onChanged: onChanged,
          ),
        ),
        Text(highLabel, style: TextStyle(fontSize: 9, color: c.textTertiary)),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text('${value.toStringAsFixed(1)}x',
              style: TextStyle(fontSize: 10, color: c.textPrimary)),
        ),
      ],
    );
  }

  Widget _buildToggle({
    required ThemeColors c,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyMedium(c.textPrimary)),
                Text(subtitle, style: AppTypography.bodySmall(c.textTertiary)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: c.isDark ? AppColors.white : AppColors.black,
          ),
        ],
      ),
    );
  }
}
