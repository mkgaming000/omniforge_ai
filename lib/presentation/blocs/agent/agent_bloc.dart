// Agent Bloc - manages agent creation, listing, execution
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/agent_repository.dart';
import '../../../data/services/agent/agent_runtime.dart';
import 'agent_event.dart';
import 'agent_state.dart';

class AgentBloc extends Bloc<AgentEvent, AgentState> {
  AgentBloc({
    required this.repository,
    required this.runtime,
  }) : super(const AgentState.initial()) {
    on<LoadAgents>(_onLoad);
    on<CreateAgent>(_onCreate);
    on<DeleteAgent>(_onDelete);
    on<RunAgent>(_onRun);
    on<CancelAgentRun>(_onCancel);
    on<AgentStepReceived>(_onStepReceived);
    on<AgentRunCompleted>(_onRunCompleted);
    on<AgentRunFailed>(_onRunFailed);
  }

  final AgentRepository repository;
  final AgentRuntime runtime;
  StreamSubscription<dynamic>? _runSubscription;

  Future<void> _onLoad(LoadAgents event, Emitter<AgentState> emit) async {
    emit(state.copyWith(status: AgentStatus.loading));
    final result = await repository.getAll();
    result.fold(
      (f) => emit(
        state.copyWith(
          status: AgentStatus.error,
          error: f.userMessage,
        ),
      ),
      (agents) => emit(
        state.copyWith(
          status: AgentStatus.ready,
          agents: agents,
        ),
      ),
    );
  }

  Future<void> _onCreate(CreateAgent event, Emitter<AgentState> emit) async {
    final result = await repository.create(event.agent);
    result.fold(
      (f) => emit(
        state.copyWith(
          status: AgentStatus.error,
          error: f.userMessage,
        ),
      ),
      (agent) => emit(
        state.copyWith(
          agents: [agent, ...state.agents],
        ),
      ),
    );
  }

  Future<void> _onDelete(DeleteAgent event, Emitter<AgentState> emit) async {
    final result = await repository.delete(event.id);
    result.fold(
      (f) => emit(
        state.copyWith(
          status: AgentStatus.error,
          error: f.userMessage,
        ),
      ),
      (_) => emit(
        state.copyWith(
          agents: state.agents.where((a) => a.id != event.id).toList(),
        ),
      ),
    );
  }

  Future<void> _onRun(RunAgent event, Emitter<AgentState> emit) async {
    emit(
      state.copyWith(
        status: AgentStatus.running,
        activeAgentId: event.agent.id,
        runSteps: [],
        error: null,
      ),
    );

    // Cancel any previously-active run before starting a new one so a rapid
    // second RunAgent doesn't leak the first subscription.
    await _runSubscription?.cancel();
    _runSubscription = runtime
        .run(
      agent: event.agent,
      userInput: event.input,
    )
        .listen(
      (result) {
        result.fold(
          (failure) => add(AgentRunFailed(failure)),
          (step) => add(AgentStepReceived(step)),
        );
      },
      onDone: () => add(const AgentRunCompleted()),
    );
  }

  void _onCancel(CancelAgentRun event, Emitter<AgentState> emit) {
    _runSubscription?.cancel();
    emit(state.copyWith(status: AgentStatus.ready));
  }

  void _onStepReceived(
    AgentStepReceived event,
    Emitter<AgentState> emit,
  ) {
    emit(
      state.copyWith(
        runSteps: [...state.runSteps, event.step],
      ),
    );
  }

  void _onRunCompleted(
    AgentRunCompleted event,
    Emitter<AgentState> emit,
  ) {
    emit(state.copyWith(status: AgentStatus.ready));
  }

  void _onRunFailed(
    AgentRunFailed event,
    Emitter<AgentState> emit,
  ) {
    emit(
      state.copyWith(
        status: AgentStatus.error,
        error: event.failure.userMessage,
      ),
    );
  }

  @override
  Future<void> close() {
    _runSubscription?.cancel();
    return super.close();
  }
}
