import 'package:flutter/material.dart';

import '../../../../core/device_control/execution_mode.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';

class AgentAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ExecutionMode mode;
  final ValueChanged<ExecutionMode> onModeChanged;
  final VoidCallback onBack;
  final Color textPrimary;
  final bool isDark;
  final bool butlerMode;
  final VoidCallback onToggleButler;

  const AgentAppBar({
    super.key,
    required this.mode,
    required this.onModeChanged,
    required this.onBack,
    required this.textPrimary,
    required this.isDark,
    this.butlerMode = false,
    required this.onToggleButler,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: textPrimary),
        onPressed: onBack,
      ),
      title: Text(
        butlerMode ? 'BUTLER' : 'AGENT',
        style: AppTypography.headlineSmall(textPrimary),
      ),
      actions: [
        IconButton(
          icon: Icon(
            butlerMode ? Icons.diamond : Icons.diamond_outlined,
            color: butlerMode
                ? AppColors.success
                : textPrimary,
          ),
          tooltip: butlerMode ? 'Disable butler mode' : 'Enable butler mode',
          onPressed: onToggleButler,
        ),
        ExecutionModeSelector(
          mode: mode,
          isDark: isDark,
          onChanged: onModeChanged,
        ),
      ],
    );
  }
}

class ExecutionModeSelector extends StatelessWidget {
  final ExecutionMode mode;
  final bool isDark;
  final ValueChanged<ExecutionMode> onChanged;

  const ExecutionModeSelector({
    super.key,
    required this.mode,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ExecutionMode>(
      icon: Icon(mode.icon,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
      tooltip: mode.label,
      itemBuilder: (ctx) => ExecutionMode.values
          .map((m) => PopupMenuItem(
                value: m,
                child: Row(
                  children: [
                    Icon(m.icon, size: 18),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.label),
                        Text(
                          m.description,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ))
          .toList(),
      onSelected: onChanged,
    );
  }
}
