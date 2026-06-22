// AssemblyAI Speech-to-Text Service
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/dio_client.dart';

class AssemblyAIService {
  AssemblyAIService();
  String? _apiKey;
  void setApiKey(String key) => _apiKey = key;

  /// Upload audio file and start transcription
  Future<Either<Failure, String>> startTranscription({
    required String audioUrl,
    bool speakerLabels = true,
    bool autoChapters = false,
    bool autoHighlights = false,
    bool sentimentAnalysis = false,
    bool summarize = false,
  }) async {
    if (_apiKey == null) {
      return const Left(
        UnauthorizedFailure(
          message: 'AssemblyAI API key not configured.',
        ),
      );
    }
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: 'https://api.assemblyai.com/v2',
        apiKey: _apiKey,
      );
      final r = await dio.post(
        '/transcript',
        data: {
          'audio_url': audioUrl,
          'speaker_labels': speakerLabels,
          'auto_chapters': autoChapters,
          'auto_highlights': autoHighlights,
          'sentiment_analysis': sentimentAnalysis,
          'summarization': summarize,
        },
      );
      final data = r.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message:
              'AssemblyAI transcript start returned non-map: ${data.runtimeType}',
        );
      }
      final id = data['id'];
      if (id is! String || id.isEmpty) {
        throw ProviderFailure(
          message:
              'AssemblyAI transcript start returned invalid id: ${id.runtimeType}',
        );
      }
      return id;
    });
  }

  /// Poll for transcription completion
  Future<Either<Failure, Map<String, dynamic>>> getTranscription(
    String id,
  ) async {
    if (_apiKey == null) {
      return const Left(UnauthorizedFailure(message: 'API key not set'));
    }
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: 'https://api.assemblyai.com/v2',
        apiKey: _apiKey,
      );
      final r = await dio.get('/transcript/$id');
      final data = r.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message:
              'AssemblyAI getTranscription returned non-map: ${data.runtimeType}',
        );
      }
      return data;
    });
  }

  /// LeMUR - LLM-powered audio Q&A and summarization
  Future<Either<Failure, Map<String, dynamic>>> lemur({
    required String transcriptId,
    required String prompt,
    String model = 'default',
  }) async {
    if (_apiKey == null) {
      return const Left(UnauthorizedFailure(message: 'API key not set'));
    }
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: 'https://api.assemblyai.com/v2',
        apiKey: _apiKey,
      );
      final r = await dio.post(
        '/lemur',
        data: {
          'transcript_ids': [transcriptId],
          'prompt': prompt,
          'model': model,
        },
      );
      final data = r.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'AssemblyAI lemur returned non-map: ${data.runtimeType}',
        );
      }
      return data;
    });
  }
}
