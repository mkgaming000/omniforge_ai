// FLUX Image Service - FLUX.1 Pro, Dev, Schnell by Black Forest Labs
import 'package:dartz/dartz.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../domain/entities/image_entity.dart';
import '../../../../core/constants/ai_providers.dart';
import 'ai_image_service.dart';

class FluxImageService implements AIImageService {
  FluxImageService();

  String? _apiKey;
  void setApiKey(String key) => _apiKey = key;
  final _uuid = const Uuid();

  String get _baseUrl =>
      dotenv.maybeGet('FLUX_BASE_URL') ?? 'https://api.bfl.ai';

  @override
  Future<Either<Failure, List<ImageEntity>>> generate(
    ImageGenerationRequest req,
  ) async {
    if (_apiKey == null) {
      return const Left(
        UnauthorizedFailure(
          message: 'FLUX API key not configured.',
        ),
      );
    }
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: _baseUrl,
        apiKey: _apiKey,
        apiKeyHeader: 'X-Key',
      );

      // Submit generation task
      final submit = await dio.post(
        '/v1/${req.model}',
        data: {
          'prompt': req.prompt,
          'width': req.width,
          'height': req.height,
          'seed': req.seed,
          'steps': req.steps ?? (req.model.contains('schnell') ? 4 : 28),
          'guidance': req.cfgScale ?? 3.0,
        },
      );

