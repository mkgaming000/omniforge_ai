import 'package:equatable/equatable.dart';

import '../../../domain/entities/video_entity.dart';

enum VideoBlocStatus { initial, loading, ready, generating, error }

class VideoState extends Equatable {
  const VideoState({
    this.status = VideoBlocStatus.initial,
    this.videos = const [],
    this.lastGenerated,
    this.error,
  });

  const VideoState.initial() : this();

  final VideoBlocStatus status;
  final List<VideoEntity> videos;
  final VideoEntity? lastGenerated;
  final String? error;

  VideoState copyWith({
    VideoBlocStatus? status,
    List<VideoEntity>? videos,
    VideoEntity? lastGenerated,
    String? error,
  }) {
    return VideoState(
      status: status ?? this.status,
      videos: videos ?? this.videos,
      lastGenerated: lastGenerated ?? this.lastGenerated,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, videos, lastGenerated, error];
}
