import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TerminalLine {
  final String content;
  final TerminalLineType type;
  final DateTime timestamp;

  TerminalLine({
    required this.content,
    this.type = TerminalLineType.output,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

enum TerminalLineType { input, output, error, system }

class TerminalPanel extends StatefulWidget {
  final String workingDirectory;
  final ValueChanged<String>? onCommand;

  const TerminalPanel({
    super.key,
    this.workingDirectory = '.',
    this.onCommand,
  });

  @override
  State<TerminalPanel> createState() => _TerminalPanelState();
}

class _TerminalPanelState extends State<TerminalPanel> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final List<TerminalLine> _lines = [];
  Process? _process;
  bool _isRunning = false;
  final List<String> _history = [];
  int _historyIndex = -1;

  @override
  void initState() {
    super.initState();
    _addSystemLine('Ambot AI Terminal v1.0');
    _addSystemLine('Type "help" for available commands');
    _addSystemLine('');
  }

  @override
  void dispose() {
    _process?.kill();
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addLine(String content, {TerminalLineType type = TerminalLineType.output}) {
    setState(() {
      _lines.add(TerminalLine(content: content, type: type));
    });
    _scrollToBottom();
  }

  void _addSystemLine(String content) {
    _addLine(content, type: TerminalLineType.system);
  }

  void _addInputLine(String content) {
    _addLine('\$ $content', type: TerminalLineType.input);
  }

  void _addErrorLine(String content) {
    _addLine(content, type: TerminalLineType.error);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _executeCommand(String command) async {
    if (command.trim().isEmpty) return;

    _addInputLine(command);
    _history.add(command);
    _historyIndex = _history.length;

    widget.onCommand?.call(command);

    if (command.toLowerCase() == 'clear') {
      setState(() => _lines.clear());
      return;
    }

    if (command.toLowerCase() == 'help') {
      _addSystemLine('Available commands:');
      _addSystemLine('  clear     - Clear terminal');
      _addSystemLine('  help      - Show this help');
      _addSystemLine('  version   - Show version');
      _addSystemLine('  exit      - Close terminal');
      _addSystemLine('');
      return;
    }

    if (command.toLowerCase() == 'version') {
      _addSystemLine('Ambot AI v1.6.6');
      return;
    }

    if (command.toLowerCase() == 'exit') {
      _addSystemLine('Terminal closed');
      return;
    }

    await _runProcess(command);
  }

  Future<void> _runProcess(String command) async {
    setState(() => _isRunning = true);

    try {
      final isWindows = Platform.isWindows;
      final shell = isWindows ? 'powershell' : 'bash';
      final args = isWindows ? ['-Command', command] : ['-c', command];

      _process = await Process.start(
        shell,
        args,
        workingDirectory: widget.workingDirectory,
      );

      _process!.stdout.listen((data) {
        final output = String.fromCharCodes(data).trim();
        if (output.isNotEmpty) {
          _addLine(output);
        }
      });

      _process!.stderr.listen((data) {
        final output = String.fromCharCodes(data).trim();
        if (output.isNotEmpty) {
          _addErrorLine(output);
        }
      });

      final exitCode = await _process!.exitCode;
      if (exitCode != 0) {
        _addErrorLine('Process exited with code $exitCode');
      }
    } catch (e) {
      _addErrorLine('Error: $e');
    } finally {
      setState(() => _isRunning = false);
      _process = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
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
          _buildHeader(),
          Expanded(child: _buildOutput()),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
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
          Icon(Icons.terminal, size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'TERMINAL',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          if (_isRunning)
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
          GestureDetector(
            onTap: () => setState(() => _lines.clear()),
            child: Icon(
              Icons.delete_outline,
              size: 14,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutput() {
    return Container(
      color: const Color(0xFF0D1117),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8),
        itemCount: _lines.length,
        itemBuilder: (context, index) {
          final line = _lines[index];
          return _buildLine(line);
        },
      ),
    );
  }

  Widget _buildLine(TerminalLine line) {
    Color color;
    switch (line.type) {
      case TerminalLineType.input:
        color = const Color(0xFF58A6FF);
        break;
      case TerminalLineType.output:
        color = const Color(0xFFC9D1D9);
        break;
      case TerminalLineType.error:
        color = const Color(0xFFF85149);
        break;
      case TerminalLineType.system:
        color = const Color(0xFF8B949E);
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Text(
        line.content,
        style: TextStyle(
          fontSize: 12,
          fontFamily: 'monospace',
          color: color,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      color: const Color(0xFF0D1117),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Text(
            '\$ ',
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Expanded(
            child: Focus(
              autofocus: true,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    if (_historyIndex > 0) {
                      _historyIndex--;
                      _inputController.text = _history[_historyIndex];
                      return KeyEventResult.handled;
                    }
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    if (_historyIndex < _history.length - 1) {
                      _historyIndex++;
                      _inputController.text = _history[_historyIndex];
                      return KeyEventResult.handled;
                    } else {
                      _historyIndex = _history.length;
                      _inputController.clear();
                      return KeyEventResult.handled;
                    }
                  } else if (event.logicalKey == LogicalKeyboardKey.escape) {
                    _inputController.clear();
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: TextField(
                controller: _inputController,
                focusNode: _focusNode,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: Color(0xFFC9D1D9),
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (value) {
                  _executeCommand(value);
                  _inputController.clear();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
