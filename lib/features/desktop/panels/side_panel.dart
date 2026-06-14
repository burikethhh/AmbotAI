import 'dart:io';

import 'package:flutter/material.dart';
import 'activity_bar.dart';
import 'file_tree.dart';
import '../desktop_colors.dart';

class SidePanel extends StatefulWidget {
  final ActivityType activity;
  final String? selectedFile;
  final ValueChanged<String>? onFileSelected;
  final ValueChanged<String>? onAddToContext;
  final String? modelName;
  final String? gpuInfo;

  const SidePanel({
    super.key,
    required this.activity,
    this.selectedFile,
    this.onFileSelected,
    this.onAddToContext,
    this.modelName,
    this.gpuInfo,
  });

  @override
  State<SidePanel> createState() => _SidePanelState();
}

class _SidePanelState extends State<SidePanel> {
  List<_GitFile> _gitFiles = [];
  bool _gitLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.activity == ActivityType.sourceControl) {
      _loadGitStatus();
    }
  }

  @override
  void didUpdateWidget(SidePanel old) {
    super.didUpdateWidget(old);
    if (widget.activity == ActivityType.sourceControl &&
        old.activity != widget.activity) {
      _loadGitStatus();
    }
  }

  Future<void> _loadGitStatus() async {
    setState(() => _gitLoading = true);
    try {
      final result = await Process.run(
        'git',
        ['status', '--porcelain'],
        workingDirectory: '.',
      );
      final lines = (result.stdout as String)
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();
      _gitFiles = lines.map((l) {
        final status = l.substring(0, 2).trim();
        final path = l.substring(3).trim();
        return _GitFile(status, path);
      }).toList();
    } catch (_) {}
    setState(() => _gitLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: dcSidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const Divider(height: 1, color: dcBorder),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Text(
        _headerTitle(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: dcText,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _headerTitle() {
    switch (widget.activity) {
      case ActivityType.files:
        return 'EXPLORER';
      case ActivityType.search:
        return 'SEARCH';
      case ActivityType.sourceControl:
        return 'SOURCE CONTROL';
      case ActivityType.extensions:
        return 'EXTENSIONS';
      case ActivityType.settings:
        return 'SETTINGS';
    }
  }

  Widget _buildContent() {
    switch (widget.activity) {
      case ActivityType.files:
        return FileTree(
          rootPath: '.',
          selectedPath: widget.selectedFile,
          onFileSelected: widget.onFileSelected,
          onAddToContext: widget.onAddToContext,
        );
      case ActivityType.search:
        return _buildSearchView();
      case ActivityType.sourceControl:
        return _buildSourceControlView();
      case ActivityType.extensions:
        return _buildExtensionsView();
      case ActivityType.settings:
        return _buildSettingsView();
    }
  }

  Widget _buildSourceControlView() {
    if (_gitLoading) {
      return const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_gitFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.source, size: 32, color: Color(0xFF555555)),
            const SizedBox(height: 8),
            const Text(
              'No changes',
              style: TextStyle(fontSize: 12, color: dcTextMuted),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _gitFiles.length,
      itemBuilder: (context, index) {
        final f = _gitFiles[index];
        return _buildGitFileTile(f);
      },
    );
  }

  Widget _buildGitFileTile(_GitFile f) {
    Color iconColor;
    IconData icon;
    switch (f.status) {
      case 'A':
        iconColor = dcSuccess;
        icon = Icons.add_circle_outline;
        break;
      case 'M':
      case 'AM':
      case 'MM':
        iconColor = dcWarning;
        icon = Icons.edit;
        break;
      case 'R':
        iconColor = dcSuccess;
        icon = Icons.drive_file_rename_outline;
        break;
      case 'D':
        iconColor = dcError;
        icon = Icons.delete_outline;
        break;
      default:
        iconColor = dcTextMuted;
        icon = Icons.question_mark;
    }
    return InkWell(
      onTap: () => widget.onFileSelected?.call(f.path),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 8),
            Text(
              f.path,
              style: const TextStyle(fontSize: 12, color: dcText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtensionsView() {
    const tools = [
      ('Read File', 'Read file contents', Icons.description),
      ('Write File', 'Create/overwrite files', Icons.edit_note),
      ('Edit File', 'Apply patches to files', Icons.find_replace),
      ('List Directory', 'Browse directory contents', Icons.folder_open),
      ('Shell', 'Execute shell commands', Icons.terminal),
      ('Search Files', 'Find files by name', Icons.search),
      ('Grep', 'Search file contents', Icons.text_snippet),
    ];
    return ListView(
      padding: const EdgeInsets.all(8),
      children: tools.map((t) => ListTile(
        dense: true,
        leading: Icon(t.$3, size: 16, color: dcAccent),
        title: Text(t.$1, style: const TextStyle(fontSize: 12, color: dcText)),
        subtitle: Text(t.$2, style: const TextStyle(fontSize: 10, color: dcTextMuted)),
      )).toList(),
    );
  }

  Widget _buildSettingsView() {
    final modelName = widget.modelName ?? 'none';
    final gpuInfo = widget.gpuInfo ?? 'CPU';
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text('Keyboard Shortcuts',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: dcText)),
        const SizedBox(height: 8),
        _shortcutRow('Toggle Terminal', 'Ctrl + `'),
        _shortcutRow('Toggle Sidebar', 'Ctrl + B'),
        _shortcutRow('Search Files', 'Ctrl + Shift + F'),
        _shortcutRow('Focus Mode', 'Ctrl + K Z'),
        const SizedBox(height: 16),
        const Text('Model Info',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: dcText)),
        const SizedBox(height: 8),
        Text(
          'Model: $modelName',
          style: const TextStyle(fontSize: 12, color: dcText),
        ),
        const SizedBox(height: 4),
        Text(
          'GPU: $gpuInfo',
          style: const TextStyle(fontSize: 12, color: dcTextMuted),
        ),
      ],
    );
  }

  Widget _shortcutRow(String label, String shortcut) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: dcText),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: dcSurface,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: dcBorder),
            ),
            child: Text(
              shortcut,
              style: const TextStyle(fontSize: 10, color: dcTextMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchView() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Container(
            height: 28,
            decoration: BoxDecoration(
              color: dcBorder,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF555555)),
            ),
            child: const TextField(
              style: TextStyle(fontSize: 12, color: dcText),
              decoration: InputDecoration(
                hintText: 'Search files...',
                hintStyle: TextStyle(fontSize: 12, color: dcTextMuted),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: Text(
                'Type to search across files',
                style: TextStyle(
                  fontSize: 11,
                  color: dcTextMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GitFile {
  final String status;
  final String path;
  const _GitFile(this.status, this.path);
}
