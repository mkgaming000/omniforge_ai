// OpenAI DALL-E Image Service - DALL-E 3, DALL-E 2, gpt-image-1
import 'package:dartz/dartz.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../domain/entities/image_entity.dart';
import '../../../../core/constants/ai_providers.dart';
import 'ai_image_service.dart';

class OpenAIImageService implements AIImageService {
  OpenAIImageService();

  String? _apiKey;
  void setApiKey(String key) => _apiKey = key;

  final _uuid = const Uuid();

  @override
  Future<Either<Failure, List<ImageEntity>>> generate(
    ImageGenerationRequest req,
  ) async {
    if (_apiKey == null) {
      return const Left(
        UnauthorizedFailure(
          message: 'OpenAI API key not configured.',
        ),
      );
    }
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl:
            dotenv.maybeGet('OPENAI_BASE_URL') ?? 'https://api.openai.com/v1',
        apiKey: _apiKey,
      );
      final response = await dio.post(
        '/images/generations',
        data: {
          'model': req.model,
          'prompt': req.prompt,
          'n': req.count,
          'size': _sizeString(req.width, req.height),
          'quality': req.model == 'dall-e-3' ? 'standard' : null,
          'response_format': req.responseFormat,
          ...(req.style != null ? {'style': req.style} : {}),
        },
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'OpenAI images returned non-map: ${data.runtimeType}',
        );
      }
      final images = (data['data'] as List?) ?? <dynamic>[];
      if (images.isEmpty) {
        throw const ProviderFailure(
          message: 'OpenAI images returned empty data array',
        );
      }
      return images
          .whereType<Map<String, dynamic>>()
          .map<ImageEntity>((img) {
            final url = img['url'] as String?;
            final b64 = img['b64_json'] as String?;
            final effectiveUrl =
                url ?? (b64 != null ? 'data:image/png;base64,$b64' : '');
            return ImageEntity(
              id: _uuid.v4(),
              url: effectiveUrl,
              prompt: req.prompt,
              provider: AIProvider.openai,
              model: req.model,
              createdAt: DateTime.now(),
              width: req.width,
              height: req.height,
              style: req.style,
              metadata: Map<String, dynamic>.from(img),
            );
          })
          .where((e) => e.url.isNotEmpty)
          .toList();
    });
  }

  @override
  Future<Either<Failure, List<ImageEntity>>> edit(
    ImageEntity source,
    ImageGenerationRequest req,
  ) async {
    if (_apiKey == null) {
      return const Left(UnauthorizedFailure(message: 'API key not set'));
    }
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl:
            dotenv.maybeGet('OPENAI_BASE_URL') ?? 'https://api.openai.com/v1',
        apiKey: _apiKey,
      );
      final response = await dio.post(
        '/images/edits',
        data: {
          'image': source.url,
          'prompt': req.prompt,
          'n': req.count,
          'size': _sizeString(req.width, req.height),
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'OpenAI edits returned non-map: ${data.runtimeType}',
        );
      }
      final images = (data['data'] as List?) ?? <dynamic>[];
      if (images.isEmpty) {
        throw const ProviderFailure(
          message: 'OpenAI edits returned empty data array',
        );
      }
      return images
          .whereType<Map<String, dynamic>>()
          .map<ImageEntity>((img) {
            final url = img['url'] as String?;
            final b64 = img['b64_json'] as String?;
            final effectiveUrl =
                url ?? (b64 != null ? 'data:image/png;base64,$b64' : '');
            return ImageEntity(
              id: _uuid.v4(),
              url: effectiveUrl,
              prompt: req.prompt,
              provider: AIProvider.openai,
              model: req.model,
              createdAt: DateTime.now(),
              width: req.width,
              height: req.height,
              metadata: {'parent': source.id},
            );
          })
          .where((e) => e.url.isNotEmpty)
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
        message: 'OpenAI does not support upscaling. Use Stability or Recraft.',
      ),
    );
  }

  @override
  Future<Either<Failure, ImageEntity>> removeBackground(
    ImageEntity source,
  ) async {
    return const Left(
      ProviderFailure(
        message: 'OpenAI does not support background removal. Use Recraft.',
      ),
    );
  }

  @override
  Future<Either<Failure, List<ModelInfo>>> listModels() async {
    return const Right([
      ModelInfo(
        id: 'gpt-image-1',
        displayName: 'GPT Image 1',
        provider: 'openai',
        maxResolution: 1536,
        supportsEditing: true,
        costPerImage: 0.04,
      ),
      ModelInfo(
        id: 'dall-e-3',
        displayName: 'DALL-E 3',
        provider: 'openai',
        maxResolution: 1792,
        supportsEditing: false,
        costPerImage: 0.04,
      ),
      ModelInfo(
        id: 'dall-e-2',
        displayName: 'DALL-E 2',
        provider: 'openai',
        maxResolution: 1024,
        supportsEditing: true,
        supportsInpainting: true,
        costPerImage: 0.02,
      ),
    ]);
  }

  @override
  Future<Either<Failure, bool>> healthCheck() async {
    if (_apiKey == null) return const Right(false);
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl:
            dotenv.maybeGet('OPENAI_BASE_URL') ?? 'https://api.openai.com/v1',
        apiKey: _apiKey,
      );
      final r = await dio.get('/models');
      return r.statusCode == 200;
    });
  }

  String _sizeString(int w, int h) {
    if (w == 1024 && h == 1024) return '1024x1024';
    if (w == 1792 && h == 1024) return '1792x1024';
    if (w == 1024 && h == 1792) return '1024x1792';
    if (w == 512 && h == 512) return '512x512';
    if (w == 256 && h == 256) return '256x256';
    return '1024x1024';
  }
}
