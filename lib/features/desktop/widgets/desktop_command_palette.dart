import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/theme_colors.dart';

class DesktopCommandPalette extends ConsumerStatefulWidget {
  final Function(int) onNavigate;
  final VoidCallback onClose;

  const DesktopCommandPalette({
    super.key,
    required this.onNavigate,
    required this.onClose,
  });

  @override
  ConsumerState<DesktopCommandPalette> createState() => _DesktopCommandPaletteState();
}

class _DesktopCommandPaletteState extends ConsumerState<DesktopCommandPalette>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _selectedIndex = 0;
  List<_CommandItem> _filtered = [];

  static final List<_CommandItem> _commands = [
    _CommandItem(icon: Icons.chat_outlined, label: 'General Chat', section: 'Navigate', index: 0),
    _CommandItem(icon: Icons.forum_outlined, label: 'Role Chat', section: 'Navigate', index: 1),
    _CommandItem(icon: Icons.image_outlined, label: 'Image Generation', section: 'Navigate', index: 2),
    _CommandItem(icon: Icons.description_outlined, label: 'Documents', section: 'Navigate', index: 3),
    _CommandItem(icon: Icons.code_outlined, label: 'Programmer', section: 'Navigate', index: 4),
    _CommandItem(icon: Icons.apps_outlined, label: 'All Roles', section: 'Navigate', index: 5),
    _CommandItem(icon: Icons.storage_outlined, label: 'Models', section: 'Navigate', index: 6),
    _CommandItem(icon: Icons.memory_outlined, label: 'Memory', section: 'Navigate', index: 7),
    _CommandItem(icon: Icons.settings_outlined, label: 'Settings', section: 'Navigate', index: 8),
    _CommandItem(icon: Icons.add_circle_outline, label: 'New Chat', section: 'Action', index: 0),
    _CommandItem(icon: Icons.brightness_6, label: 'Toggle Theme', section: 'Action', index: -1),
  ];

  @override
  void initState() {
    super.initState();
    _filtered = _commands;
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = _commands;
      } else {
        _filtered = _commands
            .where((c) => c.label.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
      _selectedIndex = 0;
    });
  }

  void _execute(_CommandItem item) {
    widget.onClose();
    if (item.index >= 0) {
      widget.onNavigate(item.index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(themeColorsProvider);

    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // absorb taps
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (event) {
                if (event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.escape) {
                    widget.onClose();
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    setState(() {
                      _selectedIndex = (_selectedIndex + 1) % _filtered.length;
                    });
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    setState(() {
                      _selectedIndex = (_selectedIndex - 1 + _filtered.length) % _filtered.length;
                    });
                  } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                    if (_filtered.isNotEmpty) {
                      _execute(_filtered[_selectedIndex]);
                    }
                  }
                }
              },
              child: Container(
                width: 480,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                margin: const EdgeInsets.only(bottom: 80),
                decoration: BoxDecoration(
                  color: c.isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  border: Border.all(color: c.borderColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSearchBar(c),
                    if (_filtered.isNotEmpty) _buildDivider(c),
                    Flexible(
                      child: _filtered.isEmpty
                          ? _buildEmptyState(c)
                          : _buildResults(c),
                    ),
                    _buildFooter(c),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.search, size: 18, color: c.textTertiary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: _filter,
              style: TextStyle(fontSize: 15, color: c.textPrimary),
              decoration: InputDecoration(
                hintText: 'Type a command...',
                hintStyle: TextStyle(color: c.textTertiary, fontSize: 15),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: c.borderColor, width: 1),
            ),
            child: Text('ESC', style: AppTypography.labelSmall(c.textTertiary)),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(ThemeColors c) {
    return Container(height: 1, color: c.borderColor);
  }

  Widget _buildResults(ThemeColors c) {
    String? lastSection;

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _filtered.length,
      itemBuilder: (context, index) {
        final item = _filtered[index];
        final showHeader = item.section != lastSection;
        lastSection = item.section;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  item.section.toUpperCase(),
                  style: AppTypography.labelSmall(c.textTertiary),
                ),
              ),
            _CommandTile(
              item: item,
              isSelected: index == _selectedIndex,
              onTap: () => _execute(item),
              onHover: () => setState(() => _selectedIndex = index),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeColors c) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          'No commands found',
          style: TextStyle(color: c.textTertiary, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildFooter(ThemeColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.borderColor, width: 1)),
      ),
      child: Row(
        children: [
          _ShortcutHint(label: '↑↓', desc: 'Navigate'),
          const SizedBox(width: 12),
          _ShortcutHint(label: '↵', desc: 'Select'),
          const SizedBox(width: 12),
          _ShortcutHint(label: 'esc', desc: 'Close'),
          const Spacer(),
          Text('${_filtered.length} commands', style: AppTypography.labelSmall(c.textTertiary)),
        ],
      ),
    );
  }
}

class _CommandTile extends StatelessWidget {
  final _CommandItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onHover;

  const _CommandTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onHover(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: isSelected
              ? (c.isDark ? AppColors.cardDark : AppColors.cardLight)
              : Colors.transparent,
          child: Row(
            children: [
              Icon(item.icon, size: 16, color: c.textSecondary),
              const SizedBox(width: 10),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? c.textPrimary : c.textSecondary,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
              const Spacer(),
              if (item.index >= 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    border: Border.all(color: c.borderColor, width: 1),
                  ),
                  child: Text(
                    '${item.index + 1}',
                    style: AppTypography.labelSmall(c.textTertiary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutHint extends StatelessWidget {
  final String label;
  final String desc;

  const _ShortcutHint({required this.label, required this.desc});

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            border: Border.all(color: c.borderColor, width: 1),
          ),
          child: Text(label, style: AppTypography.labelSmall(c.textTertiary)),
        ),
        const SizedBox(width: 4),
        Text(desc, style: AppTypography.labelSmall(c.textTertiary)),
      ],
    );
  }
}

class _CommandItem {
  final IconData icon;
  final String label;
  final String section;
  final int index;

  const _CommandItem({
    required this.icon,
    required this.label,
    required this.section,
    required this.index,
  });
}
