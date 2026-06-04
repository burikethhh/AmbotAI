import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/memory/conversation_summary_store.dart';
import '../../core/providers/app_providers.dart';
import '../../core/rag/document_qa_service.dart';
import '../../core/rag/app_knowledge.dart';
import '../../core/roles/role.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/conversation_store.dart';
import '../../core/services/daily_limit_tracker.dart';
import '../../core/services/haptic_feedback_service.dart';
import '../../core/services/document_reader.dart';
import '../../core/voice/engines/android_voice_engine.dart';
import '../../core/voice/voice_service.dart';
import '../../core/image_gen/cloud_image_gen.dart';
import '../../core/image_gen/local_image_gen.dart';
import '../../core/image_gen/prompt_enhancer.dart';
import '../../core/config/api_keys.dart';
import '../../core/document_gen/document_gen_service.dart';
import '../../core/ai/ai_engine.dart' show MessageEntry;
import '../../core/ai/engine_selector.dart' show EngineMode;
import '../../core/ai/model_prompt.dart';
import '../../core/ai/nvidia_vision.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/theme/theme_colors.dart';
import 'widgets/chat_app_bar.dart';
import 'widgets/system_message.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/context_panel.dart';
import 'widgets/conversation_list.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final Role role;
  final Conversation? initialConversation;

  const ChatScreen({
    super.key,
    required this.role,
    this.initialConversation,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  Conversation? _conversation;
  List<ChatMessage> _messages = [];
  bool _isStreaming = false;
  String? _lastError;
  String? _lastUserMessage;
  ResponseMode _responseMode = ResponseMode.chat;
  bool _isGeneratingImage = false;
  double _imageGenProgress = 0.0;

  late AnimationController _welcomeController;

  // Voice
  final VoiceService _voiceService = AndroidVoiceEngine();
  VoiceState _voiceState = VoiceState.idle;
  bool _voiceEnabled = false;
  StreamSubscription? _voiceResultSub;
  StreamSubscription? _voiceErrorSub;

  // Image generation - cloud NVIDIA + local SD fallback
  late LocalImageGenEngine _localImageEngine;
  late CloudImageGenEngine _cloudImageEngine;
  late ImagePromptEnhancer _imagePromptEnhancer;
  ({int width, int height, int steps, int seed})? _imageGenSettings;
  int _remainingImageGenToday = 10;
  static const int _dailyImageLimit = 10;
  static final _imageLimitTracker = DailyLimitTracker('image_gen');

  // NVIDIA Vision for image/document understanding
  final NvidiaVisionService _visionService = NvidiaVisionService();

  // Image/document attachment paths
  String? _pendingImagePath;
  String? _pendingFilePath;
  String? _pendingFileName;

  // Document Q&A
  final DocumentQaService _qaService = DocumentQaService();
  bool _qaMode = false;

  @override
  void initState() {
    super.initState();
    _localImageEngine = LocalImageGenEngine();
    _cloudImageEngine = CloudImageGenEngine();
    _imagePromptEnhancer = ImagePromptEnhancer();

    _localImageEngine.initialize().then((_) {
      final engine = ref.read(aiEngineProvider);
      if (engine.isReady) {
        _localImageEngine.setLlmEngine(engine);
      }
    }).catchError((_) {
      _localImageEngine = LocalImageGenEngine();
      _localImageEngine.initialize().catchError((_) {});
    });

    _cloudImageEngine.initialize().then((_) {
      final nvidiaKey1 = ref.read(userNvidiaKeyProvider);
      final nvidiaKey2 = ref.read(userNvidiaKey2Provider);
      _cloudImageEngine.setNvidiaApiKeys(
        nvidiaKey1 ?? ApiKeys.nvidiaKey1,
        nvidiaKey2 ?? ApiKeys.nvidiaKey2,
      );
      _imagePromptEnhancer.initialize(userNvidiaKey: nvidiaKey1 ?? ApiKeys.nvidiaKey1);
      _visionService.setApiKeys(
        nvidiaKey1 ?? ApiKeys.nvidiaKey1,
        nvidiaKey2 ?? ApiKeys.nvidiaKey2,
      );
    });

    _imageLimitTracker.remaining(_dailyImageLimit).then((r) {
      if (mounted) setState(() => _remainingImageGenToday = r);
    });

    _welcomeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _welcomeController.forward();

    _initVoice();

    Future(() {
      if (!mounted) return;
      if (widget.initialConversation != null) {
        setState(() {
          _conversation = widget.initialConversation;
          _messages = List.from(widget.initialConversation!.messages);
        });
        final notifier = ref.read(conversationsProvider.notifier);
        final currentConvs = ref.read(conversationsProvider);
        final roleConvs = currentConvs[widget.role.id] ?? [];
        if (!roleConvs.any((c) => c.id == widget.initialConversation!.id)) {
          notifier.addConversation(widget.initialConversation!);
        }
      } else {
        setState(() {
          _conversation = ref
              .read(conversationsProvider.notifier)
              .createConversation(widget.role.id);
        });
      }
    });
  }

  Future<void> _initVoice() async {
    await _voiceService.initialize();
    final available = await _voiceService.isSpeechAvailable;
    if (!mounted) return;
    setState(() => _voiceEnabled = available);
    if (available) {
      _voiceResultSub = _voiceService.onResult.listen((result) {
        if (!mounted || result.isPartial || result.text.isEmpty) return;
        setState(() {
          _voiceState = VoiceState.idle;
          _controller.text = result.text;
        });
        _sendMessage();
      });
      _voiceErrorSub = _voiceService.onError.listen((_) {
        if (mounted) setState(() => _voiceState = VoiceState.idle);
      });
    }
  }

  @override
  void dispose() {
    _voiceResultSub?.cancel();
    _voiceErrorSub?.cancel();
    _voiceService.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _welcomeController.dispose();
    _localImageEngine.dispose();
    _cloudImageEngine.dispose();
    _imagePromptEnhancer.dispose();
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

  Future<void> _pickImage() async {
    HapticFeedbackService.tap();
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
    HapticFeedbackService.tap();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
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

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    final hasAttachment = _pendingImagePath != null || _pendingFilePath != null;
    if ((text.isEmpty && !hasAttachment) || _isStreaming || _conversation == null) return;

    final engineSelection = ref.read(engineSelectionProvider);
    final isReady = engineSelection.when(
      data: (s) => s.engine.isReady,
      loading: () => false,
      error: (_, _) => false,
    );

    if (!isReady) {
      final downloaded = await showModelRequiredPrompt(
        context: context,
        ref: ref,
        featureName: 'Chat',
      );
      if (!downloaded) return;
    }

    final conversation = _conversation!;

    HapticFeedbackService.tap();
    _controller.clear();

    // Handle pending attachment first (analyze and respond)
    if (_pendingImagePath != null) {
      await _sendWithImageAttachment(text);
      return;
    }
    if (_pendingFilePath != null) {
      await _sendWithFileAttachment(text);
      return;
    }

    // Check if this is an image generation request
    if (_isImageRequest(text)) {
      await _generateImage(text);
      return;
    }

    // Check if this is a document generation request
    if (_isDocumentRequest(text)) {
      await _generateDocument(text);
      return;
    }

    // Q&A mode: first paste/ingest, then answer against ingested text
    if (_qaMode) {
      if (!_qaService.hasContent) {
        _qaService.ingest(text);
        final count = _qaService.chunkCount;
        final userMessage = ChatMessage(content: text, role: MessageRole.user);
        final aiMessage = ChatMessage(
          content: 'Document ingested ($count paragraphs). Ask me questions about it.',
          role: MessageRole.assistant,
        );
        setState(() => _messages = [..._messages, userMessage, aiMessage]);
        ref.read(conversationsProvider.notifier).addMessage(widget.role.id, conversation.id, userMessage);
        ref.read(conversationsProvider.notifier).addMessage(widget.role.id, conversation.id, aiMessage);
        final updatedConv = Conversation(
          id: conversation.id, roleId: conversation.roleId,
          messages: _messages, createdAt: conversation.createdAt, updatedAt: DateTime.now(),
        );
        await ConversationStore.instance.save(updatedConv);
        _scrollToBottom();
        return;
      }
      // Answer question using Q&A service
      final qaPrompt = _qaService.buildQaPrompt(text);
      final userMessage = ChatMessage(content: text, role: MessageRole.user);
      setState(() { _messages = [..._messages, userMessage]; _isStreaming = true; });
      _scrollToBottom();
      ref.read(conversationsProvider.notifier).addMessage(widget.role.id, conversation.id, userMessage);
      final aiMessage = ChatMessage(content: '', role: MessageRole.assistant, isStreaming: true);
      setState(() => _messages = [..._messages, aiMessage]);
      _scrollToBottom();
      return _streamAndFinalize(text, qaPrompt, aiMessage, conversation);
    }

    final userMessage = ChatMessage(content: text, role: MessageRole.user);
    setState(() {
      _messages = [..._messages, userMessage];
      _isStreaming = true;
    });
    _scrollToBottom();

    ref
        .read(conversationsProvider.notifier)
        .addMessage(widget.role.id, conversation.id, userMessage);

    final aiMessage = ChatMessage(
      content: '',
      role: MessageRole.assistant,
      isStreaming: true,
    );
    setState(() {
      _messages = [..._messages, aiMessage];
    });
    _scrollToBottom();

    // Memory retrieval
    final retriever = ref.read(memoryRetrieverProvider);
    final memories = await retriever.retrieve(
      query: text,
      roleId: widget.role.id,
      conversationId: conversation.id,
      topK: 5,
    );
    final memoryBlock = retriever.renderForPrompt(memories);

    // Build message history for structured KV cache reuse
    final historyList = _buildHistoryEntries();

    // Keep summary-based context for very long conversations
    String summaryPrefix = '';
    if (historyList.length > 12) {
      final summaryBlock = ConversationSummaryStore.instance.renderForPrompt(
        widget.role.id, text, limit: 2,
      );
      if (summaryBlock.isNotEmpty) {
        summaryPrefix = '\n\nEarlier context:\n$summaryBlock';
      }
    }

    String modeInstruction = '';
    switch (_responseMode) {
      case ResponseMode.thinking:
        modeInstruction =
            '\n\nBefore answering, think through your reasoning step by step inside <thinking> tags. Then provide your final answer after the closing tag.';
        break;
      case ResponseMode.plan:
        modeInstruction =
            '\n\nFirst, create a numbered step-by-step plan inside <plan> tags. Each step should be on its own line starting with "Step N: ". Then execute the plan and provide your final answer after the closing tag.';
        break;
      case ResponseMode.chat:
        break;
    }

    final appKnowledgeBlock = AppKnowledge.buildContext(text);

    // Static system prompt — no embedded history, enables KV cache reuse
    final staticPrompt = widget.role.systemPrompt + appKnowledgeBlock + modeInstruction;

    // Conversation summaries for context recycling
    final summaryBlock = ConversationSummaryStore.instance.renderForPrompt(
      widget.role.id,
      text,
      limit: 3,
    );
    final contextBlock = memoryBlock.isEmpty
        ? (summaryBlock.isEmpty ? summaryPrefix : summaryPrefix.isNotEmpty
            ? '$summaryPrefix\n\n$summaryBlock'
            : summaryBlock)
        : '$memoryBlock${summaryPrefix.isNotEmpty ? '\n\n$summaryPrefix' : ''}${summaryBlock.isNotEmpty ? '\n\n$summaryBlock' : ''}';
    final systemPrompt = contextBlock.isEmpty
        ? staticPrompt
        : '$staticPrompt\n\n$contextBlock';

    await _streamAndFinalize(text, systemPrompt, aiMessage, conversation, history: historyList);
  }

  Future<void> _sendWithImageAttachment(String text) async {
    final path = _pendingImagePath!;
    _clearPendingAttachment();

    final userMessage = ChatMessage(
      content: text.isNotEmpty ? text : '[Attached image]',
      role: MessageRole.user,
      attachments: [MessageAttachment(type: MessageAttachmentType.image, path: path)],
    );
    setState(() {
      _messages = [..._messages, userMessage];
      _isStreaming = true;
    });
    _scrollToBottom();
    ref.read(conversationsProvider.notifier).addMessage(widget.role.id, _conversation!.id, userMessage);

    final aiMessage = ChatMessage(content: '', role: MessageRole.assistant, isStreaming: true);
    setState(() => _messages = [..._messages, aiMessage]);
    _scrollToBottom();

    final analysis = await _visionService.analyzeImage(path);
    if (!mounted) return;
    await _finalizeAttachment(analysis, userMessage, aiMessage);
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

    final userMessage = ChatMessage(
      content: text.isNotEmpty ? text : '[Attached file: $name]',
      role: MessageRole.user,
      attachments: [MessageAttachment(type: MessageAttachmentType.document, path: path, caption: name)],
    );
    setState(() {
      _messages = [..._messages, userMessage];
      _isStreaming = true;
    });
    _scrollToBottom();
    ref.read(conversationsProvider.notifier).addMessage(widget.role.id, _conversation!.id, userMessage);

    final aiMessage = ChatMessage(content: '', role: MessageRole.assistant, isStreaming: true);
    setState(() => _messages = [..._messages, aiMessage]);
    _scrollToBottom();

    final analysis = await _visionService.analyzeDocument(fileText);
    if (!mounted) return;
    await _finalizeAttachment(analysis, userMessage, aiMessage);
  }

  Future<void> _finalizeAttachment(String analysis, ChatMessage userMessage, ChatMessage aiMessage) async {
    final idx = _messages.indexOf(aiMessage);
    if (idx == -1) return;
    setState(() {
      _messages[idx] = aiMessage.copyWith(content: analysis, isStreaming: false);
      _isStreaming = false;
    });
    _scrollToBottom();
    ref.read(conversationsProvider.notifier).addMessage(widget.role.id, _conversation!.id, _messages.last);
    final updatedConv = Conversation(
      id: _conversation!.id, roleId: widget.role.id,
      messages: _messages, createdAt: _conversation!.createdAt, updatedAt: DateTime.now(),
    );
    await ConversationStore.instance.save(updatedConv);
  }

  /// Shared streaming helper used by normal chat and Q&A mode.
  List<MessageEntry> _buildHistoryEntries() {
    return _messages
        .where((m) => m.role != MessageRole.assistant || m.content.isNotEmpty)
        .map((m) => MessageEntry(
              role: m.role.name,
              content: m.content,
            ))
        .toList();
  }

  Future<void> _streamAndFinalize(
    String userText,
    String fullPrompt,
    ChatMessage aiMessage,
    Conversation conversation, {
    List<MessageEntry>? history,
  }) async {
    final engine = ref.read(aiEngineProvider);
    final buffer = StringBuffer();

    try {
      DateTime? lastUpdate;

       await for (final chunk
           in engine.generateStream(userText, systemPrompt: fullPrompt, history: history)) {
         buffer.write(chunk);
         final now = DateTime.now();
         if (lastUpdate == null ||
             now.difference(lastUpdate).inMilliseconds >= 16) {
           lastUpdate = now;
           final parsed = _parseResponse(buffer.toString());
           if (!mounted) return;
           setState(() {
             _messages = [
               ..._messages.sublist(0, _messages.length - 1),
               aiMessage.copyWith(
                 content: parsed.content,
                 thinking: parsed.thinking,
                 planSteps: parsed.planSteps,
               ),
             ];
           });
           _scrollToBottom();
         }
       }
      if (!mounted) return;
      // Final update
      final parsed = _parseResponse(buffer.toString());
      setState(() {
        _messages = [
          ..._messages.sublist(0, _messages.length - 1),
          aiMessage.copyWith(
            content: parsed.content,
            thinking: parsed.thinking,
            planSteps: parsed.planSteps,
          ),
        ];
      });
      _scrollToBottom();
    } catch (e) {
      final rawError = e.toString().replaceFirst('Exception: ', '');
      final isNetworkError = rawError.contains('SocketException') ||
          rawError.contains('HandshakeException') ||
          rawError.contains('HttpException') ||
          rawError.contains('TimeoutException') ||
          rawError.contains('No address') ||
          rawError.contains('Connection refused') ||
          rawError.contains('Failed host lookup');
      HapticFeedbackService.error();

      final engineSelection = ref.read(engineSelectionProvider);
      final mode = engineSelection.when(
        data: (s) => s.mode,
        loading: () => null,
        error: (_, _) => null,
      );

      if (buffer.isEmpty) {
        if (mode == EngineMode.cloud && isNetworkError) {
          buffer.write('Could not reach the cloud AI service.'
              '\n\nMake sure you have an internet connection and try again.'
              '\n\nAlternatively, download a local AI model in Settings → AI MODEL '
              'to use Ambot AI offline.');
        } else if (mode == EngineMode.cloud) {
          buffer.write('Cloud AI service error.'
              '\n\nTry again later. If the problem persists,'
              '\ndownload a local model in Settings → AI MODEL.');
        } else {
          buffer.write('Failed to get a response.\n\n`$rawError`');
        }
      } else {
        if (isNetworkError) {
          buffer.write('\n\n---\n'
              '*Connection lost. Make sure you\'re online.*');
        } else {
          buffer.write('\n\n---\n*Stream interrupted:* `$rawError`');
        }
      }
      if (mounted) {
        setState(() {
          _lastError = rawError;
          _lastUserMessage = userText;
        });
      }
    }

    if (!mounted) return;
    final fullContent = buffer.toString().trim();
    final parsed = _parseResponse(fullContent);
    final finalMessage = ChatMessage(
      content: parsed.content,
      role: MessageRole.assistant,
      thinking: parsed.thinking,
      planSteps: parsed.planSteps,
    );
    setState(() {
      _messages = [
        ..._messages.sublist(0, _messages.length - 1),
        finalMessage,
      ];
      _isStreaming = false;
      _lastError = null;
    });
    _scrollToBottom();

    ref
        .read(conversationsProvider.notifier)
        .addMessage(widget.role.id, conversation.id, finalMessage);

    // Persist to Hive
    final updatedConv = Conversation(
      id: conversation.id,
      roleId: conversation.roleId,
      messages: _messages,
      createdAt: conversation.createdAt,
      updatedAt: DateTime.now(),
    );
    await ConversationStore.instance.save(updatedConv);

    // Auto-generate title from first message
    if (_messages.where((m) => m.role == MessageRole.user).length == 1) {
      final title = ConversationStore.generateTitle(_messages);
      await ConversationStore.instance.setTitle(conversation.id, title);
    }

    // Memory extraction
    final extractor = ref.read(memoryExtractorProvider);
    await extractor.extractAndStore(
      userMessage: userText,
      assistantMessage: finalMessage.content,
      roleId: widget.role.id,
      conversationId: conversation.id,
      defaultScope: widget.role.defaultMemoryScope,
    );

    // Extract conversation summary when conversation gets long
    final userMsgCount = _messages.where((m) => m.role == MessageRole.user).length;
    if (userMsgCount > 0 && userMsgCount % 10 == 0) {
      await _extractConversationSummary(conversation.id);
    }
  }

  bool _isImageRequest(String text) {
    final lower = text.toLowerCase();
    return lower.contains('generate image') ||
        lower.contains('create image') ||
        lower.contains('draw ') ||
        lower.contains('generate picture') ||
        lower.contains('create picture') ||
        lower.contains('make an image') ||
        lower.contains('make a picture') ||
        lower.contains('generate a photo') ||
        lower.contains('create a photo') ||
        (lower.startsWith('image:') || lower.startsWith('image ')) ||
        (lower.startsWith('draw:') || lower.startsWith('draw '));
  }

  bool _isDocumentRequest(String text) {
    final lower = text.toLowerCase();
    return lower.contains('generate document') ||
        lower.contains('create document') ||
        lower.contains('generate study guide') ||
        lower.contains('create study guide') ||
        lower.contains('generate quiz') ||
        lower.contains('create quiz') ||
        lower.contains('generate flashcard') ||
        lower.contains('create flashcard') ||
        lower.contains('generate summary') ||
        lower.contains('create summary') ||
        lower.contains('generate lesson plan') ||
        lower.contains('create lesson plan');
  }

  Future<void> _generateImage(String prompt) async {
    if (_isGeneratingImage || _conversation == null) return;

    final conversation = _conversation!;

    HapticFeedbackService.medium();
    _controller.clear();

    String imagePrompt = prompt
        .replaceAll(RegExp(r'^(generate|create|make|draw)\s*(image|picture|photo|a|an)?\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^(image|draw):\s*'), '')
        .trim();

    if (imagePrompt.isEmpty) imagePrompt = prompt;

    imagePrompt = await _imagePromptEnhancer.enhance(imagePrompt);

    final userMessage = ChatMessage(content: prompt, role: MessageRole.user);
    setState(() {
      _messages = [..._messages, userMessage];
      _isGeneratingImage = true;
      _imageGenProgress = 0.0;
    });
    _scrollToBottom();

    ref.read(conversationsProvider.notifier).addMessage(widget.role.id, conversation.id, userMessage);

    final aiMessage = ChatMessage(
      content: 'Generating image...',
      role: MessageRole.assistant,
      isStreaming: true,
    );
    setState(() {
      _messages = [..._messages, aiMessage];
    });
    _scrollToBottom();

    try {
      String? imagePath;
      final settings = _imageGenSettings;
      _imageGenSettings = null;

      // 1. Try cloud (NVIDIA) first
      bool cloudUsed = false;
      if (await _imageLimitTracker.canIncrement(_dailyImageLimit)) {
        try {
          await for (final progress in _cloudImageEngine.generateWithProgress(
            prompt: imagePrompt,
            width: settings?.width ?? 1024,
            height: settings?.height ?? 1024,
            steps: settings?.steps ?? 4,
          )) {
            if (!mounted) return;
            setState(() {
              _imageGenProgress = progress.progress;
            });
            if (progress.isComplete) {
              imagePath = progress.imagePath;
            }
          }
          if (imagePath != null) {
            cloudUsed = true;
            await _imageLimitTracker.increment();
            if (mounted) setState(() => _remainingImageGenToday--);
          }
        } catch (_) {}
      }

      // 2. Fall back to local SD if cloud failed
      if (imagePath == null) {
        final llmEngine = ref.read(aiEngineProvider);
        final wasLlmReady = llmEngine.isReady;
        if (wasLlmReady) {
          try { await llmEngine.dispose(); } catch (_) {}
        }

        try {
          await for (final progress in _localImageEngine.generateWithProgress(
            prompt: imagePrompt,
            width: settings?.width ?? 512,
            height: settings?.height ?? 512,
            steps: settings?.steps ?? 4,
            seed: settings?.seed ?? -1,
          )) {
            if (!mounted) return;
            setState(() {
              _imageGenProgress = progress.progress;
            });
            if (progress.isComplete) imagePath = progress.imagePath;
          }
        } finally {
          if (wasLlmReady && mounted) {
            try {
              await llmEngine.initialize();
              _localImageEngine.setLlmEngine(llmEngine);
            } catch (_) {}
          }
        }
      }

      if (imagePath != null && mounted) {
        final attachment = MessageAttachment(
          type: MessageAttachmentType.image,
          path: imagePath,
          caption: imagePrompt,
        );
        final finalMessage = ChatMessage(
          content: cloudUsed
              ? 'Image generated via cloud: "$imagePrompt"'
              : 'Image generated locally: "$imagePrompt"',
          role: MessageRole.assistant,
          attachments: [attachment],
        );
        setState(() {
          _messages = [..._messages.sublist(0, _messages.length - 1), finalMessage];
          _isGeneratingImage = false;
        });
        _scrollToBottom();

        ref.read(conversationsProvider.notifier).addMessage(widget.role.id, conversation.id, finalMessage);
        HapticFeedbackService.success();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGeneratingImage = false;
          _messages = [..._messages.sublist(0, _messages.length - 1)];
          _lastError = 'Image generation failed: $e';
        });
        HapticFeedbackService.error();
      }
    }
  }

  Future<void> _generateDocument(String prompt) async {
    if (_conversation == null) return;

    final engineSelection = ref.read(engineSelectionProvider);
    final isReady = engineSelection.when(
      data: (s) => s.engine.isReady,
      loading: () => false,
      error: (_, _) => false,
    );

    if (!isReady) {
      final downloaded = await showModelRequiredPrompt(
        context: context,
        ref: ref,
        featureName: 'Document generation',
      );
      if (!downloaded) return;
    }

    final conversation = _conversation!;

    HapticFeedbackService.medium();
    _controller.clear();

    final lower = prompt.toLowerCase();
    DocumentType docType = DocumentType.general;
    String title = 'Generated Document';
    String topic = prompt;

    if (lower.contains('study guide')) {
      docType = DocumentType.studyGuide;
      title = 'Study Guide';
      topic = prompt.replaceAll(RegExp(r'^(generate|create)\s*(study guide)?\s*', caseSensitive: false), '').trim();
    } else if (lower.contains('quiz')) {
      docType = DocumentType.quiz;
      title = 'Quiz';
      topic = prompt.replaceAll(RegExp(r'^(generate|create)\s*quiz\s*', caseSensitive: false), '').trim();
    } else if (lower.contains('flashcard')) {
      docType = DocumentType.flashcards;
      title = 'Flashcards';
      topic = prompt.replaceAll(RegExp(r'^(generate|create)\s*flashcards?\s*', caseSensitive: false), '').trim();
    } else if (lower.contains('summary')) {
      docType = DocumentType.summary;
      title = 'Summary';
      topic = prompt.replaceAll(RegExp(r'^(generate|create)\s*summary\s*', caseSensitive: false), '').trim();
    } else if (lower.contains('lesson plan')) {
      docType = DocumentType.lessonPlan;
      title = 'Lesson Plan';
      topic = prompt.replaceAll(RegExp(r'^(generate|create)\s*lesson plan\s*', caseSensitive: false), '').trim();
    }

    final userMessage = ChatMessage(content: prompt, role: MessageRole.user);
    setState(() {
      _messages = [..._messages, userMessage];
      _isStreaming = true;
    });
    _scrollToBottom();

    ref.read(conversationsProvider.notifier).addMessage(widget.role.id, conversation.id, userMessage);

    final aiMessage = ChatMessage(
      content: 'Generating $title...',
      role: MessageRole.assistant,
      isStreaming: true,
    );
    setState(() {
      _messages = [..._messages, aiMessage];
    });
    _scrollToBottom();

    try {
      final engine = ref.read(aiEngineProvider);

      // Memory-augmented context for document generation
      final retriever = ref.read(memoryRetrieverProvider);
      final memories = await retriever.retrieve(
        query: topic,
        roleId: widget.role.id,
        conversationId: conversation.id,
        topK: 3,
      );
      final memoryLines = memories.map((m) => m.value).toList();
      final docPrompt = DocumentGenService.instance.buildContextPrompt(
        'Create a $title about: $topic. Format it clearly with headings, bullet points, and structured content.',
        memoryLines,
      );

      final content = await engine.generate(
        docPrompt,
        systemPrompt: widget.role.systemPrompt,
      );

      if (!mounted) return;

      final doc = await DocumentGenService.instance.generateFromResponse(
        title: '$title: $topic',
        aiResponse: content,
        type: docType,
        llmEngine: engine,
      );

      // Export to PDF with fallback to markdown if it fails
      String? pdfPath;
      String docxPath;
      String displayPath;
      
      try {
        pdfPath = await DocumentGenService.instance.exportToPdf(doc);
        displayPath = pdfPath;
      } catch (e) {
        // Fallback to markdown if PDF generation fails
        displayPath = await DocumentGenService.instance.exportToMarkdown(doc);
      }

      // Always export to RTF (Word-compatible)
      docxPath = await DocumentGenService.instance.exportToDocx(doc);

      final attachment = MessageAttachment(
        type: MessageAttachmentType.document,
        path: displayPath,
        caption: doc.title,
        metadata: {
          'pdfPath': pdfPath,
          'docxPath': docxPath,
          'docType': docType.label,
          'fallbackFormat': pdfPath == null ? 'markdown' : 'pdf',
        },
      );

      final finalMessage = ChatMessage(
        content: content,
        role: MessageRole.assistant,
        attachments: [attachment],
      );
      setState(() {
        _messages = [..._messages.sublist(0, _messages.length - 1), finalMessage];
        _isStreaming = false;
      });
      _scrollToBottom();

      ref.read(conversationsProvider.notifier).addMessage(widget.role.id, conversation.id, finalMessage);
      HapticFeedbackService.success();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isStreaming = false;
          _messages = [..._messages.sublist(0, _messages.length - 1)];
          _lastError = 'Document generation failed: $e';
        });
        HapticFeedbackService.error();
      }
    }
  }

  Future<void> _extractConversationSummary(String conversationId) async {
    final assistantMessages = _messages
        .where((m) => m.role == MessageRole.assistant && m.content.isNotEmpty)
        .map((m) => m.content)
        .toList();
    final userMessages = _messages
        .where((m) => m.role == MessageRole.user)
        .map((m) => m.content)
        .toList();

    if (assistantMessages.isEmpty || userMessages.isEmpty) return;

    final engine = ref.read(aiEngineProvider);
    try {
      final lastFewUser = userMessages.length > 5
          ? userMessages.sublist(userMessages.length - 5).join('\n')
          : userMessages.join('\n');
      final lastFewAssistant = assistantMessages.length > 5
          ? assistantMessages.sublist(assistantMessages.length - 5).join('\n')
          : assistantMessages.join('\n');

      final prompt = '''
Summarize the key topics and conclusions from this conversation in 2-3 sentences.
Also extract 3-5 topic keywords.

Recent user messages:
$lastFewUser

Recent assistant responses:
$lastFewAssistant

Respond in this exact format:
SUMMARY: [your 2-3 sentence summary]
TOPICS: [keyword1], [keyword2], [keyword3]
''';

      final response = await engine.generate(prompt);
      final summaryMatch = RegExp(r'SUMMARY:\s*(.+)', caseSensitive: false).firstMatch(response);
      final topicsMatch = RegExp(r'TOPICS:\s*(.+)', caseSensitive: false).firstMatch(response);

      if (summaryMatch != null) {
        final summary = summaryMatch.group(1)!.trim();
        final topics = topicsMatch != null
            ? topicsMatch.group(1)!.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList()
            : ['general'];

        await ConversationSummaryStore.instance.addSummary(
          roleId: widget.role.id,
          conversationId: conversationId,
          summary: summary,
          topics: topics,
          importance: 0.6,
        );
      }
    } catch (_) {
      // Silently fail - summary extraction is non-critical
    }
  }

  ({String content, String? thinking, List<String>? planSteps})
  _parseResponse(String raw) {
    String? thinking;
    List<String>? planSteps;
    String content = raw;

    // Single-pass extraction for better performance
    final thinkingStart = raw.indexOf('<thinking>');
    if (thinkingStart != -1) {
      final thinkingEnd = raw.indexOf('</thinking>', thinkingStart);
      if (thinkingEnd != -1) {
        thinking = raw.substring(thinkingStart + 10, thinkingEnd).trim();
        // Remove thinking tag from content
        content = raw.replaceRange(thinkingStart, thinkingEnd + 11, '').trim();
      }
    }

    // Extract plan from the (possibly already cleaned) content
    final planStart = content.indexOf('<plan>');
    if (planStart != -1) {
      final planEnd = content.indexOf('</plan>', planStart);
      if (planEnd != -1) {
        final planRaw = content.substring(planStart + 6, planEnd).trim();
        planSteps = planRaw
            .split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .map((s) => s.replaceFirst(RegExp(r'^Step\s*\d+:\s*'), ''))
            .toList();
        // Remove plan tag from content
        content = content.replaceRange(planStart, planEnd + 7, '').trim();
      }
    }

    return (content: content, thinking: thinking, planSteps: planSteps);
  }

  Future<void> _retryLastMessage() async {
    if (_lastUserMessage == null || _isStreaming) return;
    final text = _lastUserMessage!;
    setState(() {
      _lastError = null;
      _lastUserMessage = null;
    });
    _controller.text = text;
    await _sendMessage();
  }

  Future<void> _toggleVoice() async {
    HapticFeedbackService.tap();
    if (_voiceState == VoiceState.listening) {
      await _voiceService.stopListening();
      if (mounted) setState(() => _voiceState = VoiceState.idle);
    } else {
      if (mounted) setState(() => _voiceState = VoiceState.listening);
      await _voiceService.startListening(continuous: false);
    }
  }

  void _showImageGenDialog() {
    HapticFeedbackService.tap();
    final c = ref.read(themeColorsProvider);

    final promptController = TextEditingController();
    String selectedResolution = '512x512';
    int selectedSteps = 4;
    int selectedSeed = -1;
    final resolutions = ['512x512', '512x768', '768x512', '768x768', '1024x1024'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: c.isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          title: Row(
            children: [
              Icon(Icons.image_outlined, color: c.textPrimary),
              const SizedBox(width: 8),
              Text('Generate Image', style: AppTypography.headlineSmall(c.textPrimary)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_remainingImageGenToday < _dailyImageLimit)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 14, color: c.textSecondary),
                        const SizedBox(width: 6),
                        Text('$_remainingImageGenToday/$_dailyImageLimit cloud today',
                          style: AppTypography.labelSmall(c.textSecondary)),
                      ],
                    ),
                  ),
                TextField(
                  controller: promptController,
                  decoration: InputDecoration(
                    hintText: 'Describe the image you want to create...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: c.cardColor,
                  ),
                  maxLines: 3,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                // Resolution selector
                Row(children: [
                  Icon(Icons.aspect_ratio, size: 18, color: c.textSecondary),
                  const SizedBox(width: 8),
                  Text('Resolution', style: AppTypography.labelMedium(c.textSecondary)),
                ]),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: resolutions.map((res) => Material(
                    color: selectedResolution == res ? c.accent.withValues(alpha: 0.2) : c.cardColor,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () => setDialogState(() => selectedResolution = res),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text(res, style: AppTypography.labelMedium(
                          selectedResolution == res ? c.accent : c.textSecondary,
                        )),
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                // Steps selector
                Row(children: [
                  Icon(Icons.speed, size: 18, color: c.textSecondary),
                  const SizedBox(width: 8),
                  Text('Steps: $selectedSteps', style: AppTypography.labelMedium(c.textSecondary)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove, size: 20),
                    onPressed: selectedSteps > 1 ? () => setDialogState(() => selectedSteps--) : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    onPressed: selectedSteps < 20 ? () => setDialogState(() => selectedSteps++) : null,
                  ),
                ]),
                const SizedBox(height: 16),
                // Quick suggestions
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'A futuristic city at sunset',
                    'A cute robot reading a book',
                    'Abstract colorful patterns',
                    'A peaceful mountain landscape',
                  ].map((suggestion) => Material(
                    color: c.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () {
                        promptController.text = suggestion;
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Text(suggestion, style: AppTypography.labelSmall(c.textSecondary)),
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: c.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                final prompt = promptController.text.trim();
                if (prompt.isNotEmpty) {
                  Navigator.pop(ctx);
                  final parts = selectedResolution.split('x');
                  final width = int.parse(parts[0]);
                  final height = int.parse(parts[1]);
                  _controller.text = 'Generate image: $prompt';
                  _sendMessage();
                  // Store generation settings for use in _generateImage
                  _imageGenSettings = (width: width, height: height, steps: selectedSteps, seed: selectedSeed);
                }
              },
              child: const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDocGenDialog() {
    HapticFeedbackService.tap();
    final c = ref.read(themeColorsProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        title: Row(
          children: [
            Icon(Icons.description_outlined, color: c.textPrimary),
            const SizedBox(width: 8),
            Text('Generate Document', style: AppTypography.headlineSmall(c.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DocTypeTile(
              icon: Icons.menu_book,
              label: 'Study Guide',
              description: 'Create a structured study guide',
              isDark: c.isDark,
              onTap: () {
                Navigator.pop(ctx);
                _controller.text = 'Generate study guide: ';
                _focusNode.requestFocus();
              },
            ),
            DocTypeTile(
              icon: Icons.quiz,
              label: 'Quiz',
              description: 'Generate quiz questions',
              isDark: c.isDark,
              onTap: () {
                Navigator.pop(ctx);
                _controller.text = 'Generate quiz: ';
                _focusNode.requestFocus();
              },
            ),
            DocTypeTile(
              icon: Icons.style,
              label: 'Flashcards',
              description: 'Create flashcards for studying',
              isDark: c.isDark,
              onTap: () {
                Navigator.pop(ctx);
                _controller.text = 'Generate flashcards: ';
                _focusNode.requestFocus();
              },
            ),
            DocTypeTile(
              icon: Icons.summarize,
              label: 'Summary',
              description: 'Generate a concise summary',
              isDark: c.isDark,
              onTap: () {
                Navigator.pop(ctx);
                _controller.text = 'Generate summary: ';
                _focusNode.requestFocus();
              },
            ),
            DocTypeTile(
              icon: Icons.school,
              label: 'Lesson Plan',
              description: 'Create a lesson plan',
              isDark: c.isDark,
              onTap: () {
                Navigator.pop(ctx);
                _controller.text = 'Generate lesson plan: ';
                _focusNode.requestFocus();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: c.textSecondary)),
          ),
        ],
      ),
    );
  }

  void _cycleResponseMode() {
    HapticFeedbackService.tap();
    setState(() {
      _responseMode = switch (_responseMode) {
        ResponseMode.chat => ResponseMode.thinking,
        ResponseMode.thinking => ResponseMode.plan,
        ResponseMode.plan => ResponseMode.chat,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(themeColorsProvider);
    return Scaffold(
      appBar: ChatAppBar(
        role: widget.role,
        isStreaming: _isStreaming,
        responseMode: _responseMode,
        qaMode: _qaMode,
        onCycleResponseMode: _cycleResponseMode,
        onToggleQaMode: () {
          setState(() {
            _qaMode = !_qaMode;
            if (!_qaMode) _qaService.clear();
          });
          HapticFeedbackService.tap();
        },
        onHistory: () => context.pushNamed('chatHistory', extra: widget.role.id),
        onMoreOptions: () => _showRoleInfo(context, c.isDark),
      ),
      body: Column(
        children: [
          Divider(
            color: c.isDark ? AppColors.borderDark : AppColors.borderLight,
            thickness: 2,
            height: 2,
          ),
          SystemMessageBanner(
            error: _lastError,
            isStreaming: _isStreaming,
            onRetry: _retryLastMessage,
            onDismiss: () => setState(() {
              _lastError = null;
              _lastUserMessage = null;
            }),
          ),
          Expanded(
            child: ConversationList(
              messages: _messages,
              scrollController: _scrollController,
              isDark: c.isDark,
              role: widget.role,
              onQuickAction: (text) {
                _controller.text = text;
                _sendMessage();
              },
            ),
          ),
          if (_qaMode)
            ContextPanel(
              qaService: _qaService,
              isDark: c.isDark,
              onClose: () {
                setState(() {
                  _qaMode = false;
                  _qaService.clear();
                });
              },
            ),
          if (_pendingImagePath != null || _pendingFilePath != null)
            _buildPendingAttachment(c),
          ChatInputBar(
            controller: _controller,
            focusNode: _focusNode,
            isDark: c.isDark,
            isStreaming: _isStreaming,
            voiceEnabled: _voiceEnabled,
            voiceState: _voiceState,
            isGeneratingImage: _isGeneratingImage,
            imageGenProgress: _imageGenProgress,
            onSend: _sendMessage,
            onVoice: _toggleVoice,
            onImageGen: _showImageGenDialog,
            onDocGen: _showDocGenDialog,
            onAttachImage: _pickImage,
            onAttachFile: _pickFile,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingAttachment(ThemeColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: c.cardColor,
        border: Border(top: BorderSide(color: c.borderColor)),
      ),
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

  void _showRoleInfo(BuildContext context, bool isDark) {
    showRoleInfo(context, ref, widget.role, isDark);
  }
}
