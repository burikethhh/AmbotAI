import 'package:flutter/material.dart';
import '../../../core/agent/autonomous_agent.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/app_icon.dart';

class AgentStatusBanner extends StatelessWidget {
  final AgentState state;
  final IconData roleIcon;
  final String roleName;
  final bool isDark;

  const AgentStatusBanner({
    super.key,
    required this.state,
    required this.roleIcon,
    required this.roleName,
    required this.isDark,
  });

  Color get _stateColor {
    return switch (state) {
      AgentState.idle => isDark ? AppColors.silver : AppColors.grey,
      AgentState.planning ||
      AgentState.executing ||
      AgentState.observing =>
        AppColors.success,
      AgentState.paused => AppColors.warning,
      AgentState.stopped => AppColors.error,
    };
  }

  String get _stateLabel {
    return switch (state) {
      AgentState.idle => 'READY',
      AgentState.planning => 'PLANNING...',
      AgentState.executing => 'EXECUTING...',
      AgentState.observing => 'OBSERVING...',
      AgentState.paused => 'PAUSED',
      AgentState.stopped => 'STOPPED',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppIcon(
          icon: roleIcon,
          size: 32,
          backgroundColor:
              isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight,
          iconColor: _stateColor,
          borderColor: isDark ? AppColors.borderDark : AppColors.borderLight,
          borderWidth: 1.5,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$roleName - AGENT',
              style: AppTypography.headlineSmall(
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              _stateLabel,
              style: AppTypography.labelSmall(_stateColor),
            ),
          ],
        ),
      ],
    );
  }
}
