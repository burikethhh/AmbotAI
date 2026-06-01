import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/roles/role.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/ambot_avatar.dart';
import 'message_bubble.dart';
import 'quick_actions.dart';

class ConversationList extends ConsumerWidget {
  final List<ChatMessage> messages;
  final ScrollController scrollController;
  final bool isDark;
  final Role role;
  final ValueChanged<String>? onQuickAction;

  const ConversationList({
    super.key,
    required this.messages,
    required this.scrollController,
    required this.isDark,
    required this.role,
    this.onQuickAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (messages.isEmpty) {
      return WelcomeView(
        role: role,
        isDark: isDark,
        onQuickAction: onQuickAction,
      );
    }
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return ChatMessageBubble(
          message: messages[index],
          isDark: isDark,
        );
      },
    );
  }
}

class WelcomeView extends StatelessWidget {
  final Role role;
  final bool isDark;
  final ValueChanged<String>? onQuickAction;

  const WelcomeView({
    super.key,
    required this.role,
    required this.isDark,
    this.onQuickAction,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textTertiary =
        isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AmbotAvatar(size: 72, isDark: isDark),
            const SizedBox(height: 24),
            Text(
              role.name.toUpperCase(),
              style: AppTypography.headlineLarge(textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              role.description,
              style: AppTypography.bodyMedium(textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Text(
              'SEND A MESSAGE TO START',
              style: AppTypography.labelMedium(textTertiary),
            ),
            if (onQuickAction != null) ...[
              const SizedBox(height: 24),
              QuickActions(isDark: isDark, onAction: onQuickAction!),
            ],
          ],
        ),
      ),
    );
  }
}
