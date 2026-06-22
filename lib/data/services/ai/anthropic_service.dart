// Anthropic Claude Chat Service
// Supports Claude 3.5 Sonnet, Opus, Haiku, and Claude 3 series
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

class AnthropicService implements AIChatService {
  AnthropicService();

  static const _apiVersion = '2023-06-01';

  String? _apiKey;

  void setApiKey(String key) => _apiKey = key;

  Dio get _dio {
    final dio = DioClient.create(
      baseUrl: dotenv.maybeGet('ANTHROPIC_BASE_URL') ??
          'https://api.anthropic.com/v1',
      apiKey: _apiKey,
      // Anthropic's Messages API authenticates with `x-api-key` + an
      // `anthropic-version` header — NOT `Authorization: Bearer`. Sending
      // Bearer causes every request to 401.
      apiKeyHeader: 'x-api-key',
      defaultHeaders: {
        'anthropic-version': _apiVersion,
      },
    );
    return dio;
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
          message: 'Anthropic API key not configured. Add it in Settings.',
        ),
      );
    }
    return safeApiCall(() async {
      final response = await _dio.post(
        '/messages',
        data: _buildBody(messages, config, systemPrompt),
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'Anthropic returned non-map response: ${data.runtimeType}',
        );
      }
      final content = (data['content'] as List?) ?? <dynamic>[];
      if (content.isEmpty) {
        throw const ProviderFailure(
          message: 'Anthropic returned empty content array',
        );
      }
      return content
          .whereType<Map<String, dynamic>>()
          .where((c) => c['type'] == 'text')
          .map((c) => (c['text'] as String?) ?? '')
          .where((s) => s.isNotEmpty)
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
          message: 'Anthropic API key not configured. Add it in Settings.',
        ),
      );
      return;
    }

    final streamDio = DioClient.createStream(
      baseUrl: dotenv.maybeGet('ANTHROPIC_BASE_URL') ??
          'https://api.anthropic.com/v1',
      apiKey: _apiKey,
      apiKeyHeader: 'x-api-key',
    );
    streamDio.options.headers['anthropic-version'] = _apiVersion;

    try {
      final body = _buildBody(messages, config, systemPrompt);
      body['stream'] = true;
      final response = await streamDio.post('/messages', data: body);

      final stream = response.data.stream as Stream<List<int>>;
      await for (final chunk in stream) {
        final text = utf8.decode(chunk);
        final lines = text.split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            try {
              final json = jsonDecode(data);
              if (json is! Map<String, dynamic>) continue;
              final type = json['type'];
              if (type is! String) continue;
              if (type == 'content_block_delta') {
                final delta = json['delta'];
                if (delta is! Map<String, dynamic>) continue;
                if (delta['type'] == 'text_delta') {
                  final text = delta['text'];
                  if (text is String && text.isNotEmpty) yield Right(text);
                }
              }
            } catch (e) {
              // Malformed/partial SSE chunk — skip it but keep the
              // stream alive instead of silently losing the error.
              AppLogger.d('Anthropic stream: skipped unparsable chunk: $e');
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
    if (_apiKey == null) {
      return const Right(_staticModels);
    }
    return safeApiCall(() async {
      try {
        final response = await _dio.get('/models');
        final data = response.data;
        if (data is! Map<String, dynamic>) {
          return _staticModels;
        }
        final models = (data['data'] as List?) ?? <dynamic>[];
        return models
            .map<ModelInfo?>((m) {
              if (m is! Map<String, dynamic>) return null;
              final id = m['id'];
              if (id is! String) return null;
              return ModelInfo(
                id: id,
                displayName: (m['display_name'] as String?) ?? _prettyName(id),
                provider: 'anthropic',
                contextWindow: 200000,
                supportsVision: true,
                supportsTools: true,
                costPer1kInput: _inputCost(id),
                costPer1kOutput: _outputCost(id),
                maxOutputTokens: 8192,
              );
            })
            .whereType<ModelInfo>()
            .toList();
      } catch (_) {
        return _staticModels;
      }
    });
  }

  @override
  Future<Either<Failure, bool>> healthCheck() async {
    if (_apiKey == null) return const Right(false);
    return safeApiCall(() async {
      final response = await _dio.get('/models');
      return response.statusCode == 200;
    });
  }

  static const _staticModels = <ModelInfo>[
    ModelInfo(
      id: 'claude-3-5-sonnet-20241022',
      displayName: 'Claude 3.5 Sonnet v2',
      provider: 'anthropic',
      contextWindow: 200000,
      supportsVision: true,
      supportsTools: true,
      costPer1kInput: 0.003,
      costPer1kOutput: 0.015,
      maxOutputTokens: 8192,
    ),
    ModelInfo(
      id: 'claude-3-5-haiku-20241022',
      displayName: 'Claude 3.5 Haiku',
      provider: 'anthropic',
      contextWindow: 200000,
      supportsVision: true,
      supportsTools: true,
      costPer1kInput: 0.0008,
      costPer1kOutput: 0.004,
      maxOutputTokens: 8192,
    ),
    ModelInfo(
      id: 'claude-3-opus-20240229',
      displayName: 'Claude 3 Opus',
      provider: 'anthropic',
      contextWindow: 200000,
      supportsVision: true,
      supportsTools: true,
      costPer1kInput: 0.015,
      costPer1kOutput: 0.075,
      maxOutputTokens: 4096,
    ),
  ];

  Map<String, dynamic> _buildBody(
    List<MessageEntity> messages,
    ModelConfigEntity config,
    String? systemPrompt,
  ) {
    final apiMessages = messages
        .where((m) => m.role != MessageRole.system)
        .map(
          (m) => {
            'role': m.role == MessageRole.assistant ? 'assistant' : 'user',
            'content': m.attachments.isEmpty
                ? m.content
                : [
                    if (m.content.isNotEmpty)
                      {'type': 'text', 'text': m.content},
                    ...m.attachments
                        .where((a) => a.type == AttachmentType.image)
                        .map(
                          (a) => {
                            'type': 'image',
                            'source': {
                              'type': 'url',
                              'url': a.url,
                            },
                          },
                        ),
                  ],
          },
        )
        .toList();

    final body = <String, dynamic>{
      'model': config.modelId,
      'messages': apiMessages,
      'max_tokens': config.maxTokens,
      'temperature': config.temperature,
      'top_p': config.topP,
    };

    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      body['system'] = systemPrompt;
    }
    if (config.stopSequences.isNotEmpty) {
      body['stop_sequences'] = config.stopSequences;
    }
    body.addAll(config.customParams);
    return body;
  }

  String _prettyName(String id) {
    if (id.contains('sonnet')) return 'Claude Sonnet';
    if (id.contains('haiku')) return 'Claude Haiku';
    if (id.contains('opus')) return 'Claude Opus';
    return id;
  }

  double _inputCost(String id) {
    if (id.contains('opus')) return 0.015;
    if (id.contains('sonnet')) return 0.003;
    if (id.contains('haiku')) return 0.00025;
    return 0.003;
  }

  double _outputCost(String id) {
    if (id.contains('opus')) return 0.075;
    if (id.contains('sonnet')) return 0.015;
    if (id.contains('haiku')) return 0.00125;
    return 0.015;
  }
}
