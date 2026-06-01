import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/storage/output_storage_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/theme/theme_colors.dart';
import '../../shared/widgets/app_icon.dart';

class GeneratedFilesScreen extends ConsumerStatefulWidget {
  const GeneratedFilesScreen({super.key});

  @override
  ConsumerState<GeneratedFilesScreen> createState() => _GeneratedFilesScreenState();
}

class _GeneratedFilesScreenState extends ConsumerState<GeneratedFilesScreen> {
  List<OutputFileInfo>? _files;
  bool _loading = true;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFiles() async {
    setState(() => _loading = true);
    try {
      final files = await OutputStorageService.instance.listAll();
      if (mounted) setState(() { _files = files; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _files = []; _loading = false; });
    }
  }

  void _showFileActions(OutputFileInfo file) {
    final c = ref.read(themeColorsProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: c.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(file.name, style: AppTypography.labelSmall(c.textPrimary), overflow: TextOverflow.ellipsis, maxLines: 1),
              const SizedBox(height: 4),
              Text('${_labelForType(file.type)} · ${file.sizeFormatted}',
                  style: AppTypography.bodySmall(c.textTertiary)),
              const SizedBox(height: 16),
              Divider(color: c.borderColor, height: 1, thickness: 1),
              ListTile(
                leading: Icon(Icons.open_in_new, color: c.textSecondary),
                title: Text('Open', style: AppTypography.bodyMedium(c.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _openFile(file);
                },
              ),
              ListTile(
                leading: Icon(Icons.share, color: c.textSecondary),
                title: Text('Share', style: AppTypography.bodyMedium(c.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _shareFile(file);
                },
              ),
              ListTile(
                leading: Icon(Icons.folder_open, color: c.textSecondary),
                title: Text('Show in folder', style: AppTypography.bodyMedium(c.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showInFolder(file);
                },
              ),
              Divider(color: c.borderColor, height: 1, thickness: 1),
              ListTile(
                leading: Icon(Icons.delete_outline, color: AppColors.danger),
                title: Text('Delete', style: AppTypography.bodyMedium(AppColors.danger)),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteFile(file.path);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openFile(OutputFileInfo file) async {
    final result = await OpenFile.open(file.path);
    if (result.type != ResultType.done && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open file: ${result.message}'), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _shareFile(OutputFileInfo file) async {
    try {
      await Share.shareXFiles([XFile(file.path)], subject: 'Ambot AI - ${file.name}');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not share file'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _showInFolder(OutputFileInfo file) async {
    // On Android, we try to open the parent folder.
    // Fallback: try opening the file itself.
    final result = await OpenFile.open(file.path);
    if (result.type != ResultType.done && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open folder: ${result.message}'), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _deleteFile(String path) async {
    await OutputStorageService.instance.deleteFile(path);
    _loadFiles();
  }

  List<OutputFileInfo> get _filteredFiles {
    if (_files == null) return [];
    if (_searchQuery.isEmpty) return _files!;
    final lower = _searchQuery.toLowerCase();
    return _files!.where((f) {
      if (f.name.toLowerCase().contains(lower)) return true;
      if (f.type.name.toLowerCase().contains(lower)) return true;
      if (f.tags.any((t) => t.toLowerCase().contains(lower))) return true;
      return false;
    }).toList();
  }

  Widget _emptyState(Color textTertiary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(icon: Icons.folder_open, iconColor: textTertiary, backgroundColor: Colors.transparent, size: 48),
            const SizedBox(height: 16),
            Text('NO GENERATED FILES', style: AppTypography.bodyMedium(textTertiary)),
            const SizedBox(height: 8),
            Text('Generated documents, images, and voice files will appear here.',
                style: AppTypography.bodySmall(textTertiary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildFileTile(OutputFileInfo file, Color cardColor, Color borderColor, Color textPrimary, Color textSecondary, Color textTertiary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showFileActions(file),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
AppIcon(
                      icon: _iconForType(file.type),
                      iconColor: textSecondary,
                      backgroundColor: Colors.transparent,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(file.name, style: AppTypography.labelSmall(textPrimary), overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(
                            '${_labelForType(file.type)} · ${file.sizeFormatted} · ${file.createdAt.toString().substring(0, 19)}',
                            style: AppTypography.bodySmall(textTertiary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: AppColors.danger, size: 18),
                      tooltip: 'Delete file',
                      onPressed: () => _deleteFile(file.path),
                    ),
                  ],
                ),
                if (file.tags.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: file.tags.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text('#$tag', style: AppTypography.labelSmall(textTertiary)),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForType(OutputType type) {
    switch (type) {
      case OutputType.documents: return Icons.description;
      case OutputType.images: return Icons.image;
      case OutputType.voice: return Icons.volume_up;
    }
  }

  String _labelForType(OutputType type) {
    switch (type) {
      case OutputType.documents: return 'Document';
      case OutputType.images: return 'Image';
      case OutputType.voice: return 'Voice';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(themeColorsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('MY FILES', style: AppTypography.headlineMedium(c.textPrimary)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: c.textPrimary),
            tooltip: 'Refresh files',
            onPressed: _loadFiles,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search by name or tag...',
                prefixIcon: Icon(Icons.search, color: c.textTertiary, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: c.textTertiary, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: c.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: c.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: c.textPrimary),
                ),
                filled: true,
                fillColor: c.cardColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              style: AppTypography.bodyMedium(c.textPrimary),
            ),
          ),
          Divider(color: c.borderColor, thickness: 2, height: 2),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _files == null || _files!.isEmpty
                    ? _emptyState(c.textTertiary)
                    : _filteredFiles.isEmpty
                        ? Center(
                            child: Text('No files match "$_searchQuery"',
                                style: AppTypography.bodyMedium(c.textTertiary)),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredFiles.length,
                            itemBuilder: (context, index) {
                              final file = _filteredFiles[index];
                              return _buildFileTile(file, c.cardColor, c.borderColor, c.textPrimary, c.textSecondary, c.textTertiary);
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
