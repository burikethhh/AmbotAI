import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../core/voice/voice_service.dart';

class ChatInputBar extends StatefulWidget {
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
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (widget.focusNode.hasFocus && _expanded) {
      setState(() => _expanded = false);
    }
  }

  void _toggleExpand() {
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = widget.isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = widget.isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final hintColor = widget.isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;
    final isListening = widget.voiceState == VoiceState.listening;
    final isDisabled = widget.isStreaming || widget.isGeneratingImage;

    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isGeneratingImage)
            LinearProgressIndicator(
              value: widget.imageGenProgress,
              backgroundColor: widget.isDark ? AppColors.cardDark : AppColors.cardLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.isDark ? AppColors.silver : AppColors.grey,
              ),
            ),
          if (_expanded)
            _AttachmentPanel(
              isDark: widget.isDark,
              isDisabled: isDisabled,
              onAttachImage: widget.onAttachImage,
              onAttachFile: widget.onAttachFile,
              onImageGen: widget.onImageGen,
              onDocGen: widget.onDocGen,
              onDone: () => setState(() => _expanded = false),
            ),
          Row(
            children: [
              _IconButton(
                icon: _expanded ? Icons.close : Icons.add,
                label: _expanded ? 'Close' : 'Attach',
                onTap: isDisabled ? null : _toggleExpand,
                isActive: _expanded,
                isDark: widget.isDark,
                borderColor: borderColor,
                margin: const EdgeInsets.only(right: 6),
              ),
              if (widget.voiceEnabled)
                _IconButton(
                  icon: isListening ? Icons.stop : Icons.mic,
                  label: isListening ? 'Stop' : 'Voice',
                  onTap: isDisabled ? null : widget.onVoice,
                  isActive: isListening,
                  isDark: widget.isDark,
                  borderColor: borderColor,
                  activeColor: AppColors.error,
                  margin: const EdgeInsets.only(right: 6),
                ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: borderColor, width: 2),
                  ),
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    enabled: !isDisabled,
                    style: AppTypography.bodyMedium(textColor),
                    maxLines: 4,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => widget.onSend(),
                    decoration: InputDecoration(
                      hintText: widget.isGeneratingImage
                          ? 'Generating image...'
                          : (widget.isStreaming ? 'Thinking...' : 'Type a message...'),
                      hintStyle: AppTypography.bodyMedium(hintColor),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      filled: false,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: widget.isGeneratingImage ? 'Generating' : 'Send message',
                child: GestureDetector(
                  onTap: isDisabled ? null : widget.onSend,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDisabled
                          ? (widget.isDark ? AppColors.grey : AppColors.silver)
                          : (widget.isDark ? AppColors.white : AppColors.black),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.isGeneratingImage ? Icons.hourglass_top : Icons.arrow_upward,
                      color: isDisabled
                          ? (widget.isDark ? AppColors.lightGrey : AppColors.offWhite)
                          : (widget.isDark ? AppColors.black : AppColors.white),
                      size: 20,
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

class _AttachmentPanel extends StatelessWidget {
  final bool isDark;
  final bool isDisabled;
  final VoidCallback onAttachImage;
  final VoidCallback onAttachFile;
  final VoidCallback onImageGen;
  final VoidCallback onDocGen;
  final VoidCallback onDone;

  const _AttachmentPanel({
    required this.isDark,
    required this.isDisabled,
    required this.onAttachImage,
    required this.onAttachFile,
    required this.onImageGen,
    required this.onDocGen,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final cardBg = isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'ACTIONS',
              style: AppTypography.labelSmall(textSecondary),
            ),
          ),
          Row(
            children: [
              _AttachmentOption(
                icon: Icons.photo_outlined,
                label: 'Image',
                onTap: isDisabled
                    ? null
                    : () {
                        onAttachImage();
                        onDone();
                      },
                isDark: isDark,
                textPrimary: textPrimary,
              ),
              const SizedBox(width: 8),
              _AttachmentOption(
                icon: Icons.attach_file_outlined,
                label: 'File',
                onTap: isDisabled
                    ? null
                    : () {
                        onAttachFile();
                        onDone();
                      },
                isDark: isDark,
                textPrimary: textPrimary,
              ),
              const SizedBox(width: 8),
              _AttachmentOption(
                icon: Icons.image_outlined,
                label: 'Gen Image',
                onTap: isDisabled
                    ? null
                    : () {
                        onImageGen();
                        onDone();
                      },
                isDark: isDark,
                textPrimary: textPrimary,
              ),
              const SizedBox(width: 8),
              _AttachmentOption(
                icon: Icons.description_outlined,
                label: 'Gen Doc',
                onTap: isDisabled
                    ? null
                    : () {
                        onDocGen();
                        onDone();
                      },
                isDark: isDark,
                textPrimary: textPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDark;
  final Color textPrimary;

  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final cardBg = isDark ? AppColors.cardDark : AppColors.cardLight;
    final enabled = onTap != null;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: enabled
                    ? (isDark ? AppColors.silver : AppColors.grey)
                    : (isDark ? AppColors.grey : AppColors.silver),
              ),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                style: AppTypography.labelMicro(
                  enabled
                      ? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)
                      : (isDark ? AppColors.grey : AppColors.silver),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isActive;
  final bool isDark;
  final Color borderColor;
  final Color? activeColor;
  final EdgeInsetsGeometry? margin;

  const _IconButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isActive,
    required this.isDark,
    required this.borderColor,
    this.activeColor,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isActive
        ? (activeColor ?? (isDark ? AppColors.silver : AppColors.grey))
        : (isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight);
    final iconColor = isActive
        ? (activeColor != null ? Colors.white : (isDark ? AppColors.black : AppColors.white))
        : (isDark ? AppColors.silver : AppColors.grey);

    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          margin: margin,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive
                  ? (activeColor ?? borderColor)
                  : borderColor,
              width: 2,
            ),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }
}
