import 'package:flutter/material.dart';
import 'agent_tool.dart';

enum PermissionAction {
  approve,
  deny,
  always,
}

class PermissionRequest {
  final String toolId;
  final String toolName;
  final String description;
  final PermissionLevel level;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;

  PermissionRequest({
    required this.toolId,
    required this.toolName,
    required this.description,
    required this.level,
    required this.parameters,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class PermissionDecision {
  final PermissionAction action;
  final bool rememberChoice;

  const PermissionDecision({
    required this.action,
    this.rememberChoice = false,
  });
}

class PermissionManager extends ChangeNotifier {
  final Map<String, bool> _alwaysApproved = {};
  final Map<String, bool> _alwaysDenied = {};
  final List<PermissionRequest> _pendingRequests = [];

  PermissionRequest? _currentRequest;
  PermissionRequest? get currentRequest => _currentRequest;

  bool _dialogOpen = false;
  bool get dialogOpen => _dialogOpen;

  Future<PermissionDecision> requestPermission(PermissionRequest request) async {
    if (_alwaysApproved.containsKey(request.toolId)) {
      return const PermissionDecision(action: PermissionAction.approve);
    }
    if (_alwaysDenied.containsKey(request.toolId)) {
      return const PermissionDecision(action: PermissionAction.deny);
    }

    _currentRequest = request;
    _pendingRequests.add(request);
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 100));
    notifyListeners();

    return const PermissionDecision(action: PermissionAction.approve);
  }

  void handleDecision(String requestId, PermissionDecision decision) {
    switch (decision.action) {
      case PermissionAction.approve:
        if (decision.rememberChoice) {
          _alwaysApproved[requestId] = true;
        }
        break;
      case PermissionAction.deny:
        if (decision.rememberChoice) {
          _alwaysDenied[requestId] = true;
        }
        break;
      case PermissionAction.always:
        _alwaysApproved[requestId] = true;
        break;
    }

    _pendingRequests.removeWhere((r) => r.toolId == requestId);
    _currentRequest = null;
    notifyListeners();
  }

  void revokeAlways(String toolId) {
    _alwaysApproved.remove(toolId);
    _alwaysDenied.remove(toolId);
    notifyListeners();
  }

  void revokeAll() {
    _alwaysApproved.clear();
    _alwaysDenied.clear();
    notifyListeners();
  }

  List<PermissionRequest> get pendingRequests => List.unmodifiable(_pendingRequests);

  bool isAlwaysApproved(String toolId) => _alwaysApproved.containsKey(toolId);
  bool isAlwaysDenied(String toolId) => _alwaysDenied.containsKey(toolId);
}

class PermissionDialog extends StatelessWidget {
  final PermissionRequest request;
  final ValueChanged<PermissionDecision> onDecision;

  const PermissionDialog({
    super.key,
    required this.request,
    required this.onDecision,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Row(
        children: [
          Icon(
            _permissionIcon(request.level),
            color: _permissionColor(request.level),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Permission Required',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            request.toolName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            request.description,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              request.parameters.toString(),
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => onDecision(const PermissionDecision(
            action: PermissionAction.deny,
          )),
          child: const Text('Deny'),
        ),
        TextButton(
          onPressed: () => onDecision(const PermissionDecision(
            action: PermissionAction.approve,
          )),
          child: const Text('Allow'),
        ),
        TextButton(
          onPressed: () => onDecision(const PermissionDecision(
            action: PermissionAction.approve,
            rememberChoice: true,
          )),
          child: const Text('Always Allow'),
        ),
      ],
    );
  }

  IconData _permissionIcon(PermissionLevel level) {
    switch (level) {
      case PermissionLevel.none:
        return Icons.remove;
      case PermissionLevel.read:
        return Icons.visibility;
      case PermissionLevel.write:
        return Icons.edit;
      case PermissionLevel.execute:
        return Icons.terminal;
      case PermissionLevel.admin:
        return Icons.admin_panel_settings;
    }
  }

  Color _permissionColor(PermissionLevel level) {
    switch (level) {
      case PermissionLevel.none:
        return Colors.grey;
      case PermissionLevel.read:
        return Colors.blue;
      case PermissionLevel.write:
        return Colors.orange;
      case PermissionLevel.execute:
        return Colors.red;
      case PermissionLevel.admin:
        return Colors.purple;
    }
  }
}
