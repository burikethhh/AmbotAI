import 'dart:async';
import 'package:flutter/material.dart';
import 'agent_tool.dart';

enum PermissionAction { approve, deny, always }

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

  Completer<PermissionDecision>? _currentCompleter;

  PermissionRequest? _currentRequest;
  PermissionRequest? get currentRequest => _currentRequest;

  bool get hasPendingRequest => _currentRequest != null;

  Future<PermissionDecision> requestPermission(PermissionRequest request) async {
    if (_alwaysApproved.containsKey(request.toolId)) {
      return const PermissionDecision(action: PermissionAction.approve);
    }
    if (_alwaysDenied.containsKey(request.toolId)) {
      return const PermissionDecision(action: PermissionAction.deny);
    }

    _currentRequest = request;
    _pendingRequests.add(request);
    _currentCompleter = Completer<PermissionDecision>();
    notifyListeners();

    final decision = await _currentCompleter!.future;

    _pendingRequests.remove(request);
    _currentRequest = _pendingRequests.isNotEmpty ? _pendingRequests.last : null;
    _currentCompleter = null;
    notifyListeners();

    return decision;
  }

  void handleDecision(PermissionDecision decision) {
    if (_currentCompleter == null || _currentCompleter!.isCompleted) return;

    if (decision.rememberChoice && _currentRequest != null) {
      switch (decision.action) {
        case PermissionAction.approve:
        case PermissionAction.always:
          _alwaysApproved[_currentRequest!.toolId] = true;
          break;
        case PermissionAction.deny:
          _alwaysDenied[_currentRequest!.toolId] = true;
          break;
      }
    }

    _currentCompleter!.complete(decision);
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
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _formatParameters(request.parameters),
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
        FilledButton(
          onPressed: () => onDecision(const PermissionDecision(
            action: PermissionAction.always,
            rememberChoice: true,
          )),
          child: const Text('Always Allow'),
        ),
      ],
    );
  }

  String _formatParameters(Map<String, dynamic> params) {
    final buffer = StringBuffer();
    for (final entry in params.entries) {
      buffer.writeln('${entry.key}: ${entry.value}');
    }
    return buffer.toString();
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
