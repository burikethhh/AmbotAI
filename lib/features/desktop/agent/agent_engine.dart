import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/ai/ai_engine.dart';
import '../../../core/ai/engines/llama_engine.dart';
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
  String? finalAnswer;

  AgentExecution({
    required this.id,
    required this.input,
    List<AgentStep>? steps,
    DateTime? startTime,
    this.endTime,
    this.isComplete = false,
    this.finalAnswer,
  })  : steps = steps ?? [],
        startTime = startTime ?? DateTime.now();
}

class AgentStep {
  final String toolId;
  final Map<String, dynamic> parameters;
  ToolResult? result;
  final DateTime timestamp;
  Duration? duration;
  String? thinking;

  AgentStep({
    required this.toolId,
    required this.parameters,
    this.result,
    DateTime? timestamp,
    this.duration,
    this.thinking,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AgentEngine extends ChangeNotifier {
  final ToolRegistry _registry;
  final PermissionManager _permissionManager;
  LlamaEngine? _llm;

  AgentState _state = AgentState.idle;
  AgentState get state => _state;

  AgentExecution? _currentExecution;
  AgentExecution? get currentExecution => _currentExecution;

  final List<AgentExecution> _history = [];
  List<AgentExecution> get history => List.unmodifiable(_history);

  static const int _maxIterations = 10;

  AgentEngine({
    required ToolRegistry registry,
    required PermissionManager permissionManager,
    LlamaEngine? llm,
  })  : _registry = registry,
        _permissionManager = permissionManager,
        _llm = llm;

  void setLlm(LlamaEngine? engine) {
    _llm = engine;
  }

  bool get hasLlm => _llm != null && _llm!.isReady;

  String _buildSystemPrompt() {
    final toolDescriptions = _registry.all.map((tool) {
      final schemaStr = jsonEncode(tool.schema);
      return '- ${tool.id}: ${tool.description}\n  Permission: ${tool.permissionLevel.name}\n  Schema: $schemaStr';
    }).join('\n\n');

    return '''You are an AI coding agent. You have access to tools that can read, write, edit files, run shell commands, and search code.

AVAILABLE TOOLS:
$toolDescriptions

RESPONSE FORMAT:
When you need to use a tool, respond with EXACTLY this JSON format on a single line:
{"thinking": "brief explanation of what you're doing", "tool": "tool_id", "params": {"param1": "value1"}}

When you have completed the task and have a final answer for the user, respond with:
{"answer": "your response to the user"}

RULES:
- Think step by step before each tool call
- One tool call per response
- Always explain your thinking briefly
- If the task is simple and needs no tools, respond with {"answer": "your response"}
- Read files before modifying them
- Verify changes after writing files''';
  }

  String _buildToolCallPrompt(String userMessage, List<AgentStep> previousSteps) {
    final buffer = StringBuffer();
    buffer.writeln('USER REQUEST: $userMessage');
    buffer.writeln();

    if (previousSteps.isNotEmpty) {
      buffer.writeln('PREVIOUS STEPS:');
      for (final step in previousSteps) {
        buffer.writeln('- Called ${step.toolId}(${jsonEncode(step.parameters)})');
        if (step.result != null) {
          final truncated = step.result!.content.length > 500
              ? '${step.result!.content.substring(0, 500)}...'
              : step.result!.content;
          buffer.writeln('  Result: ${step.result!.success ? "SUCCESS" : "FAILURE"} - $truncated');
        }
        buffer.writeln();
      }
      buffer.writeln('What should I do next? Respond with the next tool call or final answer.');
    }

    return buffer.toString();
  }

  _ParsedResponse? _parseLlmResponse(String response) {
    final trimmed = response.trim();

    // Find JSON object in the response
    final jsonStart = trimmed.indexOf('{');
    final jsonEnd = trimmed.lastIndexOf('}');
    if (jsonStart == -1 || jsonEnd == -1 || jsonEnd <= jsonStart) return null;

    final jsonStr = trimmed.substring(jsonStart, jsonEnd + 1);

    try {
      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

      if (parsed.containsKey('answer')) {
        return _ParsedResponse(
          type: _ResponseType.answer,
          answer: parsed['answer'] as String,
        );
      }

      if (parsed.containsKey('tool')) {
        return _ParsedResponse(
          type: _ResponseType.toolCall,
          toolId: parsed['tool'] as String,
          params: (parsed['params'] as Map<String, dynamic>?) ?? {},
          thinking: parsed['thinking'] as String?,
        );
      }
    } catch (_) {
      // JSON parse failed
    }

    // Fallback: treat entire response as answer
    return _ParsedResponse(
      type: _ResponseType.answer,
      answer: trimmed,
    );
  }

  Future<AgentExecution> execute(String input, {String? systemPrompt}) async {
    final execution = AgentExecution(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      input: input,
    );

    _currentExecution = execution;
    _state = AgentState.thinking;
    notifyListeners();

    try {
      if (!hasLlm) {
        // Fallback: keyword-based planning (no LLM available)
        return _executeWithoutLlm(execution, input);
      }

      final messages = <Map<String, String>>[];
      final sysPrompt = systemPrompt ?? _buildSystemPrompt();

      for (var i = 0; i < _maxIterations; i++) {
        final prompt = _buildToolCallPrompt(input, execution.steps);

        _state = AgentState.streaming;
        notifyListeners();

        final response = await _llm!.generate(
          prompt,
          systemPrompt: sysPrompt,
          history: messages.map((m) => MessageEntry(
            role: m['role'] ?? '',
            content: m['content'] ?? '',
          )).toList(),
        );

        messages.add({'role': 'user', 'content': prompt});
        messages.add({'role': 'assistant', 'content': response});

        final parsed = _parseLlmResponse(response);

        if (parsed == null || parsed.type == _ResponseType.answer) {
          execution.finalAnswer = parsed?.answer ?? response;
          execution.endTime = DateTime.now();
          execution.isComplete = true;
          _history.add(execution);
          _state = AgentState.idle;
          notifyListeners();
          return execution;
        }

        // Tool call
        final toolId = parsed.toolId ?? '';
        final tool = _registry.get(toolId);
        if (tool == null) {
          execution.steps.add(AgentStep(
            toolId: toolId,
            parameters: parsed.params,
            result: ToolResult.failure('Tool not found', 'Tool "$toolId" is not registered'),
            thinking: parsed.thinking,
          ));
          messages.add({'role': 'user', 'content': 'Tool "$toolId" not found. Available tools: ${_registry.all.map((t) => t.id).join(', ')}'});
          continue;
        }

        // Permission check
        if (tool.permissionLevel.index > PermissionLevel.read.index) {
          final request = PermissionRequest(
            toolId: tool.id,
            toolName: tool.name,
            description: tool.description,
            level: tool.permissionLevel,
            parameters: parsed.params,
          );

          _state = AgentState.waitingForPermission;
          notifyListeners();

          final decision = await _permissionManager.requestPermission(request);

          if (decision.action == PermissionAction.deny) {
            final step = AgentStep(
              toolId: toolId,
              parameters: parsed.params,
              result: ToolResult.failure('Permission denied', 'User denied permission for ${tool.name}'),
              thinking: parsed.thinking,
            );
            execution.steps.add(step);
            messages.add({'role': 'user', 'content': 'Permission denied for ${tool.name}. Try a different approach.'});
            continue;
          }
        }

        _state = AgentState.executingTool;
        notifyListeners();

        final step = AgentStep(
          toolId: toolId,
          parameters: parsed.params,
          thinking: parsed.thinking,
        );
        execution.steps.add(step);
        notifyListeners();

        final stopwatch = Stopwatch()..start();
        final result = await tool.execute(parsed.params, _createContext());
        stopwatch.stop();

        step.result = result;
        step.duration = stopwatch.elapsed;
        notifyListeners();

        // Feed result back to LLM
        final resultMsg = 'Tool ${tool.id} result: ${result.success ? "SUCCESS" : "FAILURE"}\n${result.title}\n${result.content}';
        messages.add({'role': 'user', 'content': resultMsg});
      }

      // Max iterations reached
      execution.finalAnswer = 'Reached maximum tool call iterations. Here is what I accomplished:\n\n'
          '${execution.steps.map((s) => '- ${s.toolId}: ${s.result?.title ?? "pending"}').join('\n')}';
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

  Future<AgentExecution> _executeWithoutLlm(AgentExecution execution, String input) async {
    final steps = _planStepsWithoutLlm(input);

    for (final step in steps) {
      execution.steps.add(step);
      notifyListeners();

      final tool = _registry.get(step.toolId);
      if (tool == null) {
        step.result = ToolResult.failure('Tool not found', 'Tool "${step.toolId}" is not registered');
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
          step.result = ToolResult.failure('Permission denied', 'User denied permission for ${tool.name}');
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

    execution.finalAnswer = steps.map((s) {
      if (s.result != null && s.result!.success) {
        return '${s.result!.title}\n${s.result!.content}';
      }
      return '${s.toolId}: ${s.result?.title ?? "No result"}';
    }).join('\n\n');

    execution.endTime = DateTime.now();
    execution.isComplete = true;
    _history.add(execution);
    _state = AgentState.idle;
    notifyListeners();
    return execution;
  }

  List<AgentStep> _planStepsWithoutLlm(String input) {
    final steps = <AgentStep>[];
    final lower = input.toLowerCase();

    if (lower.contains('read') || lower.contains('show') || lower.contains('open')) {
      steps.add(AgentStep(
        toolId: 'read_file',
        parameters: {'path': _extractPath(input)},
      ));
    } else if (lower.contains('write') || lower.contains('create')) {
      steps.add(AgentStep(
        toolId: 'write_file',
        parameters: {
          'path': _extractPath(input),
          'content': _extractContent(input),
        },
      ));
    } else if (lower.contains('edit') || lower.contains('change') || lower.contains('modify')) {
      steps.add(AgentStep(
        toolId: 'edit_file',
        parameters: {
          'path': _extractPath(input),
          'oldString': '',
          'newString': '',
        },
      ));
    } else if (lower.contains('run') || lower.contains('execute')) {
      steps.add(AgentStep(
        toolId: 'shell',
        parameters: {'command': _extractCommand(input)},
      ));
    } else if (lower.contains('search') || lower.contains('find') || lower.contains('grep')) {
      steps.add(AgentStep(
        toolId: 'grep',
        parameters: {'pattern': _extractPattern(input)},
      ));
    } else if (lower.contains('list') || lower.contains('directory') || lower.contains('files')) {
      steps.add(AgentStep(
        toolId: 'list_directory',
        parameters: {'path': _extractPath(input)},
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
      if (words[i] == 'file' || words[i] == 'path' || words[i] == 'to') {
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
    if (startIdx == -1) {
      final execIdx = words.indexOf('execute');
      if (execIdx == -1) return input;
      return words.sublist(execIdx + 1).join(' ');
    }
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

enum _ResponseType { toolCall, answer }

class _ParsedResponse {
  final _ResponseType type;
  final String? toolId;
  final Map<String, dynamic> params;
  final String? thinking;
  final String? answer;

  _ParsedResponse({
    required this.type,
    this.toolId,
    this.params = const {},
    this.thinking,
    this.answer,
  });
}
