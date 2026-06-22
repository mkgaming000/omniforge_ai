// Hugging Face Inference Service
import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../../../domain/entities/message_entity.dart';
import '../../../domain/entities/model_config_entity.dart';
import 'ai_chat_service.dart';

class HuggingFaceService implements AIChatService {
  HuggingFaceService();

  String? _apiKey;
  void setApiKey(String key) => _apiKey = key;

  String get _baseUrl =>
      dotenv.maybeGet('HUGGINGFACE_BASE_URL') ??
      'https://api-inference.huggingface.co';

  Dio get _dio => DioClient.create(baseUrl: _baseUrl, apiKey: _apiKey);

  @override
  Future<Either<Failure, String>> complete({
    required List<MessageEntity> messages,
    required ModelConfigEntity config,
    String? systemPrompt,
  }) async {
    if (_apiKey == null) {
      return const Left(
        UnauthorizedFailure(
          message: 'Hugging Face API key not configured.',
        ),
      );
    }
    return safeApiCall(() async {
      // HF inference API uses /models/{model_id}
      final response = await _dio.post(
        '/models/${config.modelId}',
        data: {
          'inputs': _buildInput(messages, systemPrompt),
          'parameters': {
            'temperature': config.temperature,
            'max_new_tokens': config.maxTokens,
            'top_p': config.topP,
            'return_full_text': false,
          },
          'options': {'wait_for_model': true},
        },
      );

      final data = response.data;
      if (data is List) {
        if (data.isEmpty) {
          throw const ProviderFailure(
            message: 'Hugging Face returned empty response array',
          );
        }
        final item = data.first;
        if (item is! Map<String, dynamic>) {
          throw ProviderFailure(
            message: 'Hugging Face returned non-map item: ${item.runtimeType}',
          );
        }
        final generated = item['generated_text'];
        if (generated is! String) {
          throw ProviderFailure(
            message:
                'Hugging Face returned non-string generated_text: ${generated.runtimeType}',
          );
        }
        return generated;
      } else if (data is Map<String, dynamic>) {
        final generated = data['generated_text'];
        if (generated is! String) {
          throw ProviderFailure(
            message:
                'Hugging Face returned non-string generated_text: ${generated.runtimeType}',
          );
        }
        return generated;
      }
      throw ProviderFailure(
        message:
            'Hugging Face returned unexpected response shape: ${data.runtimeType}',
      );
    });
  }

  @override
  Stream<Either<Failure, String>> stream({
    required List<MessageEntity> messages,
    required ModelConfigEntity config,
    String? systemPrompt,
  }) async* {
    // HF doesn't support native SSE streaming for chat; emulate via chunked generation
    final result = await complete(
      messages: messages,
      config: config,
      systemPrompt: systemPrompt,
    );
    yield result;
  }

  @override
  Future<Either<Failure, List<ModelInfo>>> listModels() async {
    return const Right([
      ModelInfo(
        id: 'meta-llama/Llama-3.3-70B-Instruct',
        displayName: 'Llama 3.3 70B (HF)',
        provider: 'huggingface',
        contextWindow: 128000,
        costPer1kInput: 0.0008,
        costPer1kOutput: 0.0008,
        maxOutputTokens: 4096,
      ),
      ModelInfo(
        id: 'mistralai/Mistral-7B-Instruct-v0.3',
        displayName: 'Mistral 7B v0.3 (HF)',
        provider: 'huggingface',
        contextWindow: 32768,
        costPer1kInput: 0.0001,
        costPer1kOutput: 0.0001,
        maxOutputTokens: 4096,
      ),
      ModelInfo(
        id: 'Qwen/Qwen2.5-72B-Instruct',
        displayName: 'Qwen 2.5 72B (HF)',
        provider: 'huggingface',
        contextWindow: 32768,
        costPer1kInput: 0.0006,
        costPer1kOutput: 0.0006,
        maxOutputTokens: 4096,
      ),
      ModelInfo(
        id: 'deepseek-ai/DeepSeek-V3',
        displayName: 'DeepSeek-V3 (HF)',
        provider: 'huggingface',
        contextWindow: 64000,
        costPer1kInput: 0.0003,
        costPer1kOutput: 0.0003,
        maxOutputTokens: 4096,
      ),
    ]);
  }

  @override
  Future<Either<Failure, bool>> healthCheck() async {
    if (_apiKey == null) return const Right(false);
    return safeApiCall(() async {
      final response = await _dio.get('/whoami-v2');
      return response.statusCode == 200;
    });
  }

  String _buildInput(List<MessageEntity> messages, String? systemPrompt) {
    final buffer = StringBuffer();
    if (systemPrompt != null) buffer.writeln(systemPrompt);
    for (final m in messages) {
      buffer.writeln('${m.role.name}: ${m.content}');
    }
    buffer.write('assistant: ');
    return buffer.toString();
  }
}
