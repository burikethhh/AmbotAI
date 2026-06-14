import 'package:flutter/material.dart';
import '../../../core/utils/app_version.dart';
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
  final List<AgentSession> _sessions = [];
  int _activeSessionIndex = 0;
  final bool _sidebarCollapsed = false;
  bool _contextPanelCollapsed = false;
  bool _terminalVisible = false;

  final List<AgentMessage> _messages = [];
  bool _isStreaming = false;
  final List<ContextFile> _contextFiles = [];
  final List<AgentLogEntry> _logs = [];

  @override
  void initState() {
    super.initState();
    _addSession('New Session', 'build');
    _logs.add(AgentLogEntry(
      time: '00:00',
      level: 'info',
      message: 'Workspace initialized',
    ));
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
    _simulateAgentResponse(text);
  }

  void _simulateAgentResponse(String userMessage) {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _messages.add(AgentMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          role: MessageRole.agent,
          content: 'Processing your request: "$userMessage"',
          timestamp: DateTime.now(),
          toolCall: ToolCall(
            name: 'analyze',
            parameters: {'query': userMessage},
            thinking: 'Analyzing request...',
          ),
        ));
        _isStreaming = false;
        _logs.add(AgentLogEntry(
          time: _timeNow(),
          level: 'success',
          message: 'Agent processed request',
        ));
      });
    });
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
          SessionTabBar(
            sessions: _sessions,
            activeIndex: _activeSessionIndex,
            onSelect: (i) => setState(() => _activeSessionIndex = i),
            onClose: _closeSession,
            onNewSession: () => _addSession('Session ${_sessions.length + 1}', 'build'),
          ),
          Expanded(
            child: Row(
              children: [
                if (!_sidebarCollapsed) _buildSidebar(),
                Expanded(
                  child: ResizablePanel(
                    axis: PanelAxis.horizontal,
                    initialRatio: 0.7,
                    minRatio: 0.4,
                    maxRatio: 0.9,
                    collapsible: true,
                    collapsed: _contextPanelCollapsed,
                    onToggleCollapse: () => setState(() => _contextPanelCollapsed = !_contextPanelCollapsed),
                    panel: ContextPanel(
                      files: _contextFiles,
                      logs: _logs,
                      inputTokens: 2340,
                      outputTokens: 890,
                    ),
                    child: Column(
                      children: [
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
                        if (_terminalVisible) _buildTerminal(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildStatusBar(),
        ],
      ),
    );
  }

  Widget _buildTitleBar() {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.smart_toy, color: accent, size: 18),
          const SizedBox(width: 8),
          Text(
            'AMBOT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: accent,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 16),
          _buildTitleButton('Session', _sessions.isNotEmpty
              ? _sessions[_activeSessionIndex].title
              : 'None'),
          const SizedBox(width: 8),
          _buildTitleButton('Agent', _sessions.isNotEmpty
              ? _sessions[_activeSessionIndex].agentType.toUpperCase()
              : 'BUILD'),
          const SizedBox(width: 8),
          _buildTitleButton('Model', 'Llama 3 8B'),
          const Spacer(),
          _buildTitleAction(Icons.code, 'Programmer', () {}),
          const SizedBox(width: 4),
          _buildTitleAction(Icons.chat, 'General Chat', () {}),
          const SizedBox(width: 4),
          _buildTitleAction(Icons.image, 'Image Gen', () {}),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildTitleButton(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleAction(IconData icon, String tooltip, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 14, color: Theme.of(context).textTheme.bodySmall?.color),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 48,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildSidebarButton(Icons.build, 'Build', () {}),
          _buildSidebarButton(Icons.lightbulb_outline, 'Plan', () {}),
          _buildSidebarButton(Icons.auto_fix_high, 'Refactor', () {}),
          _buildSidebarButton(Icons.bug_report, 'Debug', () {}),
          _buildSidebarButton(Icons.description, 'Document', () {}),
          const Spacer(),
          _buildSidebarButton(Icons.terminal, 'Terminal', () {
            setState(() => _terminalVisible = !_terminalVisible);
          }),
          _buildSidebarButton(Icons.settings, 'Settings', () {}),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSidebarButton(IconData icon, String tooltip, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 18, color: Theme.of(context).textTheme.bodySmall?.color),
        ),
      ),
    );
  }

  Widget _buildTerminal() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'TERMINAL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _terminalVisible = false),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                '\$ ambot_ai --version\nAmbot AI ${AppVersion.displayVersion}\n\$ ',
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: Color(0xFF00FF00),
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
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: Colors.green),
          const SizedBox(width: 6),
          Text(
            'Connected to local AI',
            style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color),
          ),
          const SizedBox(width: 16),
          Text(
            'GPU: RTX 4060',
            style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color),
          ),
          const SizedBox(width: 16),
          Text(
            'Model: 8B Q4_K_M',
            style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color),
          ),
          const SizedBox(width: 16),
          Text(
            '23 tok/s',
            style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color),
          ),
          const Spacer(),
          Text(
            AppVersion.displayVersion,
            style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color),
          ),
        ],
      ),
    );
  }
}
