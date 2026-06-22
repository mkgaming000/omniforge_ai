// Music Bloc
//
// NOTE: Uses `MusicBlocStatus` for the bloc's UI state and `MusicStatus`
// (imported from the domain entity) for the persisted track's lifecycle
// state (pending/processing/complete/failed/streaming).
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/music_repository.dart';
import '../../../domain/entities/music_entity.dart';
import 'music_event.dart';
import 'music_state.dart';

class MusicBloc extends Bloc<MusicEvent, MusicState> {
  MusicBloc({required this.repository}) : super(const MusicState.initial()) {
    on<GenerateMusic>(_onGenerate);
    on<LoadMusic>(_onLoad);
    on<DeleteMusic>(_onDelete);
  }

  final MusicRepository repository;

  Future<void> _onGenerate(
    GenerateMusic event,
    Emitter<MusicState> emit,
  ) async {
    emit(state.copyWith(status: MusicBlocStatus.generating));
    final result = await repository.persist(
      MusicEntity(
        id: '',
        prompt: event.prompt,
        provider: event.provider,
        model: event.model,
        createdAt: DateTime.now(),
        title: event.title,
        lyrics: event.lyrics,
        duration: event.duration,
        tags: event.tags,
        style: event.style,
        status: MusicStatus.pending,
      ),
    );
    result.fold(
      (f) => emit(
        state.copyWith(
          status: MusicBlocStatus.error,
          error: f.userMessage,
        ),
      ),
      (music) => emit(
        state.copyWith(
          status: MusicBlocStatus.ready,
          tracks: [music, ...state.tracks],
          lastGenerated: music,
        ),
      ),
    );
  }

  Future<void> _onLoad(LoadMusic event, Emitter<MusicState> emit) async {
    emit(state.copyWith(status: MusicBlocStatus.loading));
    final result = await repository.getAll();
    result.fold(
      (f) => emit(
        state.copyWith(
          status: MusicBlocStatus.error,
          error: f.userMessage,
        ),
      ),
      (tracks) => emit(
        state.copyWith(
          status: MusicBlocStatus.ready,
          tracks: tracks,
        ),
      ),
    );
  }

  Future<void> _onDelete(DeleteMusic event, Emitter<MusicState> emit) async {
    final result = await repository.delete(event.id);
    result.fold(
      (f) => emit(
        state.copyWith(
          status: MusicBlocStatus.error,
          error: f.userMessage,
        ),
      ),
      (_) => emit(
        state.copyWith(
          tracks: state.tracks.where((m) => m.id != event.id).toList(),
        ),
      ),
    );
  }
}
