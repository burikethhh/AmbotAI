import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ai/model_manager.dart';
import '../../core/ai/image_model_manager.dart';
import '../../core/ai/model_registry.dart';
import '../../core/voice_gen/voice_model_manager.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/theme/theme_colors.dart';

class ModelsScreen extends ConsumerWidget {
  const ModelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(themeColorsProvider);
    final textModelState = ref.watch(modelManagerProvider);
    final imageModelState = ref.watch(imageModelManagerProvider);
    final voiceModelState = ref.watch(voiceModelManagerProvider);

    final textModels = ModelRegistry.all.where((m) => m.modelType == ModelType.text).toList();
    final imageModels = ModelRegistry.getImageModels();
    final voiceModels = ModelRegistry.getVoiceModels();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('MODELS', style: AppTypography.headlineMedium(c.textPrimary)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('TEXT MODELS', style: AppTypography.labelMedium(c.textPrimary)),
          const SizedBox(height: 8),
          ...textModels.map((model) => _ModelTile(
                model: model,
                currentState: model.id == textModelState.modelId ? textModelState : null,
                isDark: c.isDark,
                onDownload: () => ref.read(modelManagerProvider.notifier)
                    .downloadModel(model, hfToken: ref.read(userHfTokenProvider)),
                onDelete: () => ref.read(modelManagerProvider.notifier).deleteModel(),
                onCancel: () => ref.read(modelManagerProvider.notifier).cancelDownload(),
              )),
          const SizedBox(height: 24),
          Text('IMAGE MODELS', style: AppTypography.labelMedium(c.textPrimary)),
          const SizedBox(height: 8),
          ...imageModels.map((model) => _ModelTile(
                model: model,
                currentState: model.id == imageModelState.modelId ? imageModelState : null,
                isDark: c.isDark,
                onDownload: () => ref.read(imageModelManagerProvider.notifier)
                    .downloadModel(model, hfToken: ref.read(userHfTokenProvider)),
                onDelete: () => ref.read(imageModelManagerProvider.notifier).deleteModel(),
                onCancel: () => ref.read(imageModelManagerProvider.notifier).cancelDownload(),
              )),
          const SizedBox(height: 24),
          Text('VOICE MODELS', style: AppTypography.labelMedium(c.textPrimary)),
          const SizedBox(height: 8),
          ...voiceModels.map((model) => _ModelTile(
                model: model,
                currentState: model.id == voiceModelState.modelId ? voiceModelState : null,
                isDark: c.isDark,
                onDownload: () => ref.read(voiceModelManagerProvider.notifier)
                    .downloadModel(model, hfToken: ref.read(userHfTokenProvider)),
                onDelete: () => ref.read(voiceModelManagerProvider.notifier).deleteModel(),
                onCancel: () => ref.read(voiceModelManagerProvider.notifier).cancelDownload(),
              )),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ModelTile extends StatelessWidget {
  final ModelInfo model;
  final dynamic currentState;
  final bool isDark;
  final VoidCallback onDownload;
  final VoidCallback onDelete;
  final VoidCallback onCancel;

  const _ModelTile({
    required this.model,
    required this.currentState,
    required this.isDark,
    required this.onDownload,
    required this.onDelete,
    required this.onCancel,
  });

  bool get _isReady {
    if (currentState == null) return false;
    if (currentState is ModelState) return currentState.isReady;
    if (currentState is ImageModelState) return currentState.isReady;
    if (currentState is VoiceModelState) return currentState.isReady;
    return false;
  }

  bool get _isDownloading {
    if (currentState == null) return false;
    if (currentState is ModelState) return currentState.isDownloading || currentState.isPaused;
    if (currentState is ImageModelState) return currentState.isDownloading || currentState.isPaused;
    if (currentState is VoiceModelState) return currentState.isDownloading || currentState.isPaused;
    return false;
  }

  double get _progress {
    if (currentState == null) return 0.0;
    if (currentState is ModelState) return currentState.progress;
    if (currentState is ImageModelState) return currentState.progress;
    if (currentState is VoiceModelState) return currentState.progress;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textTertiary = isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final cardColor = isDark ? AppColors.cardDark : AppColors.cardLight;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(model.name, style: AppTypography.bodyMedium(textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      '${model.params} · ${model.quantization} · ${model.displaySize} · Tier: ${model.targetTier.name}',
                      style: AppTypography.bodySmall(textTertiary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (_isReady)
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.danger, width: 2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text('DELETE', style: AppTypography.labelSmall(AppColors.danger)),
                  ),
                )
              else if (_isDownloading)
                GestureDetector(
                  onTap: onCancel,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor, width: 2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text('CANCEL', style: AppTypography.labelSmall(textSecondary)),
                  ),
                )
              else
                GestureDetector(
                  onTap: onDownload,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.white : AppColors.black,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      'DOWNLOAD',
                      style: AppTypography.labelSmall(isDark ? AppColors.black : AppColors.white),
                    ),
                  ),
                ),
            ],
          ),
          if (_isDownloading) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: borderColor,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? AppColors.white : AppColors.black,
                ),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(_progress * 100).toStringAsFixed(0)}%',
              style: AppTypography.labelSmall(textTertiary),
            ),
          ],
        ],
      ),
    );
  }
}
