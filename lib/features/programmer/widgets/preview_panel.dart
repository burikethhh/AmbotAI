import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/theme/theme_colors.dart';

const _maxConsoleEntries = 100;

class PreviewPanel extends StatefulWidget {
  final String htmlCode;
  final ThemeColors themeColors;

  const PreviewPanel({
    super.key,
    required this.htmlCode,
    required this.themeColors,
  });

  @override
  State<PreviewPanel> createState() => _PreviewPanelState();
}

class _PreviewPanelState extends State<PreviewPanel> {
  WebViewController? _controller;
  final List<String> _consoleLogs = [];
  final _consoleScrollController = ScrollController();
  bool _showConsole = false;
  bool _isLoading = true;
  bool _loadFailed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  @override
  void didUpdateWidget(PreviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.htmlCode != widget.htmlCode) {
      _loadHtml();
    }
  }

  @override
  void dispose() {
    _consoleScrollController.dispose();
    super.dispose();
  }

  Future<void> _initWebView() async {
    try {
      final controller = WebViewController();
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.addJavaScriptChannel(
        'AmbotConsole',
        onMessageReceived: (message) {
          if (mounted) {
            setState(() {
              _consoleLogs.add(message.message);
              if (_consoleLogs.length > _maxConsoleEntries) {
                _consoleLogs.removeAt(0);
              }
            });
            _scrollConsoleToBottom();
          }
        },
      );
    _controller = controller;
    await _loadHtml();
  } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loadFailed = true;
        });
      }
    }
  }

  void _scrollConsoleToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_consoleScrollController.hasClients) {
        _consoleScrollController.animateTo(
          _consoleScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 50),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _buildFullHtml(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) {
      return '''<!DOCTYPE html>
<html><head><meta charset="UTF-8">
<style>body{font-family:system-ui,sans-serif;padding:20px;color:#888;text-align:center;padding-top:40px}</style>
</head><body>
<p>Write some code and press RUN</p>
</body></html>''';
    }

    final consoleCapture = '''
<script>
(function() {
  var origLog = console.log;
  var origError = console.error;
  console.log = function() {
    AmbotConsole.postMessage('[LOG] ' + Array.prototype.join.call(arguments, ' '));
    origLog.apply(console, arguments);
  };
  console.error = function() {
    AmbotConsole.postMessage('[ERROR] ' + Array.prototype.join.call(arguments, ' '));
    origError.apply(console, arguments);
  };
  window.onerror = function(msg, url, line, col) {
    AmbotConsole.postMessage('[RUNTIME ERROR] ' + msg + ' at line ' + line);
    return false;
  };
  AmbotConsole.postMessage('[INFO] Page loaded');
})();
</script>
''';

    if (trimmed.contains('<!DOCTYPE html', 0) ||
        trimmed.contains('<html', 0)) {
      final bodyEnd = trimmed.lastIndexOf('</html>');
      if (bodyEnd != -1) {
        return '${trimmed.substring(0, bodyEnd)}$consoleCapture\n</html>';
      }
      return '$trimmed\n$consoleCapture';
    }

    return '''<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body>
$trimmed
$consoleCapture
</body>
</html>''';
  }

  Future<void> _loadHtml() async {
    final controller = _controller;
    if (controller == null) return;

    setState(() {
      _isLoading = true;
      _loadFailed = false;
      _error = null;
      _consoleLogs.clear();
    });

    try {
      final fullHtml = _buildFullHtml(widget.htmlCode);
      await controller.loadHtmlString(fullHtml);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loadFailed = true;
          _isLoading = false;
        });
      }
    }
  }

  void _clearConsole() {
    setState(() => _consoleLogs.clear());
  }

  void _retry() {
    setState(() {
      _error = null;
      _loadFailed = false;
    });
    _initWebView();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.themeColors;
    final isCodeEmpty = widget.htmlCode.trim().isEmpty;

    return Column(
      children: [
        if (_loadFailed)
          _buildErrorState(c)
        else if (isCodeEmpty)
          _buildEmptyCodeState(c)
        else
          Expanded(
            child: _controller == null
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      WebViewWidget(controller: _controller!),
                      if (_isLoading)
                        Container(
                          color: c.surfaceColor.withValues(alpha: 0.7),
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
          ),
        if (!_loadFailed && !isCodeEmpty)
          _buildConsoleToggle(c),
        if (_showConsole && !_loadFailed && !isCodeEmpty)
          _buildConsolePanel(c),
      ],
    );
  }

  Widget _buildErrorState(ThemeColors c) {
    return Expanded(
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.error, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 32, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                'WEBVIEW ERROR',
                style: AppTypography.bodyMedium(AppColors.error),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'Unknown error',
                style: AppTypography.bodySmall(c.textTertiary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _retry,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: c.accent, width: 2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text('RETRY',
                      style: AppTypography.labelSmall(c.accent)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCodeState(ThemeColors c) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_circle_outline, size: 40, color: c.textTertiary),
            const SizedBox(height: 12),
            Text(
              'WRITE SOME CODE',
              style: AppTypography.bodyMedium(c.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Then press RUN to preview',
              style: AppTypography.bodySmall(c.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsoleToggle(ThemeColors c) {
    return GestureDetector(
      onTap: () => setState(() => _showConsole = !_showConsole),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: c.cardColor,
          border: Border(top: BorderSide(color: c.borderColor, width: 1)),
        ),
        child: Row(
          children: [
            Icon(
              _showConsole ? Icons.expand_less : Icons.expand_more,
              size: 14,
              color: c.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              'CONSOLE (${_consoleLogs.length})',
              style: AppTypography.labelSmall(c.textSecondary),
            ),
            const Spacer(),
            if (_consoleLogs.isNotEmpty)
              GestureDetector(
                onTap: _clearConsole,
                child: Icon(Icons.delete_outline,
                    size: 14, color: c.textTertiary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsolePanel(ThemeColors c) {
    return Container(
      height: 120,
      color: const Color(0xFF1E1E1E),
      child: _consoleLogs.isEmpty
          ? Center(
              child: Text('No output yet',
                  style: AppTypography.bodySmall(c.textTertiary)),
            )
          : ListView.builder(
              controller: _consoleScrollController,
              padding: const EdgeInsets.all(8),
              itemCount: _consoleLogs.length,
              itemBuilder: (context, i) {
                final log = _consoleLogs[i];
                final isError = log.contains('[ERROR]') ||
                    log.contains('[RUNTIME ERROR]');
                return Text(
                  log,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: isError
                        ? AppColors.error
                        : const Color(0xFFD4D4D4),
                    height: 1.4,
                  ),
                );
              },
            ),
    );
  }
}
