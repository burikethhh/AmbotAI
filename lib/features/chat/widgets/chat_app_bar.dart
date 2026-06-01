import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/roles/role.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/theme/theme_colors.dart';
import '../../../shared/widgets/app_icon.dart';
import '../../../core/roles/role_domain.dart';

class ChatAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final Role role;
  final bool isStreaming;
  final ResponseMode responseMode;
  final bool qaMode;
  final VoidCallback onCycleResponseMode;
  final VoidCallback onToggleQaMode;
  final VoidCallback onHistory;
  final VoidCallback onMoreOptions;

  const ChatAppBar({
    super.key,
    required this.role,
    required this.isStreaming,
    required this.responseMode,
    required this.qaMode,
    required this.onCycleResponseMode,
    required this.onToggleQaMode,
    required this.onHistory,
    required this.onMoreOptions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(themeColorsProvider);
    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: c.textPrimary),
        tooltip: 'Back',
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          AppIcon(
            icon: role.icon,
            size: 32,
            backgroundColor: c.isDark ? AppColors.cardDarkElevated : AppColors.surfaceLight,
            iconColor: c.textSecondary,
            borderColor: c.isDark ? AppColors.borderDark : AppColors.borderLight,
            borderWidth: 1.5,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role.name.toUpperCase(),
                  style: AppTypography.headlineSmall(c.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isStreaming ? 'THINKING...' : 'ONLINE',
                  style: AppTypography.labelSmall(c.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            responseMode == ResponseMode.thinking
                ? Icons.psychology
                : responseMode == ResponseMode.plan
                    ? Icons.account_tree
                    : Icons.chat_bubble_outline,
            color: c.textSecondary,
          ),
          tooltip: 'Response mode: ${responseMode.name}',
          onPressed: isStreaming ? null : onCycleResponseMode,
        ),
        IconButton(
          icon: Icon(
            qaMode ? Icons.quiz : Icons.quiz_outlined,
            color: qaMode
                ? (c.isDark ? AppColors.white : AppColors.black)
                : c.textSecondary,
          ),
          tooltip: qaMode ? 'Q&A mode ON' : 'Q&A mode OFF',
          onPressed: isStreaming ? null : onToggleQaMode,
        ),
        IconButton(
          icon: Icon(Icons.history_outlined, color: c.textSecondary),
          tooltip: 'Conversation history',
          onPressed: onHistory,
        ),
        IconButton(
          icon: Icon(Icons.more_vert, color: c.textSecondary),
          tooltip: 'More options',
          onPressed: onMoreOptions,
        ),
      ],
    );
  }
}

class InfoChip extends StatelessWidget {
  final String label;
  final bool isDark;

  const InfoChip({super.key, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall(
          isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
      ),
    );
  }
}

void showRoleInfo(BuildContext context, WidgetRef ref, Role role, bool isDark) {
  final c = isDark ? ThemeColors.dark() : ThemeColors.light();

  showModalBottomSheet(
    context: context,
    backgroundColor: c.isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
    builder: (ctx) => Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
AppIcon(
                icon: role.icon,
                size: 40,
                backgroundColor: c.isDark
                    ? AppColors.cardDarkElevated
                    : AppColors.surfaceLight,
                iconColor: c.textSecondary,
                borderColor: c.borderColor,
                borderWidth: 1.5,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  role.name.toUpperCase(),
                  style: AppTypography.headlineMedium(c.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            role.description,
            style: AppTypography.bodyMedium(c.textSecondary),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              InfoChip(label: role.category.name.toUpperCase(), isDark: c.isDark),
              InfoChip(label: role.domain.label, isDark: c.isDark),
              if (role.acceptsImage) InfoChip(label: 'IMAGE INPUT', isDark: c.isDark),
              if (role.acceptsDocument) InfoChip(label: 'DOCUMENT INPUT', isDark: c.isDark),
              InfoChip(label: role.defaultMemoryScope.label, isDark: c.isDark),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                context.pushNamed('agent', extra: role);
              },
              icon: const Icon(Icons.smart_toy_outlined),
              label: const Text('AGENT MODE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: c.isDark ? AppColors.white : AppColors.black,
                foregroundColor: c.isDark ? AppColors.black : AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (role.tags.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: role.tags
                  .map((t) => Text(
                        '#$t',
                        style: AppTypography.labelSmall(c.textSecondary),
                      ))
                  .toList(),
            ),
        ],
      ),
    ),
  );
}
