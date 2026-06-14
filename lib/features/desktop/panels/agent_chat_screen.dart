import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Color _bg = Color(0xFF1E1E1E);
const Color _text = Color(0xFFCCCCCC);
const Color _muted = Color(0xFF858585);
const Color _accent = Color(0xFFFFA726);
const Color _surface = Color(0xFF2D2D2D);
const Color _inputBg = Color(0xFF3C3C3C);
const Color _border = Color(0xFF3C3C3C);
const Color _userBg = Color(0xFF2D2D2D);

enum MessageRole { user, agent, system, tool }

class AgentMessage {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final ToolCall? toolCall;
  final ChatToolResult? toolResult;
  final bool isStreaming;

  const AgentMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.toolCall,
    this.toolResult,
    this.isStreaming = false,
  });
}

class ToolCall {
  final String name;
  final Map<String, dynamic> parameters;
  final String? thinking;

  const ToolCall({
    required this.name,
    required this.parameters,
    this.thinking,
  });
}

class ChatToolResult {
  final String title;
  final String content;
  final bool success;
  final DiffInfo? diff;

  const ChatToolResult({
    required this.title,
    required this.content,
    this.success = true,
    this.diff,
  });
}

class DiffInfo {
  final String file;
  final int addedLines;
  final int removedLines;
  final String? preview;

  const DiffInfo({
    required this.file,
    required this.addedLines,
    required this.removedLines,
    this.preview,
  });
}

class AgentChatScreen extends StatefulWidget {
  final List<AgentMessage> messages;
  final ValueChanged<String> onSendMessage;
  final bool isStreaming;
  final String agentType;
  final String modelName;

  const AgentChatScreen({
    super.key,
    required this.messages,
    required this.onSendMessage,
    this.isStreaming = false,
    this.agentType = 'build',
    this.modelName = 'Llama 3 8B',
  });

  @override
  State<AgentChatScreen> createState() => _AgentChatScreenState();
}

