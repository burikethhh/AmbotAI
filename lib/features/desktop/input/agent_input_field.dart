import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'input_parser.dart';

class AgentInputField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmit;
  final String workingDirectory;
  final bool isStreaming;
  final VoidCallback? onCancel;

  const AgentInputField({
    super.key,
    required this.controller,
    required this.onSubmit,
    this.workingDirectory = '.',
    this.isStreaming = false,
    this.onCancel,
  });

  @override
  State<AgentInputField> createState() => _AgentInputFieldState();
}

class _AgentInputFieldState extends State<AgentInputField> {
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<String> _completions = [];
  int _selectedCompletion = -1;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _removeOverlay();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _updateCompletions();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _removeOverlay();
    }
  }

  void _updateCompletions() {
    final text = widget.controller.text;
    final cursorPos = widget.controller.selection.baseOffset;

    if (cursorPos <= 0) {
      _removeOverlay();
      return;
    }

    final textBeforeCursor = text.substring(0, cursorPos);
    final lastSpace = textBeforeCursor.lastIndexOf(' ');
    final currentWord = lastSpace == -1
        ? textBeforeCursor
        : textBeforeCursor.substring(lastSpace + 1);

    if (currentWord.isEmpty || (!_isMentionPrefix(currentWord))) {
      _removeOverlay();
      return;
    }

    final completions = InputParser.getCompletions(currentWord, widget.workingDirectory);
    if (completions.isEmpty) {
      _removeOverlay();
      return;
    }

    _completions = completions;
    _selectedCompletion = -1;
    _showOverlay();
  }

  bool _isMentionPrefix(String text) {
    if (text.startsWith('@') && text.length > 1) return true;
    if (text.startsWith('#') && text.length > 1) return true;
    if (text.startsWith('/') && text.length > 1) return true;
    return false;
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = OverlayEntry(
      builder: (context) => _buildCompletionOverlay(),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildCompletionOverlay() {
    return Positioned(
      width: 300,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: const Offset(0, -200),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
              ),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _completions.length,
              itemBuilder: (context, index) {
                final completion = _completions[index];
                final isSelected = index == _selectedCompletion;
                return _buildCompletionItem(completion, isSelected, index);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionItem(String completion, bool isSelected, int index) {
    final accent = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: () => _insertCompletion(completion),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: isSelected ? accent.withValues(alpha: 0.1) : Colors.transparent,
        child: Row(
          children: [
            Icon(
              _completionIcon(completion),
              size: 14,
              color: isSelected ? accent : Theme.of(context).textTheme.bodySmall?.color,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                completion,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                  color: isSelected ? accent : Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _completionIcon(String completion) {
    if (completion.startsWith('@')) return Icons.insert_drive_file;
    if (completion.startsWith('#')) return Icons.folder;
    if (completion.startsWith('/')) return Icons.terminal;
    return Icons.code;
  }

  void _insertCompletion(String completion) {
    final text = widget.controller.text;
    final cursorPos = widget.controller.selection.baseOffset;
    final textBeforeCursor = text.substring(0, cursorPos);
    final textAfterCursor = text.substring(cursorPos);

    final lastSpace = textBeforeCursor.lastIndexOf(' ');
    final currentWordStart = lastSpace == -1 ? 0 : lastSpace + 1;

    final newText = textBeforeCursor.substring(0, currentWordStart) +
        completion +
        ' ' +
        textAfterCursor;

    widget.controller.text = newText;
    widget.controller.selection = TextSelection.collapsed(
      offset: currentWordStart + completion.length + 1,
    );

    _removeOverlay();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (_overlayEntry != null) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _selectedCompletion = (_selectedCompletion + 1) % _completions.length;
        });
        _overlayEntry?.markNeedsBuild();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _selectedCompletion = (_selectedCompletion - 1 + _completions.length) % _completions.length;
        });
        _overlayEntry?.markNeedsBuild();
      } else if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.tab) {
        if (_selectedCompletion >= 0 && _selectedCompletion < _completions.length) {
          _insertCompletion(_completions[_selectedCompletion]);
        }
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        _removeOverlay();
      }
    } else if (event.logicalKey == LogicalKeyboardKey.enter &&
        !HardwareKeyboard.instance.isShiftPressed) {
      _submit();
    }
  }

  void _submit() {
    final text = widget.controller.text.trim();
    if (text.isEmpty || widget.isStreaming) return;
    widget.onSubmit(text);
    widget.controller.clear();
    _removeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
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
            _buildMentionBar(),
            const SizedBox(height: 8),
            _buildInputRow(),
            const SizedBox(height: 4),
            _buildHintText(),
          ],
        ),
      ),
    );
  }

  Widget _buildMentionBar() {
    return Row(
      children: [
        _buildMentionButton('@', 'File'),
        const SizedBox(width: 4),
        _buildMentionButton('#', 'Folder'),
        const SizedBox(width: 4),
        _buildMentionButton('!', 'Shell'),
        const SizedBox(width: 4),
        _buildMentionButton('/', 'Command'),
      ],
    );
  }

  Widget _buildMentionButton(String prefix, String label) {
    return GestureDetector(
      onTap: () {
        final text = widget.controller.text;
        final cursorPos = widget.controller.selection.baseOffset;
        final newText = text.substring(0, cursorPos) + prefix + text.substring(cursorPos);
        widget.controller.text = newText;
        widget.controller.selection = TextSelection.collapsed(offset: cursorPos + 1);
        _focusNode.requestFocus();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            fontSize: 11,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildInputRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: _handleKeyEvent,
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
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
              onSubmitted: (_) => _submit(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildSendButton(),
      ],
    );
  }

  Widget _buildSendButton() {
    final accent = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: widget.isStreaming ? widget.onCancel : _submit,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: widget.isStreaming
              ? Theme.of(context).colorScheme.error
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

  Widget _buildHintText() {
    return Row(
      children: [
        Text(
          'Ctrl+Enter to send',
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        const Spacer(),
        if (widget.controller.text.isNotEmpty)
          Text(
            '${widget.controller.text.length} chars',
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
      ],
    );
  }
}
