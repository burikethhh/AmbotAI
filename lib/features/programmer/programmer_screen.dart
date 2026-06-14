import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/engine_providers.dart';
import '../../core/ai/ai_engine.dart';
import '../../core/ai/engines/mock_engine.dart';
import '../../core/ai/engines/openai_engine.dart';
import '../../core/ai/nvidia_models.dart';
import '../../core/rag/app_knowledge.dart';
import '../../core/config/api_keys.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/theme/theme_colors.dart';
import 'highlighted_code_controller.dart';
import 'language_registry.dart';
import 'programmer_store.dart';
import 'programmer_types.dart';
import 'widgets/chat_panel.dart';
import 'widgets/code_editor_panel.dart';
import 'widgets/preview_panel.dart';

List<ProjectFile> _defaultProjectForLang(LanguageConfig lang) {
  return [
    ProjectFile(
      filename: lang.defaultFilename,
      content: lang.defaultContent ?? '',
      language: lang.id,
    ),
  ];
}

final List<ProjectFile> defaultProject = _defaultProjectForLang(LanguageRegistry.fallback());

class ProgrammerScreen extends ConsumerStatefulWidget {
  const ProgrammerScreen({super.key});

  @override
  ConsumerState<ProgrammerScreen> createState() => _ProgrammerScreenState();
}

class _ProgrammerScreenState extends ConsumerState<ProgrammerScreen> {
  int _currentTab = 0;
  int _selectedFileIndex = 0;
  late final List<ProjectFile> _projectFiles;
  final List<ChatMessage> _messages = [];
  bool _isAiResponding = false;
  int _previewKey = 0;
  bool _engineCheckDone = false;
  final _chatTextController = TextEditingController();
  final _chatScrollController = ScrollController();
  late final HighlightedCodeController _codeController;
  late AIEngine _programmerEngine;
  bool _programmerEngineReady = false;
  Timer? _saveTimer;
  NvidiaModel _selectedProgrammerModel = NvidiaModelCatalog.nemotron3Super;
  bool _showModelSelector = false;
  LanguageConfig _selectedLanguage = LanguageRegistry.fallback();

  @override
  void initState() {
    super.initState();
    final saved = ProgrammerStore.instance.loadCurrentProject();
    _projectFiles = saved != null ? List.from(saved) : List.from(defaultProject);
    if (_projectFiles.isNotEmpty) {
      _selectedLanguage = LanguageRegistry.findByFilename(_projectFiles.first.filename) ?? LanguageRegistry.fallback();
    }
    _codeController = HighlightedCodeController(
      text: _currentFileContent,
      language: _currentFileLanguage,
    );
    _initProgrammerEngine();
    _messages.add(ChatMessage(
      role: 'ai',
      content:
          'Welcome to the Programmer! I can help you code in ${LanguageRegistry.all.map((l) => l.name).join(", ")}. '
          'Pick a language from the selector above or just ask me to build something!',
    ));
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _chatTextController.dispose();
    _chatScrollController.dispose();
    _codeController.dispose();
    _programmerEngine.dispose();
    super.dispose();
  }

