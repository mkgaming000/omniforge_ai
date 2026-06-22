// Image Editing Service - advanced editing operations
// Inpainting, outpainting, background removal, upscaling, variations, controlnet
import 'package:dartz/dartz.dart';

import '../../../core/constants/ai_providers.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/entities/image_entity.dart';
import '../ai/image/ai_image_service.dart';

class ImageEditingService {
  ImageEditingService({
    required this.openai,
    required this.stability,
    required this.flux,
    required this.recraft,
    required this.leonardo,
  });

  final AIImageService openai;
  final AIImageService stability;
  final AIImageService flux;
  final AIImageService recraft;
  final AIImageService leonardo;

  /// Inpaint - edit specific region of image using mask.
  Future<Either<Failure, List<ImageEntity>>> inpaint({
    required ImageEntity source,
    required String prompt,
    required String maskUrl,
    AIProvider? provider,
  }) async {
    final service = _selectProvider(provider);
    final req = ImageGenerationRequest(
      provider: provider ?? AIProvider.openai,
      model: _modelForProvider(provider),
      prompt: prompt,
      maskUrl: maskUrl,
      referenceImageUrl: source.url,
      strength: 0.8,
    );
    return service.edit(source, req);
  }

  /// Outpaint - extend image beyond its boundaries.
  Future<Either<Failure, List<ImageEntity>>> outpaint({
    required ImageEntity source,
    required String prompt,
    String direction = 'all',
    int extendBy = 256,
  }) async {
    return openai.edit(
      source,
      ImageGenerationRequest(
        provider: AIProvider.openai,
        model: 'dall-e-2',
        prompt: prompt,
        maskUrl: null,
        referenceImageUrl: source.url,
        width: source.width + extendBy * 2,
        height: source.height + extendBy * 2,
      ),
    );
  }

  /// Image-to-image - use source as reference for new generation.
  Future<Either<Failure, List<ImageEntity>>> imageToImage({
    required ImageEntity source,
    required String prompt,
    double strength = 0.7,
    AIProvider? provider,
  }) async {
    final service = _selectProvider(provider);
    return service.edit(
      source,
      ImageGenerationRequest(
        provider: provider ?? AIProvider.stability,
        model: _modelForProvider(provider),
        prompt: prompt,
        referenceImageUrl: source.url,
        strength: strength,
      ),
    );
  }

  /// Upscale image to higher resolution.
  Future<Either<Failure, ImageEntity>> upscale({
    required ImageEntity source,
    int scale = 2,
    AIProvider? provider,
  }) async {
    final service = _selectProvider(provider);
    return service.upscale(source, scale: scale);
  }

  /// Remove background from image.
  Future<Either<Failure, ImageEntity>> removeBackground({
    required ImageEntity source,
    AIProvider? provider,
  }) async {
    final service = _selectProvider(provider);
    return service.removeBackground(source);
  }

  /// Generate variations of an existing image.
  Future<Either<Failure, List<ImageEntity>>> variations({
    required ImageEntity source,
    int count = 4,
  }) async {
    return openai.edit(
      source,
      ImageGenerationRequest(
        provider: AIProvider.openai,
        model: 'dall-e-2',
        prompt: source.prompt,
        count: count,
      ),
    );
  }

  /// ControlNet - use structural hints (edges, depth, pose) to guide generation.
  Future<Either<Failure, List<ImageEntity>>> controlNet({
    required ImageEntity source,
    required String prompt,
    required ControlNetType type,
    double guidanceScale = 1.5,
  }) async {
    final service = source.provider == AIProvider.flux ? flux : stability;
    return service.edit(
      source,
      ImageGenerationRequest(
        provider: source.provider,
        model:
            type == ControlNetType.canny ? 'flux-pro-canny' : 'flux-pro-depth',
        prompt: prompt,
        referenceImageUrl: source.url,
        cfgScale: guidanceScale,
      ),
    );
  }

  /// Batch generate - same prompt, different seeds.
  Future<Either<Failure, List<ImageEntity>>> batchGenerate({
    required String prompt,
    required AIProvider provider,
    required String model,
    int count = 8,
    int width = 1024,
    int height = 1024,
  }) async {
    final service = _selectProvider(provider);
    final results = <ImageEntity>[];
    for (var i = 0; i < count; i += 4) {
      final batch = await service.generate(
        ImageGenerationRequest(
          provider: provider,
          model: model,
          prompt: prompt,
          count: (count - i).clamp(1, 4),
          width: width,
          height: height,
        ),
      );
      batch.fold(
        (_) {},
        (images) => results.addAll(images),
      );
    }
    return Right(results);
  }

  AIImageService _selectProvider(AIProvider? provider) {
    switch (provider) {
      case AIProvider.openai:
        return openai;
      case AIProvider.stability:
        return stability;
      case AIProvider.flux:
        return flux;
      case AIProvider.recraft:
        return recraft;
      case AIProvider.leonardo:
        return leonardo;
      default:
        return openai;
    }
  }

  String _modelForProvider(AIProvider? provider) {
    switch (provider) {
      case AIProvider.openai:
        return 'dall-e-2';
      case AIProvider.stability:
        return 'sdxl-1.0';
      case AIProvider.flux:
        return 'flux-dev';
      case AIProvider.recraft:
        return 'recraftv3';
      case AIProvider.leonardo:
        return '6bef9f1b-29cb-40c7-b9df-32b51c1f67d3';
      default:
        return 'dall-e-2';
    }
  }
}

enum ControlNetType {
  canny,
  depth,
  pose,
  openpose,
  hed,
  scribble,
  segmentation
}
