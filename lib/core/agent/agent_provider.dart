import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import 'autonomous_agent.dart';

final agentStateProvider = StateNotifierProvider<AgentStateNotifier, AgentUIState>((ref) {
  return AgentStateNotifier(ref);
});

class AgentUIState {
  final AgentState state;
  final String goal;
  final List<String> plan;
  final List<AgentStep> steps;
  final List<String> log;

  const AgentUIState({
    this.state = AgentState.idle,
    this.goal = '',
    this.plan = const [],
    this.steps = const [],
    this.log = const [],
  });

  AgentUIState copyWith({
    AgentState? state,
    String? goal,
    List<String>? plan,
    List<AgentStep>? steps,
    List<String>? log,
  }) {
    return AgentUIState(
      state: state ?? this.state,
      goal: goal ?? this.goal,
      plan: plan ?? this.plan,
      steps: steps ?? this.steps,
      log: log ?? this.log,
    );
  }
}

class AgentStateNotifier extends StateNotifier<AgentUIState> {
  final Ref ref;
  AutonomousAgent? _agent;
  StreamSubscription<AgentEvent>? _eventSub;

  AgentStateNotifier(this.ref) : super(const AgentUIState());

  Future<void> start(String goal, {Duration? timeout}) async {
    await _eventSub?.cancel();
    _agent?.dispose();

    final engine = ref.read(aiEngineProvider);
    final role = ref.read(activeRoleProvider);

    _agent = AutonomousAgent(
      engine: engine,
      roleId: role?.id ?? 'default',
      systemPrompt: role?.systemPrompt ?? 'You are a helpful AI assistant.',
      onExecuteAction: (action) {
        state = state.copyWith(
          log: [...state.log, '[ACTION] $action'],
        );
      },
    );

    state = state.copyWith(
      goal: goal,
      log: [...state.log, 'Starting: $goal'],
    );

    _eventSub = _agent!.events.listen((event) {
      final newLog = [...state.log, event.message];
      state = state.copyWith(
        state: event.type == AgentEventType.stateChanged
            ? _agent!.state
            : state.state,
        plan: event.type == AgentEventType.planGenerated
            ? _agent!.plan
            : state.plan,
        steps: _agent!.steps,
        log: newLog,
      );
    });

    await _agent!.start(goal, timeout: timeout);
  }

  void pause() {
    _agent?.pause();
  }

  Future<void> resume() async {
    await _agent?.resume();
  }

  void stop() {
    _eventSub?.cancel();
    _eventSub = null;
    _agent?.stop();
    _agent = null;
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _agent?.dispose();
    super.dispose();
  }
}
