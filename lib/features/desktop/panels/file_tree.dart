import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../desktop_colors.dart';

class FileTreeItem {
  final String name;
  final String path;
  final bool isDirectory;
  final List<FileTreeItem> children;

  FileTreeItem({
    required this.name,
    required this.path,
    this.isDirectory = false,
    this.children = const [],
  });
}

class FileTree extends StatefulWidget {
  final String rootPath;
  final String? selectedPath;
  final ValueChanged<String>? onFileSelected;

  const FileTree({
    super.key,
    this.rootPath = '.',
    this.selectedPath,
    this.onFileSelected,
  });

  @override
  State<FileTree> createState() => _FileTreeState();
}

class _FileTreeState extends State<FileTree> {
  List<FileTreeItem> _items = [];
  final Set<String> _expandedDirs = {};
  bool _loading = true;
  String? _error;
  StreamSubscription? _watcher;

  @override
  void initState() {
    super.initState();
    _loadDirectory(widget.rootPath);
  }

  @override
  void dispose() {
    _watcher?.cancel();
    super.dispose();
  }

  Future<void> _loadDirectory(String path) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dir = Directory(path);
      if (!await dir.exists()) {
        setState(() {
          _error = 'Directory not found';
          _loading = false;
        });
        return;
      }
      _items = await _listDirectory(dir);
      _loading = false;
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<List<FileTreeItem>> _listDirectory(Directory dir) async {
    final items = <FileTreeItem>[];
    try {
      final entities = await dir.list().toList();
      entities.sort((a, b) {
        final aDir = a is Directory;
        final bDir = b is Directory;
        if (aDir && !bDir) return -1;
        if (!aDir && bDir) return 1;
        return a.path.split(Platform.pathSeparator).last
            .compareTo(b.path.split(Platform.pathSeparator).last);
      });
      for (final entity in entities) {
        final name = entity.path.split(Platform.pathSeparator).last;
        if (name.startsWith('.') || name == 'node_modules' || name == '.dart_tool' || name == 'build') continue;
        items.add(FileTreeItem(
          name: name,
          path: entity.path,
          isDirectory: entity is Directory,
        ));
      }
    } catch (_) {}
    return items;
  }

  Future<List<FileTreeItem>> _loadChildren(Directory dir) async {
    final items = <FileTreeItem>[];
    try {
      final entities = await dir.list().toList();
      entities.sort((a, b) {
        final aDir = a is Directory;
        final bDir = b is Directory;
        if (aDir && !bDir) return -1;
        if (!aDir && bDir) return 1;
        return a.path.split(Platform.pathSeparator).last
            .compareTo(b.path.split(Platform.pathSeparator).last);
      });
      for (final entity in entities) {
        final name = entity.path.split(Platform.pathSeparator).last;
        if (name.startsWith('.') || name == 'node_modules' || name == '.dart_tool' || name == 'build') continue;
        items.add(FileTreeItem(
          name: name,
          path: entity.path,
          isDirectory: entity is Directory,
        ));
      }
    } catch (_) {}
    return items;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: _items.map((item) => _buildItem(item, 0)).toList(),
    );
  }

  Widget _buildItem(FileTreeItem item, int depth) {
    final isExpanded = _expandedDirs.contains(item.path);
    final isSelected = item.path == widget.selectedPath;

    if (item.isDirectory) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedDirs.remove(item.path);
                } else {
                  _expandedDirs.add(item.path);
                }
              });
            },
            child: Container(
              padding: EdgeInsets.only(
                left: 8.0 + depth * 16,
                right: 8,
                top: 3,
                bottom: 3,
              ),
              color: Colors.transparent,
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                    size: 14,
                    color: dcTextMuted,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded ? Icons.folder_open : Icons.folder,
                    size: 14,
                    color: const Color(0xFFD4A05A),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 12,
                          color: dcText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) _buildDirectoryContents(item, depth + 1),
        ],
      );
    }

    return GestureDetector(
      onTap: () => widget.onFileSelected?.call(item.path),
      child: Container(
        padding: EdgeInsets.only(
          left: 28.0 + depth * 16,
          right: 8,
          top: 3,
          bottom: 3,
        ),
        color: isSelected ? const Color(0xFF37373D) : Colors.transparent,
        child: Row(
          children: [
              Icon(
                _fileIcon(item.name),
                size: 14,
                color: dcTextMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected
                        ? dcAccent
                        : dcText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectoryContents(FileTreeItem item, int depth) {
    return FutureBuilder<List<FileTreeItem>>(
      future: _loadChildren(Directory(item.path)),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: EdgeInsets.only(left: 8.0 + depth * 16),
            child: const Text(
              '  (empty)',
              style: TextStyle(
                fontSize: 11,
                color: dcTextMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: snapshot.data!.map((child) => _buildItem(child, depth)).toList(),
        );
      },
    );
  }

  IconData _fileIcon(String name) {
    if (name.endsWith('.dart')) return Icons.code;
    if (name.endsWith('.yaml') || name.endsWith('.yml')) return Icons.settings;
    if (name.endsWith('.json')) return Icons.data_object;
    if (name.endsWith('.md')) return Icons.article;
    if (name.endsWith('.txt')) return Icons.text_snippet;
    if (name.endsWith('.png') || name.endsWith('.jpg') || name.endsWith('.svg')) return Icons.image;
    if (name.endsWith('.html')) return Icons.language;
    if (name.endsWith('.css') || name.endsWith('.scss')) return Icons.palette;
    if (name.endsWith('.js') || name.endsWith('.ts')) return Icons.javascript;
    return Icons.insert_drive_file;
  }
}
