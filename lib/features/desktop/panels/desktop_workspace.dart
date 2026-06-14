import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/app_version.dart';
import '../ai/local_ai_manager.dart';
import '../ai/model_download_manager.dart';
import '../ai/model_recommendation_engine.dart';
import '../ai/performance_monitor.dart';
import '../agent/agent_engine.dart';
import '../agent/agent_tool.dart';
import '../agent/permission_manager.dart';
import '../agent/tools/file_tools.dart';
import '../agent/tools/shell_tools.dart';
import 'activity_bar.dart';
import 'side_panel.dart';
import 'resizable_panel.dart';
import 'session_tab_bar.dart';
import 'agent_chat_screen.dart';
import 'context_panel.dart';
import 'code_preview.dart';
import '../desktop_colors.dart';
import '../terminal/terminal_shell.dart';

class DesktopWorkspace extends StatefulWidget {
  const DesktopWorkspace({super.key});

  @override
  State<DesktopWorkspace> createState() => _DesktopWorkspaceState();
}

class _DesktopWorkspaceState extends State<DesktopWorkspace> {
  static const _kContextPanelRatio = 'ws_context_ratio';
  static const _kContextCollapsed = 'ws_context_collapsed';
  static const _kTerminalVisible = 'ws_terminal_visible';
  static const _kFocusMode = 'ws_focus_mode';
  static const _kActivity = 'ws_activity';

  final List<AgentSession> _sessions = [];
  int _activeSessionIndex = 0;
  bool _contextPanelCollapsed = false;
  bool _terminalVisible = false;
  bool _focusMode = false;
  double _contextRatio = 0.7;
  ActivityType _activeActivity = ActivityType.files;
  String? _selectedFilePath;
  final List<String> _openFiles = [];
  String? _activeFile;

  final List<AgentMessage> _messages = [];
  bool _isStreaming = false;
  final List<ContextFile> _contextFiles = [];
  final List<AgentLogEntry> _logs = [];

  HardwareInfo? _hardwareInfo;
  PerformanceMetrics? _latestMetrics;
  StreamSubscription<PerformanceMetrics>? _metricsSub;

  late final LocalAIManager _aiManager;
  late final AgentEngine _agentEngine;
  late final PermissionManager _permissionManager;

  @override
  void initState() {
    super.initState();
    _initAgent();
    _loadLayout();
    _addSession('New Session', 'build');
    _logs.add(AgentLogEntry(
      time: '00:00',
      level: 'info',
      message: 'Workspace initialized',
    ));
  }

  void _initAgent() {
    _aiManager = LocalAIManager();
    _permissionManager = PermissionManager();

    final registry = ToolRegistry();
    registry.registerAll([
      ReadFileTool(),
      WriteFileTool(),
      EditFileTool(),
      ListDirectoryTool(),
      ShellTool(),
      SearchFilesTool(),
      GrepTool(),
    ]);

    _agentEngine = AgentEngine(
      registry: registry,
      permissionManager: _permissionManager,
    );

    _aiManager.addListener(_onAiStateChanged);
    _aiManager.initialize();
    _metricsSub = _aiManager.performanceMonitor.metricsStream.listen((m) {
      if (mounted) setState(() => _latestMetrics = m);
    });
    _aiManager.getHardwareInfo().then((h) {
      if (mounted) setState(() => _hardwareInfo = h);
    });

    _logs.add(AgentLogEntry(
      time: _timeNow(),
      level: 'info',
      message: 'Agent engine initialized with ${registry.all.length} tools',
    ));
  }

  void _onAiStateChanged() {
    if (!mounted) return;
    if (_aiManager.state == ModelState.ready && _aiManager.engine != null) {
      _agentEngine.setLlm(_aiManager.engine);
      setState(() {
        _logs.add(AgentLogEntry(
          time: _timeNow(),
          level: 'success',
          message: 'Local AI model loaded: ${_aiManager.currentModel?.name ?? "unknown"}',
        ));
      });
    } else if (_aiManager.state == ModelState.error) {
      setState(() {
        _logs.add(AgentLogEntry(
          time: _timeNow(),
          level: 'error',
          message: 'AI error: ${_aiManager.error ?? "unknown"}',
        ));
      });
    }
  }

