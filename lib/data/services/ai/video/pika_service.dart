// Pika Video Service
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../domain/entities/video_entity.dart';
import '../../../../core/constants/ai_providers.dart';
import 'ai_video_service.dart';

class PikaService implements AIVideoService {
  PikaService();
  String? _apiKey;
  void setApiKey(String key) => _apiKey = key;
  final _uuid = const Uuid();

  @override
  Future<Either<Failure, VideoEntity>> textToVideo(
    VideoGenerationRequest req,
  ) async {
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: 'https://api.pika.art/v1',
        apiKey: _apiKey,
      );
      final r = await dio.post(
        '/generate',
        data: {
          'promptText': req.prompt,
          'options': {
            'duration': req.duration,
            'resolution': '${req.width}x${req.height}',
          },
        },
      );
      final data = r.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'Pika text_to_video returned non-map: ${data.runtimeType}',
        );
      }
      final id = data['id'];
      if (id is! String || id.isEmpty) {
        throw ProviderFailure(
          message: 'Pika text_to_video returned invalid id: ${id.runtimeType}',
        );
      }
      return VideoEntity(
        id: _uuid.v4(),
        taskId: id,
        prompt: req.prompt,
        provider: AIProvider.pika,
        model: req.model,
        createdAt: DateTime.now(),
        status: VideoStatus.processing,
      );
    });
  }

  @override
  Future<Either<Failure, VideoEntity>> imageToVideo(
    VideoGenerationRequest req,
  ) async {
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: 'https://api.pika.art/v1',
        apiKey: _apiKey,
      );
      final r = await dio.post(
        '/generate',
        data: {
          'promptImage': req.imageUrl,
          'promptText': req.prompt,
        },
      );
      final data = r.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'Pika image_to_video returned non-map: ${data.runtimeType}',
        );
      }
      final id = data['id'];
      if (id is! String || id.isEmpty) {
        throw ProviderFailure(
          message: 'Pika image_to_video returned invalid id: ${id.runtimeType}',
        );
      }
      return VideoEntity(
        id: _uuid.v4(),
        taskId: id,
        prompt: req.prompt,
        provider: AIProvider.pika,
        model: req.model,
        createdAt: DateTime.now(),
        status: VideoStatus.processing,
      );
    });
  }

  @override
  Future<Either<Failure, VideoEntity>> videoToVideo(
    VideoGenerationRequest req,
  ) async {
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: 'https://api.pika.art/v1',
        apiKey: _apiKey,
      );
      final r = await dio.post(
        '/generate',
        data: {
          'promptVideo': req.videoUrl,
          'promptText': req.prompt,
        },
      );
      final data = r.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'Pika video_to_video returned non-map: ${data.runtimeType}',
        );
      }
      final id = data['id'];
      if (id is! String || id.isEmpty) {
        throw ProviderFailure(
          message: 'Pika video_to_video returned invalid id: ${id.runtimeType}',
        );
      }
      return VideoEntity(
        id: _uuid.v4(),
        taskId: id,
        prompt: req.prompt,
        provider: AIProvider.pika,
        model: req.model,
        createdAt: DateTime.now(),
        status: VideoStatus.processing,
      );
    });
  }

  @override
  Future<Either<Failure, VideoEntity>> getStatus(String taskId) async {
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: 'https://api.pika.art/v1',
        apiKey: _apiKey,
      );
      final r = await dio.get('/videos/$taskId');
      final data = r.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'Pika status returned non-map: ${data.runtimeType}',
        );
      }
      final statusStr = data['status'];
      if (statusStr is! String) {
        throw ProviderFailure(
          message:
              'Pika status returned non-string status: ${statusStr.runtimeType}',
        );
      }
      return VideoEntity(
        id: taskId,
        taskId: taskId,
        prompt: '',
        provider: AIProvider.pika,
        model: '',
        createdAt: DateTime.now(),
        url: data['url'] as String?,
        status: _map(statusStr),
      );
    });
  }

  @override
  Future<Either<Failure, List<ModelInfo>>> listModels() async {
    return const Right([
      ModelInfo(id: 'pika-1.5', displayName: 'Pika 1.5', provider: 'pika'),
      ModelInfo(id: 'pika-1.0', displayName: 'Pika 1.0', provider: 'pika'),
    ]);
  }

  @override
  Future<Either<Failure, bool>> healthCheck() async => const Right(true);

  VideoStatus _map(String s) => switch (s) {
        'processing' => VideoStatus.processing,
        'complete' => VideoStatus.complete,
        'failed' => VideoStatus.failed,
        _ => VideoStatus.pending,
      };
}
