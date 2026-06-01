import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/agent/agent_provider.dart';
import '../../core/agent/autonomous_agent.dart';
import '../../core/roles/role.dart';
import '../../core/services/haptic_feedback_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/theme/theme_colors.dart';
import 'widgets/agent_status_banner.dart';
import 'widgets/agent_automation_list.dart';
import 'widgets/agent_log_panel.dart';

class AgentScreen extends ConsumerStatefulWidget {
  final Role role;

  const AgentScreen({super.key, required this.role});

  @override
  ConsumerState<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends ConsumerState<AgentScreen> {
  final _goalController = TextEditingController();

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  void _startAgent() {
    final goal = _goalController.text.trim();
    if (goal.isEmpty) return;
    HapticFeedbackService.heavy();
    ref.read(agentStateProvider.notifier).start(goal);
  }

  void _pauseAgent() {
    HapticFeedbackService.tap();
    ref.read(agentStateProvider.notifier).pause();
  }

  void _resumeAgent() {
    HapticFeedbackService.tap();
    ref.read(agentStateProvider.notifier).resume();
  }

  void _stopAgent() {
    HapticFeedbackService.heavy();
    ref.read(agentStateProvider.notifier).stop();
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(themeColorsProvider);
    final agentState = ref.watch(agentStateProvider);

    final isRunning = agentState.state == AgentState.planning ||
        agentState.state == AgentState.executing ||
        agentState.state == AgentState.observing;
    final isPaused = agentState.state == AgentState.paused;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: AgentStatusBanner(
          state: agentState.state,
          roleIcon: widget.role.icon,
          roleName: widget.role.name.toUpperCase(),
          isDark: c.isDark,
        ),
      ),
      body: Column(
        children: [
          Divider(color: c.borderColor, thickness: 2, height: 2),
          if (!isRunning && !isPaused) _GoalInput(
            controller: _goalController,
            isDark: c.isDark,
            onStart: _startAgent,
          ),
          Expanded(
            child: Column(
              children: [
                if (agentState.plan.isNotEmpty)
                  AgentPlanList(plan: agentState.plan, isDark: c.isDark),
                if (agentState.steps.isNotEmpty)
                  Expanded(
                    child: AgentStepsList(
                      steps: agentState.steps,
                      isDark: c.isDark,
                    ),
                  ),
                if (agentState.log.isNotEmpty)
                  AgentLogPanel(log: agentState.log, isDark: c.isDark),
              ],
            ),
          ),
          if (isRunning || isPaused)
            _AgentControls(
              isRunning: isRunning,
              isPaused: isPaused,
              isDark: c.isDark,
              onPause: _pauseAgent,
              onResume: _resumeAgent,
              onStop: _stopAgent,
            ),
        ],
      ),
    );
  }

}

class _GoalInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final VoidCallback onStart;

  const _GoalInput({
    required this.controller,
    required this.isDark,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppColors.cardDark : AppColors.cardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final hintColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What should I accomplish?',
            style: AppTypography.headlineSmall(textColor),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: TextField(
              controller: controller,
              style: AppTypography.bodyMedium(textColor),
              maxLines: 3,
              minLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g., Research the best practices for Flutter state management and summarize the findings',
                hintStyle: AppTypography.bodyMedium(hintColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.white : AppColors.black,
                foregroundColor: isDark ? AppColors.black : AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'START AGENT',
                style: AppTypography.labelMedium(
                  isDark ? AppColors.black : AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentControls extends StatelessWidget {
  final bool isRunning;
  final bool isPaused;
  final bool isDark;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  const _AgentControls({
    required this.isRunning,
    required this.isPaused,
    required this.isDark,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          if (isPaused)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onResume,
                icon: const Icon(Icons.play_arrow),
                label: const Text('RESUME'),
              ),
            ),
          if (isRunning || isPaused)
            const SizedBox(width: 12),
          if (isRunning)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onPause,
                icon: const Icon(Icons.pause),
                label: const Text('PAUSE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.black,
                ),
              ),
            ),
          if (isRunning || isPaused)
            const SizedBox(width: 12),
          if (isRunning || isPaused)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onStop,
                icon: const Icon(Icons.stop),
                label: const Text('STOP'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
