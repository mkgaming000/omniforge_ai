// Kling AI Video Service
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../domain/entities/video_entity.dart';
import '../../../../core/constants/ai_providers.dart';
import 'ai_video_service.dart';

class KlingService implements AIVideoService {
  KlingService();
  String? _apiKey;
  void setApiKey(String key) => _apiKey = key;
  final _uuid = const Uuid();

  @override
  Future<Either<Failure, VideoEntity>> textToVideo(
    VideoGenerationRequest req,
  ) async {
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: 'https://api.klingai.com/v1',
        apiKey: _apiKey,
      );
      final r = await dio.post(
        '/videos/text2video',
        data: {
          'model': req.model,
          'prompt': req.prompt,
          'duration': req.duration,
          'aspect_ratio': req.width > req.height ? '16:9' : '9:16',
        },
      );
      final data = r.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'Kling text2video returned non-map: ${data.runtimeType}',
        );
      }
      final innerData = data['data'];
      if (innerData is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'Kling text2video data is non-map: ${innerData.runtimeType}',
        );
      }
      final id = innerData['task_id'];
      if (id is! String || id.isEmpty) {
        throw ProviderFailure(
          message:
              'Kling text2video returned invalid task_id: ${id.runtimeType}',
        );
      }
      return VideoEntity(
        id: _uuid.v4(),
        taskId: id,
        prompt: req.prompt,
        provider: AIProvider.kling,
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
        baseUrl: 'https://api.klingai.com/v1',
        apiKey: _apiKey,
      );
      final r = await dio.post(
        '/videos/image2video',
        data: {
          'model': req.model,
          'prompt': req.prompt,
          'image': req.imageUrl,
        },
      );
      final data = r.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'Kling image2video returned non-map: ${data.runtimeType}',
        );
      }
      final innerData = data['data'];
      if (innerData is! Map<String, dynamic>) {
        throw ProviderFailure(
          message:
              'Kling image2video data is non-map: ${innerData.runtimeType}',
        );
      }
      final id = innerData['task_id'];
      if (id is! String || id.isEmpty) {
        throw ProviderFailure(
          message:
              'Kling image2video returned invalid task_id: ${id.runtimeType}',
        );
      }
      return VideoEntity(
        id: _uuid.v4(),
        taskId: id,
        prompt: req.prompt,
        provider: AIProvider.kling,
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
        baseUrl: 'https://api.klingai.com/v1',
        apiKey: _apiKey,
      );
      final r = await dio.post(
        '/videos/video2video',
        data: {
          'model': req.model,
          'prompt': req.prompt,
          'video': req.videoUrl,
        },
      );
      final data = r.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'Kling video2video returned non-map: ${data.runtimeType}',
        );
      }
      final innerData = data['data'];
      if (innerData is! Map<String, dynamic>) {
        throw ProviderFailure(
          message:
              'Kling video2video data is non-map: ${innerData.runtimeType}',
        );
      }
      final id = innerData['task_id'];
      if (id is! String || id.isEmpty) {
        throw ProviderFailure(
          message:
              'Kling video2video returned invalid task_id: ${id.runtimeType}',
        );
      }
      return VideoEntity(
        id: _uuid.v4(),
        taskId: id,
        prompt: req.prompt,
        provider: AIProvider.kling,
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
        baseUrl: 'https://api.klingai.com/v1',
        apiKey: _apiKey,
      );
      final r = await dio.get('/videos/text2video/$taskId');
      final outerData = r.data;
      if (outerData is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'Kling status returned non-map: ${outerData.runtimeType}',
        );
      }
      final data = outerData['data'];
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'Kling status data is non-map: ${data.runtimeType}',
        );
      }
      final taskStatus = data['task_status'];
      if (taskStatus is! String) {
        throw ProviderFailure(
          message:
              'Kling status returned non-string task_status: ${taskStatus.runtimeType}',
        );
      }
      final videos = (data['videos'] as List?) ?? <dynamic>[];
      String? videoUrl;
      if (videos.isNotEmpty) {
        final firstVideo = videos.first;
        if (firstVideo is Map<String, dynamic>) {
          videoUrl = firstVideo['url'] as String?;
        }
      }
      return VideoEntity(
        id: taskId,
        taskId: taskId,
        prompt: '',
        provider: AIProvider.kling,
        model: '',
        createdAt: DateTime.now(),
        url: videoUrl,
        status: _map(taskStatus),
        progress:
            int.tryParse(data['task_status_percent']?.toString() ?? '0') ?? 0,
      );
    });
  }

  @override
  Future<Either<Failure, List<ModelInfo>>> listModels() async {
    return const Right([
      ModelInfo(
        id: 'kling-v1-6',
        displayName: 'Kling 1.6 Pro',
        provider: 'kling',
      ),
      ModelInfo(
        id: 'kling-v1-5',
        displayName: 'Kling 1.5 Pro',
        provider: 'kling',
      ),
      ModelInfo(id: 'kling-v1', displayName: 'Kling 1.0', provider: 'kling'),
    ]);
  }

  @override
  Future<Either<Failure, bool>> healthCheck() async => const Right(true);

  VideoStatus _map(String s) => switch (s) {
        'succeed' => VideoStatus.complete,
        'failed' => VideoStatus.failed,
        'processing' => VideoStatus.processing,
        _ => VideoStatus.pending,
      };
}
