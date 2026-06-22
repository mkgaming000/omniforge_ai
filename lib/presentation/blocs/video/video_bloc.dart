// Video Bloc
//
// NOTE: This file deliberately uses `VideoBlocStatus` for the bloc's UI
// state (loading/ready/generating/error) and `VideoStatus` (imported from
// the domain entity) for the persisted video's lifecycle state
// (pending/processing/complete/failed/cancelled). The two enums are
// distinct and must not be confused.
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/logger.dart';
import '../../../data/repositories/video_repository.dart';
import '../../../domain/entities/video_entity.dart';
import 'video_event.dart';
import 'video_state.dart';

class VideoBloc extends Bloc<VideoEvent, VideoState> {
  VideoBloc({required this.repository}) : super(const VideoState.initial()) {
    on<GenerateTextToVideo>(_onGenerateText);
    on<GenerateImageToVideo>(_onGenerateImage);
    on<LoadVideos>(_onLoad);
    on<DeleteVideo>(_onDelete);
    on<PollVideoStatus>(_onPoll);
  }

  final VideoRepository repository;

  Future<void> _onGenerateText(
    GenerateTextToVideo event,
    Emitter<VideoState> emit,
  ) async {
    emit(state.copyWith(status: VideoBlocStatus.generating));
    final result = await repository.persist(
      VideoEntity(
        id: '',
        taskId: '',
        prompt: event.prompt,
        provider: event.provider,
        model: event.model,
        createdAt: DateTime.now(),
        duration: event.duration,
        width: 1280,
        height: 720,
        status: VideoStatus.pending,
      ),
    );
    result.fold(
      (f) => emit(
        state.copyWith(
          status: VideoBlocStatus.error,
          error: f.userMessage,
        ),
      ),
      (video) => emit(
        state.copyWith(
          status: VideoBlocStatus.ready,
          videos: [video, ...state.videos],
          lastGenerated: video,
        ),
      ),
    );
  }

  Future<void> _onGenerateImage(
    GenerateImageToVideo event,
    Emitter<VideoState> emit,
  ) async {
    emit(state.copyWith(status: VideoBlocStatus.generating));
    final result = await repository.persist(
      VideoEntity(
        id: '',
        taskId: '',
        prompt: event.prompt,
        provider: event.provider,
        model: event.model,
        createdAt: DateTime.now(),
        status: VideoStatus.pending,
        metadata: {'imageUrl': event.imageUrl},
      ),
    );
    result.fold(
      (f) => emit(
        state.copyWith(
          status: VideoBlocStatus.error,
          error: f.userMessage,
        ),
      ),
      (video) => emit(
        state.copyWith(
          status: VideoBlocStatus.ready,
          videos: [video, ...state.videos],
          lastGenerated: video,
        ),
      ),
    );
  }

  Future<void> _onLoad(LoadVideos event, Emitter<VideoState> emit) async {
    emit(state.copyWith(status: VideoBlocStatus.loading));
    final result = await repository.getAll();
    result.fold(
      (f) => emit(
        state.copyWith(
          status: VideoBlocStatus.error,
          error: f.userMessage,
        ),
      ),
      (videos) => emit(
        state.copyWith(
          status: VideoBlocStatus.ready,
          videos: videos,
        ),
      ),
    );
  }

  Future<void> _onDelete(DeleteVideo event, Emitter<VideoState> emit) async {
    final result = await repository.delete(event.id);
    result.fold(
      (f) => emit(
        state.copyWith(
          status: VideoBlocStatus.error,
          error: f.userMessage,
        ),
      ),
      (_) => emit(
        state.copyWith(
          videos: state.videos.where((v) => v.id != event.id).toList(),
        ),
      ),
    );
  }

  Future<void> _onPoll(PollVideoStatus event, Emitter<VideoState> emit) async {
    // Provider polling is not wired into this bloc; emit an honest error
    // instead of faking completion.
    final idx = state.videos.indexWhere((v) => v.id == event.videoId);
    if (idx == -1) return;
    AppLogger.w('Video status polling is not wired to the provider yet.');
    emit(
      state.copyWith(
        status: VideoBlocStatus.error,
        error: 'Video status polling is not wired to the provider yet.',
      ),
    );
  }
}
