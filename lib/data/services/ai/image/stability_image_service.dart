// Stability AI Image Service - Stable Diffusion 3, SDXL, SD 1.5
import 'package:dartz/dartz.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../domain/entities/image_entity.dart';
import '../../../../core/constants/ai_providers.dart';
import 'ai_image_service.dart';

class StabilityImageService implements AIImageService {
  StabilityImageService();

  String? _apiKey;
  void setApiKey(String key) => _apiKey = key;
  final _uuid = const Uuid();

  String get _baseUrl =>
      dotenv.maybeGet('STABILITY_BASE_URL') ?? 'https://api.stability.ai/v1';

  @override
  Future<Either<Failure, List<ImageEntity>>> generate(
    ImageGenerationRequest req,
  ) async {
    if (_apiKey == null) {
      return const Left(
        UnauthorizedFailure(
          message: 'Stability AI API key not configured.',
        ),
      );
    }
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: _baseUrl,
        apiKey: _apiKey,
        apiKeyHeader: 'Authorization',
      );

      final endpoint = '/generation/${req.model}/text-to-image';

      final textPrompts = <Map<String, dynamic>>[
        {'text': req.prompt, 'weight': 1.0},
        if (req.negativePrompt != null && req.negativePrompt!.isNotEmpty)
          {'text': req.negativePrompt, 'weight': -1.0},
      ];

      final response = await dio.post(
        endpoint,
        data: {
          'text_prompts': textPrompts,
          'width': req.width,
          'height': req.height,
          'steps': req.steps ?? 30,
          'cfg_scale': req.cfgScale ?? 7.0,
          'seed': req.seed,
          'samples': req.count,
        },
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'Stability returned non-map: ${data.runtimeType}',
        );
      }
      final artifacts = (data['artifacts'] as List?) ?? <dynamic>[];
      if (artifacts.isEmpty) {
        throw const ProviderFailure(
          message: 'Stability returned empty artifacts array',
        );
      }
      return artifacts
          .whereType<Map<String, dynamic>>()
          .map<ImageEntity>((a) {
            final b64 = a['base64'] as String?;
            if (b64 == null || b64.isEmpty) {
              throw const ProviderFailure(
                message: 'Stability returned artifact with missing base64',
              );
            }
            return ImageEntity(
              id: _uuid.v4(),
              url: 'data:image/png;base64,$b64',
              prompt: req.prompt,
              provider: AIProvider.stability,
              model: req.model,
              createdAt: DateTime.now(),
              width: req.width,
              height: req.height,
              seed: a['seed'] as int?,
              steps: req.steps,
              cfgScale: req.cfgScale,
              metadata: Map<String, dynamic>.from(a),
            );
          })
          .whereType<ImageEntity>()
          .toList();
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
      final textPrompts = <Map<String, dynamic>>[
        {'text': req.prompt, 'weight': 1.0},
        if (req.negativePrompt != null && req.negativePrompt!.isNotEmpty)
          {'text': req.negativePrompt, 'weight': -1.0},
      ];
      final response = await dio.post(
        '/generation/${req.model}/image-to-image',
        data: {
          'init_image': source.url,
          'text_prompts': textPrompts,
          'strength': req.strength ?? 0.7,
          'steps': req.steps ?? 30,
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'Stability edit returned non-map: ${data.runtimeType}',
        );
      }
      final artifacts = (data['artifacts'] as List?) ?? <dynamic>[];
      if (artifacts.isEmpty) {
        throw const ProviderFailure(
          message: 'Stability edit returned empty artifacts array',
        );
      }
      return artifacts
          .whereType<Map<String, dynamic>>()
          .map<ImageEntity>((img) {
            final b64 = img['base64'] as String?;
            if (b64 == null || b64.isEmpty) {
              throw const ProviderFailure(
                message: 'Stability returned artifact with missing base64',
              );
            }
            return ImageEntity(
              id: _uuid.v4(),
              url: 'data:image/png;base64,$b64',
              prompt: req.prompt,
              provider: AIProvider.stability,
              model: req.model,
              createdAt: DateTime.now(),
              metadata: {'parent': source.id},
            );
          })
          .whereType<ImageEntity>()
          .toList();
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
        '/generation/esrgan-v1-x2plus/image-to-image/upscale',
        data: {
          'image': source.url,
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'Stability upscale returned non-map: ${data.runtimeType}',
        );
      }
      final artifacts = (data['artifacts'] as List?) ?? <dynamic>[];
      if (artifacts.isEmpty) {
        throw const ProviderFailure(
          message: 'Stability upscale returned empty artifacts array',
        );
      }
      final firstArtifact = artifacts.first;
      if (firstArtifact is! Map<String, dynamic>) {
        throw ProviderFailure(
          message:
              'Stability upscale returned non-map artifact: ${firstArtifact.runtimeType}',
        );
      }
      final b64 = firstArtifact['base64'] as String?;
      if (b64 == null || b64.isEmpty) {
        throw const ProviderFailure(
          message: 'Stability upscale returned empty base64 payload',
        );
      }
      return source.copyWith(
        url: 'data:image/png;base64,$b64',
        width: source.width * scale,
        height: source.height * scale,
        metadata: {'upscaled': true, 'scale': scale},
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
        '/remove-background',
        data: {'image': source.url},
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'Stability remove-bg returned non-map: ${data.runtimeType}',
        );
      }
      final artifacts = (data['artifacts'] as List?) ?? <dynamic>[];
      if (artifacts.isEmpty) {
        throw const ProviderFailure(
          message: 'Stability remove-bg returned empty artifacts array',
        );
      }
      final firstArtifact = artifacts.first;
      if (firstArtifact is! Map<String, dynamic>) {
        throw ProviderFailure(
          message:
              'Stability remove-bg returned non-map artifact: ${firstArtifact.runtimeType}',
        );
      }
      final b64 = firstArtifact['base64'] as String?;
      if (b64 == null || b64.isEmpty) {
        throw const ProviderFailure(
          message: 'Stability remove-bg returned empty base64 payload',
        );
      }
      return source.copyWith(
        url: 'data:image/png;base64,$b64',
        metadata: {'bgRemoved': true},
      );
    });
  }

  @override
  Future<Either<Failure, List<ModelInfo>>> listModels() async {
    return const Right([
      ModelInfo(
        id: 'stable-image-core',
        displayName: 'Stable Image Core',
        provider: 'stability',
        maxResolution: 1536,
        costPerImage: 0.03,
      ),
      ModelInfo(
        id: 'stable-image-ultra',
        displayName: 'Stable Image Ultra',
        provider: 'stability',
        maxResolution: 1536,
        supportsEditing: true,
        costPerImage: 0.08,
      ),
      ModelInfo(
        id: 'sd3-large',
        displayName: 'Stable Diffusion 3 Large',
        provider: 'stability',
        maxResolution: 1024,
        supportsEditing: true,
        costPerImage: 0.065,
      ),
      ModelInfo(
        id: 'sdxl-1.0',
        displayName: 'SDXL 1.0',
        provider: 'stability',
        maxResolution: 1024,
        supportsEditing: true,
        supportsInpainting: true,
        supportsControlNet: true,
        costPerImage: 0.04,
      ),
    ]);
  }

  @override
  Future<Either<Failure, bool>> healthCheck() async {
    if (_apiKey == null) return const Right(false);
    return safeApiCall(() async {
      final dio = DioClient.create(baseUrl: _baseUrl, apiKey: _apiKey);
      final r = await dio.get('/user/account');
      return r.statusCode == 200;
    });
  }
}
