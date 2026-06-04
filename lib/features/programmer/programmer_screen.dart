import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/engine_providers.dart';
import '../../core/ai/ai_engine.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/theme/theme_colors.dart';
import 'programmer_types.dart';
import 'widgets/chat_panel.dart';
import 'widgets/code_editor_panel.dart';
import 'widgets/preview_panel.dart';

const String defaultHtmlTemplate = '''<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: system-ui, sans-serif; padding: 20px; background: #f5f5f5; }
    h1 { color: #333; }
  </style>
</head>
<body>
  <h1>Hello, World!</h1>
  <p>Start editing or ask the AI to teach you something!</p>
</body>
</html>''';

class ProgrammerScreen extends ConsumerStatefulWidget {
  const ProgrammerScreen({super.key});

  @override
  ConsumerState<ProgrammerScreen> createState() => _ProgrammerScreenState();
}

class _ProgrammerScreenState extends ConsumerState<ProgrammerScreen> {
  int _currentTab = 0;
  String _htmlCode = defaultHtmlTemplate;
  final List<ChatMessage> _messages = [];
  bool _isAiResponding = false;
  int _previewKey = 0;
  bool _isEngineReady = false;
  bool _engineCheckDone = false;
  final _chatTextController = TextEditingController();
  final _chatScrollController = ScrollController();
  late final TextEditingController _codeController;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: _htmlCode);
    _checkEngine();
    _messages.add(ChatMessage(
      role: 'ai',
      content:
          'Welcome to the Programmer! I can teach you HTML, CSS, and JavaScript. '
          'Try asking me to explain a concept or generate code for you.',
    ));
  }

  @override
  void dispose() {
    _chatTextController.dispose();
    _chatScrollController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _checkEngine() {
    final engine = ref.read(aiEngineProvider);
    final isMock = engine.engineName == 'MockAI' || engine is MockAIEngine;
    if (mounted) {
      setState(() {
        _isEngineReady = !isMock;
        _engineCheckDone = true;
      });
    }
  }

  void _runCode() {
    FocusScope.of(context).unfocus();
    setState(() => _previewKey++);
  }

  void _switchToCode() {
    FocusScope.of(context).unfocus();
    setState(() => _currentTab = 1);
  }

  Future<void> _sendToAi(String message) async {
    if (message.trim().isEmpty || _isAiResponding) return;

    FocusScope.of(context).unfocus();

    final userMsg = ChatMessage(role: 'user', content: message);
    final aiMsg = ChatMessage(role: 'ai', content: '', isStreaming: true);

    setState(() {
      _messages.add(userMsg);
      _messages.add(aiMsg);
      _isAiResponding = true;
    });

    _chatTextController.clear();

    try {
      final engine = ref.read(aiEngineProvider);
      final buffer = StringBuffer();

      const systemPrompt =
          'You are an expert HTML/CSS/JS tutor teaching an absolute beginner. '
          'Teach web development fundamentals through interactive examples. '
          'Always provide COMPLETE, RUNNABLE HTML code between ```html and ``` markers. '
          'Explain concepts simply with analogies. '
          'After providing code, encourage the student to modify and experiment. '
          'Keep examples small and focused on one concept at a time. '
          'Never use external CSS/JS files or CDN links. '
          'Everything must be self-contained in one HTML file.';

      final history = _messages
          .where((m) => m.role == 'user' || (m.role == 'ai' && !m.isStreaming))
          .map((m) => MessageEntry(role: m.role, content: m.content))
          .toList();

      await for (final chunk in engine.generateStream(
          message, systemPrompt: systemPrompt, history: history)) {
        buffer.write(chunk);
        if (mounted) {
          setState(() {
            _messages.last = ChatMessage(
                role: 'ai', content: buffer.toString(), isStreaming: true);
          });
        }
        _scrollChatToBottom();
      }

      if (!mounted) return;
      final fullResponse = buffer.toString();
      setState(() {
        _messages.last = ChatMessage(
            role: 'ai', content: fullResponse, isStreaming: false);
        _isAiResponding = false;
      });

      _extractAndInsertCode(fullResponse);
    } catch (e) {
      if (!mounted) return;
      final errMsg = e.toString();
      final friendly = errMsg.contains('timeout')
          ? 'The AI took too long to respond. Check your internet connection or try a simpler question.'
          : errMsg.contains('SocketException') || errMsg.contains('HandshakeException')
              ? 'Network error. Make sure you are connected to the internet and try again.'
              : 'AI error: $errMsg';
      setState(() {
        _messages.last =
            ChatMessage(role: 'ai', content: friendly, isStreaming: false);
        _isAiResponding = false;
      });
    }
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 50),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _extractAndInsertCode(String response) {
    final regex = RegExp(r'```(?:html|css|javascript|js)?\s*\n([\s\S]*?)```');
    final matches = regex.allMatches(response);
    if (matches.isNotEmpty) {
      final code = matches.first.group(1)?.trim();
      if (code != null && code.isNotEmpty) {
        _htmlCode = code;
        _codeController.text = code;
        _previewKey++;
      }
    }
  }

  void _insertCode(String code) {
    _htmlCode = code;
    _codeController.text = code;
    _previewKey++;
    _switchToCode();
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);

    return Scaffold(
      backgroundColor: c.surfaceColor,
      appBar: _buildAppBar(c),
      body: Column(
        children: [
          _buildTabBar(c),
          Expanded(child: _buildCurrentTab(c)),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeColors c) {
    return AppBar(
      backgroundColor: c.surfaceColor,
      elevation: 0,
      title: Text('PROGRAMMER', style: AppTypography.headlineSmall(c.textPrimary)),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: c.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        TextButton.icon(
          onPressed: _runCode,
          icon: Icon(Icons.play_arrow, color: AppColors.success),
          label: Text('RUN', style: AppTypography.labelSmall(AppColors.success)),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildTabBar(ThemeColors c) {
    const tabs = ['CHAT', 'CODE', 'RUN'];
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.borderColor, width: 2)),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final sel = _currentTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _currentTab = i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: sel ? c.accent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tabs[i],
                  textAlign: TextAlign.center,
                  style: AppTypography.labelMedium(
                      sel ? c.accent : c.textSecondary),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentTab(ThemeColors c) {
    switch (_currentTab) {
      case 0:
        return ChatPanel(
          messages: _messages,
          isAiResponding: _isAiResponding,
          isEngineReady: _engineCheckDone ? _isEngineReady : null,
          textController: _chatTextController,
          scrollController: _chatScrollController,
          onSend: _sendToAi,
          onInsertCode: _insertCode,
          themeColors: c,
        );
      case 1:
        return CodeEditorPanel(
          controller: _codeController,
          onChanged: (v) => _htmlCode = v,
          themeColors: c,
        );
      case 2:
        return PreviewPanel(
          key: ValueKey('preview_$_previewKey'),
          htmlCode: _htmlCode,
          themeColors: c,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class MockAIEngine implements AIEngine {
  @override
  String get engineName => 'MockAI';

  @override
  DeviceTier get tier => DeviceTier.lowEnd;

  @override
  bool get isReady => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<String> generate(String prompt,
      {String? systemPrompt, List<MessageEntry>? history}) async {
    return 'Mock AI response. Configure a model or cloud API in Settings.';
  }

  @override
  Stream<String> generateStream(String prompt,
      {String? systemPrompt, List<MessageEntry>? history}) async* {
    yield 'Mock AI response. Configure a model or cloud API in Settings.';
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<void> handleMemoryPressure() async {}
}
