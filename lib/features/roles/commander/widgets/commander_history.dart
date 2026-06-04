import 'package:flutter/material.dart';

import '../../../../core/device_control/action_log.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';

class AgentHistory extends StatelessWidget {
  final List<LogEntry> log;
  final bool isDark;
  final Color cardColor;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onClear;

  const AgentHistory({
    super.key,
    required this.log,
    required this.isDark,
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Text(
                'ACTION LOG',
                style: AppTypography.labelSmall(textSecondary),
              ),
              const Spacer(),
              if (log.isNotEmpty)
                TextButton(
                  onPressed: onClear,
                  child: const Text('CLEAR'),
                ),
            ],
          ),
        ),
        Expanded(
          child: log.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.touch_app_outlined,
                        size: 48,
                        color: textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No actions yet',
                        style: AppTypography.bodyMedium(textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Use quick actions or voice commands',
                        style: AppTypography.labelSmall(
                          textSecondary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: log.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final entry = log[index];
                    return LogTile(
                      entry: entry,
                      isDark: isDark,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class LogTile extends StatelessWidget {
  final LogEntry entry;
  final bool isDark;
  final Color cardColor;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  const LogTile({
    super.key,
    required this.entry,
    required this.isDark,
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(
            entry.success
                ? Icons.check_circle_outline
                : Icons.error_outline,
            size: 16,
            color: entry.success
                ? AppColors.success
                : AppColors.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.actionLabel,
                  style: AppTypography.labelSmall(textPrimary),
                ),
                Text(
                  entry.userResponse,
                  style: AppTypography.labelSmall(textSecondary),
                ),
              ],
            ),
          ),
          Text(
            _timeAgo(entry.timestamp),
            style: AppTypography.labelSmall(textSecondary),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
