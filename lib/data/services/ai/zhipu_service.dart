// Zhipu AI (BigModel) Chat Service
// Supports GLM-5.2, GLM-4-Plus, GLM-4-Air, GLM-4-Long, GLM-4-Flash, GLM-4V, GLM-4-9B
// API docs: https://open.bigmodel.cn/dev/api
//
// Zhipu's API is OpenAI-compatible at /api/paas/v4/chat/completions.
// Auth uses a JWT derived from the API key (id:secret), but the platform
// also accepts the raw API key as a Bearer token since 2024-Q3.
import 'dart:async';
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../core/errors/error_handler.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/entities/message_entity.dart';
import '../../../domain/entities/model_config_entity.dart';
import 'ai_chat_service.dart';

class ZhipuService implements AIChatService {
  ZhipuService();

  String? _apiKey;
  void setApiKey(String key) => _apiKey = key;

  String get _baseUrl =>
      dotenv.maybeGet('ZHIPU_BASE_URL') ??
      'https://open.bigmodel.cn/api/paas/v4';

  /// List of GLM models exposed by the Zhipu platform, with pricing as of 2026.
  /// GLM-5.2 is the flagship reasoning + vision model.
  static const _staticModels = <ModelInfo>[
    ModelInfo(
      id: 'glm-5.2',
      displayName: 'GLM-5.2',
      provider: 'zhipu',
      contextWindow: 256000,
      supportsVision: true,
      supportsTools: true,
      supportsStreaming: true,
      costPer1kInput: 0.005,
      costPer1kOutput: 0.02,
      maxOutputTokens: 16384,
      description: 'Flagship GLM-5.2 with reasoning, vision, and tool use',
    ),
    ModelInfo(
      id: 'glm-5.2-flash',
      displayName: 'GLM-5.2 Flash',
      provider: 'zhipu',
      contextWindow: 256000,
      supportsVision: true,
      supportsTools: true,
      supportsStreaming: true,
      costPer1kInput: 0.0005,
      costPer1kOutput: 0.002,
      maxOutputTokens: 8192,
      description: 'Fast, cheap GLM-5.2 variant for high-volume workloads',
    ),
    ModelInfo(
      id: 'glm-5',
      displayName: 'GLM-5',
      provider: 'zhipu',
      contextWindow: 200000,
      supportsVision: true,
      supportsTools: true,
      supportsStreaming: true,
      costPer1kInput: 0.003,
      costPer1kOutput: 0.012,
      maxOutputTokens: 8192,
      description: 'Previous-generation GLM-5 base model',
    ),
    ModelInfo(
      id: 'glm-4-plus',
      displayName: 'GLM-4-Plus',
      provider: 'zhipu',
      contextWindow: 128000,
      supportsVision: true,
      supportsTools: true,
      supportsStreaming: true,
      costPer1kInput: 0.0035,
      costPer1kOutput: 0.014,
      maxOutputTokens: 4096,
      description: 'GLM-4 Plus - balanced quality and cost',
    ),
    ModelInfo(
      id: 'glm-4-air',
      displayName: 'GLM-4-Air',
      provider: 'zhipu',
      contextWindow: 128000,
      supportsVision: false,
      supportsTools: true,
      supportsStreaming: true,
      costPer1kInput: 0.0005,
      costPer1kOutput: 0.001,
      maxOutputTokens: 4096,
      description: 'GLM-4 Air - low-cost, high-throughput model',
    ),
    ModelInfo(
      id: 'glm-4-airx',
      displayName: 'GLM-4-AirX',
      provider: 'zhipu',
      contextWindow: 8000,
      supportsVision: false,
      supportsTools: true,
      supportsStreaming: true,
      costPer1kInput: 0.001,
      costPer1kOutput: 0.001,
      maxOutputTokens: 4096,
      description: 'GLM-4 AirX - ultra-low latency variant',
    ),
    ModelInfo(
      id: 'glm-4-long',
      displayName: 'GLM-4-Long',
      provider: 'zhipu',
      contextWindow: 1000000,
      supportsVision: false,
      supportsTools: true,
      supportsStreaming: true,
      costPer1kInput: 0.001,
      costPer1kOutput: 0.001,
      maxOutputTokens: 4096,
      description: 'GLM-4 Long - 1M token context window',
    ),
    ModelInfo(
      id: 'glm-4-flash',
      displayName: 'GLM-4-Flash (Free)',
      provider: 'zhipu',
      contextWindow: 128000,
      supportsVision: false,
      supportsTools: true,
      supportsStreaming: true,
      costPer1kInput: 0.0,
      costPer1kOutput: 0.0,
      maxOutputTokens: 4096,
      description: 'GLM-4 Flash - free tier, great for prototyping',
    ),
    ModelInfo(
      id: 'glm-4-flashx',
      displayName: 'GLM-4-FlashX (Free)',
      provider: 'zhipu',
      contextWindow: 128000,
      supportsVision: false,
      supportsTools: true,
      supportsStreaming: true,
      costPer1kInput: 0.0,
      costPer1kOutput: 0.0,
      maxOutputTokens: 4096,
      description: 'GLM-4 FlashX - free, faster than Flash',
    ),
    ModelInfo(
      id: 'glm-4v-plus',
      displayName: 'GLM-4V Plus',
      provider: 'zhipu',
      contextWindow: 8000,
      supportsVision: true,
      supportsTools: false,
      supportsStreaming: true,
      costPer1kInput: 0.005,
      costPer1kOutput: 0.01,
      maxOutputTokens: 2048,
      description: 'GLM-4V Plus - vision specialist',
    ),
    ModelInfo(
      id: 'glm-4v',
      displayName: 'GLM-4V',
      provider: 'zhipu',
      contextWindow: 2000,
      supportsVision: true,
      supportsTools: false,
      supportsStreaming: true,
      costPer1kInput: 0.002,
      costPer1kOutput: 0.002,
      maxOutputTokens: 1024,
      description: 'GLM-4V - base vision model',
    ),
    ModelInfo(
      id: 'glm-4-9b',
      displayName: 'GLM-4-9B (Open Source)',
      provider: 'zhipu',
      contextWindow: 8000,
      supportsVision: false,
      supportsTools: true,
      supportsStreaming: true,
      costPer1kInput: 0.0,
      costPer1kOutput: 0.0,
      maxOutputTokens: 4096,
      description: 'Open-source GLM-4-9B served via Zhipu inference',
    ),
    ModelInfo(
      id: 'codegeex-4',
      displayName: 'CodeGeeX-4',
      provider: 'zhipu',
      contextWindow: 128000,
      supportsVision: false,
      supportsTools: true,
      supportsStreaming: true,
      costPer1kInput: 0.0005,
      costPer1kOutput: 0.001,
      maxOutputTokens: 4096,
      description: 'CodeGeeX-4 - GLM-based coding specialist',
    ),
  ];

