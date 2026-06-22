// Agent State
import 'package:equatable/equatable.dart';

import '../../../domain/entities/agent_entity.dart';

enum AgentStatus { initial, loading, ready, running, error }

class AgentState extends Equatable {
  const AgentState({
    this.status = AgentStatus.initial,
    this.agents = const [],
    this.activeAgentId,
    this.runSteps = const [],
    this.error,
  });

  const AgentState.initial() : this();

  final AgentStatus status;
  final List<AgentEntity> agents;
  final String? activeAgentId;
  final List<AgentStep> runSteps;
  final String? error;

  AgentState copyWith({
    AgentStatus? status,
    List<AgentEntity>? agents,
    String? activeAgentId,
    List<AgentStep>? runSteps,
    String? error,
  }) {
    return AgentState(
      status: status ?? this.status,
      agents: agents ?? this.agents,
      // Preserve activeAgentId when not explicitly provided, so step events
      // (which only pass runSteps) don't wipe the running agent mid-run.
      activeAgentId: activeAgentId ?? this.activeAgentId,
      runSteps: runSteps ?? this.runSteps,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        status,
        agents,
        activeAgentId,
        runSteps,
        error,
      ];
}
