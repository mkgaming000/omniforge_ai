// Orchestrator State
import 'package:equatable/equatable.dart';

import '../../../domain/entities/orchestrator/orchestrator_entities.dart';

enum OrchestratorStatus { initial, running, completed, failed, cancelled }

class OrchestratorState extends Equatable {
  const OrchestratorState({
    this.status = OrchestratorStatus.initial,
    this.userRequest,
    this.progress = const [],
    this.currentStep,
    this.currentAgent,
    this.currentMessage,
    this.overallProgress = 0.0,
    this.deliverable,
    this.error,
    this.startedAt,
    this.completedAt,
  });

  const OrchestratorState.initial() : this();

  final OrchestratorStatus status;
  final String? userRequest;
  final List<OrchestratorProgress> progress;
  final OrchestratorStep? currentStep;
  final OrchestratorAgent? currentAgent;
  final String? currentMessage;
  final double overallProgress;
  final OrchestratorDeliverable? deliverable;
  final String? error;
  final DateTime? startedAt;
  final DateTime? completedAt;

  bool get isRunning => status == OrchestratorStatus.running;
  bool get isComplete => status == OrchestratorStatus.completed;
  bool get isFailed => status == OrchestratorStatus.failed;

  Duration? get duration => startedAt != null && completedAt != null
      ? completedAt!.difference(startedAt!)
      : null;

  OrchestratorState copyWith({
    OrchestratorStatus? status,
    String? userRequest,
    List<OrchestratorProgress>? progress,
    OrchestratorStep? currentStep,
    OrchestratorAgent? currentAgent,
    String? currentMessage,
    double? overallProgress,
    OrchestratorDeliverable? deliverable,
    String? error,
    DateTime? startedAt,
    DateTime? completedAt,
  }) =>
      OrchestratorState(
        status: status ?? this.status,
        userRequest: userRequest ?? this.userRequest,
        progress: progress ?? this.progress,
        currentStep: currentStep ?? this.currentStep,
        currentAgent: currentAgent ?? this.currentAgent,
        currentMessage: currentMessage,
        overallProgress: overallProgress ?? this.overallProgress,
        deliverable: deliverable ?? this.deliverable,
        error: error,
        startedAt: startedAt ?? this.startedAt,
        completedAt: completedAt ?? this.completedAt,
      );

  @override
  List<Object?> get props => [
        status,
        userRequest,
        progress,
        currentStep,
        currentAgent,
        currentMessage,
        overallProgress,
        deliverable,
        error,
        startedAt,
        completedAt,
      ];
}
