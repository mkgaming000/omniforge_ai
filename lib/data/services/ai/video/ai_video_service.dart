// Abstract AI Video Service
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../domain/entities/video_entity.dart';

/// Catalog entry for a video-generation model offered by a provider.
class ModelInfo {
  const ModelInfo({
    required this.id,
    required this.displayName,
    required this.provider,
  });
  final String id;
  final String displayName;
  final String provider;
}

abstract class AIVideoService {
  Future<Either<Failure, VideoEntity>> textToVideo(VideoGenerationRequest req);
  Future<Either<Failure, VideoEntity>> imageToVideo(VideoGenerationRequest req);
  Future<Either<Failure, VideoEntity>> videoToVideo(VideoGenerationRequest req);
  Future<Either<Failure, VideoEntity>> getStatus(String taskId);
  Future<Either<Failure, List<ModelInfo>>> listModels();
  Future<Either<Failure, bool>> healthCheck();
}