      final submitData = submit.data;
      if (submitData is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'FLUX submit returned non-map: ${submitData.runtimeType}',
        );
      }
      final taskId = submitData['id'];
      if (taskId is! String || taskId.isEmpty) {
        throw ProviderFailure(
          message: 'FLUX submit returned invalid id: ${taskId.runtimeType}',
        );
      }

      // Poll for result
      String? imageUrl;
      for (var i = 0; i < 60; i++) {
        await Future.delayed(const Duration(seconds: 2));
        final status = await dio.get('/v1/get_result?id=$taskId');
        final statusData = status.data;
        if (statusData is! Map<String, dynamic>) continue;
        final statusStr = statusData['status'];
        if (statusStr is! String) continue;
        if (statusStr == 'Ready') {
          final result = statusData['result'];
          if (result is! Map<String, dynamic>) {
            throw ProviderFailure(
              message: 'FLUX result is non-map: ${result.runtimeType}',
            );
          }
          final samples = (result['sample'] as List?) ?? <dynamic>[];
          if (samples.isEmpty) {
            throw const ProviderFailure(
              message: 'FLUX result.sample is empty',
            );
          }
          final firstSample = samples.first;
          if (firstSample is! Map<String, dynamic>) {
            throw ProviderFailure(
              message:
                  'FLUX result.sample[0] non-map: ${firstSample.runtimeType}',
            );
          }
          final url = firstSample['url'] as String?;
          if (url == null || url.isEmpty) {
            throw const ProviderFailure(
              message: 'FLUX result.sample[0].url missing',
            );
          }
          imageUrl = url;
          break;
        }
        if (statusStr == 'Error') {
          throw const ProviderFailure(message: 'FLUX generation failed');
        }
      }
      if (imageUrl == null) {
        throw const TimeoutFailure(message: 'FLUX generation timed out');
      }

      return [
        ImageEntity(
          id: _uuid.v4(),
          url: imageUrl,
          prompt: req.prompt,
          provider: AIProvider.flux,
          model: req.model,
          createdAt: DateTime.now(),
          width: req.width,
          height: req.height,
          seed: req.seed,
          steps: req.steps,
          cfgScale: req.cfgScale,
        ),
      ];
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
        apiKeyHeader: 'X-Key',
      );
      final submit = await dio.post(
        '/v1/flux-pro-1.0-canny',
        data: {
          'prompt': req.prompt,
          'control_image': source.url,
          'width': req.width,
          'height': req.height,
        },
      );
      final submitData = submit.data;
      if (submitData is! Map<String, dynamic>) {
        throw ProviderFailure(
          message:
              'FLUX edit submit returned non-map: ${submitData.runtimeType}',
        );
      }
      final taskId = submitData['id'];
      if (taskId is! String || taskId.isEmpty) {
        throw ProviderFailure(
          message:
              'FLUX edit submit returned invalid id: ${taskId.runtimeType}',
        );
      }

      // Poll for result (mirrors generate()).
      String? url;
      for (var i = 0; i < 60; i++) {
        await Future.delayed(const Duration(seconds: 2));
        final status = await dio.get('/v1/get_result?id=$taskId');
        final statusData = status.data;
        if (statusData is! Map<String, dynamic>) continue;
        final statusStr = statusData['status'];
        if (statusStr is! String) continue;
        if (statusStr == 'Ready') {
          final result = statusData['result'];
          if (result is! Map<String, dynamic>) {
            throw ProviderFailure(
              message: 'FLUX edit result is non-map: ${result.runtimeType}',
            );
          }
          final samples = (result['sample'] as List?) ?? <dynamic>[];
          if (samples.isEmpty) {
            throw const ProviderFailure(
              message: 'FLUX edit result.sample is empty',
            );
          }
          final firstSample = samples.first;
          if (firstSample is! Map<String, dynamic>) {
            throw ProviderFailure(
              message:
                  'FLUX edit result.sample[0] non-map: ${firstSample.runtimeType}',
            );
          }
          final sampleUrl = firstSample['url'] as String?;
          if (sampleUrl == null || sampleUrl.isEmpty) {
            throw const ProviderFailure(
              message: 'FLUX edit result.sample[0].url missing',
            );
          }
          url = sampleUrl;
          break;
        }
        if (statusStr == 'Error') {
          throw const ProviderFailure(message: 'FLUX edit generation failed');
        }
      }
      if (url == null) {
        throw const TimeoutFailure(message: 'FLUX edit generation timed out');
      }
      return [
        ImageEntity(
          id: _uuid.v4(),
          url: url,
          prompt: req.prompt,
          provider: AIProvider.flux,
          model: req.model,
          createdAt: DateTime.now(),
          metadata: {'parent': source.id},
        ),
      ];
    });
  }

  @override
  Future<Either<Failure, ImageEntity>> upscale(
    ImageEntity source, {
    int scale = 2,
  }) async {
    return const Left(
      ProviderFailure(
        message: 'FLUX does not support upscaling natively.',
      ),
    );
  }

  @override
  Future<Either<Failure, ImageEntity>> removeBackground(
    ImageEntity source,
  ) async {
    return const Left(
      ProviderFailure(
        message: 'FLUX does not support background removal.',
      ),
    );
  }

  @override
  Future<Either<Failure, List<ModelInfo>>> listModels() async {
    return const Right([
      ModelInfo(
        id: 'flux-pro-1.1',
        displayName: 'FLUX 1.1 Pro',
        provider: 'flux',
        maxResolution: 1440,
        costPerImage: 0.04,
      ),
      ModelInfo(
        id: 'flux-dev',
        displayName: 'FLUX Dev',
        provider: 'flux',
        maxResolution: 1024,
        costPerImage: 0.025,
      ),
      ModelInfo(
        id: 'flux-schnell',
        displayName: 'FLUX Schnell',
        provider: 'flux',
        maxResolution: 1024,
        costPerImage: 0.003,
      ),
      ModelInfo(
        id: 'flux-pro-canny',
        displayName: 'FLUX Pro Canny',
        provider: 'flux',
        maxResolution: 1440,
        supportsEditing: true,
        supportsControlNet: true,
        costPerImage: 0.05,
      ),
      ModelInfo(
        id: 'flux-pro-depth',
        displayName: 'FLUX Pro Depth',
        provider: 'flux',
        maxResolution: 1440,
        supportsEditing: true,
        supportsControlNet: true,
        costPerImage: 0.05,
      ),
    ]);
  }

  @override
  Future<Either<Failure, bool>> healthCheck() async {
    return const Right(true);
  }
}
