import 'package:flutter/material.dart';
import 'activity_bar.dart';
import 'file_tree.dart';

class SidePanel extends StatelessWidget {
  final ActivityType activity;
  final String? selectedFile;
  final ValueChanged<String>? onFileSelected;

  const SidePanel({
    super.key,
    required this.activity,
    this.selectedFile,
    this.onFileSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: const Color(0xFF252526),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Text(
        _headerTitle(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFFCCCCCC),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _headerTitle() {
    switch (activity) {
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
    switch (activity) {
      case ActivityType.files:
        return FileTree(
          rootPath: '.',
          selectedPath: selectedFile,
          onFileSelected: onFileSelected,
        );
      case ActivityType.search:
        return _buildSearchView();
      case ActivityType.sourceControl:
        return _buildPlaceholder('No source control', Icons.source);
      case ActivityType.extensions:
        return _buildPlaceholder('Extensions', Icons.extension);
      case ActivityType.settings:
        return _buildPlaceholder('Settings', Icons.settings);
    }
  }

  Widget _buildSearchView() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Container(
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF3C3C3C),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF555555)),
            ),
            child: const TextField(
              style: TextStyle(fontSize: 12, color: Color(0xFFCCCCCC)),
              decoration: InputDecoration(
                hintText: 'Search files...',
                hintStyle: TextStyle(fontSize: 12, color: Color(0xFF858585)),
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
                  color: const Color(0xFF858585),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String label, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: const Color(0xFF555555)),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF858585),
            ),
          ),
        ],
      ),
    );
  }
}
