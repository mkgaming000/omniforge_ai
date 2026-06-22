// Abstract AI Image Service
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../domain/entities/image_entity.dart';

abstract class AIImageService {
  Future<Either<Failure, List<ImageEntity>>> generate(
    ImageGenerationRequest req,
  );
  Future<Either<Failure, List<ImageEntity>>> edit(
    ImageEntity source,
    ImageGenerationRequest req,
  );
  Future<Either<Failure, ImageEntity>> upscale(
    ImageEntity source, {
    int scale = 2,
  });
  Future<Either<Failure, ImageEntity>> removeBackground(ImageEntity source);
  Future<Either<Failure, List<ModelInfo>>> listModels();
  Future<Either<Failure, bool>> healthCheck();
}

class ModelInfo {
  const ModelInfo({
    required this.id,
    required this.displayName,
    required this.provider,
    this.maxResolution = 1024,
    this.supportsEditing = false,
    this.supportsUpscaling = false,
    this.supportsInpainting = false,
    this.supportsControlNet = false,
    this.costPerImage = 0.04,
  });

  final String id;
  final String displayName;
  final String provider;
  final int maxResolution;
  final bool supportsEditing;
  final bool supportsUpscaling;
  final bool supportsInpainting;
  final bool supportsControlNet;
  final double costPerImage;
}
