import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../agent/tools/shell_tools.dart';

class TerminalShell extends StatefulWidget {
  const TerminalShell({super.key});

  @override
  State<TerminalShell> createState() => _TerminalShellState();
}

class _TerminalShellState extends State<TerminalShell> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final List<_TerminalLine> _lines = [];
  final _history = <String>[];
  int _historyIndex = -1;
  bool _executing = false;

  @override
  void initState() {
    super.initState();
    _lines.add(_TerminalLine(
      'Ambot AI Desktop Terminal\nType "help" for available commands.\n',
      _LineStyle.dim,
    ));
    _lines.add(_TerminalLine('\$ ', _LineStyle.prompt));
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _execute(String input) {
    if (input.trim().isEmpty) {
      setState(() => _lines.add(_TerminalLine('\$ ', _LineStyle.prompt)));
      return;
    }

    _history.add(input);
    _historyIndex = -1;
    _lines.add(_TerminalLine('$input\n', _LineStyle.command));

    if (input == 'help') {
      setState(() {
        _lines.add(_TerminalLine(
          'Commands:\n  help      - Show this help\n  clear     - Clear terminal\n  exit      - Close terminal\n  echo      - Print text\n  ls/dir    - List directory\n  cat/type  - View file\n  pwd/cd    - Print/cwd\n  Any other command runs via shell\n',
          _LineStyle.dim,
        ));
        _lines.add(_TerminalLine('\$ ', _LineStyle.prompt));
      });
      return;
    }

    if (input == 'clear') {
      setState(() {
        _lines.clear();
        _lines.add(_TerminalLine('\$ ', _LineStyle.prompt));
      });
      return;
    }

    if (input == 'exit') {
      // Handled by parent - close terminal
      return;
    }

    _runCommand(input);
  }

  Future<void> _runCommand(String input) async {
    setState(() => _executing = true);

    try {
      final check = CommandSandbox.checkCommand(input);
      if (!check.allowed) {
        setState(() {
          _lines.add(_TerminalLine('Error: ${check.reason}\n', _LineStyle.error));
          _lines.add(_TerminalLine('\$ ', _LineStyle.prompt));
          _executing = false;
        });
        return;
      }

      final isWindows = Platform.isWindows;
      final result = await Process.run(
        isWindows ? 'powershell' : 'bash',
        isWindows ? ['-Command', input] : ['-c', input],
        runInShell: true,
      );

      final stdout = result.stdout as String;
      final stderr = result.stderr as String;

      setState(() {
        if (stdout.isNotEmpty) {
          _lines.add(_TerminalLine(stdout.endsWith('\n') ? stdout : '$stdout\n', _LineStyle.output));
        }
        if (stderr.isNotEmpty) {
          _lines.add(_TerminalLine(stderr.endsWith('\n') ? stderr : '$stderr\n', _LineStyle.error));
        }
        _lines.add(_TerminalLine('\$ ', _LineStyle.prompt));
        _executing = false;
      });
    } catch (e) {
      setState(() {
        _lines.add(_TerminalLine('Error: $e\n', _LineStyle.error));
        _lines.add(_TerminalLine('\$ ', _LineStyle.prompt));
        _executing = false;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: Container(
        color: const Color(0xFF1E1E1E),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8),
                itemCount: _lines.length,
                itemBuilder: (context, i) => _buildLine(_lines[i]),
              ),
            ),
            _buildInputLine(),
          ],
        ),
      ),
    );
  }

  Widget _buildLine(_TerminalLine line) {
    switch (line.style) {
      case _LineStyle.prompt:
        return Text(
          line.text,
          style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFF4EC9B0), height: 1.4),
        );
      case _LineStyle.command:
        return Text(
          line.text,
          style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFFDCDCAA), height: 1.4),
        );
      case _LineStyle.output:
        return Text(
          line.text,
          style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFFCCCCCC), height: 1.4),
        );
      case _LineStyle.error:
        return Text(
          line.text,
          style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFFF44747), height: 1.4),
        );
      case _LineStyle.dim:
        return Text(
          line.text,
          style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFF858585), height: 1.4),
        );
    }
  }

  Widget _buildInputLine() {
    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
      child: Row(
        children: [
          const Text('\$ ', style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFF4EC9B0))),
          Expanded(
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (event) {
                if (event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    if (_history.isNotEmpty) {
                      if (_historyIndex == -1) {
                        _historyIndex = _history.length - 1;
                      } else if (_historyIndex > 0) {
                        _historyIndex--;
                      }
                      _inputController.text = _history[_historyIndex];
                      _inputController.selection = TextSelection.collapsed(offset: _inputController.text.length);
                    }
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    if (_history.isNotEmpty && _historyIndex >= 0) {
                      if (_historyIndex < _history.length - 1) {
                        _historyIndex++;
                        _inputController.text = _history[_historyIndex];
                      } else {
                        _historyIndex = -1;
                        _inputController.text = '';
                      }
                      _inputController.selection = TextSelection.collapsed(offset: _inputController.text.length);
                    }
                  }
                }
              },
              child: TextField(
                controller: _inputController,
                focusNode: _focusNode,
                enabled: !_executing,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFFCCCCCC)),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (value) {
                  if (value == 'exit') return;
                  _execute(value);
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

enum _LineStyle { prompt, command, output, error, dim }

class _TerminalLine {
  final String text;
  final _LineStyle style;
  const _TerminalLine(this.text, this.style);
}