  @override
  void dispose() {
    _aiManager.removeListener(_onAiStateChanged);
    _metricsSub?.cancel();
    _agentEngine.dispose();
    _aiManager.dispose();
    _permissionManager.dispose();
    super.dispose();
  }

  Future<void> _loadLayout() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _contextRatio = prefs.getDouble(_kContextPanelRatio) ?? 0.7;
      _contextPanelCollapsed = prefs.getBool(_kContextCollapsed) ?? false;
      _terminalVisible = prefs.getBool(_kTerminalVisible) ?? false;
      _focusMode = prefs.getBool(_kFocusMode) ?? false;
      final activityIndex = prefs.getInt(_kActivity) ?? 0;
      _activeActivity = ActivityType.values[activityIndex.clamp(0, ActivityType.values.length - 1)];
    });
  }

  Future<void> _saveLayout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kContextPanelRatio, _contextRatio);
    await prefs.setBool(_kContextCollapsed, _contextPanelCollapsed);
    await prefs.setBool(_kTerminalVisible, _terminalVisible);
    await prefs.setBool(_kFocusMode, _focusMode);
    await prefs.setInt(_kActivity, _activeActivity.index);
  }

  void _toggleFocusMode() {
    setState(() {
      _focusMode = !_focusMode;
      if (_focusMode) {
        _contextPanelCollapsed = true;
        _terminalVisible = false;
      }
    });
    _saveLayout();
  }

  void _addSession(String title, String agentType) {
    setState(() {
      _sessions.add(AgentSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        agentType: agentType,
      ));
      _activeSessionIndex = _sessions.length - 1;
    });
  }

  void _sendMessage(String text) {
    setState(() {
      _messages.add(AgentMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.user,
        content: text,
        timestamp: DateTime.now(),
      ));
      _isStreaming = true;
      _logs.add(AgentLogEntry(
        time: _timeNow(),
        level: 'info',
        message: 'User: $text',
      ));
    });
    _runAgent(text);
  }

  Future<void> _runAgent(String userMessage) async {
    try {
      final execution = await _agentEngine.execute(userMessage);

      if (!mounted) return;

      for (final step in execution.steps) {
        setState(() {
          _messages.add(AgentMessage(
            id: 'tool_${step.toolId}_${step.timestamp.millisecondsSinceEpoch}',
            role: MessageRole.agent,
            content: '',
            timestamp: step.timestamp,
            toolCall: ToolCall(
              name: step.toolId,
              parameters: step.parameters,
              thinking: step.thinking,
            ),
          ));

          if (step.result != null) {
            _messages.add(AgentMessage(
              id: 'result_${step.toolId}_${step.timestamp.millisecondsSinceEpoch}',
              role: MessageRole.tool,
              content: step.result!.title,
              timestamp: step.timestamp,
              toolResult: ChatToolResult(
                title: step.result!.title,
                content: step.result!.content,
                success: step.result!.success,
              ),
            ));
          }

          _logs.add(AgentLogEntry(
            time: _timeNow(),
            level: step.result?.success == true ? 'success' : 'error',
            message: '${step.toolId}: ${step.result?.title ?? "pending"}',
          ));
        });
      }

      setState(() {
        _messages.add(AgentMessage(
          id: 'answer_${execution.id}',
          role: MessageRole.agent,
          content: execution.finalAnswer ?? 'No response generated.',
          timestamp: DateTime.now(),
        ));
        _isStreaming = false;
        _logs.add(AgentLogEntry(
          time: _timeNow(),
          level: 'success',
          message: 'Agent completed in ${execution.steps.length} steps',
        ));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(AgentMessage(
          id: 'error_${DateTime.now().millisecondsSinceEpoch}',
          role: MessageRole.system,
          content: 'Error: $e',
          timestamp: DateTime.now(),
        ));
        _isStreaming = false;
        _logs.add(AgentLogEntry(
          time: _timeNow(),
          level: 'error',
          message: 'Agent error: $e',
        ));
      });
    }
  }

  void _onFileSelected(String path) {
    setState(() {
      _selectedFilePath = path;
      if (!_openFiles.contains(path)) {
        _openFiles.add(path);
      }
      _activeFile = path;
    });
  }

  String _timeNow() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: dcBg,
      body: Column(
        children: [
          _buildTitleBar(),
          Expanded(
            child: Row(
              children: [
                if (!_focusMode) ActivityBar(
                  activeActivity: _activeActivity,
                  onActivityChanged: (type) {
                    setState(() => _activeActivity = type);
                    _saveLayout();
                  },
                ),
                if (!_focusMode && _activeActivity != ActivityType.files)
                  SidePanel(
                    activity: _activeActivity,
                    selectedFile: _selectedFilePath,
                    onFileSelected: _onFileSelected,
                  ),
                if (!_focusMode && _activeActivity == ActivityType.files)
                  SidePanel(
                    activity: _activeActivity,
                    selectedFile: _selectedFilePath,
                    onFileSelected: _onFileSelected,
                  ),
                Expanded(
                  child: _focusMode
                      ? AgentChatScreen(
                          messages: _messages,
                          onSendMessage: _sendMessage,
                          isStreaming: _isStreaming,
                          agentType: _sessions.isNotEmpty
                              ? _sessions[_activeSessionIndex].agentType
                              : 'build',
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: ResizablePanel(
                                axis: PanelAxis.horizontal,
                                initialRatio: _contextRatio,
                                minRatio: 0.4,
                                maxRatio: 0.9,
                                collapsible: true,
                                collapsed: _contextPanelCollapsed,
                                onToggleCollapse: () {
                                  setState(() => _contextPanelCollapsed = !_contextPanelCollapsed);
                                  _saveLayout();
                                },
                                onRatioChanged: (ratio) {
                                  _contextRatio = ratio;
                                },
                                panel: ContextPanel(
                                  files: _contextFiles,
                                  logs: _logs,
                                  inputTokens: 2340,
                                  outputTokens: 890,
                                ),
                                child: Column(
                                  children: [
                                    _buildEditorTabs(),
                                    Expanded(
                                      child: _activeFile != null
                                          ? CodePreview(
                                              filePath: _activeFile!,
                                              onClose: () => _closeFile(_activeFile!),
                                            )
                                          : AgentChatScreen(
                                              messages: _messages,
                                              onSendMessage: _sendMessage,
                                              isStreaming: _isStreaming,
                                              agentType: _sessions.isNotEmpty
                                                  ? _sessions[_activeSessionIndex].agentType
                                                  : 'build',
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_terminalVisible) _buildTerminal(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!_focusMode) _buildStatusBar(),
        ],
      ),
    );
  }

  Widget _buildEditorTabs() {
    return Container(
      height: 36,
      decoration: const BoxDecoration(
        color: dcSurface,
        border: Border(bottom: BorderSide(color: dcBorder)),
      ),
      child: Row(
        children: [
          _buildEditorTab(null, 'Chat', Icons.chat),
          ..._openFiles.map((f) => _buildEditorTab(f, f.split(Platform.pathSeparator).last, null)),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildEditorTab(String? filePath, String label, IconData? icon) {
    final isActive = (filePath == null && _activeFile == null) || (filePath != null && _activeFile == filePath);
    return GestureDetector(
      onTap: () => setState(() => _activeFile = filePath),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? dcBg : Colors.transparent,
          border: Border(
            top: BorderSide(color: isActive ? dcAccent : Colors.transparent, width: 1),
            right: const BorderSide(color: dcBorder, width: 1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) Icon(icon, size: 12, color: isActive ? dcAccent : dcTextMuted),
            if (icon != null) const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? dcText : dcTextMuted,
              ),
            ),
            if (filePath != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _closeFile(filePath),
                child: Icon(Icons.close, size: 12, color: isActive ? dcText : Colors.transparent),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _closeFile(String path) {
    setState(() {
      _openFiles.remove(path);
      if (_activeFile == path) {
        _activeFile = _openFiles.isNotEmpty ? _openFiles.last : null;
      }
    });
  }

  Widget _buildTitleBar() {
    return Container(
      height: 36,
      decoration: const BoxDecoration(
        color: dcSurface,
        border: Border(
          bottom: BorderSide(color: dcSidebarBg, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.smart_toy, color: dcAccent, size: 16),
                SizedBox(width: 6),
                Text(
                  'Ambot AI',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: dcText,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (!_focusMode)
            GestureDetector(
              onTap: _toggleFocusMode,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                height: 24,
                child: Icon(
                  Icons.fullscreen_exit,
                  size: 14,
                  color: dcTextMuted,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTerminal() {
    return Container(
      height: 150,
      decoration: const BoxDecoration(
        color: dcBg,
        border: Border(
          top: BorderSide(color: dcBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: const BoxDecoration(
              color: dcSurface,
              border: Border(
                bottom: BorderSide(color: dcBorder),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal, size: 12, color: dcTextMuted),
                const SizedBox(width: 6),
                const Text(
                  'TERMINAL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: dcText,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() => _terminalVisible = false);
                    _saveLayout();
                  },
                  child: const Icon(Icons.close, size: 14, color: dcTextMuted),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 0),
              child: TerminalShell(onExit: () {
                setState(() => _terminalVisible = false);
                _saveLayout();
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    final stateLabel = switch (_aiManager.state) {
      ModelState.ready => 'AI Ready',
      ModelState.loading => 'Loading…',
      ModelState.switching => 'Switching…',
      ModelState.error => 'Error',
      ModelState.idle => 'No Model',
    };
    final stateColor = switch (_aiManager.state) {
      ModelState.ready => dcSuccess,
      ModelState.error => dcError,
      _ => dcWarning,
    };
    final gpuName = _hardwareInfo?.gpuName ?? 'CPU';
    final vram = _hardwareInfo?.gpuVRAMMB ?? 0;
    final gpuLabel = vram > 0 ? '$gpuName ($vram MB)' : gpuName;
    final modelName = _aiManager.currentModel?.name ?? 'none';
    final tokLabel = _latestMetrics != null
        ? '${_latestMetrics!.tokensPerSecond.toStringAsFixed(1)} tok/s'
        : '— tok/s';

    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: dcStatusBar,
        border: Border(
          top: BorderSide(color: dcStatusBarBorder),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 6, color: stateColor),
          const SizedBox(width: 6),
          Text(
            stateLabel,
            style: const TextStyle(fontSize: 11, color: dcTextWhite),
          ),
          const SizedBox(width: 16),
          Text(
            'GPU: $gpuLabel',
            style: const TextStyle(fontSize: 11, color: dcTextWhite),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: _showModelSelector,
            child: Text(
              'Model: $modelName',
              style: const TextStyle(fontSize: 11, color: dcTextWhite, decoration: TextDecoration.underline),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            tokLabel,
            style: const TextStyle(fontSize: 11, color: dcTextWhite),
          ),
          const Spacer(),
          Text(
            AppVersion.displayVersion,
            style: const TextStyle(fontSize: 11, color: dcTextWhite),
          ),
        ],
      ),
    );
  }

  void _showModelSelector() {
    showDialog(
      context: context,
      builder: (ctx) {
        return FutureBuilder<List<LocalModelInfo>>(
          future: _aiManager.downloadManager.getAvailableModels(),
          builder: (ctx, snap) {
            final models = snap.data ?? [];
            return AlertDialog(
              backgroundColor: dcSidebarBg,
              title: const Text('Select Model', style: TextStyle(color: dcText)),
              content: SizedBox(
                width: 320,
                height: 300,
                child: ListView.builder(
                  itemCount: models.length,
                  itemBuilder: (ctx, i) {
                    final model = models[i];
                    final isActive = _aiManager.currentModel?.id == model.id;
                    return ListTile(
                      dense: true,
                      leading: Icon(isActive ? Icons.check_circle : Icons.circle_outlined,
                          color: isActive ? dcSuccess : dcTextMuted, size: 18),
                      title: Text(model.name, style: const TextStyle(color: dcText, fontSize: 13)),
                      subtitle: Text(
                        '${model.quantization} · ${model.sizeLabel} · ctx ${model.contextSize}',
                        style: const TextStyle(color: dcTextMuted, fontSize: 11),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _switchModel(model);
                      },
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _switchModel(LocalModelInfo model) async {
    try {
      final isDownloaded = await _aiManager.downloadManager.isModelDownloaded(model.id);
      if (!mounted) return;
      if (!isDownloaded) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: dcSidebarBg,
            title: const Text('Download Model', style: TextStyle(color: dcText)),
            content: Text('Download ${model.name} (${model.sizeLabel})?', style: const TextStyle(color: dcText)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Download')),
            ],
          ),
        );
        if (confirm != true) return;
        await _aiManager.downloadAndLoadModel(model);
      } else {
        await _aiManager.switchModel(model);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load model: $e')));
      }
    }
  }
}
