import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/theme/theme_colors.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/ai/model_registry.dart';

class VoiceStatusPanel extends ConsumerWidget {
  final String? error;
  final bool hasAiPreview;
  final String? aiProcessedText;
  final String? detectedEmotion;
  final bool useAiVersion;
  final ValueChanged<bool> onUseAiVersionChanged;
  final String originalText;

  const VoiceStatusPanel({
    super.key,
    this.error,
    required this.hasAiPreview,
    this.aiProcessedText,
    this.detectedEmotion,
    required this.useAiVersion,
    required this.onUseAiVersionChanged,
    required this.originalText,
  });

  static const _emotionColors = {
    'happy': Color(0xFFFFD700),
    'excited': Color(0xFFFF8C00),
    'sad': Color(0xFF6A85FF),
    'angry': Color(0xFFFF4444),
    'serious': Color(0xFF808080),
    'whisper': Color(0xFFB0B0B0),
    'neutral': Colors.white,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(themeColorsProvider);
    final voiceState = ref.watch(voiceModelManagerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildModelStatus(context, c, voiceState),
        if (hasAiPreview) ...[
          const SizedBox(height: 12),
          _buildAiPreview(c),
        ],
        if (error != null) ...[
          const SizedBox(height: 12),
          _buildError(c),
        ],
      ],
    );
  }

  Widget _buildModelStatus(BuildContext context, ThemeColors c, dynamic voiceState) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.cardColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: voiceState.isReady ? AppColors.accent(c.isDark) : c.borderColor,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: voiceState.isReady ? AppColors.accent(c.isDark) : c.textTertiary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  voiceState.isReady ? 'VOICE MODEL READY' : 'NO VOICE MODEL',
                  style: AppTypography.labelSmall(c.textPrimary),
                ),
                if (voiceState.modelId != null)
                  Text(
                    voiceState.modelId!.replaceAll('-', ' ').toUpperCase(),
                    style: AppTypography.bodySmall(c.textTertiary),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _VoiceModelsScreen()),
            ),
            child: Text('MANAGE', style: TextStyle(color: c.textSecondary, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildAiPreview(ThemeColors c) {
    final emotionCol = detectedEmotion != null
        ? (_emotionColors[detectedEmotion] ?? AppColors.accent(c.isDark))
        : AppColors.accent(c.isDark);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.accent(c.isDark), width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            color: AppColors.accent(c.isDark).withValues(alpha: 0.1),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, size: 14, color: AppColors.accent(c.isDark)),
                const SizedBox(width: 6),
                Text('AI ENHANCED PREVIEW',
                    style: TextStyle(
                        fontSize: 10, color: AppColors.accent(c.isDark), letterSpacing: 1)),
                const Spacer(),
                if (detectedEmotion != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: emotionCol, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.mood, size: 10, color: emotionCol),
                        const SizedBox(width: 4),
                        Text(
                          detectedEmotion!.toUpperCase(),
                          style: AppTypography.labelMicro(emotionCol).copyWith(letterSpacing: 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text('Use AI', style: AppTypography.labelSmall(c.textPrimary)),
                const SizedBox(width: 4),
                Switch(
                  value: useAiVersion,
                  onChanged: onUseAiVersionChanged,
                  activeThumbColor: c.isDark ? AppColors.white : AppColors.black,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ORIGINAL',
                    style: AppTypography.labelMicro(c.textTertiary).copyWith(letterSpacing: 1)),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: c.cardColor,
                    border: Border.all(color: c.borderColor, width: 1),
                  ),
                  child: Text(
                    originalText.length > 200
                        ? '${originalText.substring(0, 200)}...'
                        : originalText,
                    style: AppTypography.bodySmall(c.textTertiary).copyWith(height: 1.3),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Text('IMPROVED',
                    style: AppTypography.labelMicro(AppColors.accent(c.isDark)).copyWith(letterSpacing: 1)),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: c.cardColor,
                    border: Border.all(color: AppColors.accent(c.isDark), width: 1),
                  ),
                  child: Text(
                    aiProcessedText!.length > 300
                        ? '${aiProcessedText!.substring(0, 300)}...'
                        : aiProcessedText!,
                    style: TextStyle(fontSize: 11, color: c.textPrimary, height: 1.3),
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!useAiVersion)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 10, color: c.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          'Will generate from original text. Toggle "Use AI" to use the improved version.',
                          style: TextStyle(fontSize: 9, color: c.textTertiary),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ThemeColors c) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.error, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 14, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(child: Text(error!, style: AppTypography.bodySmall(AppColors.error))),
        ],
      ),
    );
  }
}

class _VoiceModelsScreen extends ConsumerWidget {
  const _VoiceModelsScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(themeColorsProvider);
    final voiceState = ref.watch(voiceModelManagerProvider);

    final voiceModels = ModelRegistry.getVoiceModels();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('VOICE MODELS', style: AppTypography.headlineMedium(c.textPrimary)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('AVAILABLE VOICES', style: AppTypography.labelMedium(c.textPrimary)),
          const SizedBox(height: 8),
          ...voiceModels.map((model) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.cardColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: model.id == voiceState.modelId
                        ? AppColors.accent(c.isDark)
                        : c.borderColor,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(model.name, style: AppTypography.labelSmall(c.textPrimary)),
                          const SizedBox(height: 2),
                          Text(
                            '${model.params} | ${model.sizeMB}MB',
                            style: AppTypography.bodySmall(c.textTertiary),
                          ),
                        ],
                      ),
                    ),
                    if (model.id == voiceState.modelId && voiceState.isReady)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.accent(c.isDark), width: 1),
                        ),
                        child: Text('ACTIVE',
                            style: AppTypography.labelSmall(AppColors.accent(c.isDark))),
                      )
                    else if (voiceState.isDownloading && model.id == voiceState.modelId)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          value: voiceState.progress,
                          strokeWidth: 2,
                        ),
                      )
                    else
                      TextButton(
                        onPressed: () {
                          ref.read(voiceModelManagerProvider.notifier)
                              .downloadModel(model, hfToken: ref.read(userHfTokenProvider));
                        },
                        child: Text('DOWNLOAD', style: TextStyle(color: c.textSecondary)),
                      ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