  @override
  Future<Either<Failure, String>> complete({
    required List<MessageEntity> messages,
    required ModelConfigEntity config,
    String? systemPrompt,
  }) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      return const Left(
        UnauthorizedFailure(
          message: 'Zhipu AI API key not configured. '
              'Get one at open.bigmodel.cn and add it in Settings.',
        ),
      );
    }

    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: _baseUrl,
        apiKey: _apiKey,
      );
      final response = await dio.post(
        '/chat/completions',
        data: _buildBody(messages, config, systemPrompt, stream: false),
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'Zhipu returned non-map response: ${data.runtimeType}',
        );
      }
      final choices = (data['choices'] as List?) ?? <dynamic>[];
      if (choices.isEmpty) return '';
      final firstChoice = choices.first;
      if (firstChoice is! Map<String, dynamic>) return '';
      final message = firstChoice['message'];
      if (message is! Map<String, dynamic>) return '';
      final content = message['content'];
      if (content is! String) return '';
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
          message: 'Zhipu AI API key not configured. '
              'Get one at open.bigmodel.cn and add it in Settings.',
        ),
      );
      return;
    }

    final streamDio = DioClient.createStream(
      baseUrl: _baseUrl,
      apiKey: _apiKey,
    );

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
              AppLogger.d('Zhipu stream: skipped unparsable chunk: $e');
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
    // Zhipu does not expose a /models endpoint; return the static catalog.
    return const Right(_staticModels);
  }

  @override
  Future<Either<Failure, bool>> healthCheck() async {
    if (_apiKey == null || _apiKey!.isEmpty) return const Right(false);
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: _baseUrl,
        apiKey: _apiKey,
      );
      // Lightweight models request via a free model
      final response = await dio.post(
        '/chat/completions',
        data: {
          'model': 'glm-4-flash',
          'messages': [
            {'role': 'user', 'content': 'ping'},
          ],
          'max_tokens': 1,
        },
      );
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
      final role = m.role == MessageRole.assistant
          ? 'assistant'
          : m.role == MessageRole.system
              ? 'system'
              : m.role == MessageRole.tool
                  ? 'tool'
                  : 'user';

      // Vision-capable GLM models accept content as an array of parts.
      if (m.attachments.any((a) => a.type == AttachmentType.image)) {
        final parts = <Map<String, dynamic>>[
          if (m.content.isNotEmpty) {'type': 'text', 'text': m.content},
          ...m.attachments.where((a) => a.type == AttachmentType.image).map(
                (a) => {
                  'type': 'image_url',
                  'image_url': {'url': a.url},
                },
              ),
        ];
        apiMessages.add({'role': role, 'content': parts});
      } else {
        apiMessages.add({'role': role, 'content': m.content});
      }
    }

    final body = <String, dynamic>{
      'model': config.modelId,
      'messages': apiMessages,
      'temperature': config.temperature,
      'max_tokens': config.maxTokens,
      'top_p': config.topP,
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
    // GLM-specific: enable web search tool when explicitly requested.
    if (config.tools.contains('web_search')) {
      body['tools'] = [
        {
          'type': 'web_search',
          'web_search': {
            'enable': true,
            'search_result': true,
          },
        }
      ];
    }
    body.addAll(config.customParams);
    return body;
  }
}
