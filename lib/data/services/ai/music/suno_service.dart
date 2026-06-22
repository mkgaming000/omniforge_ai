// Suno Music Service - v4 generation
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../domain/entities/music_entity.dart';
import '../../../../core/constants/ai_providers.dart';

class SunoService {
  SunoService();
  String? _apiKey;
  void setApiKey(String key) => _apiKey = key;
  final _uuid = const Uuid();

  Future<Either<Failure, MusicEntity>> generate(
    MusicGenerationRequest req,
  ) async {
    if (_apiKey == null) {
      return const Left(UnauthorizedFailure(message: 'Suno API key not set'));
    }
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: 'https://api.suno.ai/v1',
        apiKey: _apiKey,
      );
      final r = await dio.post(
        '/generations',
        data: {
          'prompt': req.prompt,
          'model': req.model,
          'duration': req.duration,
          'tags': req.tags,
          'instrumental': req.instrumental,
          'lyrics': req.lyrics,
          'title': req.title,
        },
      );
      final data = r.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'Suno generate returned non-map: ${data.runtimeType}',
        );
      }
      final id = data['id'];
      if (id is! String || id.isEmpty) {
        throw ProviderFailure(
          message: 'Suno generate returned invalid id: ${id.runtimeType}',
        );
      }
      return MusicEntity(
        id: _uuid.v4(),
        prompt: req.prompt,
        provider: AIProvider.suno,
        model: req.model,
        createdAt: DateTime.now(),
        title: req.title,
        lyrics: req.lyrics,
        duration: req.duration,
        tags: req.tags,
        style: req.style,
        status: MusicStatus.processing,
        metadata: {'taskId': id},
      );
    });
  }

  Future<Either<Failure, MusicEntity>> getStatus(String taskId) async {
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: 'https://api.suno.ai/v1',
        apiKey: _apiKey,
      );
      final r = await dio.get('/generations/$taskId');
      final data = r.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'Suno status returned non-map: ${data.runtimeType}',
        );
      }
      final statusStr = data['status'];
      if (statusStr is! String) {
        throw ProviderFailure(
          message:
              'Suno status returned non-string status: ${statusStr.runtimeType}',
        );
      }
      return MusicEntity(
        id: taskId,
        prompt: data['prompt'] as String? ?? '',
        provider: AIProvider.suno,
        model: data['model'] as String? ?? '',
        createdAt: DateTime.now(),
        audioUrl: data['audio_url'] as String?,
        title: data['title'] as String?,
        lyrics: data['lyrics'] as String?,
        duration: data['duration'] as int? ?? 30,
        status: _map(statusStr),
      );
    });
  }

  MusicStatus _map(String s) => switch (s) {
        'complete' => MusicStatus.complete,
        'failed' => MusicStatus.failed,
        'streaming' => MusicStatus.streaming,
        _ => MusicStatus.processing,
      };
}
