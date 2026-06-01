import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/voice/voice_service.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';

class VoiceInputSection extends StatelessWidget {
  final bool isDark;
  final VoiceState voiceState;
  final String voiceLabel;
  final String liveTranscript;
  final VoidCallback onToggleVoice;

  const VoiceInputSection({
    super.key,
    required this.isDark,
    required this.voiceState,
    required this.voiceLabel,
    required this.liveTranscript,
    required this.onToggleVoice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggleVoice,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: voiceState == VoiceState.listening ||
                        voiceState == VoiceState.recognizing
                    ? AppColors.error
                    : (isDark
                        ? AppColors.cardDarkElevated
                        : AppColors.surfaceLight),
                shape: BoxShape.circle,
                border: Border.all(
                  color: voiceState == VoiceState.listening ||
                          voiceState == VoiceState.recognizing
                      ? AppColors.error
                      : (isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.mic,
                color: voiceState == VoiceState.listening ||
                        voiceState == VoiceState.recognizing
                    ? Colors.white
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  voiceLabel,
                  style: AppTypography.labelSmall(
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                if (liveTranscript.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      liveTranscript,
                      style: AppTypography.bodySmall(
                        isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          if (voiceState == VoiceState.listening ||
              voiceState == VoiceState.recognizing)
            const _VoiceWaveAnimation(),
        ],
      ),
    );
  }
}

class TextCommandInput extends StatelessWidget {
  final bool isDark;
  final bool isProcessing;
  final TextEditingController textController;
  final VoidCallback onSendText;

  const TextCommandInput({
    super.key,
    required this.isDark,
    required this.isProcessing,
    required this.textController,
    required this.onSendText,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  width: 2,
                ),
              ),
              child: TextField(
                controller: textController,
                style: AppTypography.bodyMedium(textPrimary),
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSendText(),
                decoration: InputDecoration(
                  hintText:
                      'Type command: "open Facebook", "type hello", "read screen"...',
                  hintStyle: AppTypography.bodySmall(textSecondary),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isProcessing ? null : onSendText,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isProcessing
                    ? (isDark ? AppColors.grey : AppColors.silver)
                    : (isDark ? AppColors.white : AppColors.black),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_upward,
                color: isProcessing
                    ? (isDark ? AppColors.lightGrey : AppColors.offWhite)
                    : (isDark ? AppColors.black : AppColors.white),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceWaveAnimation extends StatefulWidget {
  const _VoiceWaveAnimation();

  @override
  State<_VoiceWaveAnimation> createState() => _VoiceWaveAnimationState();
}

class _VoiceWaveAnimationState extends State<_VoiceWaveAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: 32,
          height: 24,
          child: CustomPaint(
            painter: _WavePainter(
              color: AppColors.error,
              progress: _controller.value,
            ),
          ),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({required this.color, required this.progress});

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final barCount = 3;
    final barWidth = size.width / (barCount * 2 - 1);
    final maxBarHeight = size.height;

    for (var i = 0; i < barCount; i++) {
      final x = i * barWidth * 2;
      final phase = progress * 2 * 3.14159 + i * 1.2;
      final barHeight =
          maxBarHeight * (0.3 + 0.7 * (0.5 + 0.5 * math.sin(phase).abs()));

      final rect = Rect.fromLTWH(
        x,
        (size.height - barHeight) / 2,
        barWidth,
        barHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(barWidth / 2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) =>
      progress != old.progress || color != old.color;
}
