import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/conversation_store.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/theme/theme_colors.dart';

class ConversationHistoryScreen extends ConsumerStatefulWidget {
  final String roleId;

  const ConversationHistoryScreen({super.key, required this.roleId});

  @override
  ConsumerState<ConversationHistoryScreen> createState() =>
      _ConversationHistoryScreenState();
}

class _ConversationHistoryScreenState
    extends ConsumerState<ConversationHistoryScreen> {
  int _refreshTick = 0;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  void _refresh() => setState(() => _refreshTick++);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(themeColorsProvider);
    final roles = ref.watch(rolesProvider);
    final role = roles.where((r) => r.id == widget.roleId).firstOrNull;

    // _refreshTick forces rebuild after mutations
    final _ = _refreshTick;
    final now = DateTime.now();
    final allConvs = ConversationStore.instance.getByRole(widget.roleId);
    final conversations = _searchQuery.isEmpty
        ? allConvs
        : ConversationStore.instance.search(_searchQuery, widget.roleId);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textPrimary),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'HISTORY',
          style: AppTypography.headlineSmall(c.textPrimary),
        ),
        actions: [
          if (conversations.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep_outlined, color: c.textSecondary),
              tooltip: 'Clear all',
              onPressed: () => _confirmClearAll(context, c.isDark),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                prefixIcon: Icon(Icons.search, color: c.textSecondary, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: c.textSecondary, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: c.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: c.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: c.textPrimary),
                ),
                filled: true,
                fillColor: c.cardColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              style: AppTypography.bodyMedium(c.textPrimary),
            ),
          ),
          Divider(color: c.borderColor, thickness: 2, height: 2),
          Expanded(
            child: conversations.isEmpty
                ? _EmptyState(isDark: c.isDark, role: role)
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: conversations.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final conv = conversations[index];
                      final title = ConversationStore.instance.getTitle(conv.id) ??
                          ConversationStore.generateTitle(conv.messages);
                      final lastMsg = conv.messages.lastOrNull;
                      final preview = lastMsg?.content ?? 'No messages';
                      final timeAgo = _timeAgo(conv.updatedAt, now: now);
                  
                      return _ConversationTile(
                        title: title,
                        preview: preview,
                        timeAgo: timeAgo,
                        messageCount: conv.messages.length,
                        isDark: c.isDark,
                        cardColor: c.cardColor,
                        borderColor: c.borderColor,
                        textPrimary: c.textPrimary,
                        textSecondary: c.textSecondary,
                        onTap: () => _openConversation(context, ref, conv),
                        onDelete: () async {
                          await ConversationStore.instance.delete(conv.id);
                          _refresh();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _openConversation(
    BuildContext context,
    WidgetRef ref,
    Conversation conv,
  ) {
    final roles = ref.read(rolesProvider);
    final role = roles.where((r) => r.id == conv.roleId).firstOrNull;
    if (role == null) return;

    ref.read(activeRoleProvider.notifier).state = role;
    ref.read(conversationsProvider.notifier).addConversation(conv);

    context.pushNamed('chat', extra: (role, conv));
  }

  Future<void> _confirmClearAll(BuildContext context, bool isDark) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all history?'),
        content: const Text(
          'This permanently deletes all conversations for this role. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('CLEAR'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ConversationStore.instance.deleteByRole(widget.roleId);
      _refresh();
    }
  }

  String _timeAgo(DateTime dt, {required DateTime now}) {
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.month}/${dt.day}';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isDark, required this.role});

  final bool isDark;
  final dynamic role;

  @override
  Widget build(BuildContext context) {
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: textSecondary),
            const SizedBox(height: 16),
            Text(
              'NO CONVERSATIONS',
              style: AppTypography.headlineSmall(textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Start a new chat and it will appear here.',
              style: AppTypography.bodyMedium(textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (role != null) {
                  context.pushNamed('chat', extra: (role, null));
                }
              },
              child: const Text('NEW CHAT'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.title,
    required this.preview,
    required this.timeAgo,
    required this.messageCount,
    required this.isDark,
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
    required this.onDelete,
  });

  final String title;
  final String preview;
  final String timeAgo;
  final int messageCount;
  final bool isDark;
  final Color cardColor;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelMedium(textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preview,
                    style: AppTypography.bodySmall(textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$messageCount messages · $timeAgo',
                    style: AppTypography.labelSmall(
                      isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, size: 20, color: textSecondary),
              tooltip: 'Delete conversation',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
