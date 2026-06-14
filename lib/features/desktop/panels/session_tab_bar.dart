import 'package:flutter/material.dart';

class AgentSession {
  final String id;
  String title;
  String agentType;
  DateTime createdAt;
  DateTime lastActive;
  bool isDirty;
  String modelId;
  Map<String, dynamic> metadata;

  AgentSession({
    required this.id,
    required this.title,
    this.agentType = 'build',
    DateTime? createdAt,
    DateTime? lastActive,
    this.isDirty = false,
    this.modelId = 'local',
    Map<String, dynamic>? metadata,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastActive = lastActive ?? DateTime.now(),
        metadata = metadata ?? {};
}

class SessionTabBar extends StatelessWidget {
  final List<AgentSession> sessions;
  final int activeIndex;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onClose;
  final VoidCallback onNewSession;

  const SessionTabBar({
    super.key,
    required this.sessions,
    required this.activeIndex,
    required this.onSelect,
    required this.onClose,
    required this.onNewSession,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          _buildNewTabButton(context),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: sessions.length,
              itemBuilder: (context, i) => _buildTab(context, i),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewTabButton(BuildContext context) {
    return GestureDetector(
      onTap: onNewSession,
      child: Container(
        width: 36,
        height: 36,
        color: Colors.transparent,
        child: Icon(
          Icons.add,
          size: 16,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
    );
  }

  Widget _buildTab(BuildContext context, int index) {
    final session = sessions[index];
    final isActive = index == activeIndex;
    final accent = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: () => onSelect(index),
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.surface
              : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
          border: Border(
            right: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
            ),
            bottom: BorderSide(
              color: isActive ? accent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(
              _agentIcon(session.agentType),
              size: 12,
              color: isActive ? accent : Theme.of(context).textTheme.bodySmall?.color,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                session.title,
                style: TextStyle(
                  fontSize: 12,
                  color: isActive ? accent : Theme.of(context).textTheme.bodySmall?.color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (session.isDirty)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  shape: BoxShape.circle,
                ),
              ),
            GestureDetector(
              onTap: () => onClose(index),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  size: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _agentIcon(String type) {
    switch (type) {
      case 'build':
        return Icons.build;
      case 'plan':
        return Icons.lightbulb_outline;
      case 'refactor':
        return Icons.auto_fix_high;
      case 'debug':
        return Icons.bug_report;
      case 'document':
        return Icons.description;
      default:
        return Icons.smart_toy;
    }
  }
}
