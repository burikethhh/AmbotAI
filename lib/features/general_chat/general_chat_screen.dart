import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/ai/engine_selector.dart';
import '../../core/ai/model_prompt.dart';
import '../../core/ai/nvidia_vision.dart';
import '../../core/config/api_keys.dart';
import '../../core/image_gen/cloud_image_gen.dart';
import '../../core/image_gen/image_template.dart';
import '../../core/image_gen/local_image_gen.dart';
import '../../core/image_gen/prompt_enhancer.dart';
import '../../core/document_gen/document_gen_service.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/connectivity.dart';
import '../../core/services/document_reader.dart';
import '../../core/voice/engines/android_voice_engine.dart';
import '../../core/voice/voice_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/theme/theme_colors.dart';
import '../../shared/widgets/ambot_avatar.dart';

class GeneralChatScreen extends ConsumerStatefulWidget {
  const GeneralChatScreen({super.key});

  @override
  ConsumerState<GeneralChatScreen> createState() => _GeneralChatScreenState();
}

class _GeneralChatScreenState extends ConsumerState<GeneralChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final _messages = <_ChatMessage>[];
  bool _isStreaming = false;

  final VoiceService _voiceService = AndroidVoiceEngine();
  VoiceState _voiceState = VoiceState.idle;
  bool _voiceEnabled = false;
  StreamSubscription? _voiceResultSub;
  StreamSubscription? _voiceErrorSub;

  late LocalImageGenEngine _localImageEngine;
  late CloudImageGenEngine _cloudImageEngine;
  ImagePromptEnhancer? _imagePromptEnhancer;
  bool _isGeneratingImage = false;

  final NvidiaVisionService _visionService = NvidiaVisionService();

  String? _pendingImagePath;
  String? _pendingFilePath;
  String? _pendingFileName;

  @override
  void initState() {
    super.initState();
    _localImageEngine = LocalImageGenEngine();
    _cloudImageEngine = CloudImageGenEngine();

    _localImageEngine.initialize().then((_) {
      final engine = ref.read(aiEngineProvider);
      if (engine.isReady) _localImageEngine.setLlmEngine(engine);
    }).catchError((_) {});

    _cloudImageEngine.initialize().then((_) {
      final nvidiaKey1 = ref.read(userNvidiaKeyProvider);
      final nvidiaKey2 = ref.read(userNvidiaKey2Provider);
      _cloudImageEngine.setNvidiaApiKeys(
        nvidiaKey1 ?? ApiKeys.nvidiaKey1,
        nvidiaKey2 ?? ApiKeys.nvidiaKey2,
      );
      _imagePromptEnhancer = ImagePromptEnhancer()
        ..initialize(userNvidiaKey: nvidiaKey1 ?? ApiKeys.nvidiaKey1);
      _visionService.setApiKeys(
        nvidiaKey1 ?? ApiKeys.nvidiaKey1,
        nvidiaKey2 ?? ApiKeys.nvidiaKey2,
      );
    });

    _initVoice();
  }

  @override
  void dispose() {
    _voiceResultSub?.cancel();
    _voiceErrorSub?.cancel();
    _voiceService.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _localImageEngine.dispose();
    _cloudImageEngine.dispose();
    _imagePromptEnhancer?.dispose();
    _visionService.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // --- Voice ---

  Future<void> _initVoice() async {
    await _voiceService.initialize();
    final available = await _voiceService.isSpeechAvailable;
    if (!mounted) return;
    setState(() => _voiceEnabled = available);
    if (available) {
      _voiceResultSub = _voiceService.onResult.listen((result) {
        if (!mounted || result.isPartial || result.text.isEmpty) return;
        setState(() => _voiceState = VoiceState.idle);
        _controller.text = result.text;
        unawaited(_sendMessage());
      });
      _voiceErrorSub = _voiceService.onError.listen((_) {
        if (mounted) setState(() => _voiceState = VoiceState.idle);
      });
    }
  }

  Future<void> _toggleVoice() async {
    if (_voiceState == VoiceState.listening) {
      await _voiceService.stopListening();
      if (mounted) setState(() => _voiceState = VoiceState.idle);
    } else {
      if (mounted) setState(() => _voiceState = VoiceState.listening);
      await _voiceService.startListening(continuous: false);
    }
  }

  // --- Attachments ---

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1920);
    if (picked == null) return;
    setState(() {
      _pendingImagePath = picked.path;
      _pendingFilePath = null;
      _pendingFileName = null;
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: false);
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    setState(() {
      _pendingFilePath = path;
      _pendingFileName = result.files.single.name;
      _pendingImagePath = null;
    });
  }

  void _clearPendingAttachment() {
    setState(() {
      _pendingImagePath = null;
      _pendingFilePath = null;
      _pendingFileName = null;
    });
  }

  // --- Send ---

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();

    if ((text.isEmpty && _pendingImagePath == null && _pendingFilePath == null) || _isStreaming) return;

    final engine = ref.read(aiEngineProvider);
    if (!engine.isReady) {
      final downloaded = await showModelRequiredPrompt(context: context, ref: ref, featureName: 'Chat');
      if (!downloaded) return;
    }

    // Image gen detection
    if (text.isNotEmpty && _isImageRequest(text) && _pendingImagePath == null && _pendingFilePath == null) {
      _controller.clear();
      await _generateImage(text);
      return;
    }

    _controller.clear();

    // Pending attachment → analyze with AI
    if (_pendingImagePath != null) {
      await _sendWithImageAttachment(text);
      return;
    }
    if (_pendingFilePath != null) {
      await _sendWithFileAttachment(text);
      return;
    }

    // Plain text
    final engineSelection = ref.read(engineSelectionProvider);
    final mode = engineSelection.when(data: (s) => s.mode, loading: () => null, error: (_, _) => null);

    if (mode == EngineMode.cloud) {
      final modelState = ref.read(modelManagerProvider);
      final hasLocalModel = modelState.isReady;
      final online = await hasInternetConnection();
      if (!hasLocalModel && !online) {
        _addError('You\'re offline and no local AI model is downloaded.\n\n'
            'Connect to the internet or download a model in Settings → AI MODEL.');
        return;
      }
    }

    final userMessage = _ChatMessage(content: text, isUser: true);
    setState(() {
      _messages.add(userMessage);
      _isStreaming = true;
    });
    _scrollToBottom();

    final aiMessage = _ChatMessage(content: '', isUser: false, isStreaming: true);
    setState(() => _messages.add(aiMessage));
    _scrollToBottom();

    await _streamResponse(text, engine);
  }

  Future<void> _sendWithImageAttachment(String text) async {
    final path = _pendingImagePath!;
    _clearPendingAttachment();

    final userMessage = _ChatMessage(
      content: text.isNotEmpty ? text : '[Attached image]',
      isUser: true,
      attachmentPath: path,
      attachmentType: 'image',
    );
    setState(() {
      _messages.add(userMessage);
      _isStreaming = true;
    });
    _scrollToBottom();

    final aiMessage = _ChatMessage(content: '', isUser: false, isStreaming: true);
    setState(() => _messages.add(aiMessage));
    _scrollToBottom();

    final analysis = await _visionService.analyzeImage(path);
    if (!mounted) return;
    _finalizeMessage(analysis);
  }

  Future<void> _sendWithFileAttachment(String text) async {
    final path = _pendingFilePath!;
    final name = _pendingFileName ?? path.split('/').last;
    _clearPendingAttachment();

    if (!DocumentReader.canRead(path)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot read file type: ${path.split('.').last}')),
      );
      return;
    }

    final fileText = await DocumentReader.readText(path);

    final userMessage = _ChatMessage(
      content: text.isNotEmpty ? text : '[Attached file: $name]',
      isUser: true,
      attachmentPath: path,
      attachmentType: 'document',
    );
    setState(() {
      _messages.add(userMessage);
      _isStreaming = true;
    });
    _scrollToBottom();

    final aiMessage = _ChatMessage(content: '', isUser: false, isStreaming: true);
    setState(() => _messages.add(aiMessage));
    _scrollToBottom();

    final analysis = await _visionService.analyzeDocument(fileText);
    if (!mounted) return;
    _finalizeMessage(analysis);
  }

  bool _isImageRequest(String text) {
    final lower = text.toLowerCase();
    return lower.contains('generate image') || lower.contains('create image') ||
        lower.contains('draw ') || lower.contains('generate picture') ||
        lower.contains('create picture') || lower.contains('make an image') ||
        (lower.startsWith('image:') || lower.startsWith('image ')) ||
        (lower.startsWith('draw:') || lower.startsWith('draw '));
  }

  // --- Streaming ---

  Future<void> _streamResponse(String text, dynamic engine) async {
    final buffer = StringBuffer();
    try {
      await for (final chunk in engine.generateStream(text, systemPrompt:
          'You are Ambot AI, a general-purpose helpful assistant.')) {
        buffer.write(chunk);
        if (mounted) {
          setState(() {
            _messages.last = _ChatMessage(content: buffer.toString(), isUser: false, isStreaming: true);
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      final errorText = e.toString().replaceFirst('Exception: ', '');
      final engineSelection = ref.read(engineSelectionProvider);
      final mode = engineSelection.when(data: (s) => s.mode, loading: () => null, error: (_, _) => null);
      if (mode == EngineMode.cloud) {
        buffer.write('\n\n---\n*Could not reach cloud AI. Check your connection.*');
      } else {
        buffer.write('\n\n*Error: $errorText*');
      }
    }
    _finalizeMessage(buffer.toString().trim());
  }

  void _finalizeMessage(String content) {
    if (!mounted) return;
    setState(() {
      _messages.last = _ChatMessage(content: content, isUser: false, isStreaming: false);
      _isStreaming = false;
    });
    _scrollToBottom();
  }

  void _addError(String content) {
    setState(() => _messages.add(_ChatMessage(content: content, isUser: false)));
    _scrollToBottom();
  }

  // --- Image Gen ---

  Future<void> _generateImage(String prompt) async {
    setState(() => _isGeneratingImage = true);

    final userMessage = _ChatMessage(content: prompt, isUser: true);
    setState(() => _messages.add(userMessage));
    _scrollToBottom();

    final aiMessage = _ChatMessage(content: 'Generating image...', isUser: false, isStreaming: true);
    setState(() => _messages.add(aiMessage));
    _scrollToBottom();

    try {
      String? imagePath;
      final enhancer = _imagePromptEnhancer;
      final enhanced = enhancer != null ? await enhancer.enhance(prompt) : prompt;

      try {
        await for (final progress in _cloudImageEngine.generateWithProgress(
          prompt: enhanced, width: 1024, height: 1024, steps: 4)) {
          if (progress.isComplete) imagePath = progress.imagePath;
        }
      } catch (_) {}

      if (imagePath == null && mounted) {
        try {
          await for (final progress in _localImageEngine.generateWithProgress(
            prompt: enhanced, width: 512, height: 512, steps: 4)) {
            if (progress.isComplete) imagePath = progress.imagePath;
          }
        } catch (_) {}
      }

      if (imagePath != null && mounted) {
        setState(() {
          _messages.last = _ChatMessage(
            content: 'Image generated: "$prompt"',
            isUser: false,
            imagePath: imagePath,
          );
          _isGeneratingImage = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) _finalizeMessage('Image generation failed.');
    }
  }

  void _showImageGenDialog() {
    final c = ref.read(themeColorsProvider);
    final promptController = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: c.isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
      title: Text('Generate Image', style: TextStyle(color: c.textPrimary)),
      content: TextField(
        controller: promptController, autofocus: true, maxLines: 3,
        decoration: InputDecoration(hintText: 'Describe the image...',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
          filled: true, fillColor: c.cardColor,
        ),
      ),
      actions: [
        TextButton(onPressed: () { promptController.dispose(); Navigator.pop(ctx); }, child: Text('Cancel', style: TextStyle(color: c.textSecondary))),
        ElevatedButton(onPressed: () async {
          final p = promptController.text.trim();
          if (p.isNotEmpty) { promptController.dispose(); Navigator.pop(ctx); _controller.text = p; await _sendMessage(); }
        }, child: const Text('Generate')),
      ],
    ));
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(themeColorsProvider);
    final engine = ref.watch(aiEngineProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: Icon(Icons.arrow_back, color: c.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Row(children: [
          AmbotAvatar(size: 28, isDark: c.isDark),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AMBOT AI', style: AppTypography.headlineMedium(c.textPrimary)),
            Text(engine.isReady ? 'READY' : 'INITIALIZING', style: AppTypography.labelMicro(c.textSecondary)),
          ]),
        ]),
      ),
      body: Column(children: [
        Expanded(child: _messages.isEmpty ? _buildWelcome(c) : ListView.builder(
          controller: _scrollController, padding: const EdgeInsets.all(16),
          itemCount: _messages.length,
          itemBuilder: (ctx, i) => _buildMessageBubble(_messages[i], c),
        )),
        if (_pendingImagePath != null || _pendingFilePath != null) _buildPendingAttachment(c),
        _buildInputBar(c),
      ]),
    );
  }

  Widget _buildWelcome(ThemeColors c) {
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 56, height: 56, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.borderColor, width: 1.5)),
        child: Icon(Icons.auto_awesome, size: 24, color: c.textSecondary)),
      const SizedBox(height: 24),
      Text('ASK ME ANYTHING', style: AppTypography.headlineSmall(c.textPrimary)),
      const SizedBox(height: 8),
      Text('Chat, generate images, attach files for AI analysis.', style: AppTypography.bodyMedium(c.textTertiary), textAlign: TextAlign.center),
      const SizedBox(height: 28),
      Wrap(spacing: 8, runSpacing: 8, children: [
        'What can you do?', 'Explain quantum computing', 'Generate image: a cat',
        'Help me study history',
      ].map((s) => GestureDetector(onTap: () async { _controller.text = s; await _sendMessage(); },
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: c.cardColor, border: Border.all(color: c.borderColor, width: 1.5), borderRadius: BorderRadius.circular(20)),
          child: Text(s, style: AppTypography.labelSmall(c.textSecondary)),
        ),
      )).toList()),
    ])));
  }

  Widget _buildMessageBubble(_ChatMessage msg, ThemeColors c) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(
      mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (!msg.isUser) Padding(padding: const EdgeInsets.only(right: 8, top: 4), child: AmbotAvatar(size: 24, isDark: c.isDark)),
      Flexible(child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(
        color: msg.isUser ? (c.isDark ? AppColors.white : AppColors.black) : c.cardColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: msg.isUser ? (c.isDark ? AppColors.white : AppColors.black) : c.borderColor, width: 2),
      ), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(msg.isUser ? 'YOU' : 'AMBOT', style: AppTypography.labelMicro(
          msg.isUser ? (c.isDark ? AppColors.black : AppColors.white) : c.textSecondary)),
        const SizedBox(height: 6),
        if (msg.imagePath != null && File(msg.imagePath!).existsSync()) ...[
          ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.file(File(msg.imagePath!), width: double.infinity, fit: BoxFit.contain, height: 200)),
          const SizedBox(height: 8),
          Row(mainAxisSize: MainAxisSize.min, children: [
            _bubbleButton(Icons.download_outlined, 'SAVE', () => _saveImage(msg.imagePath!), c),
            const SizedBox(width: 8),
            _bubbleButton(Icons.share_outlined, 'SHARE', () => _shareImage(msg.imagePath!), c),
          ]),
          const SizedBox(height: 8),
        ],
        if (msg.attachmentPath != null) ...[
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: c.cardElevated, borderRadius: BorderRadius.circular(4)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(msg.attachmentType == 'image' ? Icons.image : Icons.attach_file, size: 16, color: c.textSecondary),
              const SizedBox(width: 6),
              Text(msg.attachmentType == 'image' ? 'Image attached' : 'File attached', style: AppTypography.labelSmall(c.textSecondary)),
            ]),
          ),
          const SizedBox(height: 8),
        ],
        Text(msg.content.isEmpty && msg.isStreaming ? '...' : msg.content, style: AppTypography.bodyMedium(
          msg.isUser ? (c.isDark ? AppColors.black : AppColors.white) : c.textPrimary)),
        if (msg.isStreaming) const Padding(padding: EdgeInsets.only(top: 4), child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))),
      ]))),
      if (msg.isUser) const SizedBox(width: 8),
    ]));
  }

  Widget _bubbleButton(IconData icon, String label, VoidCallback onTap, ThemeColors c) {
    return GestureDetector(onTap: onTap, child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(border: Border.all(color: c.borderColor), borderRadius: BorderRadius.circular(2)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: c.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.labelSmall(c.textSecondary)),
      ]),
    ));
  }

  Future<void> _saveImage(String? path) async {
    if (path == null) return;
    final saved = await ImageTemplate.saveToGallery(path);
    if (saved.isNotEmpty && mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved: ${saved.split('/').last}')));
  }

  Future<void> _shareImage(String? path) async {
    if (path == null) return;
    final file = File(path);
    if (!await file.exists()) return;
    final watermarked = await ImageTemplate.applyWatermark(path);
    if (mounted) {
      await DocumentGenService.shareFile(watermarked, subject: 'Ambot AI Image');
    }
  }

  Widget _buildPendingAttachment(ThemeColors c) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: c.cardColor, border: Border(top: BorderSide(color: c.borderColor))),
      child: Row(children: [
        Icon(_pendingImagePath != null ? Icons.image : Icons.attach_file, size: 16, color: c.textSecondary),
        const SizedBox(width: 8),
        Expanded(child: Text(
          _pendingImagePath != null ? 'Image attached' : 'File: ${_pendingFileName ?? ''}',
          style: AppTypography.labelSmall(c.textSecondary), overflow: TextOverflow.ellipsis)),
        GestureDetector(onTap: _clearPendingAttachment, child: Icon(Icons.close, size: 16, color: c.textSecondary)),
      ]),
    );
  }

  Widget _buildInputBar(ThemeColors c) {
    final isListening = _voiceState == VoiceState.listening;
    final isDisabled = _isStreaming || _isGeneratingImage;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(color: c.isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
      child: Container(
        decoration: BoxDecoration(color: c.cardColor, borderRadius: BorderRadius.circular(28),
          border: Border.all(color: c.borderColor, width: 1.5), boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 2)),
          ]),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          // Attach image
          _inputButton(Icons.photo_outlined, isDisabled, () => _pickImage()),
          const SizedBox(width: 2),
          // Attach file
          _inputButton(Icons.attach_file_outlined, isDisabled, () => _pickFile()),
          const SizedBox(width: 2),
          // Image gen
          _inputButton(Icons.image_outlined, isDisabled, _showImageGenDialog),
          const SizedBox(width: 2),
          // Voice
          if (_voiceEnabled)
            Padding(padding: const EdgeInsets.only(right: 4), child: GestureDetector(
              onTap: isDisabled ? null : _toggleVoice,
              child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                width: 36, height: 36, decoration: BoxDecoration(
                  color: isListening ? AppColors.error : Colors.transparent,
                  shape: BoxShape.circle, border: Border.all(color: isListening ? AppColors.error : c.borderColor, width: 1.5),
                ), child: Icon(isListening ? Icons.stop : Icons.mic,
                  size: 18, color: isListening ? Colors.white : c.textSecondary),
              ),
            )),
          Expanded(child: TextField(
            controller: _controller, focusNode: _focusNode, enabled: !isDisabled,
            style: AppTypography.bodyLarge(c.textPrimary), maxLines: 4, minLines: 1,
            textInputAction: TextInputAction.send, onSubmitted: (_) => _sendMessage(),
            decoration: InputDecoration(
              hintText: isDisabled ? 'Processing...' : 'Ask anything...',
              hintStyle: AppTypography.bodyLarge(c.textTertiary),
              border: InputBorder.none, isDense: false,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
          )),
          const SizedBox(width: 4),
          GestureDetector(onTap: isDisabled ? null : _sendMessage, child: Container(
            width: 42, height: 42, decoration: BoxDecoration(
              color: isDisabled ? AppColors.lightGrey : (c.isDark ? AppColors.white : AppColors.black),
              shape: BoxShape.circle,
            ), child: Icon(Icons.send,
              color: isDisabled ? (c.isDark ? AppColors.grey : AppColors.silver) : (c.isDark ? AppColors.black : AppColors.white),
              size: 18),
          )),
        ]),
      ),
    );
  }

  Widget _inputButton(IconData icon, bool isDisabled, VoidCallback onTap) {
    final c = ref.read(themeColorsProvider);
    return Padding(padding: const EdgeInsets.only(right: 2), child: GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.borderColor, width: 1.5)),
        child: Icon(icon, size: 18, color: isDisabled ? (c.isDark ? AppColors.grey : AppColors.silver) : c.textSecondary)),
    ));
  }
}

class _ChatMessage {
  final String content;
  final bool isUser;
  final bool isStreaming;
  final String? imagePath;
  final String? attachmentPath;
  final String? attachmentType;

  const _ChatMessage({
    required this.content,
    required this.isUser,
    this.isStreaming = false,
    this.imagePath,
    this.attachmentPath,
    this.attachmentType,
  });
}
