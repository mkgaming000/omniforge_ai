// OrchestratorBloc - exposes the orchestrator pipeline to the UI as a
// stream of [OrchestratorProgress] + final [OrchestratorDeliverable].
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/services/orchestrator/orchestrator_pipeline.dart';
import 'orchestrator_event.dart';
import 'orchestrator_state.dart';

class OrchestratorBloc extends Bloc<OrchestratorEvent, OrchestratorState> {
  OrchestratorBloc({required this.pipeline})
      : super(const OrchestratorState.initial()) {
    on<OrchestratorRunRequested>(_onRun);
    on<OrchestratorCancelled>(_onCancel);
    on<OrchestratorProgressReceived>(_onProgress);
    on<OrchestratorCompleted>(_onCompleted);
  }

  final OrchestratorPipeline pipeline;
  StreamSubscription<dynamic>? _runSubscription;

  Future<void> _onRun(
    OrchestratorRunRequested event,
    Emitter<OrchestratorState> emit,
  ) async {
    emit(
      state.copyWith(
        status: OrchestratorStatus.running,
        userRequest: event.request,
        progress: const [],
        deliverable: null,
        error: null,
        startedAt: DateTime.now(),
      ),
    );

    unawaited(_runSubscription?.cancel());
    _runSubscription = pipeline.run(userRequest: event.request).listen(
          (progress) => add(OrchestratorProgressReceived(progress)),
          onError: (e, st) => add(
            OrchestratorCompleted(
              null,
              error: e.toString(),
            ),
          ),
          onDone: () {
            if (state.status != OrchestratorStatus.completed &&
                state.status != OrchestratorStatus.failed) {
              add(const OrchestratorCompleted(null));
            }
          },
        );
  }

  void _onCancel(
    OrchestratorCancelled event,
    Emitter<OrchestratorState> emit,
  ) {
    unawaited(_runSubscription?.cancel());
    _runSubscription = null;
    emit(
      state.copyWith(
        status: OrchestratorStatus.cancelled,
        completedAt: DateTime.now(),
      ),
    );
  }

  void _onProgress(
    OrchestratorProgressReceived event,
    Emitter<OrchestratorState> emit,
  ) {
    final updated = [...state.progress, event.progress];
    emit(
      state.copyWith(
        status: OrchestratorStatus.running,
        progress: updated,
        currentStep: event.progress.currentStep,
        currentAgent: event.progress.currentAgent,
        currentMessage: event.progress.message,
        overallProgress: event.progress.overallProgress,
      ),
    );
  }

  void _onCompleted(
    OrchestratorCompleted event,
    Emitter<OrchestratorState> emit,
  ) {
    emit(
      state.copyWith(
        status: event.error != null
            ? OrchestratorStatus.failed
            : OrchestratorStatus.completed,
        deliverable: event.deliverable,
        error: event.error,
        completedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> close() {
    unawaited(_runSubscription?.cancel());
    return super.close();
  }
}