class _AgentChatScreenState extends State<AgentChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _inputFocus = FocusNode();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _send() {
    final text = _inputController.text.trim();
    if (text.isEmpty || widget.isStreaming) return;
    widget.onSendMessage(text);
    _inputController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (widget.messages.isEmpty) {
      return _buildEmptyState();
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: widget.messages.length,
      itemBuilder: (context, i) => _buildMessage(widget.messages[i]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.smart_toy, size: 40, color: _accent.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          const Text('AGENTIC WORKSPACE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _accent, letterSpacing: 2)),
          const SizedBox(height: 6),
          const Text('Describe what you want to build, fix, or explore.', style: TextStyle(fontSize: 12, color: _muted)),
          const SizedBox(height: 20),
          _buildSuggestionChips(),
        ],
      ),
    );
  }

  Widget _buildSuggestionChips() {
    final suggestions = ['Build a login page', 'Fix the API error', 'Refactor this code', 'Explain this function'];
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: suggestions.map((s) {
        return GestureDetector(
          onTap: () { _inputController.text = s; _send(); },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _border),
            ),
            child: Text(s, style: const TextStyle(fontSize: 12, color: _accent)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMessage(AgentMessage msg) {
    switch (msg.role) {
      case MessageRole.user: return _buildUserMessage(msg);
      case MessageRole.agent: return _buildAgentMessage(msg);
      case MessageRole.tool: return _buildToolMessage(msg);
      case MessageRole.system: return _buildSystemMessage(msg);
    }
  }

  Widget _buildUserMessage(AgentMessage msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(color: _accent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
            child: const Icon(Icons.person, size: 14, color: _accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _userBg, borderRadius: BorderRadius.circular(6), border: Border.all(color: _border)),
              child: Text(msg.content, style: const TextStyle(fontSize: 13, color: _text)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentMessage(AgentMessage msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(color: _accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
            child: const Icon(Icons.smart_toy, size: 14, color: _accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (msg.toolCall != null) _buildToolCallBlock(msg.toolCall!),
                if (msg.toolResult != null) _buildToolResultBlock(msg.toolResult!),
                if (msg.content.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(6), border: Border.all(color: _border)),
                    child: msg.isStreaming
                        ? _buildStreamingIndicator()
                        : Text(msg.content, style: const TextStyle(fontSize: 13, color: _text)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCallBlock(ToolCall call) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(6), border: Border.all(color: _border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_toolIcon(call.name), size: 14, color: _accent),
              const SizedBox(width: 6),
              Text(_toolLabel(call.name), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _accent)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  call.parameters.entries.map((e) => '${e.key}: ${e.value}').join(', '),
                  style: const TextStyle(fontSize: 10, color: _muted), maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (call.thinking != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(call.thinking!, style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: _muted)),
            ),
        ],
      ),
    );
  }

  Widget _buildToolResultBlock(ChatToolResult result) {
    final color = result.success ? const Color(0xFF4EC9B0) : const Color(0xFFF44747);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(result.success ? Icons.check_circle : Icons.error, size: 14, color: color),
                const SizedBox(width: 6),
                Expanded(child: Text(result.title, style: TextStyle(fontSize: 11, color: color))),
              ],
            ),
          ),
          if (result.content.isNotEmpty && result.title != result.content)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(6), border: Border.all(color: _border)),
              child: Text(result.content, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: _muted), maxLines: 10, overflow: TextOverflow.ellipsis),
            ),
          if (result.diff != null) _buildDiffPreview(result.diff!),
        ],
      ),
    );
  }

  Widget _buildDiffPreview(DiffInfo diff) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(6), border: Border.all(color: _border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(diff.file, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: _muted)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('+${diff.addedLines}', style: const TextStyle(fontSize: 11, color: Color(0xFF4EC9B0))),
              const SizedBox(width: 8),
              Text('-${diff.removedLines}', style: const TextStyle(fontSize: 11, color: Color(0xFFF44747))),
            ],
          ),
          if (diff.preview != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(diff.preview!, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: _muted), maxLines: 3, overflow: TextOverflow.ellipsis),
            ),
        ],
      ),
    );
  }

  Widget _buildToolMessage(AgentMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(left: 34, bottom: 8),
      child: Row(
        children: [
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(_accent))),
          const SizedBox(width: 8),
          Text(msg.content, style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: _muted)),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(AgentMessage msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Center(child: Text(msg.content, style: TextStyle(fontSize: 11, color: _muted))),
    );
  }

  Widget _buildStreamingIndicator() {
    return Row(
      children: [
        const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(_accent))),
        const SizedBox(width: 8),
        const Text('Thinking...', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: _accent)),
      ],
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(color: _bg, border: Border(top: BorderSide(color: _border))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _buildMentionButton('@', 'File'),
              const SizedBox(width: 4),
              _buildMentionButton('#', 'Folder'),
              const SizedBox(width: 4),
              _buildMentionButton('!', 'Shell'),
              const SizedBox(width: 4),
              _buildMentionButton('/', 'Command'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 40),
                  decoration: BoxDecoration(color: _inputBg, borderRadius: BorderRadius.circular(6), border: Border.all(color: _border)),
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: (event) {
                      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter && HardwareKeyboard.instance.isControlPressed) {
                        _send();
                      }
                    },
                    child: TextField(
                      controller: _inputController,
                      focusNode: _inputFocus,
                      maxLines: null,
                      style: const TextStyle(fontSize: 13, color: _text),
                      decoration: const InputDecoration(
                        hintText: 'Describe what you want to do...',
                        hintStyle: TextStyle(fontSize: 13, color: _muted),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildSendButton(),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Enter to send  ·  Ctrl+Enter for newline', style: TextStyle(fontSize: 10, color: _muted)),
        ],
      ),
    );
  }

  Widget _buildMentionButton(String prefix, String label) {
    return GestureDetector(
      onTap: () => _inputController.text += prefix,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(4), border: Border.all(color: _border)),
        child: Text('$prefix$label', style: const TextStyle(fontSize: 10, color: _accent)),
      ),
    );
  }

  Widget _buildSendButton() {
    return GestureDetector(
      onTap: _send,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: widget.isStreaming ? _muted : _accent, borderRadius: BorderRadius.circular(6)),
        child: Icon(widget.isStreaming ? Icons.stop : Icons.arrow_upward, color: Colors.white, size: 20),
      ),
    );
  }

  IconData _toolIcon(String toolId) {
    switch (toolId) {
      case 'read_file': case 'write_file': case 'edit_file': return Icons.description_outlined;
      case 'list_directory': return Icons.folder_open;
      case 'shell': return Icons.terminal;
      case 'search_files': return Icons.search;
      case 'grep': return Icons.find_in_page;
      default: return Icons.build_circle_outlined;
    }
  }

  String _toolLabel(String toolId) {
    switch (toolId) {
      case 'read_file': return 'READ';
      case 'write_file': return 'WRITE';
      case 'edit_file': return 'EDIT';
      case 'list_directory': return 'LIST';
      case 'shell': return 'SHELL';
      case 'search_files': return 'SEARCH';
      case 'grep': return 'GREP';
      default: return toolId.toUpperCase();
    }
  }
}
