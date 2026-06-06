import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import '../../../core/services/chat_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/theme/theme_colors.dart';
import '../../../shared/widgets/ambot_avatar.dart';
import '../../../shared/widgets/code_block.dart';
import '../../../core/document_gen/document_gen_service.dart';
import '../../../core/image_gen/image_template.dart';
import 'typing_indicator.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isDark;

  const ChatMessageBubble({super.key, required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final isUser = message.role == MessageRole.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: isUser ? _buildUserMessage(context, c) : _buildAiMessage(context, c),
    );
  }

  Widget _buildUserMessage(BuildContext context, ThemeColors c) {
    final hasAttachments = message.attachments != null && message.attachments!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 6),
          child: Text('You', style: AppTypography.labelSmall(c.textTertiary)),
        ),
        if (hasAttachments) ...[
          for (final a in message.attachments!)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _UserAttachmentPreview(attachment: a),
            ),
        ],
        Container(
          constraints: BoxConstraints(
            maxWidth: (MediaQuery.of(context).size.width * 0.78).clamp(200, 600),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: c.cardElevated,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            message.content,
            style: AppTypography.bodyMedium(c.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildAiMessage(BuildContext context, ThemeColors c) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: AmbotAvatar(size: 28, isDark: c.isDark),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: message.content.isEmpty && message.isStreaming &&
                  (message.attachments == null || message.attachments!.isEmpty)
              ? const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: TypingIndicator(),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.thinking != null && message.thinking!.isNotEmpty)
                      _ThinkingBlock(content: message.thinking!),
                    if (message.planSteps != null && message.planSteps!.isNotEmpty)
                      _PlanBlock(steps: message.planSteps!),
                    if ((message.thinking != null && message.thinking!.isNotEmpty) ||
                        (message.planSteps != null && message.planSteps!.isNotEmpty))
                      const SizedBox(height: 12),
                    if (message.attachments != null && message.attachments!.isNotEmpty)
                      ...message.attachments!.map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AttachmentView(attachment: a),
                      )),
                    if (message.content.isNotEmpty)
                      MarkdownBody(
                        data: message.content,
                        styleSheet: MarkdownStyleSheet(
                          p: AppTypography.bodyMedium(c.textPrimary),
                          strong: AppTypography.bodyMedium(c.textPrimary)
                              .copyWith(fontWeight: FontWeight.w700),
                          h1: AppTypography.headlineLarge(c.textPrimary),
                          h2: AppTypography.headlineMedium(c.textPrimary),
                          h3: AppTypography.headlineSmall(c.textPrimary),
                          code: AppTypography.mono(c.textPrimary).copyWith(
                            backgroundColor: c.cardElevated,
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          listBullet: AppTypography.bodyMedium(c.textPrimary),
                        ),
                        builders: {
                          'codeBlock': _CodeBlockBuilder(c),
                        },
                      ),
                    const SizedBox(height: 4),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ThinkingBlock extends StatefulWidget {
  final String content;

  const _ThinkingBlock({required this.content});

  @override
  State<_ThinkingBlock> createState() => _ThinkingBlockState();
}

class _ThinkingBlockState extends State<_ThinkingBlock>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: c.cardElevated.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _toggle,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.psychology_outlined, size: 14, color: c.textTertiary),
                const SizedBox(width: 4),
                Text('Thinking', style: AppTypography.labelSmall(c.textTertiary)),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down, size: 14, color: c.textTertiary),
                ),
              ],
            ),
          ),
          SizeTransition(
            sizeFactor: _animation,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                widget.content,
                style: AppTypography.bodySmall(c.textTertiary).copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanBlock extends StatefulWidget {
  final List<String> steps;

  const _PlanBlock({required this.steps});

  @override
  State<_PlanBlock> createState() => _PlanBlockState();
}

class _PlanBlockState extends State<_PlanBlock> {
  final Set<int> _completed = {};

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final accentColor = c.isDark ? AppColors.silver : AppColors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: c.cardElevated.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.account_tree_outlined, size: 14, color: c.textTertiary),
              const SizedBox(width: 4),
              Text('Plan', style: AppTypography.labelSmall(c.textTertiary)),
            ],
          ),
          const SizedBox(height: 6),
          ...widget.steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isCompleted = _completed.contains(index);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isCompleted) {
                    _completed.remove(index);
                  } else {
                    _completed.add(index);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      margin: const EdgeInsets.only(top: 1, right: 8),
                      decoration: BoxDecoration(
                        color: isCompleted ? accentColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: accentColor),
                      ),
                      child: isCompleted
                          ? Icon(Icons.check, size: 12,
                              color: c.isDark ? AppColors.black : AppColors.white)
                          : null,
                    ),
                    Expanded(
                      child: Text(
                        step,
                        style: AppTypography.bodySmall(
                          isCompleted ? c.textTertiary : c.textSecondary,
                        ).copyWith(
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _UserAttachmentPreview extends StatelessWidget {
  final MessageAttachment attachment;

  const _UserAttachmentPreview({required this.attachment});

  @override
  Widget build(BuildContext context) {
    switch (attachment.type) {
      case MessageAttachmentType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: ThemeColors.of(context).borderColor),
            ),
            child: Image.file(
              File(attachment.path),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                height: 80,
                color: ThemeColors.of(context).cardElevated,
                child: Icon(Icons.broken_image, color: ThemeColors.of(context).textSecondary, size: 32),
              ),
            ),
          ),
        );
      case MessageAttachmentType.document:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: ThemeColors.of(context).cardElevated,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: ThemeColors.of(context).borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.attach_file, size: 16, color: ThemeColors.of(context).textSecondary),
              const SizedBox(width: 6),
              Text(
                attachment.caption ?? 'Attached file',
                style: AppTypography.bodySmall(ThemeColors.of(context).textSecondary),
              ),
            ],
          ),
        );
    }
  }
}

