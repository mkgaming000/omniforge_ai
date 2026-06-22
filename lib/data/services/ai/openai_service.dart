// OpenAI Chat Completions Service
// Supports GPT-4o, GPT-4 Turbo, GPT-3.5 Turbo, o1, o3 series
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

class OpenAIService implements AIChatService {
  OpenAIService();

  Dio? _dioInstance;
  String? _apiKey;
  bool _authInterceptorInstalled = false;

  Dio get _dio {
    _dioInstance ??= DioClient.create(
      baseUrl:
          dotenv.maybeGet('OPENAI_BASE_URL') ?? 'https://api.openai.com/v1',
    );
    return _dioInstance!;
  }

  /// Returns the currently-cached API key (if any).
  String? get apiKey => _apiKey;

  /// Inject the API key. Adds the auth interceptor exactly once; subsequent
  /// calls with the same key are no-ops, calls with a different key replace
  /// the existing interceptor.
  void setApiKey(String key) {
    if (_apiKey == key && _authInterceptorInstalled) return;
    _apiKey = key;
    _dio.interceptors.removeWhere((i) => i is _AuthInterceptor);
    _dio.interceptors.add(_AuthInterceptor(key));
    _authInterceptorInstalled = true;
  }

  @override
  Future<Either<Failure, String>> complete({
    required List<MessageEntity> messages,
    required ModelConfigEntity config,
    String? systemPrompt,
  }) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      return const Left(
        UnauthorizedFailure(
          message: 'OpenAI API key not configured. Add it in Settings.',
        ),
      );
    }

    return safeApiCall(() async {
      final response = await _dio.post(
        '/chat/completions',
        data: _buildRequestBody(messages, config, systemPrompt, stream: false),
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'OpenAI returned non-map response: ${data.runtimeType}',
        );
      }
      final choices = (data['choices'] as List?) ?? <dynamic>[];
      if (choices.isEmpty) {
        throw const ProviderFailure(
          message: 'OpenAI returned empty choices array',
        );
      }
      final firstChoice = choices.first;
      if (firstChoice is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'OpenAI returned non-map choice: ${firstChoice.runtimeType}',
        );
      }
      final message = firstChoice['message'];
      if (message is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'OpenAI returned non-map message: ${message.runtimeType}',
        );
      }
      final content = message['content'];
      if (content is! String) {
        throw ProviderFailure(
          message: 'OpenAI returned non-string content: ${content.runtimeType}',
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
    if (_apiKey == null || _apiKey!.isEmpty) {
      yield const Left(
        UnauthorizedFailure(
          message: 'OpenAI API key not configured. Add it in Settings.',
        ),
      );
      return;
    }

    final streamDio = DioClient.createStream(
      baseUrl:
          dotenv.maybeGet('OPENAI_BASE_URL') ?? 'https://api.openai.com/v1',
      apiKey: _apiKey,
    );

    try {
      final response = await streamDio.post(
        '/chat/completions',
        data: _buildRequestBody(messages, config, systemPrompt, stream: true),
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
              // Skip malformed chunks
              AppLogger.d('OpenAI stream: skipped unparsable chunk: $e');
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
    if (_apiKey == null || _apiKey!.isEmpty) {
      return const Left(UnauthorizedFailure(message: 'API key not set'));
    }

    return safeApiCall(() async {
      final response = await _dio.get('/models');
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'OpenAI /models returned non-map: ${data.runtimeType}',
        );
      }
      final models = (data['data'] as List?) ?? <dynamic>[];
      return models
          .map<ModelInfo?>((m) {
            if (m is! Map<String, dynamic>) return null;
            final id = m['id'];
            if (id is! String) return null;
            if (_isOpenAIChatModel(id)) {
              return ModelInfo(
                id: id,
                displayName: _prettyName(id),
                provider: 'openai',
                contextWindow: _contextWindowFor(id),
                supportsVision: id.contains('vision') || id.contains('4o'),
                supportsTools: !id.startsWith('o1'),
                supportsStreaming: !id.startsWith('o1-preview'),
                costPer1kInput: _inputCost(id),
                costPer1kOutput: _outputCost(id),
                maxOutputTokens: _maxOutput(id),
              );
            }
            return null;
          })
          .whereType<ModelInfo>()
          .toList();
    });
  }

  @override
  Future<Either<Failure, bool>> healthCheck() async {
    if (_apiKey == null || _apiKey!.isEmpty) return const Right(false);
    return safeApiCall(() async {
      final response = await _dio.get('/models');
      return response.statusCode == 200;
    });
  }

  Map<String, dynamic> _buildRequestBody(
    List<MessageEntity> messages,
    ModelConfigEntity config,
    String? systemPrompt, {
    required bool stream,
  }) {
    final List<Map<String, dynamic>> apiMessages = [];

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
                    'type': a.type == AttachmentType.image
                        ? 'image_url'
                        : 'input_text',
                    'image_url': {'url': a.url},
                  },
                ),
              ],
      });
    }

    final body = <String, dynamic>{
      'model': config.modelId,
      'messages': apiMessages,
      'temperature': config.temperature,
      'max_tokens': config.maxTokens,
      'top_p': config.topP,
      'frequency_penalty': config.frequencyPenalty,
      'presence_penalty': config.presencePenalty,
      'stream': stream,
    };

    if (config.stopSequences.isNotEmpty) {
      body['stop'] = config.stopSequences;
    }
    if (config.seed != null) {
      body['seed'] = config.seed;
    }
    if (config.responseFormat != null) {
      body['response_format'] = {'type': config.responseFormat};
    }
    body.addAll(config.customParams);
    return body;
  }

  bool _isOpenAIChatModel(String id) =>
      id.startsWith('gpt-') ||
      id.startsWith('o1') ||
      id.startsWith('o3') ||
      id.startsWith('chatgpt');

  String _prettyName(String id) {
    final map = {
      'gpt-4o': 'GPT-4o',
      'gpt-4o-mini': 'GPT-4o Mini',
      'gpt-4-turbo': 'GPT-4 Turbo',
      'gpt-4': 'GPT-4',
      'gpt-3.5-turbo': 'GPT-3.5 Turbo',
      'o1-preview': 'o1 Preview',
      'o1-mini': 'o1 Mini',
      'o3-mini': 'o3 Mini',
    };
    return map[id] ?? id;
  }

  int _contextWindowFor(String id) {
    if (id.contains('4o')) return 128000;
    if (id.startsWith('o1')) return 200000;
    if (id.startsWith('o3')) return 200000;
    if (id.contains('turbo')) return 128000;
    if (id == 'gpt-4') return 8192;
    if (id == 'gpt-3.5-turbo') return 16385;
    return 8192;
  }

  int _maxOutput(String id) {
    if (id.startsWith('o1')) return 100000;
    if (id.contains('4o')) return 16384;
    return 4096;
  }

  double _inputCost(String id) {
    if (id == 'gpt-4o') return 0.0025;
    if (id == 'gpt-4o-mini') return 0.00015;
    if (id == 'gpt-4-turbo') return 0.01;
    if (id == 'gpt-4') return 0.03;
    if (id == 'gpt-3.5-turbo') return 0.0005;
    if (id.startsWith('o1')) return 0.015;
    return 0.001;
  }

  double _outputCost(String id) {
    if (id == 'gpt-4o') return 0.01;
    if (id == 'gpt-4o-mini') return 0.0006;
    if (id == 'gpt-4-turbo') return 0.03;
    if (id == 'gpt-4') return 0.06;
    if (id == 'gpt-3.5-turbo') return 0.0015;
    if (id.startsWith('o1')) return 0.06;
    return 0.002;
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this.apiKey);
  final String apiKey;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Authorization'] = 'Bearer $apiKey';
    handler.next(options);
  }
}
