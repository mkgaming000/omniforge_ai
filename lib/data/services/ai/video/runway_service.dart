// Runway Gen-3 Alpha Video Service
import 'package:dartz/dartz.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../domain/entities/video_entity.dart';
import '../../../../core/constants/ai_providers.dart';
import 'ai_video_service.dart';

class RunwayService implements AIVideoService {
  RunwayService();
  String? _apiKey;
  void setApiKey(String key) => _apiKey = key;
  final _uuid = const Uuid();

  String get _baseUrl =>
      dotenv.maybeGet('RUNWAY_BASE_URL') ?? 'https://api.runwayml.com/v1';

  @override
  Future<Either<Failure, VideoEntity>> textToVideo(
    VideoGenerationRequest req,
  ) async {
    if (_apiKey == null) {
      return const Left(UnauthorizedFailure(message: 'Runway API key not set'));
    }
    return safeApiCall(() async {
      final dio = DioClient.create(baseUrl: _baseUrl, apiKey: _apiKey);
      final response = await dio.post(
        '/text_to_video',
        data: {
          'promptText': req.prompt,
          'model': req.model,
          'duration': req.duration,
          'ratio': _ratio(req.width, req.height),
          'seed': req.seed,
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'Runway text_to_video returned non-map: ${data.runtimeType}',
        );
      }
      final taskId = data['taskId'];
      if (taskId is! String || taskId.isEmpty) {
        throw ProviderFailure(
          message:
              'Runway text_to_video returned invalid taskId: ${taskId.runtimeType}',
        );
      }
      return VideoEntity(
        id: _uuid.v4(),
        taskId: taskId,
        prompt: req.prompt,
        provider: AIProvider.runway,
        model: req.model,
        createdAt: DateTime.now(),
        duration: req.duration,
        width: req.width,
        height: req.height,
        status: VideoStatus.processing,
      );
    });
  }

  @override
  Future<Either<Failure, VideoEntity>> imageToVideo(
    VideoGenerationRequest req,
  ) async {
    if (_apiKey == null) {
      return const Left(UnauthorizedFailure(message: 'Runway API key not set'));
    }
    return safeApiCall(() async {
      final dio = DioClient.create(baseUrl: _baseUrl, apiKey: _apiKey);
      final response = await dio.post(
        '/image_to_video',
        data: {
          'promptImage': req.imageUrl,
          'promptText': req.prompt,
          'model': req.model,
          'duration': req.duration,
          'ratio': _ratio(req.width, req.height),
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message:
              'Runway image_to_video returned non-map: ${data.runtimeType}',
        );
      }
      final taskId = data['taskId'];
      if (taskId is! String || taskId.isEmpty) {
        throw ProviderFailure(
          message:
              'Runway image_to_video returned invalid taskId: ${taskId.runtimeType}',
        );
      }
      return VideoEntity(
        id: _uuid.v4(),
        taskId: taskId,
        prompt: req.prompt,
        provider: AIProvider.runway,
        model: req.model,
        createdAt: DateTime.now(),
        duration: req.duration,
        width: req.width,
        height: req.height,
        status: VideoStatus.processing,
      );
    });
  }

  @override
  Future<Either<Failure, VideoEntity>> videoToVideo(
    VideoGenerationRequest req,
  ) async {
    if (_apiKey == null) {
      return const Left(UnauthorizedFailure(message: 'Runway API key not set'));
    }
    return safeApiCall(() async {
      final dio = DioClient.create(baseUrl: _baseUrl, apiKey: _apiKey);
      final response = await dio.post(
        '/video_to_video',
        data: {
          'promptVideo': req.videoUrl,
          'promptText': req.prompt,
          'model': req.model,
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message:
              'Runway video_to_video returned non-map: ${data.runtimeType}',
        );
      }
      final taskId = data['taskId'];
      if (taskId is! String || taskId.isEmpty) {
        throw ProviderFailure(
          message:
              'Runway video_to_video returned invalid taskId: ${taskId.runtimeType}',
        );
      }
      return VideoEntity(
        id: _uuid.v4(),
        taskId: taskId,
        prompt: req.prompt,
        provider: AIProvider.runway,
        model: req.model,
        createdAt: DateTime.now(),
        status: VideoStatus.processing,
      );
    });
  }

  @override
  Future<Either<Failure, VideoEntity>> getStatus(String taskId) async {
    if (_apiKey == null) {
      return const Left(UnauthorizedFailure(message: 'Runway API key not set'));
    }
    return safeApiCall(() async {
      final dio = DioClient.create(baseUrl: _baseUrl, apiKey: _apiKey);
      final response = await dio.get('/tasks/$taskId');
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'Runway status returned non-map: ${data.runtimeType}',
        );
      }
      final statusStr = data['status'];
      if (statusStr is! String) {
        throw ProviderFailure(
          message:
              'Runway status returned non-string status: ${statusStr.runtimeType}',
        );
      }
      final output = data['output'];
      final Map<String, dynamic> outputMap =
          output is Map<String, dynamic> ? output : <String, dynamic>{};
      return VideoEntity(
        id: taskId,
        taskId: taskId,
        prompt: data['prompt'] as String? ?? '',
        provider: AIProvider.runway,
        model: data['model'] as String? ?? '',
        createdAt: DateTime.now(),
        url: outputMap['url'] as String?,
        thumbnailUrl: outputMap['thumbnailUrl'] as String?,
        status: _mapStatus(statusStr),
        progress: ((data['progress'] as num?) ?? 0).toInt(),
      );
    });
  }

  @override
  Future<Either<Failure, List<ModelInfo>>> listModels() async {
    return const Right([
      ModelInfo(
        id: 'gen3a_turbo',
        displayName: 'Gen-3 Alpha Turbo',
        provider: 'runway',
      ),
      ModelInfo(id: 'gen3a', displayName: 'Gen-3 Alpha', provider: 'runway'),
      ModelInfo(id: 'gen2', displayName: 'Gen-2', provider: 'runway'),
    ]);
  }

  @override
  Future<Either<Failure, bool>> healthCheck() async => const Right(true);

  VideoStatus _mapStatus(String s) {
    switch (s) {
      case 'RUNNING':
        return VideoStatus.processing;
      case 'SUCCEEDED':
        return VideoStatus.complete;
      case 'FAILED':
        return VideoStatus.failed;
      case 'CANCELLED':
        return VideoStatus.cancelled;
      default:
        return VideoStatus.pending;
    }
  }

  String _ratio(int w, int h) {
    if (w == 1920 && h == 1080) return '16:9';
    if (w == 1080 && h == 1920) return '9:16';
    if (w == 1280 && h == 720) return '16:9';
    return '16:9';
  }
}
