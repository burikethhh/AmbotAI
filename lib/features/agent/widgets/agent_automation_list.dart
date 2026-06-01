import 'package:flutter/material.dart';
import '../../../core/agent/autonomous_agent.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';

class AgentPlanList extends StatelessWidget {
  final List<String> plan;
  final bool isDark;

  const AgentPlanList({
    super.key,
    required this.plan,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final accentColor = isDark ? AppColors.silver : AppColors.grey;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_tree, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Text('Plan', style: AppTypography.headlineSmall(textColor)),
            ],
          ),
          const SizedBox(height: 8),
          ...plan.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${entry.key + 1}',
                      style: AppTypography.labelSmall(
                        isDark ? AppColors.black : AppColors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: AppTypography.bodyMedium(textColor),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class AgentStepsList extends StatelessWidget {
  final List<AgentStep> steps;
  final bool isDark;

  const AgentStepsList({
    super.key,
    required this.steps,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: steps.length,
      itemBuilder: (context, index) {
        final step = steps[index];
        final isCompleted = step.completedAt != null;
        final isCurrent = !isCompleted;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCurrent
                  ? (isDark ? AppColors.silver : AppColors.grey)
                  : borderColor,
              width: isCurrent ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isCompleted
                        ? Icons.check_circle
                        : isCurrent
                            ? Icons.play_circle
                            : Icons.circle_outlined,
                    color: isCompleted
                        ? AppColors.success
                        : (isDark ? AppColors.silver : AppColors.grey),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      step.description,
                      style: AppTypography.bodyMedium(textColor),
                    ),
                  ),
                ],
              ),
              if (step.result != null) ...[
                const SizedBox(height: 8),
                Text(
                  step.result!,
                  style: AppTypography.bodySmall(textSecondary),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
