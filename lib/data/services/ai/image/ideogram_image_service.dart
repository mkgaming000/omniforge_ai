// Ideogram Image Service - Ideogram v2 with superior text rendering
import 'package:dartz/dartz.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../domain/entities/image_entity.dart';
import '../../../../core/constants/ai_providers.dart';
import 'ai_image_service.dart';

class IdeogramImageService implements AIImageService {
  IdeogramImageService();
  String? _apiKey;
  void setApiKey(String key) => _apiKey = key;
  final _uuid = const Uuid();

  String get _baseUrl =>
      dotenv.maybeGet('IDEOGRAM_BASE_URL') ?? 'https://api.ideogram.ai/v1';

  @override
  Future<Either<Failure, List<ImageEntity>>> generate(
    ImageGenerationRequest req,
  ) async {
    if (_apiKey == null) {
      return const Left(
        UnauthorizedFailure(message: 'Ideogram API key not set'),
      );
    }
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: _baseUrl,
        apiKey: _apiKey,
        apiKeyHeader: 'Api-Key',
      );
      final response = await dio.post(
        '/generate',
        data: {
          'image_request': {
            'prompt': req.prompt,
            'model': req.model,
            'aspect_ratio': _aspectRatio(req.width, req.height),
            'magic_prompt_option': 'AUTO',
            'style_type': req.style ?? 'GENERAL',
            'seed': req.seed,
            'num_images': req.count,
          },
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'Ideogram returned non-map: ${data.runtimeType}',
        );
      }
      final images = (data['data'] as List?) ?? <dynamic>[];
      if (images.isEmpty) {
        throw const ProviderFailure(
          message: 'Ideogram returned empty data array',
        );
      }
      return images
          .whereType<Map<String, dynamic>>()
          .map<ImageEntity>((img) {
            final url = img['url'] as String?;
            if (url == null || url.isEmpty) {
              throw const ProviderFailure(
                message: 'Ideogram returned image with missing url',
              );
            }
            return ImageEntity(
              id: _uuid.v4(),
              url: url,
              prompt: req.prompt,
              provider: AIProvider.ideogram,
              model: req.model,
              createdAt: DateTime.now(),
              width: req.width,
              height: req.height,
              style: req.style,
              metadata: Map<String, dynamic>.from(img),
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
        apiKeyHeader: 'Api-Key',
      );
      final response = await dio.post(
        '/remix',
        data: {
          'image_request': {
            'prompt': req.prompt,
            'model': req.model,
            'image_num': 1,
            'images': [source.url],
          },
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'Ideogram edit returned non-map: ${data.runtimeType}',
        );
      }
      final images = (data['data'] as List?) ?? <dynamic>[];
      if (images.isEmpty) {
        throw const ProviderFailure(
          message: 'Ideogram edit returned empty data array',
        );
      }
      return images
          .whereType<Map<String, dynamic>>()
          .map<ImageEntity>((img) {
            final url = img['url'] as String?;
            if (url == null || url.isEmpty) {
              throw const ProviderFailure(
                message: 'Ideogram returned image with missing url',
              );
            }
            return ImageEntity(
              id: _uuid.v4(),
              url: url,
              prompt: req.prompt,
              provider: AIProvider.ideogram,
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
    return const Left(
      ProviderFailure(
        message: 'Ideogram does not support upscaling.',
      ),
    );
  }

  @override
  Future<Either<Failure, ImageEntity>> removeBackground(
    ImageEntity source,
  ) async {
    return const Left(
      ProviderFailure(
        message: 'Ideogram does not support background removal.',
      ),
    );
  }

  @override
  Future<Either<Failure, List<ModelInfo>>> listModels() async {
    return const Right([
      ModelInfo(
        id: 'V_2',
        displayName: 'Ideogram v2',
        provider: 'ideogram',
        maxResolution: 1024,
        supportsEditing: true,
        costPerImage: 0.08,
      ),
      ModelInfo(
        id: 'V_2_TURBO',
        displayName: 'Ideogram v2 Turbo',
        provider: 'ideogram',
        maxResolution: 1024,
        costPerImage: 0.04,
      ),
      ModelInfo(
        id: 'V_1',
        displayName: 'Ideogram v1',
        provider: 'ideogram',
        maxResolution: 1024,
        costPerImage: 0.06,
      ),
    ]);
  }

  @override
  Future<Either<Failure, bool>> healthCheck() async => const Right(true);

  String _aspectRatio(int w, int h) {
    if (w == h) return 'ASPECT_RATIO_1_1';
    if (w > h) return 'ASPECT_RATIO_16_9';
    return 'ASPECT_RATIO_9_16';
  }
}
