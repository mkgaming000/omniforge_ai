// Udio Music Service - v1.5 generation
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../domain/entities/music_entity.dart';
import '../../../../core/constants/ai_providers.dart';

class UdioService {
  UdioService();
  String? _apiKey;
  void setApiKey(String key) => _apiKey = key;
  final _uuid = const Uuid();

  Future<Either<Failure, MusicEntity>> generate(
    MusicGenerationRequest req,
  ) async {
    if (_apiKey == null) {
      return const Left(UnauthorizedFailure(message: 'Udio API key not set'));
    }
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: 'https://api.udio.com/v1',
        apiKey: _apiKey,
      );
      final r = await dio.post(
        '/generate',
        data: {
          'prompt': req.prompt,
          'model': req.model,
          'duration': req.duration,
          'instrumental': req.instrumental,
        },
      );
      final data = r.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'Udio generate returned non-map: ${data.runtimeType}',
        );
      }
      final id = data['job_id'];
      if (id is! String || id.isEmpty) {
        throw ProviderFailure(
          message: 'Udio generate returned invalid job_id: ${id.runtimeType}',
        );
      }
      return MusicEntity(
        id: _uuid.v4(),
        prompt: req.prompt,
        provider: AIProvider.udio,
        model: req.model,
        createdAt: DateTime.now(),
        duration: req.duration,
        status: MusicStatus.processing,
        metadata: {'taskId': id},
      );
    });
  }

  Future<Either<Failure, MusicEntity>> getStatus(String taskId) async {
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: 'https://api.udio.com/v1',
        apiKey: _apiKey,
      );
      final r = await dio.get('/jobs/$taskId');
      final data = r.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'Udio status returned non-map: ${data.runtimeType}',
        );
      }
      final statusStr = data['status'];
      if (statusStr is! String) {
        throw ProviderFailure(
          message:
              'Udio status returned non-string status: ${statusStr.runtimeType}',
        );
      }
      return MusicEntity(
        id: taskId,
        prompt: '',
        provider: AIProvider.udio,
        model: '',
        createdAt: DateTime.now(),
        audioUrl: data['audio_url'] as String?,
        title: data['title'] as String?,
        status: _map(statusStr),
      );
    });
  }

  MusicStatus _map(String s) => switch (s) {
        'complete' => MusicStatus.complete,
        'failed' => MusicStatus.failed,
        _ => MusicStatus.processing,
      };
}
