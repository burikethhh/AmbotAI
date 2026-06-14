import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/app_version.dart';
import '../ai/local_ai_manager.dart';
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

  final List<AgentMessage> _messages = [];
  bool _isStreaming = false;
  final List<ContextFile> _contextFiles = [];
  final List<AgentLogEntry> _logs = [];

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

  void _closeSession(int index) {
    if (_sessions.length <= 1) return;
    setState(() {
      _sessions.removeAt(index);
      if (_activeSessionIndex >= _sessions.length) {
        _activeSessionIndex = _sessions.length - 1;
      }
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
    setState(() => _selectedFilePath = path);
    _sendMessage('read file $path');
  }

  String _timeNow() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
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
                                    SessionTabBar(
                                      sessions: _sessions,
                                      activeIndex: _activeSessionIndex,
                                      onSelect: (i) => setState(() => _activeSessionIndex = i),
                                      onClose: _closeSession,
                                      onNewSession: () => _addSession('Session ${_sessions.length + 1}', 'build'),
                                    ),
                                    Expanded(
                                      child: AgentChatScreen(
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

  Widget _buildTitleBar() {
    return Container(
      height: 36,
      decoration: const BoxDecoration(
        color: Color(0xFF2D2D2D),
        border: Border(
          bottom: BorderSide(color: Color(0xFF252526), width: 1),
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
                Icon(Icons.smart_toy, color: Color(0xFFFFA726), size: 16),
                SizedBox(width: 6),
                Text(
                  'Ambot AI',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFCCCCCC),
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
                  color: const Color(0xFF858585),
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
        color: Color(0xFF1E1E1E),
        border: Border(
          top: BorderSide(color: Color(0xFF3C3C3C)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF2D2D2D),
              border: Border(
                bottom: BorderSide(color: Color(0xFF3C3C3C)),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.terminal, size: 12, color: Color(0xFF858585)),
                const SizedBox(width: 6),
                const Text(
                  'TERMINAL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFCCCCCC),
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() => _terminalVisible = false);
                    _saveLayout();
                  },
                  child: const Icon(Icons.close, size: 14, color: Color(0xFF858585)),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: '\$ ',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: Color(0xFF00FF00),
                      ),
                    ),
                    TextSpan(
                      text: 'ambot_ai --version\n',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: Color(0xFFCCCCCC),
                      ),
                    ),
                    TextSpan(
                      text: 'Ambot AI Desktop 1.6.6\n\n',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: Color(0xFF858585),
                      ),
                    ),
                    TextSpan(
                      text: '\$ ',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: Color(0xFF00FF00),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF007ACC),
        border: Border(
          top: BorderSide(color: Color(0xFF0062A3)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 6, color: Color(0xFF4EC9B0)),
          const SizedBox(width: 6),
          const Text(
            'AI Ready',
            style: TextStyle(fontSize: 11, color: Color(0xFFFFFFFF)),
          ),
          const SizedBox(width: 16),
          const Text(
            'GPU: RTX 4060',
            style: TextStyle(fontSize: 11, color: Color(0xFFFFFFFF)),
          ),
          const SizedBox(width: 16),
          const Text(
            'Model: 8B Q4_K_M',
            style: TextStyle(fontSize: 11, color: Color(0xFFFFFFFF)),
          ),
          const SizedBox(width: 16),
          const Text(
            '23 tok/s',
            style: TextStyle(fontSize: 11, color: Color(0xFFFFFFFF)),
          ),
          const Spacer(),
          Text(
            AppVersion.displayVersion,
            style: const TextStyle(fontSize: 11, color: Color(0xFFFFFFFF)),
          ),
        ],
      ),
    );
  }
}

