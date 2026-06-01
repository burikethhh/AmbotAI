import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/theme/theme_colors.dart';

class VoiceOutputList extends ConsumerWidget {
  final String? generatedAudioPath;
  final bool isPlaying;
  final String? detectedEmotion;
  final bool useAiVersion;
  final double emotionPitch;
  final double emotionRate;
  final Color? emotionColor;
  final VoidCallback? onPlay;
  final VoidCallback? onStop;

  const VoiceOutputList({
    super.key,
    required this.generatedAudioPath,
    required this.isPlaying,
    this.detectedEmotion,
    required this.useAiVersion,
    required this.emotionPitch,
    required this.emotionRate,
    this.emotionColor,
    this.onPlay,
    this.onStop,
  });

  static const _emotionColors = {
    'happy': Color(0xFFFFD700),
    'excited': Color(0xFFFF8C00),
    'sad': Color(0xFF6A85FF),
    'angry': Color(0xFFFF4444),
    'calm': Color(0xFF00CED1),
    'serious': Color(0xFF808080),
    'whisper': Color(0xFFB0B0B0),
    'neutral': Colors.white,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(themeColorsProvider);

    if (generatedAudioPath == null) return const SizedBox.shrink();

    final col = emotionColor ?? _emotionColors[detectedEmotion] ?? AppColors.accent(c.isDark);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.cardColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.accent(c.isDark), width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: c.borderColor, width: 1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isPlaying ? Icons.graphic_eq : Icons.audiotrack,
                    key: ValueKey(isPlaying),
                    size: 20,
                    color: isPlaying ? AppColors.accent(c.isDark) : c.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GENERATED AUDIO', style: AppTypography.labelSmall(c.textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      generatedAudioPath!.split(Platform.pathSeparator).last,
                      style: AppTypography.bodySmall(c.textTertiary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isPlaying ? Icons.stop_circle_outlined : Icons.play_circle_outline,
                  color: isPlaying ? AppColors.error : AppColors.accent(c.isDark),
                  size: 32,
                ),
                tooltip: isPlaying ? 'Stop' : 'Play',
                onPressed: isPlaying ? onStop : onPlay,
              ),
            ],
          ),
          if (detectedEmotion != null && useAiVersion) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: col, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mood, size: 12, color: col),
                  const SizedBox(width: 4),
                  Text(
                    '${detectedEmotion!.toUpperCase()} · ${emotionPitch.toStringAsFixed(1)}x pitch · ${emotionRate.toStringAsFixed(1)}x rate',
                    style: TextStyle(fontSize: 9, color: col),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
