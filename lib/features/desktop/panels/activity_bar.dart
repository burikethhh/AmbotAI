import 'package:flutter/material.dart';
import '../desktop_colors.dart';

enum ActivityType {
  files,
  search,
  sourceControl,
  extensions,
  settings,
}

class ActivityBar extends StatelessWidget {
  final ActivityType activeActivity;
  final ValueChanged<ActivityType> onActivityChanged;

  const ActivityBar({
    super.key,
    required this.activeActivity,
    required this.onActivityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      color: const Color(0xFF333333),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildItem(ActivityType.files, Icons.folder_outlined, 'Files'),
          _buildItem(ActivityType.search, Icons.search, 'Search'),
          _buildItem(ActivityType.sourceControl, Icons.source, 'Source Control'),
          _buildItem(ActivityType.extensions, Icons.extension, 'Extensions'),
          const Spacer(),
          _buildItem(ActivityType.settings, Icons.settings, 'Settings'),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildItem(ActivityType type, IconData icon, String tooltip) {
    final isActive = activeActivity == type;
    return GestureDetector(
      onTap: () => onActivityChanged(type),
      child: Tooltip(
        message: tooltip,
        preferBelow: false,
        waitDuration: const Duration(milliseconds: 300),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            border: isActive
                ? const Border(
                    left: BorderSide(color: dcAccent, width: 2),
                  )
                : null,
            color: isActive
                ? dcSurface
                : Colors.transparent,
          ),
          child: Icon(
            icon,
            size: 22,
            color: isActive
                ? dcAccent
                : dcTextMuted,
          ),
        ),
      ),
    );
  }
}
