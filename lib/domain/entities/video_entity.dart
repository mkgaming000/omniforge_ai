// Video entity - generated video records
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

import '../../core/constants/ai_providers.dart';

part 'video_entity.g.dart';

@HiveType(typeId: 32)
enum VideoStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  processing,
  @HiveField(2)
  complete,
  @HiveField(3)
  failed,
  @HiveField(4)
  cancelled,
}

@HiveType(typeId: 30)
class VideoEntity extends Equatable {
  const VideoEntity({
    required this.id,
    required this.taskId,
    required this.prompt,
    required this.provider,
    required this.model,
    required this.createdAt,
    this.url,
    this.thumbnailUrl,
    this.duration = 5,
    this.width = 1280,
    this.height = 720,
    this.fps = 24,
    this.status = VideoStatus.pending,
    this.progress = 0,
    this.error,
    this.metadata = const {},
    this.localPath,
    this.projectId,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String taskId;

  @HiveField(2)
  final String prompt;

  @HiveField(3)
  final AIProvider provider;

  @HiveField(4)
  final String model;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final String? url;

  @HiveField(7)
  final String? thumbnailUrl;

  @HiveField(8)
  final int duration;

  @HiveField(9)
  final int width;

  @HiveField(10)
  final int height;

  @HiveField(11)
  final int fps;

  @HiveField(12)
  final VideoStatus status;

  @HiveField(13)
  final int progress;

  @HiveField(14)
  final String? error;

  @HiveField(15)
  final Map<String, dynamic> metadata;

  @HiveField(16)
  final String? localPath;

  @HiveField(17)
  final String? projectId;

  VideoEntity copyWith({
    String? id,
    String? taskId,
    String? prompt,
    AIProvider? provider,
    String? model,
    DateTime? createdAt,
    String? url,
    String? thumbnailUrl,
    int? duration,
    int? width,
    int? height,
    int? fps,
    VideoStatus? status,
    int? progress,
    String? error,
    Map<String, dynamic>? metadata,
    String? localPath,
    String? projectId,
  }) {
    return VideoEntity(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      prompt: prompt ?? this.prompt,
      provider: provider ?? this.provider,
      model: model ?? this.model,
      createdAt: createdAt ?? this.createdAt,
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      width: width ?? this.width,
      height: height ?? this.height,
      fps: fps ?? this.fps,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error ?? this.error,
      metadata: metadata ?? this.metadata,
      localPath: localPath ?? this.localPath,
      projectId: projectId ?? this.projectId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        taskId,
        prompt,
        provider,
        model,
        createdAt,
        url,
        thumbnailUrl,
        duration,
        width,
        height,
        fps,
        status,
        progress,
        error,
        metadata,
        localPath,
        projectId,
      ];
}

@HiveType(typeId: 31)
class VideoGenerationRequest extends Equatable {
  const VideoGenerationRequest({
    required this.provider,
    required this.model,
    required this.prompt,
    this.imageUrl,
    this.videoUrl,
    this.duration = 5,
    this.width = 1280,
    this.height = 720,
    this.fps = 24,
    this.negativePrompt,
    this.seed,
    this.metadata = const {},
  });

  @HiveField(0)
  final AIProvider provider;

  @HiveField(1)
  final String model;

  @HiveField(2)
  final String prompt;

  @HiveField(3)
  final String? imageUrl;

  @HiveField(4)
  final String? videoUrl;

  @HiveField(5)
  final int duration;

  @HiveField(6)
  final int width;

  @HiveField(7)
  final int height;

  @HiveField(8)
  final int fps;

  @HiveField(9)
  final String? negativePrompt;

  @HiveField(10)
  final int? seed;

  @HiveField(11)
  final Map<String, dynamic> metadata;

  @override
  List<Object?> get props => [
        provider,
        model,
        prompt,
        imageUrl,
        videoUrl,
        duration,
        width,
        height,
        fps,
        negativePrompt,
        seed,
        metadata,
      ];
}
