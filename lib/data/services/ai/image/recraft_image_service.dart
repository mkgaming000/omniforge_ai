// Recraft Image Service - Recraft v3 with SVG generation
import 'package:dartz/dartz.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../domain/entities/image_entity.dart';
import '../../../../core/constants/ai_providers.dart';
import 'ai_image_service.dart';

class RecraftImageService implements AIImageService {
  RecraftImageService();
  String? _apiKey;
  void setApiKey(String key) => _apiKey = key;
  final _uuid = const Uuid();

  String get _baseUrl =>
      dotenv.maybeGet('RECRAFT_BASE_URL') ??
      'https://external.api.recraft.ai/v1';

  @override
  Future<Either<Failure, List<ImageEntity>>> generate(
    ImageGenerationRequest req,
  ) async {
    if (_apiKey == null) {
      return const Left(
        UnauthorizedFailure(message: 'Recraft API key not set'),
      );
    }
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: _baseUrl,
        apiKey: _apiKey,
      );
      final response = await dio.post(
        '/images/generations',
        data: {
          'prompt': req.prompt,
          'model': req.model,
          'size': '${req.width}x${req.height}',
          'n': req.count,
          'style': req.style ?? 'realistic_image',
          'response_format': 'url',
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'Recraft returned non-map: ${data.runtimeType}',
        );
      }
      final images = (data['data'] as List?) ?? <dynamic>[];
      if (images.isEmpty) {
        throw const ProviderFailure(
          message: 'Recraft returned empty data array',
        );
      }
      return images
          .whereType<Map<String, dynamic>>()
          .map<ImageEntity>((img) {
            final url = img['url'] as String?;
            if (url == null || url.isEmpty) {
              throw const ProviderFailure(
                message: 'Recraft returned image with missing url',
              );
            }
            return ImageEntity(
              id: _uuid.v4(),
              url: url,
              prompt: req.prompt,
              provider: AIProvider.recraft,
              model: req.model,
              createdAt: DateTime.now(),
              width: req.width,
              height: req.height,
              style: req.style,
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
      final dio = DioClient.create(baseUrl: _baseUrl, apiKey: _apiKey);
      final response = await dio.post(
        '/images/edits',
        data: {
          'prompt': req.prompt,
          'image': source.url,
          'model': req.model,
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'Recraft edit returned non-map: ${data.runtimeType}',
        );
      }
      final images = (data['data'] as List?) ?? <dynamic>[];
      if (images.isEmpty) {
        throw const ProviderFailure(
          message: 'Recraft edit returned empty data array',
        );
      }
      return images
          .whereType<Map<String, dynamic>>()
          .map<ImageEntity>((img) {
            final url = img['url'] as String?;
            if (url == null || url.isEmpty) {
              throw const ProviderFailure(
                message: 'Recraft returned image with missing url',
              );
            }
            return ImageEntity(
              id: _uuid.v4(),
              url: url,
              prompt: req.prompt,
              provider: AIProvider.recraft,
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
      final dio = DioClient.create(baseUrl: _baseUrl, apiKey: _apiKey);
      final response = await dio.post(
        '/images/upscale',
        data: {'image': source.url, 'scale': scale},
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'Recraft upscale returned non-map: ${data.runtimeType}',
        );
      }
      final images = (data['data'] as List?) ?? <dynamic>[];
      if (images.isEmpty) {
        throw const ProviderFailure(
          message: 'Recraft upscale returned empty data array',
        );
      }
      final firstImage = images.first;
      if (firstImage is! Map<String, dynamic>) {
        throw ProviderFailure(
          message:
              'Recraft upscale returned non-map item: ${firstImage.runtimeType}',
        );
      }
      final url = firstImage['url'] as String?;
      if (url == null || url.isEmpty) {
        throw const ProviderFailure(
          message: 'Recraft upscale returned missing url',
        );
      }
      return source.copyWith(
        url: url,
        width: source.width * scale,
        height: source.height * scale,
      );
    });
  }

  @override
  Future<Either<Failure, ImageEntity>> removeBackground(
    ImageEntity source,
  ) async {
    return safeApiCall(() async {
      final dio = DioClient.create(baseUrl: _baseUrl, apiKey: _apiKey);
      final response = await dio.post(
        '/remove_background',
        data: {'image': source.url},
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'Recraft remove-bg returned non-map: ${data.runtimeType}',
        );
      }
      final images = (data['data'] as List?) ?? <dynamic>[];
      if (images.isEmpty) {
        throw const ProviderFailure(
          message: 'Recraft remove-bg returned empty data array',
        );
      }
      final firstImage = images.first;
      if (firstImage is! Map<String, dynamic>) {
        throw ProviderFailure(
          message:
              'Recraft remove-bg returned non-map item: ${firstImage.runtimeType}',
        );
      }
      final url = firstImage['url'] as String?;
      if (url == null || url.isEmpty) {
        throw const ProviderFailure(
          message: 'Recraft remove-bg returned missing url',
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
        id: 'recraftv3',
        displayName: 'Recraft v3',
        provider: 'recraft',
        maxResolution: 2048,
        supportsEditing: true,
        supportsUpscaling: true,
        costPerImage: 0.04,
      ),
      ModelInfo(
        id: 'recraft20b',
        displayName: 'Recraft 20B',
        provider: 'recraft',
        maxResolution: 1024,
        costPerImage: 0.05,
      ),
    ]);
  }

  @override
  Future<Either<Failure, bool>> healthCheck() async => const Right(true);
}
