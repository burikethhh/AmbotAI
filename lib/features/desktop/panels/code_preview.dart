import 'dart:io';
import 'package:flutter/material.dart';

class CodePreview extends StatefulWidget {
  final String filePath;
  final VoidCallback onClose;

  const CodePreview({
    super.key,
    required this.filePath,
    required this.onClose,
  });

  @override
  State<CodePreview> createState() => _CodePreviewState();
}

class _CodePreviewState extends State<CodePreview> {
  String? _content;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  @override
  void didUpdateWidget(CodePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filePath != widget.filePath) {
      _loadFile();
    }
  }

  Future<void> _loadFile() async {
    setState(() {
      _loading = true;
      _content = null;
      _error = null;
    });
    try {
      final file = File(widget.filePath);
      if (!await file.exists()) {
        setState(() {
          _error = 'File not found';
          _loading = false;
        });
        return;
      }
      final content = await file.readAsString();
      setState(() {
        _content = content;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E1E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const Divider(height: 1, color: Color(0xFF3C3C3C)),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF2D2D2D),
      ),
      child: Row(
        children: [
          Icon(
            _fileIcon(widget.filePath),
            size: 14,
            color: const Color(0xFF858585),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.filePath.split(Platform.pathSeparator).last,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFCCCCCC),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            widget.filePath,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF858585),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.close, size: 14, color: Color(0xFF858585)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 32, color: Color(0xFFF44747)),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(fontSize: 12, color: Color(0xFFF44747)),
            ),
          ],
        ),
      );
    }

    final lines = _content!.split('\n');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          color: const Color(0xFF1E1E1E),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(lines.length, (i) {
              return Container(
                height: 20,
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Color(0xFF858585),
                    height: 1.5,
                  ),
                ),
              );
            }),
          ),
        ),
        Container(
          width: 1,
          color: const Color(0xFF3C3C3C),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 12, top: 2, right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(lines.length, (i) {
                return _buildCodeLine(lines[i], i);
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeLine(String line, int index) {
    return Container(
      height: 20,
      alignment: Alignment.centerLeft,
      child: Text(
        line,
        style: const TextStyle(
          fontSize: 12,
          fontFamily: 'monospace',
          color: Color(0xFFCCCCCC),
          height: 1.5,
        ),
      ),
    );
  }

  IconData _fileIcon(String path) {
    if (path.endsWith('.dart')) return Icons.code;
    if (path.endsWith('.yaml') || path.endsWith('.yml')) return Icons.settings;
    if (path.endsWith('.json')) return Icons.data_object;
    if (path.endsWith('.md')) return Icons.article;
    if (path.endsWith('.html')) return Icons.language;
    if (path.endsWith('.css') || path.endsWith('.scss')) return Icons.palette;
    return Icons.insert_drive_file;
  }
}
