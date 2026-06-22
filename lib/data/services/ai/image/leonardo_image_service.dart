// Leonardo AI Image Service - Phoenix, Lightning, Vision models
import 'package:dartz/dartz.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../domain/entities/image_entity.dart';
import '../../../../core/constants/ai_providers.dart';
import 'ai_image_service.dart';

class LeonardoImageService implements AIImageService {
  LeonardoImageService();
  String? _apiKey;
  void setApiKey(String key) => _apiKey = key;
  final _uuid = const Uuid();

  String get _baseUrl =>
      dotenv.maybeGet('LEONARDO_BASE_URL') ??
      'https://cloud.leonardo.ai/api/rest/v1';

  @override
  Future<Either<Failure, List<ImageEntity>>> generate(
    ImageGenerationRequest req,
  ) async {
    if (_apiKey == null) {
      return const Left(
        UnauthorizedFailure(
          message: 'Leonardo AI API key not configured.',
        ),
      );
    }
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: _baseUrl,
        apiKey: _apiKey,
        apiKeyHeader: 'Authorization',
      );

      // Create generation
      final response = await dio.post(
        '/generations',
        data: {
          'prompt': req.prompt,
          'modelId': req.model,
          'width': req.width,
          'height': req.height,
          'num_images': req.count,
          'guidance_scale': req.cfgScale ?? 7.0,
          'num_inference_steps': req.steps ?? 30,
          'seed': req.seed,
          'negative_prompt': req.negativePrompt,
        },
      );

      final submitData = response.data;
      if (submitData is! Map<String, dynamic>) {
        throw ProviderFailure(
          message:
              'Leonardo submit returned non-map: ${submitData.runtimeType}',
        );
      }
      final sdJob = submitData['sdGenerationJob'];
      if (sdJob is! Map<String, dynamic>) {
        throw ProviderFailure(
          message:
              'Leonardo sdGenerationJob missing or non-map: ${sdJob.runtimeType}',
        );
      }
      final generationId = sdJob['generationId'];
      if (generationId is! String || generationId.isEmpty) {
        throw ProviderFailure(
          message:
              'Leonardo generationId missing or invalid: ${generationId.runtimeType}',
        );
      }

