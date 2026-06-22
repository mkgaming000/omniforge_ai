// Usage Bloc
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/logger.dart';
import '../../../domain/usecases/usage/track_usage_usecase.dart';
import '../../../domain/usecases/usage/get_usage_stats_usecase.dart';
import 'usage_event.dart';
import 'usage_state.dart';

class UsageBloc extends Bloc<UsageEvent, UsageState> {
  UsageBloc({
    required TrackUsageUseCase trackUsageUseCase,
    required GetUsageStatsUseCase getUsageStatsUseCase,
  })  : _trackUseCase = trackUsageUseCase,
        _getStatsUseCase = getUsageStatsUseCase,
        super(const UsageState.initial()) {
    on<LoadUsageStats>(_onLoad);
    on<TrackUsage>(_onTrack);
  }

  final TrackUsageUseCase _trackUseCase;
  final GetUsageStatsUseCase _getStatsUseCase;

  Future<void> _onLoad(
    LoadUsageStats event,
    Emitter<UsageState> emit,
  ) async {
    emit(state.copyWith(status: UsageStatus.loading));
    final result = await _getStatsUseCase(since: event.since);
    result.fold(
      (_) => emit(state.copyWith(status: UsageStatus.error)),
      (stats) => emit(
        state.copyWith(
          status: UsageStatus.ready,
          stats: stats,
        ),
      ),
    );
  }

  Future<void> _onTrack(
    TrackUsage event,
    Emitter<UsageState> emit,
  ) async {
    final result = await _trackUseCase(event.usage);
    result.fold(
      (f) {
        AppLogger.e('Failed to track usage', f);
        emit(state.copyWith(status: UsageStatus.error));
      },
      (_) => add(const LoadUsageStats()),
    );
  }
}