  void _autoSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 1), () {
      ProgrammerStore.instance.saveCurrentProject(_projectFiles);
    });
  }

  String get _currentFileContent {
    if (_selectedFileIndex < _projectFiles.length) {
      return _projectFiles[_selectedFileIndex].content;
    }
    return '';
  }

  String get _currentFileLanguage {
    if (_selectedFileIndex < _projectFiles.length) {
      return _projectFiles[_selectedFileIndex].language;
    }
    return 'html';
  }

  void _onCodeChanged(String value) {
    if (_selectedFileIndex < _projectFiles.length) {
      final old = _projectFiles[_selectedFileIndex];
      _projectFiles[_selectedFileIndex] = old.copyWith(content: value);
    }
    _autoSave();
  }

  Future<void> _initProgrammerEngine() async {
    final nvidiaKey = ApiKeys.nvidiaKey1.isNotEmpty
        ? ApiKeys.nvidiaKey1
        : (ApiKeys.nvidiaKey2.isNotEmpty ? ApiKeys.nvidiaKey2 : null);

    if (nvidiaKey != null) {
      await _tryInitEngine(nvidiaKey, _selectedProgrammerModel);
    } else {
      final engine = ref.read(aiEngineProvider);
      final isMock = engine.engineName == 'MockAI' || engine is MockAIEngine;
      _programmerEngine = engine;
      if (mounted) {
        setState(() {
          _programmerEngineReady = !isMock;
          _engineCheckDone = true;
        });
      }
    }
  }

  Future<void> _tryInitEngine(String apiKey, NvidiaModel model) async {
    try {
      final engine = _buildEngineForModel(apiKey, model);
      await engine.initialize();
      _programmerEngine = engine;
      if (mounted) {
        setState(() {
          _programmerEngineReady = true;
          _engineCheckDone = true;
        });
      }
    } catch (e) {
      debugPrint('PROGRAMMER: engine init failed for ${model.id}: $e');
      // Fallback: try the default NVIDIA model
      await _fallbackToDefaultEngine(apiKey);
    }
  }

  Future<void> _fallbackToDefaultEngine(String apiKey) async {
    try {
      final engine = OpenAIEngine.nvidiaNim(
        apiKey: apiKey,
        model: 'meta/llama-3.3-70b-instruct',
        maxTokens: 4096,
      );
      await engine.initialize();
      _programmerEngine = engine;
      if (mounted) {
        setState(() {
          _selectedProgrammerModel = NvidiaModelCatalog.llama33_70b;
          _programmerEngineReady = true;
          _engineCheckDone = true;
        });
      }
    } catch (e2) {
      debugPrint('PROGRAMMER: fallback engine also failed: $e2');
      if (mounted) {
        setState(() {
          _programmerEngineReady = false;
          _engineCheckDone = true;
        });
      }
    }
  }

  AIEngine _buildEngineForModel(String apiKey, NvidiaModel model) {
    switch (model.provider) {
      case NvidiaModelProvider.openRouter:
        return OpenAIEngine.openRouter(
          apiKey: apiKey,
          model: model.id,
        );
      case NvidiaModelProvider.nvidia:
        return OpenAIEngine.nvidiaNim(
          apiKey: apiKey,
          model: model.id,
          maxTokens: model.maxTokens,
        );
      case NvidiaModelProvider.qwen:
        return OpenAIEngine.qwen(
          apiKey: apiKey,
          model: model.id,
        );
    }
  }

  void _onProgrammerModelChanged(NvidiaModel model) {
    final nvidiaKey = ApiKeys.nvidiaKey1.isNotEmpty
        ? ApiKeys.nvidiaKey1
        : (ApiKeys.nvidiaKey2.isNotEmpty ? ApiKeys.nvidiaKey2 : null);
    if (nvidiaKey == null) return;

    setState(() {
      _selectedProgrammerModel = model;
      _showModelSelector = false;
      _engineCheckDone = false;
    });
    _programmerEngine.dispose();
    _tryInitEngine(nvidiaKey, model);
  }

  void _selectFile(int index) {
    if (index == _selectedFileIndex) return;
    _codeController.text = _projectFiles[index].content;
    _codeController.language = _projectFiles[index].language;
    setState(() => _selectedFileIndex = index);
  }

  void _runCode() {
    FocusScope.of(context).unfocus();
    setState(() => _previewKey++);
  }

  void _switchToCode() {
    FocusScope.of(context).unfocus();
    setState(() => _currentTab = 1);
  }

  String _assemblePreviewHtml() {
    String html = '';
    String css = '';
    String js = '';

    for (final file in _projectFiles) {
      final name = file.filename.toLowerCase();
      if (name.endsWith('.html')) {
        html = file.content;
      } else if (name.endsWith('.css')) {
        css = file.content;
      } else if (name.endsWith('.js')) {
        js = file.content;
      }
    }

    if (html.isEmpty) {
      html = '<!DOCTYPE html><html><head><meta charset="UTF-8"></head><body></body></html>';
    }

    if (css.isNotEmpty && html.contains('</head>')) {
      final styleTag = '<style>\n$css\n</style>\n';
      html = html.replaceFirst('</head>', '$styleTag</head>');
    } else if (css.isNotEmpty) {
      html = html.replaceFirst('<head>', '<head>\n<style>\n$css\n</style>\n');
    }

    if (js.isNotEmpty && html.contains('</body>')) {
      final scriptTag = '<script>\n$js\n</script>\n';
      html = html.replaceFirst('</body>', '$scriptTag</body>');
    } else if (js.isNotEmpty) {
      html = '$html\n<script>\n$js\n</script>';
    }

    html = html.replaceAll('href="style.css"', '');
    html = html.replaceAll('src="script.js"', '');

    return html;
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
      final buffer = StringBuffer();

      final currentFiles = _projectFiles.map((f) =>
          '// file: ${f.filename}\n${f.content}').join('\n\n');

      final langNames = LanguageRegistry.all.map((l) => l.name).join(', ');
      final appKnowledge = AppKnowledge.buildContext(message);
      final systemPrompt =
          'You are an expert programmer and tutor. You help users code in any language: $langNames.$appKnowledge\n\n'
          'IMPORTANT: Always output SEPARATE files using this format:\n'
          '```<language>\n'
          '// file: <filename>\n'
          '<code>\n'
          '```\n\n'
          'Examples:\n'
          '```python\n'
          '# file: main.py\n'
          'print("Hello World")\n'
          '```\n'
          '```javascript\n'
          '// file: index.js\n'
          'console.log("Hello World");\n'
          '```\n'
          '```html\n'
          '// file: index.html\n'
          '<!DOCTYPE html>...\n'
          '```\n\n'
          'The current project has these files:\n'
          '$currentFiles\n\n'
          'When suggesting changes, output the COMPLETE updated files with the file: marker.\n'
          'Use modern best practices for the language.\n'
          'Explain concepts simply with analogies for beginners.\n'
          'Keep examples focused on one concept at a time.';

      final history = _messages
          .where((m) => m.role == 'user' || (m.role == 'ai' && !m.isStreaming))
          .map((m) => MessageEntry(
              role: m.role == 'ai' ? 'assistant' : 'user',
              content: m.content))
          .toList();

      await for (final chunk in _programmerEngine.generateStream(
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

      _extractAndInsertFiles(fullResponse);
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

  void _extractAndInsertFiles(String response) {
    final fileRegex = RegExp(
      r'```(\w+)\s*\n(?://|/\*|#)\s*file:\s*(\S+)\s*(?:\*/)?\n([\s\S]*?)```',
      caseSensitive: false,
    );
    final matches = fileRegex.allMatches(response);

    if (matches.isEmpty) {
      final fallbackRegex = RegExp(r'```(\w+)\s*\n([\s\S]*?)```');
      final fallbackMatches = fallbackRegex.allMatches(response);
      if (fallbackMatches.isNotEmpty) {
        final code = fallbackMatches.first.group(2)?.trim();
        if (code != null && code.isNotEmpty) {
          final htmlIdx = _projectFiles.indexWhere(
              (f) => f.filename.endsWith('.html'));
          if (htmlIdx != -1) {
            _projectFiles[htmlIdx] = _projectFiles[htmlIdx].copyWith(content: code);
            if (_selectedFileIndex == htmlIdx) {
              _codeController.text = code;
            }
            _previewKey++;
          }
        }
      }
      return;
    }

    bool changed = false;
    for (final match in matches) {
      final lang = match.group(1)!.toLowerCase();
      final rawFilename = match.group(2)!.trim();
      final code = match.group(3)!.trim();

      final filename = rawFilename.contains('.')
          ? rawFilename
          : _filenameFromLanguage(lang);

      final ext = filename.contains('.')
          ? filename.substring(filename.lastIndexOf('.'))
          : '.html';

      final existingIdx = _projectFiles.indexWhere(
          (f) => f.filename == filename || f.filename.endsWith(ext));

      if (existingIdx != -1) {
        final newLang = _langFromExt(ext);
        _projectFiles[existingIdx] = _projectFiles[existingIdx].copyWith(
          content: code,
          language: newLang,
        );
        if (_selectedFileIndex == existingIdx) {
          _codeController.text = code;
          _codeController.language = newLang;
        }
      } else {
        _projectFiles.add(ProjectFile(
          filename: filename,
          content: code,
          language: _langFromExt(ext),
        ));
      }
      changed = true;
    }

    if (changed && mounted) {
      setState(() {});
      _previewKey++;
      _switchToCode();
    }
    _autoSave();
  }

  String _filenameFromLanguage(String lang) {
    final config = LanguageRegistry.findById(lang);
    return config?.defaultFilename ?? 'index.html';
  }

  String _langFromExt(String ext) {
    final config = LanguageRegistry.findByExtension(ext);
    return config?.id ?? 'html';
  }

  void _insertCode(String code) {
    if (_projectFiles.isEmpty) return;
    final idx = _selectedFileIndex.clamp(0, _projectFiles.length - 1);
    _projectFiles[idx] = _projectFiles[idx].copyWith(content: code);
    _codeController.text = code;
    _previewKey++;
    _switchToCode();
    _autoSave();
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

  void _deleteCurrentFile(int index) {
    if (_projectFiles.length <= 1) return;
    final targetIdx = index.clamp(0, _projectFiles.length - 1);
    _projectFiles.removeAt(targetIdx);
    final newIdx = _selectedFileIndex.clamp(0, _projectFiles.length - 1);
    if (_selectedFileIndex > targetIdx || _selectedFileIndex >= _projectFiles.length) {
      _codeController.text = _projectFiles[newIdx].content;
    }
    _selectFile(newIdx);
    setState(() {});
    _autoSave();
  }

  void _showAddFileDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('NEW FILE'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: 'main.py / index.html / script.js / Main.java',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty && name.contains('.')) {
                final ext = name.substring(name.lastIndexOf('.'));
                final lang = _langFromExt(ext);
                _projectFiles.add(ProjectFile(filename: name, content: '', language: lang));
                _selectFile(_projectFiles.length - 1);
                setState(() {});
                _autoSave();
              }
              Navigator.pop(ctx);
            },
            child: const Text('ADD'),
          ),
        ],
      ),
    );
  }

  void _switchLanguage(LanguageConfig lang) {
    setState(() {
      _selectedLanguage = lang;
      if (_projectFiles.isEmpty) {
        _projectFiles.addAll(_defaultProjectForLang(lang));
        _selectFile(0);
      }
    });
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
      title: Row(
        children: [
          Text('PROGRAMMER', style: AppTypography.headlineSmall(c.textPrimary)),
          const SizedBox(width: 12),
          _buildLanguageDropdown(c),
        ],
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: c.textPrimary),
        tooltip: 'Back',
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.memory, color: c.textSecondary, size: 20),
          tooltip: 'Switch model',
          onPressed: () => _showModelSelector = !_showModelSelector,
        ),
        if (_showModelSelector)
          SizedBox(
            width: 200,
            child: _buildModelDropdown(c),
          ),
        IconButton(
          icon: Icon(Icons.add, color: c.textPrimary, size: 20),
          tooltip: 'New file',
          onPressed: _showAddFileDialog,
        ),
        TextButton.icon(
          onPressed: _runCode,
          icon: Icon(Icons.play_arrow, color: AppColors.success),
          label: Text('RUN', style: AppTypography.labelSmall(AppColors.success)),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildLanguageDropdown(ThemeColors c) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: c.borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLanguage.id,
          isDense: true,
          dropdownColor: c.surfaceColor,
          style: AppTypography.labelSmall(c.textPrimary),
          items: LanguageRegistry.all.map((lang) {
            return DropdownMenuItem(
              value: lang.id,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: lang.tabColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(lang.name),
                ],
              ),
            );
          }).toList(),
          onChanged: (id) {
            if (id == null) return;
            final lang = LanguageRegistry.findById(id);
            if (lang != null) _switchLanguage(lang);
          },
        ),
      ),
    );
  }

  Widget _buildModelDropdown(ThemeColors c) {
    return Container(
      height: 36,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: c.borderColor),
        borderRadius: BorderRadius.circular(2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedProgrammerModel.id,
          isExpanded: true,
          dropdownColor: c.surfaceColor,
          style: AppTypography.labelSmall(c.textPrimary),
          items: NvidiaModelCatalog.programmerModels.map((m) {
            return DropdownMenuItem(
              value: m.id,
              child: Text(m.name, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (id) {
            if (id == null) return;
            final model = NvidiaModelCatalog.programmerModels.firstWhere(
              (m) => m.id == id,
            );
            _onProgrammerModelChanged(model);
          },
        ),
      ),
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
          isEngineReady: _engineCheckDone ? _programmerEngineReady : null,
          textController: _chatTextController,
          scrollController: _chatScrollController,
          onSend: _sendToAi,
          onInsertCode: _insertCode,
          themeColors: c,
        );
      case 1:
        return CodeEditorPanel(
          controller: _codeController,
          onChanged: _onCodeChanged,
          projectFiles: _projectFiles,
          selectedFileIndex: _selectedFileIndex,
          onSelectFile: _selectFile,
          onDeleteFile: _deleteCurrentFile,
          themeColors: c,
        );
      case 2:
        return PreviewPanel(
          key: ValueKey('preview_$_previewKey'),
          htmlCode: _assemblePreviewHtml(),
          themeColors: c,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
