import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    return Column(
      children: [
        Expanded(child: _buildMessageList()),
        _buildInputBar(),
      ],
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
    final accent = Theme.of(context).colorScheme.primary;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _agentIcon(widget.agentType),
            size: 48,
            color: accent.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'AGENTIC WORKSPACE',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: accent,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Describe what you want to build, fix, or explore.',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 24),
          _buildSuggestionChips(),
        ],
      ),
    );
  }

  Widget _buildSuggestionChips() {
    final suggestions = [
      'Build a login page',
      'Fix the API error',
      'Refactor this code',
      'Explain this function',
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: suggestions.map((s) {
        return GestureDetector(
          onTap: () {
            _inputController.text = s;
            _send();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              s,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMessage(AgentMessage msg) {
    switch (msg.role) {
      case MessageRole.user:
        return _buildUserMessage(msg);
      case MessageRole.agent:
        return _buildAgentMessage(msg);
      case MessageRole.tool:
        return _buildToolMessage(msg);
      case MessageRole.system:
        return _buildSystemMessage(msg);
    }
  }

  Widget _buildUserMessage(AgentMessage msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(Icons.person, Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                msg.content,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildTimestamp(msg.timestamp),
        ],
      ),
    );
  }

  Widget _buildAgentMessage(AgentMessage msg) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(_agentIcon(widget.agentType), accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (msg.toolCall != null) _buildToolCallBlock(msg.toolCall!),
                if (msg.toolResult != null) _buildToolResultBlock(msg.toolResult!),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: msg.isStreaming
                      ? _buildStreamingIndicator()
                      : Text(
                          msg.content,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildTimestamp(msg.timestamp),
        ],
      ),
    );
  }

  Widget _buildToolCallBlock(ToolCall call) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: accent.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.build_circle_outlined, size: 14, color: accent),
              const SizedBox(width: 6),
              Text(
                call.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
            ],
          ),
          if (call.thinking != null) ...[
            const SizedBox(height: 6),
            Text(
              call.thinking!,
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToolResultBlock(ChatToolResult result) {
    final color = result.success ? Colors.green : Colors.red;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Icon(
                  result.success ? Icons.check_circle : Icons.error,
                  size: 14,
                  color: color,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    result.title,
                    style: TextStyle(fontSize: 11, color: color),
                  ),
                ),
              ],
            ),
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
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            diff.file,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '+${diff.addedLines}',
                style: const TextStyle(fontSize: 11, color: Colors.green),
              ),
              const SizedBox(width: 8),
              Text(
                '-${diff.removedLines}',
                style: const TextStyle(fontSize: 11, color: Colors.red),
              ),
            ],
          ),
          if (diff.preview != null) ...[
            const SizedBox(height: 6),
            Text(
              diff.preview!,
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToolMessage(AgentMessage msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            msg.content,
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(AgentMessage msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          msg.content,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(IconData icon, Color color) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }

  Widget _buildTimestamp(DateTime time) {
    return Text(
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      style: TextStyle(
        fontSize: 10,
        color: Theme.of(context).textTheme.bodySmall?.color,
      ),
    );
  }

  Widget _buildStreamingIndicator() {
    return Row(
      children: [
        SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Thinking...',
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          ),
        ),
      ),
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
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: (event) {
                      if (event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.enter &&
                          HardwareKeyboard.instance.isControlPressed) {
                        _send();
                      }
                    },
                    child: TextField(
                      controller: _inputController,
                      focusNode: _inputFocus,
                      maxLines: null,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Describe what you want to do...',
                        hintStyle: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
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
          Text(
            'Ctrl+Enter to send',
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMentionButton(String prefix, String label) {
    return GestureDetector(
      onTap: () => _inputController.text += prefix,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          '$prefix$label',
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    final accent = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: _send,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: widget.isStreaming
              ? Theme.of(context).disabledColor
              : accent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          widget.isStreaming ? Icons.stop : Icons.arrow_upward,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  IconData _agentIcon(String type) {
    switch (type) {
      case 'build':
        return Icons.build;
      case 'plan':
        return Icons.lightbulb_outline;
      case 'refactor':
        return Icons.auto_fix_high;
      case 'debug':
        return Icons.bug_report;
      case 'document':
        return Icons.description;
      default:
        return Icons.smart_toy;
    }
  }
}
