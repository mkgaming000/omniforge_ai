import 'package:equatable/equatable.dart';

import '../../../domain/entities/music_entity.dart';

enum MusicBlocStatus { initial, loading, ready, generating, error }

class MusicState extends Equatable {
  const MusicState({
    this.status = MusicBlocStatus.initial,
    this.tracks = const [],
    this.lastGenerated,
    this.error,
  });

  const MusicState.initial() : this();

  final MusicBlocStatus status;
  final List<MusicEntity> tracks;
  final MusicEntity? lastGenerated;
  final String? error;

  MusicState copyWith({
    MusicBlocStatus? status,
    List<MusicEntity>? tracks,
    MusicEntity? lastGenerated,
    String? error,
  }) {
    return MusicState(
      status: status ?? this.status,
      tracks: tracks ?? this.tracks,
      lastGenerated: lastGenerated ?? this.lastGenerated,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, tracks, lastGenerated, error];
}