class _AttachmentView extends StatelessWidget {
  final MessageAttachment attachment;

  const _AttachmentView({required this.attachment});

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);

    switch (attachment.type) {
      case MessageAttachmentType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 240, maxHeight: 240),
                decoration: BoxDecoration(
                  border: Border.all(color: c.borderColor),
                ),
                child: GestureDetector(
                  onTap: () => _showImagePreview(context),
                  child: Image.file(
                    File(attachment.path),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 120,
                      color: c.cardElevated,
                      child: Icon(Icons.broken_image, color: c.textSecondary, size: 48),
                    ),
                  ),
                ),
              ),
            ),
            if (attachment.caption != null && attachment.caption!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(attachment.caption!, style: AppTypography.bodySmall(c.textSecondary)),
              ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AttachmentButton(icon: Icons.download_outlined, label: 'Save',
                    onTap: () => _saveImage(context, attachment.path)),
                const SizedBox(width: 8),
                _AttachmentButton(icon: Icons.share, label: 'Share',
                    onTap: () => _shareImage(context, attachment.path)),
                const SizedBox(width: 8),
                _AttachmentButton(icon: Icons.fullscreen, label: 'Full',
                    onTap: () => _showImagePreview(context)),
              ],
            ),
          ],
        );
      case MessageAttachmentType.document:
        final pdfPath = attachment.metadata?['pdfPath'] as String? ?? attachment.path;
        final docxPath = attachment.metadata?['docxPath'] as String?;
        final docType = attachment.metadata?['docType'] as String? ?? 'Document';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: c.cardElevated,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(Icons.picture_as_pdf, color: AppColors.danger, size: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attachment.caption ?? 'Document',
                        style: AppTypography.bodyMedium(c.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(docType, style: AppTypography.labelSmall(c.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (pdfPath.isNotEmpty)
                  _AttachmentButton(icon: Icons.open_in_new, label: 'Open PDF',
                      onTap: () => _openFile(context, pdfPath)),
                if (pdfPath.isNotEmpty)
                  _AttachmentButton(icon: Icons.share, label: 'Share PDF',
                      onTap: () => _shareFile(context, pdfPath)),
                if (docxPath?.isNotEmpty ?? false)
                  _AttachmentButton(icon: Icons.description, label: 'Word (.rtf)',
                      onTap: () => _shareFile(context, docxPath!)),
              ],
            ),
          ],
        );
    }
  }

  Future<void> _shareFile(BuildContext context, String path) async {
    final file = File(path);
    if (!await file.exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File not found')),
        );
      }
      return;
    }
    final success = await DocumentGenService.shareFile(path);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to share file')),
      );
    }
  }

  Future<void> _saveImage(BuildContext context, String path) async {
    final saved = await ImageTemplate.saveToGallery(path);
    if (saved.isNotEmpty && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved: ${saved.split('/').last}')),
      );
    }
  }

  Future<void> _shareImage(BuildContext context, String path) async {
    final file = File(path);
    if (!await file.exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File not found')),
        );
      }
      return;
    }
    final watermarked = await ImageTemplate.applyWatermark(path);
    if (context.mounted) {
      final success = await DocumentGenService.shareFile(watermarked, subject: 'Ambot AI Image');
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to share image')),
        );
      }
    }
  }

  Future<void> _openFile(BuildContext context, String path) async {
    final file = File(path);
    if (!await file.exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File not found')),
        );
      }
      return;
    }
    await DocumentGenService.shareFile(path);
  }

  void _showImagePreview(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              tooltip: 'Close',
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                tooltip: 'Share image',
                onPressed: () => _shareImage(context, attachment.path),
              ),
              IconButton(
                icon: const Icon(Icons.download_outlined, color: Colors.white),
                tooltip: 'Save image',
                onPressed: () => _saveImage(context, attachment.path),
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(File(attachment.path)),
            ),
          ),
        ),
      ),
    );
  }
}

class _CodeBlockBuilder extends MarkdownElementBuilder {
  final ThemeColors c;

  _CodeBlockBuilder(this.c);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final code = element.textContent;
    final lang = element.attributes['language'] ?? '';
    return CodeBlock(
      code: code,
      language: lang,
      borderColor: c.borderColor,
      textTertiary: c.textTertiary,
      accent: c.accent,
    );
  }
}

class _AttachmentButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AttachmentButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: c.borderColor),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: c.textPrimary),
              const SizedBox(width: 3),
              Text(label, style: AppTypography.labelSmall(c.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}
