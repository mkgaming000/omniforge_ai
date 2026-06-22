// Google Gemini Chat Service
// Supports Gemini 1.5 Pro, Flash, 2.0 Flash, Ultra
import 'dart:async';
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../core/errors/error_handler.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/entities/message_entity.dart';
import '../../../domain/entities/model_config_entity.dart';
import 'ai_chat_service.dart';

class GeminiService implements AIChatService {
  GeminiService();

  String? _apiKey;
  Dio? _dioInstance;

  void setApiKey(String key) {
    _apiKey = key;
    // Invalidate cached Dio so the next access rebuilds with the new key.
    _dioInstance = null;
  }

  String get _baseUrl =>
      dotenv.maybeGet('GEMINI_BASE_URL') ??
      'https://generativelanguage.googleapis.com/v1beta';

  Dio get _dio {
    _dioInstance ??= DioClient.create(
      baseUrl: _baseUrl,
      apiKey: _apiKey,
      apiKeyHeader: 'X-goog-api-key',
    );
    return _dioInstance!;
  }

  @override
  Future<Either<Failure, String>> complete({
    required List<MessageEntity> messages,
    required ModelConfigEntity config,
    String? systemPrompt,
  }) async {
    if (_apiKey == null) {
      return const Left(
        UnauthorizedFailure(
          message: 'Google Gemini API key not configured.',
        ),
      );
    }
    return safeApiCall(() async {
      final response = await _dio.post(
        '/models/${config.modelId}:generateContent',
        data: _buildBody(messages, systemPrompt, config),
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'Gemini returned non-map response: ${data.runtimeType}',
        );
      }
      final candidates = (data['candidates'] as List?) ?? <dynamic>[];
      if (candidates.isEmpty) return '';
      final firstCandidate = candidates.first;
      if (firstCandidate is! Map<String, dynamic>) return '';
      final content = firstCandidate['content'];
      if (content is! Map<String, dynamic>) return '';
      final parts = (content['parts'] as List?) ?? <dynamic>[];
      return parts
          .whereType<Map<String, dynamic>>()
          .map((p) => p['text'] as String?)
          .whereType<String>()
          .join();
    });
  }

  @override
  Stream<Either<Failure, String>> stream({
    required List<MessageEntity> messages,
    required ModelConfigEntity config,
    String? systemPrompt,
  }) async* {
    if (_apiKey == null) {
      yield const Left(
        UnauthorizedFailure(
          message: 'Google Gemini API key not configured.',
        ),
      );
      return;
    }
    try {
      final streamDio = DioClient.createStream(
        baseUrl: _baseUrl,
        apiKey: _apiKey,
        apiKeyHeader: 'X-goog-api-key',
      );
      final response = await streamDio.post(
        '/models/${config.modelId}:streamGenerateContent?alt=sse',
        data: _buildBody(messages, systemPrompt, config),
      );

      final stream = response.data.stream as Stream<List<int>>;
      await for (final chunk in stream) {
        final text = utf8.decode(chunk);
        final lines = text.split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            try {
              final json = jsonDecode(line.substring(6));
              if (json is! Map<String, dynamic>) continue;
              final candidates = (json['candidates'] as List?) ?? <dynamic>[];
              if (candidates.isEmpty) continue;
              final firstCandidate = candidates.first;
              if (firstCandidate is! Map<String, dynamic>) continue;
              final content = firstCandidate['content'];
              if (content is! Map<String, dynamic>) continue;
              final parts = (content['parts'] as List?) ?? <dynamic>[];
              for (final p in parts) {
                if (p is! Map<String, dynamic>) continue;
                final t = p['text'];
                if (t is String && t.isNotEmpty) yield Right(t);
              }
            } catch (e) {
              AppLogger.d('Gemini stream: skipped unparsable chunk: $e');
            }
          }
        }
      }
    } catch (e, st) {
      yield Left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, List<ModelInfo>>> listModels() async {
    return const Right([
      ModelInfo(
        id: 'gemini-2.0-flash',
        displayName: 'Gemini 2.0 Flash',
        provider: 'google',
        contextWindow: 1048576,
        supportsVision: true,
        supportsTools: true,
        costPer1kInput: 0.0001,
        costPer1kOutput: 0.0004,
        maxOutputTokens: 8192,
      ),
      ModelInfo(
        id: 'gemini-1.5-pro',
        displayName: 'Gemini 1.5 Pro',
        provider: 'google',
        contextWindow: 2097152,
        supportsVision: true,
        supportsTools: true,
        costPer1kInput: 0.00125,
        costPer1kOutput: 0.005,
        maxOutputTokens: 8192,
      ),
      ModelInfo(
        id: 'gemini-1.5-flash',
        displayName: 'Gemini 1.5 Flash',
        provider: 'google',
        contextWindow: 1048576,
        supportsVision: true,
        supportsTools: true,
        costPer1kInput: 0.000075,
        costPer1kOutput: 0.0003,
        maxOutputTokens: 8192,
      ),
      ModelInfo(
        id: 'gemini-1.5-flash-8b',
        displayName: 'Gemini 1.5 Flash 8B',
        provider: 'google',
        contextWindow: 1048576,
        supportsVision: true,
        supportsTools: true,
        costPer1kInput: 0.0000375,
        costPer1kOutput: 0.00015,
        maxOutputTokens: 8192,
      ),
    ]);
  }

  @override
  Future<Either<Failure, bool>> healthCheck() async {
    if (_apiKey == null) return const Right(false);
    return safeApiCall(() async {
      final response = await _dio.get('/models');
      return response.statusCode == 200;
    });
  }

  Map<String, dynamic> _buildBody(
    List<MessageEntity> messages,
    String? systemPrompt,
    ModelConfigEntity config,
  ) {
    final contents = messages
        .where((m) => m.role != MessageRole.system)
        .map(
          (m) => {
            'role': m.role == MessageRole.assistant ? 'model' : 'user',
            'parts': [
              {'text': m.content},
              ...m.attachments
                  .where((a) => a.type == AttachmentType.image)
                  .map((a) {
                // Gemini's inline_data requires base64-encoded bytes,
                // not a URL. Use file_data for cloud-hosted files.
                if (a.url.startsWith('http://') ||
                    a.url.startsWith('https://')) {
                  return {
                    'file_data': {
                      'mime_type': a.mimeType ?? 'image/jpeg',
                      'file_uri': a.url,
                    },
                  };
                }
                // For data: URIs (already base64), strip the prefix.
                if (a.url.startsWith('data:')) {
                  final commaIdx = a.url.indexOf(',');
                  final b64 =
                      commaIdx >= 0 ? a.url.substring(commaIdx + 1) : a.url;
                  return {
                    'inline_data': {
                      'mime_type': a.mimeType ?? 'image/jpeg',
                      'data': b64,
                    },
                  };
                }
                // For local file paths or bare base64, treat as inline.
                return {
                  'inline_data': {
                    'mime_type': a.mimeType ?? 'image/jpeg',
                    'data': a.url,
                  },
                };
              }),
            ],
          },
        )
        .toList();

    final body = <String, dynamic>{
      'contents': contents,
      'generationConfig': {
        'temperature': config.temperature,
        'maxOutputTokens': config.maxTokens,
        'topP': config.topP,
        if (config.stopSequences.isNotEmpty)
          'stopSequences': config.stopSequences,
      },
    };

    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      body['systemInstruction'] = {
        'parts': [
          {'text': systemPrompt},
        ],
      };
    }
    return body;
  }
}