      // Poll for completion
      for (var i = 0; i < 60; i++) {
        await Future.delayed(const Duration(seconds: 3));
        final status = await dio.get('/generations/$generationId');
        final statusData = status.data;
        if (statusData is! Map<String, dynamic>) continue;
        final data = statusData['generations_by_pk'];
        if (data is! Map<String, dynamic>) continue;
        final statusStr = data['status'];
        if (statusStr is! String) continue;
        if (statusStr == 'COMPLETE') {
          final images = (data['generated_images'] as List?) ?? <dynamic>[];
          if (images.isEmpty) {
            throw const ProviderFailure(
              message: 'Leonardo returned empty generated_images array',
            );
          }
          return images
              .whereType<Map<String, dynamic>>()
              .map<ImageEntity>((img) {
                final url = img['url'] as String?;
                if (url == null || url.isEmpty) {
                  throw const ProviderFailure(
                    message: 'Leonardo returned image with missing url',
                  );
                }
                return ImageEntity(
                  id: _uuid.v4(),
                  url: url,
                  prompt: req.prompt,
                  provider: AIProvider.leonardo,
                  model: req.model,
                  createdAt: DateTime.now(),
                  width: req.width,
                  height: req.height,
                  seed: img['seed'] as int?,
                );
              })
              .whereType<ImageEntity>()
              .toList();
        }
        if (statusStr == 'FAILED') {
          throw const ProviderFailure(message: 'Leonardo generation failed');
        }
      }
      throw const TimeoutFailure(message: 'Leonardo generation timed out');
    });
  }

  @override
  Future<Either<Failure, List<ImageEntity>>> edit(
    ImageEntity source,
    ImageGenerationRequest req,
  ) async {
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: _baseUrl,
        apiKey: _apiKey,
        apiKeyHeader: 'Authorization',
      );
      final response = await dio.post(
        '/edits',
        data: {
          'prompt': req.prompt,
          'init_image_id': source.id,
          'modelId': req.model,
          'strength': req.strength ?? 0.7,
        },
      );
      final submitData = response.data;
      if (submitData is! Map<String, dynamic>) {
        throw ProviderFailure(
          message:
              'Leonardo edit submit returned non-map: ${submitData.runtimeType}',
        );
      }
      final sdJob = submitData['sdGenerationJob'];
      if (sdJob is! Map<String, dynamic>) {
        throw ProviderFailure(
          message:
              'Leonardo edit sdGenerationJob missing or non-map: ${sdJob.runtimeType}',
        );
      }
      final generationId = sdJob['generationId'];
      if (generationId is! String || generationId.isEmpty) {
        throw ProviderFailure(
          message:
              'Leonardo edit generationId missing or invalid: ${generationId.runtimeType}',
        );
      }

      // Poll for completion (mirrors generate()).
      for (var i = 0; i < 60; i++) {
        await Future.delayed(const Duration(seconds: 3));
        final status = await dio.get('/generations/$generationId');
        final statusData = status.data;
        if (statusData is! Map<String, dynamic>) continue;
        final data = statusData['generations_by_pk'];
        if (data is! Map<String, dynamic>) continue;
        final statusStr = data['status'];
        if (statusStr is! String) continue;
        if (statusStr == 'COMPLETE') {
          final images = (data['generated_images'] as List?) ?? <dynamic>[];
          if (images.isEmpty) {
            throw const ProviderFailure(
              message: 'Leonardo edit returned empty generated_images array',
            );
          }
          return images
              .whereType<Map<String, dynamic>>()
              .map<ImageEntity>((img) {
                final url = img['url'] as String?;
                if (url == null || url.isEmpty) {
                  throw const ProviderFailure(
                    message: 'Leonardo returned image with missing url',
                  );
                }
                return ImageEntity(
                  id: _uuid.v4(),
                  url: url,
                  prompt: req.prompt,
                  provider: AIProvider.leonardo,
                  model: req.model,
                  createdAt: DateTime.now(),
                  metadata: {'parent': source.id},
                );
              })
              .whereType<ImageEntity>()
              .toList();
        }
        if (statusStr == 'FAILED') {
          throw const ProviderFailure(
            message: 'Leonardo edit generation failed',
          );
        }
      }
      throw const TimeoutFailure(message: 'Leonardo edit generation timed out');
    });
  }

  @override
  Future<Either<Failure, ImageEntity>> upscale(
    ImageEntity source, {
    int scale = 2,
  }) async {
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: _baseUrl,
        apiKey: _apiKey,
        apiKeyHeader: 'Authorization',
      );
      final response = await dio.post(
        '/variations/upscale',
        data: {'image_id': source.id},
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'Leonardo upscale returned non-map: ${data.runtimeType}',
        );
      }
      final url = data['url'] as String?;
      if (url == null || url.isEmpty) {
        throw const ProviderFailure(
          message: 'Leonardo upscale returned missing url',
        );
      }
      return source.copyWith(
        url: url,
        width: source.width * 2,
        height: source.height * 2,
      );
    });
  }

  @override
  Future<Either<Failure, ImageEntity>> removeBackground(
    ImageEntity source,
  ) async {
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: _baseUrl,
        apiKey: _apiKey,
        apiKeyHeader: 'Authorization',
      );
      final response = await dio.post(
        '/variations/canvas',
        data: {'image_id': source.id, 'operation': 'remove_background'},
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'Leonardo remove-bg returned non-map: ${data.runtimeType}',
        );
      }
      final url = data['url'] as String?;
      if (url == null || url.isEmpty) {
        throw const ProviderFailure(
          message: 'Leonardo remove-bg returned missing url',
        );
      }
      return source.copyWith(
        url: url,
        metadata: {'bgRemoved': true},
      );
    });
  }

  @override
  Future<Either<Failure, List<ModelInfo>>> listModels() async {
    return const Right([
      ModelInfo(
        id: '6bef9f1b-29cb-40c7-b9df-32b51c1f67d3',
        displayName: 'Phoenix',
        provider: 'leonardo',
        maxResolution: 1024,
        costPerImage: 0.05,
      ),
      ModelInfo(
        id: 'b24e16ff-06e3-43eb-8d33-4416c2d75876',
        displayName: 'Lightning XL',
        provider: 'leonardo',
        maxResolution: 1024,
        supportsEditing: true,
        costPerImage: 0.025,
      ),
      ModelInfo(
        id: 'aa77f04e-3eec-4034-9c8d-37e1a0daef6a',
        displayName: 'Leonardo Vision XL',
        provider: 'leonardo',
        maxResolution: 1024,
        supportsEditing: true,
        costPerImage: 0.035,
      ),
    ]);
  }

  @override
  Future<Either<Failure, bool>> healthCheck() async => const Right(true);
}
