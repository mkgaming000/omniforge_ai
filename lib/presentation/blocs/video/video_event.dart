import 'package:equatable/equatable.dart';

import '../../../core/constants/ai_providers.dart';

abstract class VideoEvent extends Equatable {
  const VideoEvent();
}

class GenerateTextToVideo extends VideoEvent {
  const GenerateTextToVideo({
    required this.provider,
    required this.model,
    required this.prompt,
    this.duration = 5,
  });
  final AIProvider provider;
  final String model;
  final String prompt;
  final int duration;
  @override
  List<Object?> get props => [provider, model, prompt, duration];
}

class GenerateImageToVideo extends VideoEvent {
  const GenerateImageToVideo({
    required this.provider,
    required this.model,
    required this.prompt,
    required this.imageUrl,
  });
  final AIProvider provider;
  final String model;
  final String prompt;
  final String imageUrl;
  @override
  List<Object?> get props => [provider, model, prompt, imageUrl];
}

class LoadVideos extends VideoEvent {
  const LoadVideos();
  @override
  List<Object?> get props => [];
}

class DeleteVideo extends VideoEvent {
  const DeleteVideo(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

class PollVideoStatus extends VideoEvent {
  const PollVideoStatus(this.videoId);
  final String videoId;
  @override
  List<Object?> get props => [videoId];
}
