// Agent Events
import 'package:equatable/equatable.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/entities/agent_entity.dart';

abstract class AgentEvent extends Equatable {
  const AgentEvent();
}

class LoadAgents extends AgentEvent {
  const LoadAgents();
  @override
  List<Object?> get props => [];
}

class CreateAgent extends AgentEvent {
  const CreateAgent(this.agent);
  final AgentEntity agent;
  @override
  List<Object?> get props => [agent];
}

class DeleteAgent extends AgentEvent {
  const DeleteAgent(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

class RunAgent extends AgentEvent {
  const RunAgent({required this.agent, required this.input});
  final AgentEntity agent;
  final String input;
  @override
  List<Object?> get props => [agent, input];
}

class CancelAgentRun extends AgentEvent {
  const CancelAgentRun();
  @override
  List<Object?> get props => [];
}

/// Internal: emitted by the bloc itself when the runtime stream produces
/// a new step. Kept public (not prefixed with `_`) so the event can be
/// imported as a library member.
class AgentStepReceived extends AgentEvent {
  const AgentStepReceived(this.step);
  final AgentStep step;
  @override
  List<Object?> get props => [step];
}

class AgentRunCompleted extends AgentEvent {
  const AgentRunCompleted();
  @override
  List<Object?> get props => [];
}

class AgentRunFailed extends AgentEvent {
  const AgentRunFailed(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
