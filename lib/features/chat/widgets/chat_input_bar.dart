import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../core/voice/voice_service.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDark;
  final bool isStreaming;
  final bool voiceEnabled;
  final VoiceState voiceState;
  final bool isGeneratingImage;
  final double imageGenProgress;
  final VoidCallback onSend;
  final VoidCallback onVoice;
  final VoidCallback onImageGen;
  final VoidCallback onDocGen;
  final VoidCallback onAttachImage;
  final VoidCallback onAttachFile;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isDark,
    required this.isStreaming,
    required this.voiceEnabled,
    required this.voiceState,
    required this.isGeneratingImage,
    required this.imageGenProgress,
    required this.onSend,
    required this.onVoice,
    required this.onImageGen,
    required this.onDocGen,
    required this.onAttachImage,
    required this.onAttachFile,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final hintColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;
    final isListening = voiceState == VoiceState.listening;
    final isDisabled = isStreaming || isGeneratingImage;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isGeneratingImage)
            LinearProgressIndicator(
              value: imageGenProgress,
              backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? AppColors.silver : AppColors.grey,
              ),
            ),
          Row(
            children: [
              Semantics(
                button: true,
                label: 'Attach image',
                child: GestureDetector(
                  onTap: isDisabled ? null : onAttachImage,
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor, width: 2),
                    ),
                    child: Icon(
                      Icons.photo_outlined,
                      color: isDisabled
                          ? (isDark ? AppColors.grey : AppColors.silver)
                          : (isDark ? AppColors.silver : AppColors.grey),
                      size: 20,
                    ),
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: 'Attach file',
                child: GestureDetector(
                  onTap: isDisabled ? null : onAttachFile,
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor, width: 2),
                    ),
                    child: Icon(
                      Icons.attach_file_outlined,
                      color: isDisabled
                          ? (isDark ? AppColors.grey : AppColors.silver)
                          : (isDark ? AppColors.silver : AppColors.grey),
                      size: 20,
                    ),
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: 'Generate image',
                child: GestureDetector(
                  onTap: isDisabled ? null : onImageGen,
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor, width: 2),
                    ),
                    child: Icon(
                      Icons.image_outlined,
                      color: isDisabled
                          ? (isDark ? AppColors.grey : AppColors.silver)
                          : (isDark ? AppColors.silver : AppColors.grey),
                      size: 20,
                    ),
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: 'Generate document',
                child: GestureDetector(
                  onTap: isDisabled ? null : onDocGen,
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor, width: 2),
                    ),
                    child: Icon(
                      Icons.description_outlined,
                      color: isDisabled
                          ? (isDark ? AppColors.grey : AppColors.silver)
                          : (isDark ? AppColors.silver : AppColors.grey),
                      size: 20,
                    ),
                  ),
                ),
              ),
              if (voiceEnabled)
                Semantics(
                  button: true,
                  label: isListening ? 'Stop listening' : 'Voice input',
                  child: GestureDetector(
                    onTap: isDisabled ? null : onVoice,
                    child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isListening
                          ? AppColors.error
                          : (isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isListening ? AppColors.error : borderColor,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      isListening ? Icons.stop : Icons.mic,
                      color: isListening ? Colors.white : (isDark ? AppColors.silver : AppColors.grey),
                      size: 20,
                    ),
                  ),
                  ),
                ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: borderColor, width: 2),
                  ),
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: !isDisabled,
                    style: AppTypography.bodyMedium(textColor),
                    maxLines: 4,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    decoration: InputDecoration(
                      hintText: isGeneratingImage
                          ? 'Generating image...'
                          : (isStreaming ? 'Thinking...' : 'Type a message...'),
                      hintStyle: AppTypography.bodyMedium(hintColor),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      filled: false,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: isGeneratingImage ? 'Generating' : 'Send message',
                child: GestureDetector(
                  onTap: isDisabled ? null : onSend,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDisabled
                          ? (isDark ? AppColors.grey : AppColors.silver)
                          : (isDark ? AppColors.white : AppColors.black),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isGeneratingImage ? Icons.hourglass_top : Icons.arrow_upward,
                      color: isDisabled
                          ? (isDark ? AppColors.lightGrey : AppColors.offWhite)
                          : (isDark ? AppColors.black : AppColors.white),
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
