// Orchestrator Events
import 'package:equatable/equatable.dart';

import '../../../domain/entities/orchestrator/orchestrator_entities.dart';

abstract class OrchestratorEvent extends Equatable {
  const OrchestratorEvent();
}

class OrchestratorRunRequested extends OrchestratorEvent {
  const OrchestratorRunRequested(this.request);
  final String request;
  @override
  List<Object?> get props => [request];
}

class OrchestratorCancelled extends OrchestratorEvent {
  const OrchestratorCancelled();
  @override
  List<Object?> get props => [];
}

/// Internal event emitted by the bloc when the pipeline stream produces a
/// progress update. Public (no `_` prefix) so it can be imported as a
/// library member of orchestrator_event.dart.
class OrchestratorProgressReceived extends OrchestratorEvent {
  const OrchestratorProgressReceived(this.progress);
  final OrchestratorProgress progress;
  @override
  List<Object?> get props => [progress];
}

class OrchestratorCompleted extends OrchestratorEvent {
  const OrchestratorCompleted(this.deliverable, {this.error});
  final OrchestratorDeliverable? deliverable;
  final String? error;
  @override
  List<Object?> get props => [deliverable, error];
}
