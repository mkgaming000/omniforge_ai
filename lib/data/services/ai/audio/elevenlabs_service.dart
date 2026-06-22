// ElevenLabs Voice Service - TTS, voice cloning, speech-to-speech
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/dio_client.dart';

class ElevenLabsService {
  ElevenLabsService();
  String? _apiKey;
  void setApiKey(String key) => _apiKey = key;

  /// Synthesize speech from text.
  Future<Either<Failure, List<int>>> textToSpeech({
    required String text,
    required String voiceId,
    String model = 'eleven_multilingual_v2',
    double stability = 0.5,
    double similarityBoost = 0.75,
    double style = 0.0,
    bool speakerBoost = true,
  }) async {
    if (_apiKey == null) {
      return const Left(
        UnauthorizedFailure(
          message: 'ElevenLabs API key not configured.',
        ),
      );
    }
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: 'https://api.elevenlabs.io/v1',
        apiKey: _apiKey,
        apiKeyHeader: 'xi-api-key',
      );
      final response = await dio.post(
        '/text-to-speech/$voiceId',
        data: {
          'text': text,
          'model_id': model,
          'voice_settings': {
            'stability': stability,
            'similarity_boost': similarityBoost,
            'style': style,
            'use_speaker_boost': speakerBoost,
          },
        },
        options: Options(responseType: ResponseType.bytes),
      );
      final data = response.data;
      if (data is! List) {
        throw ProviderFailure(
          message:
              'ElevenLabs TTS returned non-bytes payload: ${data.runtimeType}',
        );
      }
      if (data.isEmpty) {
        throw const ProviderFailure(
          message: 'ElevenLabs TTS returned empty audio payload',
        );
      }
      return data.cast<int>();
    });
  }

  /// Stream TTS audio in chunks for low-latency playback.
  Stream<Either<Failure, List<int>>> streamTts({
    required String text,
    required String voiceId,
    String model = 'eleven_multilingual_v2',
  }) async* {
    if (_apiKey == null) {
      yield const Left(UnauthorizedFailure(message: 'API key not set'));
      return;
    }
    try {
      final dio = DioClient.createStream(
        baseUrl: 'https://api.elevenlabs.io/v1',
        apiKey: _apiKey,
        apiKeyHeader: 'xi-api-key',
      );
      final response = await dio.post(
        '/text-to-speech/$voiceId/stream',
        data: {
          'text': text,
          'model_id': model,
        },
      );
      final stream = response.data.stream as Stream<List<int>>;
      await for (final chunk in stream) {
        yield Right(chunk);
      }
    } catch (e, st) {
      yield Left(ErrorHandler.handle(e, st));
    }
  }

  /// List available voices.
  Future<Either<Failure, List<Map<String, dynamic>>>> listVoices() async {
    if (_apiKey == null) {
      return const Left(UnauthorizedFailure(message: 'API key not set'));
    }
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: 'https://api.elevenlabs.io/v1',
        apiKey: _apiKey,
        apiKeyHeader: 'xi-api-key',
      );
      final r = await dio.get('/voices');
      final data = r.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'ElevenLabs /voices returned non-map: ${data.runtimeType}',
        );
      }
      final voices = (data['voices'] as List?) ?? <dynamic>[];
      return voices.whereType<Map<String, dynamic>>().toList();
    });
  }

  /// Clone a voice from audio samples.
  ///
  /// [sampleFilePaths] must be LOCAL file paths on the device's filesystem.
  /// If you have URLs instead, download them to a temp directory first
  /// and pass the resulting file paths here.
  Future<Either<Failure, String>> cloneVoice({
    required String name,
    required List<String> sampleFilePaths,
    String? description,
  }) async {
    if (_apiKey == null) {
      return const Left(UnauthorizedFailure(message: 'API key not set'));
    }
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: 'https://api.elevenlabs.io/v1',
        apiKey: _apiKey,
        apiKeyHeader: 'xi-api-key',
      );
      final formMap = <String, dynamic>{
        'name': name,
        if (description != null) 'description': description,
      };
      final fileEntries = <MapEntry<String, MultipartFile>>[];
      for (final path in sampleFilePaths) {
        if (path.isEmpty) continue;
        // MultipartFile.fromFile requires a local filesystem path.
        // If the caller passed a URL, this will throw FileSystemException;
        // they should download to a temp file first.
        final mp = await MultipartFile.fromFile(
          path,
          filename: path.split('/').last,
        );
        fileEntries.add(MapEntry('files', mp));
      }
      final form = FormData.fromMap(formMap);
      form.files.addAll(fileEntries);
      final r = await dio.post('/voices/add', data: form);
      final data = r.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'ElevenLabs clone returned non-map: ${data.runtimeType}',
        );
      }
      final voiceId = data['voice_id'];
      if (voiceId is! String || voiceId.isEmpty) {
        throw ProviderFailure(
          message:
              'ElevenLabs clone returned invalid voice_id: ${voiceId.runtimeType}',
        );
      }
      return voiceId;
    });
  }
}
