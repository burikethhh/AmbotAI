import 'package:flutter/material.dart';

class DesktopContextMenu extends StatelessWidget {
  final Widget child;
  final VoidCallback? onCopy;
  final VoidCallback? onPaste;
  final VoidCallback? onSelectAll;
  final VoidCallback? onCut;

  const DesktopContextMenu({
    super.key,
    required this.child,
    this.onCopy,
    this.onPaste,
    this.onSelectAll,
    this.onCut,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapUp: (details) {
        _showContextMenu(context, details.globalPosition);
      },
      child: child,
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final items = <PopupMenuEntry<String>>[];

    if (onCopy != null) {
      items.add(_buildItem('Copy', Icons.copy, 'copy'));
    }
    if (onCut != null) {
      items.add(_buildItem('Cut', Icons.content_cut, 'cut'));
    }
    if (onPaste != null) {
      items.add(_buildItem('Paste', Icons.content_paste, 'paste'));
    }
    if (onSelectAll != null) {
      items.add(_buildItem('Select All', Icons.select_all, 'select_all'));
    }

    if (items.isEmpty) return;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: items,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: Colors.grey[800]!, width: 1),
      ),
      color: const Color(0xFF1E1E1E),
      elevation: 8,
    ).then((value) {
      if (value == null) return;
      switch (value) {
        case 'copy':
          onCopy?.call();
          break;
        case 'cut':
          onCut?.call();
          break;
        case 'paste':
          onPaste?.call();
          break;
        case 'select_all':
          onSelectAll?.call();
          break;
      }
    });
  }

  PopupMenuItem<String> _buildItem(String label, IconData icon, String value) {
    return PopupMenuItem<String>(
      value: value,
      height: 36,
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[400]),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
