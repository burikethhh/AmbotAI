import 'package:flutter/material.dart';
import '../../../shared/theme/theme_colors.dart';

class CodeEditorPanel extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ThemeColors themeColors;

  const CodeEditorPanel({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.themeColors,
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

  @override
  Widget build(BuildContext context) {
    final c = widget.themeColors;
    final isDark = c.isDark;

    return Container(
      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8F8F8),
      child: Column(
        children: [
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
          _buildStatusBar(c, isDark),
        ],
      ),
    );
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
                  color: isDark ? const Color(0xFF858585) : const Color(0xFF999999),
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
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: isDark ? const Color(0xFFD4D4D4) : const Color(0xFF333333),
            height: 20 / 13,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            isCollapsed: true,
            hintText: '// Start writing HTML, CSS, or JS here...',
            hintStyle: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA),
            ),
          ),
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
        ),
      ),
    );
  }

  Widget _buildStatusBar(ThemeColors c, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.borderColor, width: 1)),
      ),
      child: Row(
        children: [
          Text(
            'LINES: $_lineCount',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: isDark ? c.textTertiary : c.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            'HTML',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: isDark ? c.textTertiary : c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
