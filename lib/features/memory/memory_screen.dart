import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/memory/memory_entry.dart';
import '../../core/providers/app_providers.dart';
import '../../core/roles/role_domain.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/theme/theme_colors.dart';

/// View, pin, and delete long-term memories.
///
/// Shows every [MemoryEntry] grouped by scope, with quick actions to
/// pin/unpin, delete, and wipe per-scope. All operations run locally on
/// device; nothing ever leaves the phone.
class MemoryScreen extends ConsumerStatefulWidget {
  const MemoryScreen({super.key});

  @override
  ConsumerState<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends ConsumerState<MemoryScreen> {
  int _refreshTick = 0;

  void _refresh() => setState(() => _refreshTick++);

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(themeColorsProvider);
    final enabled = ref.watch(memoryEnabledProvider);
    final service = ref.watch(memoryServiceProvider);

    // _refreshTick is read to force a rebuild after mutations.
    final _ = _refreshTick;
    final entries = service.all();
    entries.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'MEMORY',
          style: AppTypography.headlineSmall(c.textPrimary),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_sweep_outlined, color: c.textSecondary),
            tooltip: 'Wipe all memories',
            onPressed: entries.isEmpty
                ? null
                : () => _confirmWipe(context, c.isDark),
          ),
        ],
      ),
      body: Column(
        children: [
          Divider(color: c.borderColor, thickness: 2, height: 2),
          _EnabledToggle(
            enabled: enabled,
            isDark: c.isDark,
            onChanged: (v) =>
                ref.read(memoryEnabledProvider.notifier).setEnabled(v),
          ),
          Expanded(
            child: !enabled
                ? _MessageState(
                    isDark: c.isDark,
                    title: 'MEMORY DISABLED',
                    subtitle:
                        'Turn memory on to let Ambot remember facts across chats. Nothing leaves your device.',
                  )
                : entries.isEmpty
                    ? _MessageState(
                        isDark: c.isDark,
                        title: 'NO MEMORIES YET',
                        subtitle:
                            'Ambot will remember durable facts you share, like your name, goals, and preferences.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: entries.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return _MemoryTile(
                            entry: entry,
                            isDark: c.isDark,
                            cardColor: c.cardColor,
                            borderColor: c.borderColor,
                            textPrimary: c.textPrimary,
                            textSecondary: c.textSecondary,
                            onTogglePin: () async {
                              await service.update(entry.copyWith(
                                pinned: !entry.pinned,
                              ));
                              _refresh();
                            },
                            onDelete: () async {
                              await service.delete(entry.id);
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

  Future<void> _confirmWipe(BuildContext context, bool isDark) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Wipe all memories?'),
        content: const Text(
          'This permanently deletes every remembered fact. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('WIPE'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(memoryServiceProvider).wipeAll();
      _refresh();
    }
  }
}

class _EnabledToggle extends StatelessWidget {
  const _EnabledToggle({
    required this.enabled,
    required this.isDark,
    required this.onChanged,
  });

  final bool enabled;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PERSISTENT MEMORY',
                  style: AppTypography.labelMedium(textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  'Stored on this device only',
                  style: AppTypography.labelSmall(textSecondary),
                ),
              ],
            ),
          ),
          Switch(value: enabled, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _MemoryTile extends StatelessWidget {
  const _MemoryTile({
    required this.entry,
    required this.isDark,
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTogglePin,
    required this.onDelete,
  });

  final MemoryEntry entry;
  final bool isDark;
  final Color cardColor;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTogglePin;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.key.toUpperCase(),
                  style: AppTypography.labelSmall(textSecondary),
                ),
              ),
              _ScopeChip(scope: entry.scope, textSecondary: textSecondary),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            entry.value,
            style: AppTypography.bodyMedium(textPrimary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                entry.pinned
                    ? Icons.push_pin
                    : Icons.push_pin_outlined,
                size: 18,
                color: textSecondary,
              ),
              const SizedBox(width: 4),
              TextButton(
                onPressed: onTogglePin,
                child: Text(entry.pinned ? 'UNPIN' : 'PIN'),
              ),
              const Spacer(),
              TextButton(
                onPressed: onDelete,
                child: const Text('DELETE'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({required this.scope, required this.textSecondary});

  final MemoryScope scope;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: textSecondary.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        scope.label.toUpperCase(),
        style: AppTypography.labelSmall(textSecondary),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.isDark,
    required this.title,
    required this.subtitle,
  });

  final bool isDark;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.memory_outlined, size: 48, color: textSecondary),
            const SizedBox(height: 16),
            Text(
              title,
          style: AppTypography.headlineSmall(textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTypography.bodyMedium(textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
