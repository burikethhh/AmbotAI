import 'dart:async';
import '../ai/ai_engine.dart';

enum AgentState { idle, planning, executing, observing, paused, stopped }

class AgentStep {
  final String id;
  final String description;
  final String action;
  final String? result;
  final DateTime startedAt;
  final DateTime? completedAt;
  final bool success;

  AgentStep({
    required this.id,
    required this.description,
    required this.action,
    this.result,
    required this.startedAt,
    this.completedAt,
    this.success = true,
  });

  AgentStep copyWith({
    String? action,
    String? result,
    DateTime? completedAt,
    bool? success,
  }) {
    return AgentStep(
      id: id,
      description: description,
      action: action ?? this.action,
      result: result ?? this.result,
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
      success: success ?? this.success,
    );
  }
}

class AgentEvent {
  final AgentEventType type;
  final String message;
  final AgentStep? step;

  const AgentEvent({
    required this.type,
    required this.message,
    this.step,
  });
}

enum AgentEventType {
  stateChanged,
  stepStarted,
  stepCompleted,
  stepFailed,
  planGenerated,
  error,
  finished,
}

class AutonomousAgent {
  final AIEngine engine;
  final String roleId;
  final String systemPrompt;
  final Function(String action) onExecuteAction;

  AgentState _state = AgentState.idle;
  AgentState get state => _state;

  String _goal = '';
  List<String> _plan = [];
  final List<AgentStep> _steps = [];
  int _currentStepIndex = 0;

  final _eventController = StreamController<AgentEvent>.broadcast();
  Stream<AgentEvent> get events => _eventController.stream;

  Timer? _timeoutTimer;
  bool _isRunning = false;

  AutonomousAgent({
    required this.engine,
    required this.roleId,
    required this.systemPrompt,
    required this.onExecuteAction,
  });

  Future<void> start(String goal, {Duration? timeout}) async {
    if (_isRunning) return;
    _isRunning = true;
    _goal = goal;
    _plan = [];
    _steps.clear();
    _currentStepIndex = 0;

    _setState(AgentState.planning);
    _emitEvent(AgentEventType.stateChanged, 'Starting autonomous task...');

    if (timeout != null) {
      _timeoutTimer = Timer(timeout, () {
        if (_isRunning) stop();
      });
    }

    try {
      await _generatePlan();
      if (!_isRunning) return;

      _setState(AgentState.executing);

      for (int i = 0; i < _plan.length && _isRunning; i++) {
        _currentStepIndex = i;
        await _executeStep(_plan[i], i);
      }

      if (_isRunning) {
        _setState(AgentState.idle);
        _emitEvent(AgentEventType.finished, 'Task completed successfully');
      }
    } catch (e) {
      _emitEvent(AgentEventType.error, 'Agent error: $e');
      _setState(AgentState.idle);
    } finally {
      _isRunning = false;
      _timeoutTimer?.cancel();
    }
  }

  void pause() {
    if (!_isRunning) return;
    _isRunning = false;
    _setState(AgentState.paused);
    _emitEvent(AgentEventType.stateChanged, 'Agent paused');
  }

  Future<void> resume() async {
    if (_state != AgentState.paused) return;
    _isRunning = true;
    _setState(AgentState.executing);
    _emitEvent(AgentEventType.stateChanged, 'Agent resumed');

    for (int i = _currentStepIndex; i < _plan.length && _isRunning; i++) {
      _currentStepIndex = i;
      await _executeStep(_plan[i], i);
    }

    if (_isRunning) {
      _setState(AgentState.idle);
      _emitEvent(AgentEventType.finished, 'Task completed');
    }
    _isRunning = false;
  }

  void stop() {
    _isRunning = false;
    _setState(AgentState.stopped);
    _emitEvent(AgentEventType.stateChanged, 'Agent stopped');
    _timeoutTimer?.cancel();
  }

  List<AgentStep> get steps => List.unmodifiable(_steps);
  String get goal => _goal;
  List<String> get plan => List.unmodifiable(_plan);

  Future<void> _generatePlan() async {
    _emitEvent(AgentEventType.stateChanged, 'Generating plan...');

    final planPrompt = '''
$systemPrompt

You are an autonomous AI agent. Given the following goal, create a step-by-step plan.
Respond with ONLY a numbered list of steps, one per line, in this format:
1. [First step]
2. [Second step]
3. [Third step]

Goal: $_goal

Keep steps concise and actionable. Maximum 10 steps.''';

    final response = await engine.generate(planPrompt);
    _plan = response
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && RegExp(r'^\d+\.').hasMatch(s))
        .map((s) => s.replaceFirst(RegExp(r'^\d+\.\s*'), ''))
        .toList();

    if (_plan.isEmpty) {
      _plan = [_goal];
    }

    _emitEvent(AgentEventType.planGenerated, 'Plan: ${_plan.length} steps',
        step: null);
  }

  Future<void> _executeStep(String stepDescription, int index) async {
    if (!_isRunning) return;

    final step = AgentStep(
      id: 'step_$index',
      description: stepDescription,
      action: '',
      startedAt: DateTime.now(),
    );
    _steps.add(step);

    _emitEvent(AgentEventType.stepStarted, 'Step ${index + 1}: $stepDescription',
        step: step);

    try {
      final actionPrompt = '''
$systemPrompt

You are executing step ${index + 1} of your plan: "$stepDescription"
Goal: $_goal

What specific action should be taken? Respond with a concise action description.
Context from previous steps:
${_getPreviousContext()}''';

      final action = await engine.generate(actionPrompt);

      final updatedStep = step.copyWith(action: action);
      _steps[_steps.length - 1] = updatedStep;

      onExecuteAction(action);

      final observePrompt = '''
$systemPrompt

You executed: "$action"
Step: "$stepDescription"
Goal: $_goal

What was the result? Summarize the outcome in 1-2 sentences.''';

      final result = await engine.generate(observePrompt);

      final completedStep = updatedStep.copyWith(
        result: result,
        completedAt: DateTime.now(),
        success: true,
      );
      _steps[_steps.length - 1] = completedStep;

      _emitEvent(
          AgentEventType.stepCompleted, 'Step ${index + 1} completed',
          step: completedStep);
    } catch (e) {
      final failedStep = step.copyWith(
        result: 'Error: $e',
        completedAt: DateTime.now(),
        success: false,
      );
      if (_steps.isNotEmpty) {
        _steps[_steps.length - 1] = failedStep;
      }
      _emitEvent(AgentEventType.stepFailed, 'Step ${index + 1} failed: $e',
          step: failedStep);
    }
  }

  String _getPreviousContext() {
    if (_steps.isEmpty) return 'No previous steps.';
    return _steps
        .map((s) => '- ${s.description}: ${s.result ?? 'In progress'}')
        .join('\n');
  }

  void _setState(AgentState newState) {
    _state = newState;
  }

  void _emitEvent(AgentEventType type, String message, {AgentStep? step}) {
    if (!_eventController.isClosed) {
      _eventController.add(AgentEvent(type: type, message: message, step: step));
    }
  }

  void dispose() {
    stop();
    _eventController.close();
    _timeoutTimer?.cancel();
  }
}
