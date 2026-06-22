// Generic OpenAI-compatible Chat Service implementation
// Used by: DeepSeek, Mistral, Grok, Qwen, OpenRouter, LM Studio, HuggingFace TGI
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

class OpenAICompatibleService implements AIChatService {
  OpenAICompatibleService({
    required this.providerId,
    required this.defaultBaseUrl,
    required this.envBaseUrlKey,
    required this.staticModels,
  });

  final String providerId;
  final String defaultBaseUrl;
  final String envBaseUrlKey;
  final List<ModelInfo> staticModels;

  String? _apiKey;

  void setApiKey(String key) => _apiKey = key;

  String get _baseUrl => dotenv.maybeGet(envBaseUrlKey) ?? defaultBaseUrl;

  Dio get _dio => DioClient.create(baseUrl: _baseUrl, apiKey: _apiKey);

  @override
  Future<Either<Failure, String>> complete({
    required List<MessageEntity> messages,
    required ModelConfigEntity config,
    String? systemPrompt,
  }) async {
    if (_apiKey == null && providerId != 'lmstudio' && providerId != 'ollama') {
      return Left(
        UnauthorizedFailure(
          message: '$providerId API key not configured. Add it in Settings.',
        ),
      );
    }
    return safeApiCall(() async {
      final response = await _dio.post(
        '/chat/completions',
        data: _buildBody(messages, config, systemPrompt, stream: false),
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: '$providerId returned non-map response: ${data.runtimeType}',
        );
      }
      final choices = (data['choices'] as List?) ?? <dynamic>[];
      if (choices.isEmpty) {
        throw ProviderFailure(
          message: '$providerId returned empty choices array',
        );
      }
      final firstChoice = choices.first;
      if (firstChoice is! Map<String, dynamic>) {
        throw ProviderFailure(
          message:
              '$providerId returned non-map choice: ${firstChoice.runtimeType}',
        );
      }
      final message = firstChoice['message'];
      if (message is! Map<String, dynamic>) {
        throw ProviderFailure(
          message:
              '$providerId returned non-map message: ${message.runtimeType}',
        );
      }
      final content = message['content'];
      if (content is! String) {
        throw ProviderFailure(
          message:
              '$providerId returned non-string content: ${content.runtimeType}',
        );
      }
      return content;
    });
  }

  @override
  Stream<Either<Failure, String>> stream({
    required List<MessageEntity> messages,
    required ModelConfigEntity config,
    String? systemPrompt,
  }) async* {
    if (_apiKey == null && providerId != 'lmstudio' && providerId != 'ollama') {
      yield Left(
        UnauthorizedFailure(
          message: '$providerId API key not configured. Add it in Settings.',
        ),
      );
      return;
    }

    final streamDio =
        DioClient.createStream(baseUrl: _baseUrl, apiKey: _apiKey);
    try {
      final response = await streamDio.post(
        '/chat/completions',
        data: _buildBody(messages, config, systemPrompt, stream: true),
      );
      final stream = response.data.stream as Stream<List<int>>;
      await for (final chunk in stream) {
        final text = utf8.decode(chunk);
        final lines = text.split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            if (data == '[DONE]') return;
            try {
              final json = jsonDecode(data);
              if (json is! Map<String, dynamic>) continue;
              final choices = (json['choices'] as List?) ?? <dynamic>[];
              if (choices.isEmpty) continue;
              final firstChoice = choices.first;
              if (firstChoice is! Map<String, dynamic>) continue;
              final delta = firstChoice['delta'];
              if (delta is! Map<String, dynamic>) continue;
              final content = delta['content'];
              if (content is String && content.isNotEmpty) {
                yield Right(content);
              }
            } catch (e) {
              AppLogger.d(
                'OpenAI-compatible stream: skipped unparsable chunk: $e',
              );
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
    if (providerId == 'ollama' || providerId == 'lmstudio') {
      return safeApiCall(() async {
        final response = await _dio.get('/models');
        final data = response.data;
        if (data is! Map<String, dynamic>) {
          throw ProviderFailure(
            message:
                '$providerId /models returned non-map: ${data.runtimeType}',
          );
        }
        final models = (data['data'] as List?) ?? <dynamic>[];
        return models
            .map<ModelInfo?>((m) {
              if (m is! Map<String, dynamic>) return null;
              final id = m['id'];
              if (id is! String) return null;
              return ModelInfo(
                id: id,
                displayName: id,
                provider: providerId,
                contextWindow: 8192,
                costPer1kInput: 0.0,
                costPer1kOutput: 0.0,
              );
            })
            .whereType<ModelInfo>()
            .toList();
      });
    }
    return Right(staticModels);
  }

  @override
  Future<Either<Failure, bool>> healthCheck() async {
    return safeApiCall(() async {
      final response = await _dio.get('/models');
      return response.statusCode == 200;
    });
  }

  Map<String, dynamic> _buildBody(
    List<MessageEntity> messages,
    ModelConfigEntity config,
    String? systemPrompt, {
    required bool stream,
  }) {
    final apiMessages = <Map<String, dynamic>>[];

    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      apiMessages.add({'role': 'system', 'content': systemPrompt});
    }

    for (final m in messages) {
      apiMessages.add({
        'role': m.role.name,
        'content': m.attachments.isEmpty
            ? m.content
            : [
                {'type': 'text', 'text': m.content},
                ...m.attachments.map(
                  (a) => {
                    'type': 'image_url',
                    'image_url': {'url': a.url},
                  },
                ),
              ],
      });
    }

    return <String, dynamic>{
      'model': config.modelId,
      'messages': apiMessages,
      'temperature': config.temperature,
      'max_tokens': config.maxTokens,
      'top_p': config.topP,
      'stream': stream,
      if (config.stopSequences.isNotEmpty) 'stop': config.stopSequences,
      ...config.customParams,
    };
  }
}
