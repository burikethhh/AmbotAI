import 'package:flutter/material.dart';

const Color _bg = Color(0xFF252526);
const Color _border = Color(0xFF3C3C3C);
const Color _text = Color(0xFFCCCCCC);
const Color _muted = Color(0xFF858585);
const Color _accent = Color(0xFFFFA726);
const Color _surface = Color(0xFF2D2D2D);

class ContextPanel extends StatefulWidget {
  final List<ContextFile> files;
  final List<AgentLogEntry> logs;
  final int inputTokens;
  final int outputTokens;
  final String? selectedFile;
  final ValueChanged<String?>? onSelectFile;
  final VoidCallback? onClearFiles;

  const ContextPanel({
    super.key,
    required this.files,
    required this.logs,
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.selectedFile,
    this.onSelectFile,
    this.onClearFiles,
  });

  @override
  State<ContextPanel> createState() => _ContextPanelState();
}

class _ContextPanelState extends State<ContextPanel> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTabs(),
          Expanded(child: _buildContent()),
          _buildTokenBar(),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      height: 32,
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          _buildTab(0, 'FILES', Icons.folder_outlined),
          _buildTab(1, 'LOGS', Icons.list_alt),
          _buildTab(2, 'STATE', Icons.psychology),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label, IconData icon) {
    final isActive = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: isActive ? _accent : Colors.transparent, width: 2),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 12, color: isActive ? _accent : _muted),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isActive ? _accent : _muted,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case 0:
        return _buildFilesTab();
      case 1:
        return _buildLogsTab();
      case 2:
        return _buildStateTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFilesTab() {
    if (widget.files.isEmpty) {
      return Center(
        child: Text(
          'No files in context',
          style: TextStyle(fontSize: 11, color: _muted, fontStyle: FontStyle.italic),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: widget.files.length,
      itemBuilder: (context, i) {
        final file = widget.files[i];
        final isSelected = file.path == widget.selectedFile;
        return _buildFileItem(file, isSelected);
      },
    );
  }

  Widget _buildFileItem(ContextFile file, bool isSelected) {
    return GestureDetector(
      onTap: () => widget.onSelectFile?.call(file.path),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF37373D) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(_fileIcon(file.path), size: 14, color: isSelected ? _accent : _muted),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: TextStyle(fontSize: 12, color: isSelected ? _accent : _text),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (file.description != null)
                    Text(
                      file.description!,
                      style: const TextStyle(fontSize: 10, color: _muted),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _fileIcon(String path) {
    final ext = path.contains('.') ? path.substring(path.lastIndexOf('.')) : '';
    switch (ext) {
      case '.dart':
        return Icons.code;
      case '.yaml':
      case '.yml':
        return Icons.settings;
      case '.json':
        return Icons.data_object;
      case '.md':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  Widget _buildLogsTab() {
    if (widget.logs.isEmpty) {
      return Center(
        child: Text(
          'No logs yet',
          style: TextStyle(fontSize: 11, color: _muted, fontStyle: FontStyle.italic),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: widget.logs.length,
      itemBuilder: (context, i) => _buildLogEntry(widget.logs[i]),
    );
  }

  Widget _buildLogEntry(AgentLogEntry log) {
    final color = _logColor(log.level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            log.time,
            style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: _muted),
          ),
          const SizedBox(width: 8),
          Icon(_logIcon(log.level), size: 12, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(log.message, style: TextStyle(fontSize: 11, color: color)),
          ),
        ],
      ),
    );
  }

  Color _logColor(String level) {
    switch (level) {
      case 'info':
        return const Color(0xFF569CD6);
      case 'success':
        return const Color(0xFF4EC9B0);
      case 'warning':
        return const Color(0xFFDCDCA0);
      case 'error':
        return const Color(0xFFF44747);
      default:
        return _muted;
    }
  }

  IconData _logIcon(String level) {
    switch (level) {
      case 'info':
        return Icons.info_outline;
      case 'success':
        return Icons.check_circle_outline;
      case 'warning':
        return Icons.warning_amber;
      case 'error':
        return Icons.error_outline;
      default:
        return Icons.circle;
    }
  }

  Widget _buildStateTab() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStateItem('Session', 'Build Agent'),
          _buildStateItem('Model', 'Llama 3 8B'),
          _buildStateItem('Context', '${widget.inputTokens} tokens'),
          _buildStateItem('Status', 'Connected'),
          const SizedBox(height: 16),
          const Text(
            'MEMORY',
            style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: _muted, letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Working on ${widget.files.length} files',
            style: const TextStyle(fontSize: 12, color: _text),
          ),
        ],
      ),
    );
  }

  Widget _buildStateItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: _muted)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _accent)),
        ],
      ),
    );
  }

  Widget _buildTokenBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Input: ${widget.inputTokens}', style: const TextStyle(fontSize: 10, color: _muted)),
          Text('Output: ${widget.outputTokens}', style: const TextStyle(fontSize: 10, color: _muted)),
        ],
      ),
    );
  }
}

class ContextFile {
  final String name;
  final String path;
  final String? description;

  const ContextFile({
    required this.name,
    required this.path,
    this.description,
  });
}

class AgentLogEntry {
  final String time;
  final String level;
  final String message;

  const AgentLogEntry({
    required this.time,
    required this.level,
    required this.message,
  });
}
