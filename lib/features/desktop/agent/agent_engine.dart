import 'dart:async';
import 'package:flutter/foundation.dart';
import 'agent_tool.dart';
import 'permission_manager.dart';

enum AgentState {
  idle,
  thinking,
  executingTool,
  waitingForPermission,
  streaming,
  error,
}

class AgentExecution {
  final String id;
  final String input;
  final List<AgentStep> steps;
  final DateTime startTime;
  DateTime? endTime;
  bool isComplete;

  AgentExecution({
    required this.id,
    required this.input,
    List<AgentStep>? steps,
    DateTime? startTime,
    this.endTime,
    this.isComplete = false,
  })  : steps = steps ?? [],
        startTime = startTime ?? DateTime.now();
}

class AgentStep {
  final String toolId;
  final Map<String, dynamic> parameters;
  ToolResult? result;
  final DateTime timestamp;
  Duration? duration;

  AgentStep({
    required this.toolId,
    required this.parameters,
    this.result,
    DateTime? timestamp,
    this.duration,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AgentEngine extends ChangeNotifier {
  final ToolRegistry _registry;
  final PermissionManager _permissionManager;

  AgentState _state = AgentState.idle;
  AgentState get state => _state;

  AgentExecution? _currentExecution;
  AgentExecution? get currentExecution => _currentExecution;

  final List<AgentExecution> _history = [];
  List<AgentExecution> get history => List.unmodifiable(_history);

  AgentEngine({
    required ToolRegistry registry,
    required PermissionManager permissionManager,
  })  : _registry = registry,
        _permissionManager = permissionManager;

  Future<AgentExecution> execute(String input, {String? systemPrompt}) async {
    final execution = AgentExecution(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      input: input,
    );

    _currentExecution = execution;
    _state = AgentState.thinking;
    notifyListeners();

    try {
      final steps = _planSteps(input, systemPrompt);

      for (final step in steps) {
        execution.steps.add(step);
        notifyListeners();

        final tool = _registry.get(step.toolId);
        if (tool == null) {
          step.result = ToolResult.failure(
            'Tool not found',
            'Tool "${step.toolId}" is not registered',
          );
          continue;
        }

        if (tool.permissionLevel.index > PermissionLevel.read.index) {
          final request = PermissionRequest(
            toolId: tool.id,
            toolName: tool.name,
            description: tool.description,
            level: tool.permissionLevel,
            parameters: step.parameters,
          );

          _state = AgentState.waitingForPermission;
          notifyListeners();

          final decision = await _permissionManager.requestPermission(request);

          if (decision.action == PermissionAction.deny) {
            step.result = ToolResult.failure(
              'Permission denied',
              'User denied permission for ${tool.name}',
            );
            continue;
          }
        }

        _state = AgentState.executingTool;
        notifyListeners();

        final stopwatch = Stopwatch()..start();
        final result = await tool.execute(step.parameters, _createContext());
        stopwatch.stop();

        step.result = result;
        step.duration = stopwatch.elapsed;
        notifyListeners();
      }

      execution.endTime = DateTime.now();
      execution.isComplete = true;
      _history.add(execution);

      _state = AgentState.idle;
      notifyListeners();

      return execution;
    } catch (e) {
      _state = AgentState.error;
      notifyListeners();
      rethrow;
    }
  }

  List<AgentStep> _planSteps(String input, String? systemPrompt) {
    final steps = <AgentStep>[];

    if (input.toLowerCase().contains('read') || input.toLowerCase().contains('show')) {
      steps.add(AgentStep(
        toolId: 'read_file',
        parameters: {'path': _extractPath(input)},
      ));
    } else if (input.toLowerCase().contains('write') || input.toLowerCase().contains('create')) {
      steps.add(AgentStep(
        toolId: 'write_file',
        parameters: {
          'path': _extractPath(input),
          'content': _extractContent(input),
        },
      ));
    } else if (input.toLowerCase().contains('edit') || input.toLowerCase().contains('change')) {
      steps.add(AgentStep(
        toolId: 'edit_file',
        parameters: {
          'path': _extractPath(input),
          'oldString': '',
          'newString': '',
        },
      ));
    } else if (input.toLowerCase().contains('run') || input.toLowerCase().contains('execute')) {
      steps.add(AgentStep(
        toolId: 'shell',
        parameters: {'command': _extractCommand(input)},
      ));
    } else if (input.toLowerCase().contains('search') || input.toLowerCase().contains('find')) {
      steps.add(AgentStep(
        toolId: 'search_files',
        parameters: {'pattern': _extractPattern(input)},
      ));
    } else {
      steps.add(AgentStep(
        toolId: 'list_directory',
        parameters: {'path': '.'},
      ));
    }

    return steps;
  }

  String _extractPath(String input) {
    final words = input.split(' ');
    for (var i = 0; i < words.length; i++) {
      if (words[i] == 'file' || words[i] == 'path') {
        if (i + 1 < words.length) return words[i + 1];
      }
    }
    return '.';
  }

  String _extractContent(String input) {
    final start = input.indexOf('"');
    final end = input.lastIndexOf('"');
    if (start != -1 && end > start) {
      return input.substring(start + 1, end);
    }
    return '';
  }

  String _extractCommand(String input) {
    final words = input.split(' ');
    final startIdx = words.indexOf('run');
    if (startIdx == -1) return input;
    return words.sublist(startIdx + 1).join(' ');
  }

  String _extractPattern(String input) {
    final words = input.split(' ');
    for (var i = 0; i < words.length; i++) {
      if (words[i] == 'pattern' || words[i] == 'for') {
        if (i + 1 < words.length) return words[i + 1];
      }
    }
    return '*';
  }

  ToolContext _createContext() {
    return const ToolContext(
      workingDirectory: '.',
      sessionId: 'current',
    );
  }

  List<AgentTool> get availableTools => _registry.all;
}
