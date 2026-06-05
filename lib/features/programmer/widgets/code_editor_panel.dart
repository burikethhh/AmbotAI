import 'package:flutter/material.dart';
import '../../../shared/theme/theme_colors.dart';
import '../programmer_types.dart';

class CodeEditorPanel extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ThemeColors themeColors;
  final List<ProjectFile> projectFiles;
  final int selectedFileIndex;
  final ValueChanged<int> onSelectFile;
  final VoidCallback onDeleteFile;

  const CodeEditorPanel({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.themeColors,
    required this.projectFiles,
    required this.selectedFileIndex,
    required this.onSelectFile,
    required this.onDeleteFile,
  });

  @override
  State<CodeEditorPanel> createState() => _CodeEditorPanelState();
}

class _CodeEditorPanelState extends State<CodeEditorPanel> {
  int _lineCount = 1;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _updateLineCount(widget.controller.text);
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(CodeEditorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedFileIndex != widget.selectedFileIndex) {
      _updateLineCount(widget.controller.text);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    _updateLineCount(widget.controller.text);
  }

  void _updateLineCount(String text) {
    final count = '\n'.allMatches(text).length + 1;
    if (count != _lineCount) {
      setState(() => _lineCount = count);
    }
  }

  Color _fileTabColor(String filename, bool isSelected) {
    if (!isSelected) return Colors.transparent;
    final ext = filename.contains('.')
        ? filename.substring(filename.lastIndexOf('.'))
        : '';
    switch (ext) {
      case '.html': return const Color(0xFFE44D26);
      case '.css': return const Color(0xFF1572B6);
      case '.js': return const Color(0xFFF7DF1E);
      default: return widget.themeColors.isDark
          ? const Color(0xFF333333)
          : const Color(0xFFDDDDDD);
    }
  }

  Color _fileTabTextColor(String filename, bool isSelected) {
    if (!isSelected) return widget.themeColors.textSecondary;
    final ext = filename.contains('.')
        ? filename.substring(filename.lastIndexOf('.'))
        : '';
    return ext == '.js' ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.themeColors;
    final isDark = c.isDark;
    final currentFile = widget.selectedFileIndex < widget.projectFiles.length
        ? widget.projectFiles[widget.selectedFileIndex]
        : null;

    return Container(
      color: const Color(0xFF1E1E1E),
      child: Column(
        children: [
          _buildFileTabs(c),
          Divider(height: 1, color: c.borderColor.withValues(alpha: 0.3)),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLineNumbers(c, isDark),
                Container(width: 1, color: const Color(0xFF333333)),
                Expanded(child: _buildCodeField(c, isDark)),
              ],
            ),
          ),
          _buildStatusBar(c, isDark, currentFile),
        ],
      ),
    );
  }

  Widget _buildFileTabs(ThemeColors c) {
    return Container(
      height: 36,
      color: const Color(0xFF252526),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.projectFiles.length,
        itemBuilder: (context, i) {
          final file = widget.projectFiles[i];
          final selected = i == widget.selectedFileIndex;
          final bgColor = _fileTabColor(file.filename, selected);
          final textColor = _fileTabTextColor(file.filename, selected);

          return GestureDetector(
            onTap: () => widget.onSelectFile(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: selected
                    ? (bgColor.withValues(alpha: 0.85))
                    : const Color(0xFF2D2D2D),
                border: Border(
                  right: BorderSide(color: const Color(0xFF3C3C3C), width: 1),
                  top: BorderSide(
                    color: selected ? bgColor : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _fileIcon(file.filename),
                    size: 14,
                    color: selected ? textColor : c.textTertiary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    file.filename,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: selected ? textColor : c.textSecondary,
                    ),
                  ),
                  if (widget.projectFiles.length > 1)
                    GestureDetector(
                      onTap: () {
                        final idx = widget.projectFiles.indexOf(file);
                        if (idx != -1 && widget.projectFiles.length > 1) {
                          widget.onDeleteFile();
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Icon(
                          Icons.close,
                          size: 12,
                          color: selected
                              ? textColor.withValues(alpha: 0.7)
                              : c.textTertiary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _fileIcon(String filename) {
    final ext = filename.contains('.')
        ? filename.substring(filename.lastIndexOf('.'))
        : '';
    switch (ext) {
      case '.html': return Icons.code;
      case '.css': return Icons.palette_outlined;
      case '.js': return Icons.javascript;
      default: return Icons.insert_drive_file_outlined;
    }
  }

  Widget _buildLineNumbers(ThemeColors c, bool isDark) {
    return SizedBox(
      width: 48,
      child: ListView.builder(
        controller: _scrollController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _lineCount,
        itemBuilder: (context, i) {
          return SizedBox(
            height: 20,
            child: Center(
              child: Text(
                '${i + 1}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: const Color(0xFF858585),
                  height: 20 / 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCodeField(ThemeColors c, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 2,
        child: TextField(
          controller: widget.controller,
          scrollController: _scrollController,
          onChanged: widget.onChanged,
          maxLines: null,
          expands: true,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: Color(0xFFD4D4D4),
            height: 20 / 13,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.fromLTRB(12, 8, 12, 8),
            isCollapsed: true,
            hintText: '// Start writing code...',
            hintStyle: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: Color(0xFF555555),
            ),
          ),
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
        ),
      ),
    );
  }

  Widget _buildStatusBar(
      ThemeColors c, bool isDark, ProjectFile? currentFile) {
    final langLabel = currentFile?.language.toUpperCase() ?? 'HTML';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.borderColor, width: 1)),
        color: const Color(0xFF007ACC),
      ),
      child: Row(
        children: [
          Text(
            'LINES: $_lineCount',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Text(
            langLabel,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
