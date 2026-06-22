// Luma AI Dream Machine Video Service
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../domain/entities/video_entity.dart';
import '../../../../core/constants/ai_providers.dart';
import 'ai_video_service.dart';

class LumaService implements AIVideoService {
  LumaService();
  String? _apiKey;
  void setApiKey(String key) => _apiKey = key;
  final _uuid = const Uuid();

  @override
  Future<Either<Failure, VideoEntity>> textToVideo(
    VideoGenerationRequest req,
  ) async {
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: 'https://api.lumalabs.ai/v1',
        apiKey: _apiKey,
      );
      final r = await dio.post(
        '/generations',
        data: {
          'prompt': req.prompt,
          'model': req.model,
          'duration': req.duration,
          'aspect_ratio': req.width > req.height ? '16:9' : '9:16',
        },
      );
      final data = r.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'Luma text_to_video returned non-map: ${data.runtimeType}',
        );
      }
      final id = data['id'];
      if (id is! String || id.isEmpty) {
        throw ProviderFailure(
          message: 'Luma text_to_video returned invalid id: ${id.runtimeType}',
        );
      }
      return VideoEntity(
        id: _uuid.v4(),
        taskId: id,
        prompt: req.prompt,
        provider: AIProvider.luma,
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
        baseUrl: 'https://api.lumalabs.ai/v1',
        apiKey: _apiKey,
      );
      final r = await dio.post(
        '/generations',
        data: {
          'prompt': req.prompt,
          'keyframes': {
            'frame0': {'type': 'image', 'url': req.imageUrl},
          },
        },
      );
      final data = r.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'Luma image_to_video returned non-map: ${data.runtimeType}',
        );
      }
      final id = data['id'];
      if (id is! String || id.isEmpty) {
        throw ProviderFailure(
          message: 'Luma image_to_video returned invalid id: ${id.runtimeType}',
        );
      }
      return VideoEntity(
        id: _uuid.v4(),
        taskId: id,
        prompt: req.prompt,
        provider: AIProvider.luma,
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
        baseUrl: 'https://api.lumalabs.ai/v1',
        apiKey: _apiKey,
      );
      final r = await dio.post(
        '/generations',
        data: {
          'prompt': req.prompt,
          'keyframes': {
            'frame0': {'type': 'video', 'url': req.videoUrl},
          },
        },
      );
      final data = r.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'Luma video_to_video returned non-map: ${data.runtimeType}',
        );
      }
      final id = data['id'];
      if (id is! String || id.isEmpty) {
        throw ProviderFailure(
          message: 'Luma video_to_video returned invalid id: ${id.runtimeType}',
        );
      }
      return VideoEntity(
        id: _uuid.v4(),
        taskId: id,
        prompt: req.prompt,
        provider: AIProvider.luma,
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
        baseUrl: 'https://api.lumalabs.ai/v1',
        apiKey: _apiKey,
      );
      final r = await dio.get('/generations/$taskId');
      final data = r.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'Luma status returned non-map: ${data.runtimeType}',
        );
      }
      final stateStr = data['state'];
      if (stateStr is! String) {
        throw ProviderFailure(
          message:
              'Luma status returned non-string state: ${stateStr.runtimeType}',
        );
      }
      final assets = data['assets'];
      final Map<String, dynamic> assetsMap =
          assets is Map<String, dynamic> ? assets : <String, dynamic>{};
      return VideoEntity(
        id: taskId,
        taskId: taskId,
        prompt: data['prompt'] as String? ?? '',
        provider: AIProvider.luma,
        model: '',
        createdAt: DateTime.now(),
        url: assetsMap['video'] as String?,
        status: _map(stateStr),
      );
    });
  }

  @override
  Future<Either<Failure, List<ModelInfo>>> listModels() async {
    return const Right([
      ModelInfo(id: 'ray2', displayName: 'Ray 2', provider: 'luma'),
      ModelInfo(id: 'ray1-6', displayName: 'Ray 1.6', provider: 'luma'),
      ModelInfo(
        id: 'dream-machine',
        displayName: 'Dream Machine',
        provider: 'luma',
      ),
    ]);
  }

  @override
  Future<Either<Failure, bool>> healthCheck() async => const Right(true);

  VideoStatus _map(String s) => switch (s) {
        'completed' => VideoStatus.complete,
        'failed' => VideoStatus.failed,
        'processing' => VideoStatus.processing,
        _ => VideoStatus.pending,
      };
}
