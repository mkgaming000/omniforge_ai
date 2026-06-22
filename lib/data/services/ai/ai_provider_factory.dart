// AI Provider Factory - routes requests to the appropriate provider service
// Handles API key injection, model selection, fallback, and provider health monitoring.
import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../../core/constants/ai_providers.dart';
import '../../../core/errors/failures.dart';
import '../../../core/security/encryption_service.dart';
import '../../../domain/entities/message_entity.dart';
import '../../../domain/entities/model_config_entity.dart';
import 'ai_chat_service.dart';
import 'anthropic_service.dart';
import 'deepseek_service.dart';
import 'gemini_service.dart';
import 'grok_service.dart';
import 'huggingface_service.dart';
import 'mistral_service.dart';
import 'ollama_service.dart';
import 'openai_service.dart';
import 'openrouter_service.dart';
import 'qwen_service.dart';
import 'zhipu_service.dart';

class AIProviderFactory {
  AIProviderFactory({
    required this.encryptionService,
    required this.openAI,
    required this.anthropic,
    required this.gemini,
    required this.deepseek,
    required this.mistral,
    required this.grok,
    required this.openRouter,
    required this.ollama,
    required this.qwen,
    required this.zhipu,
    required this.huggingFace,
  });

  final EncryptionService encryptionService;
  final OpenAIService openAI;
  final AnthropicService anthropic;
  final GeminiService gemini;
  final DeepSeekService deepseek;
  final MistralService mistral;
  final GrokService grok;
  final OpenRouterService openRouter;
  final OllamaService ollama;
  final QwenService qwen;
  final ZhipuService zhipu;
  final HuggingFaceService huggingFace;

  final Map<AIProvider, AIChatService> _cache = {};
  final Map<AIProvider, DateTime> _lastHealthCheck = {};
  final Map<AIProvider, bool> _healthStatus = {};

  /// Returns the chat service for a provider, with API key pre-loaded.
  Future<Either<Failure, AIChatService>> getService(
    AIProvider provider,
  ) async {
    if (_cache.containsKey(provider)) {
      return Right(_cache[provider]!);
    }

    final service = _instantiate(provider);
    if (service == null) {
      return Left(
        ProviderFailure(
          message: 'Provider $provider is not a chat provider',
        ),
      );
    }

    if (provider.requiresApiKey) {
      // Meta (Llama) is served through OpenRouter, so it shares the
      // OpenRouter API key rather than having its own. Look up the key
      // under the provider that actually owns the credential.
      final keyProvider =
          provider == AIProvider.meta ? AIProvider.openrouter : provider;
      final apiKey = await encryptionService.getApiKey(keyProvider.name);
      if (apiKey == null || apiKey.isEmpty) {
        return Left(
          UnauthorizedFailure(
            message:
                '${provider.displayName} API key not set. Add it in Settings.',
          ),
        );
      }
      _injectApiKey(service, apiKey);
    }

    _cache[provider] = service;
    return Right(service);
  }

  AIChatService? _instantiate(AIProvider provider) {
    switch (provider) {
      case AIProvider.openai:
        return openAI;
      case AIProvider.anthropic:
        return anthropic;
      case AIProvider.google:
        return gemini;
      case AIProvider.xai:
        return grok;
      case AIProvider.deepseek:
        return deepseek;
      case AIProvider.mistral:
        return mistral;
      case AIProvider.meta:
        return openRouter;
      case AIProvider.alibaba:
        return qwen;
      case AIProvider.zhipu:
        return zhipu;
      case AIProvider.openrouter:
        return openRouter;
      case AIProvider.huggingface:
        return huggingFace;
      case AIProvider.ollama:
        return ollama;
      case AIProvider.lmstudio:
        return ollama; // LM Studio is OpenAI-compatible
      default:
        return null;
    }
  }

  void _injectApiKey(AIChatService service, String apiKey) {
    if (service is OpenAIService) {
      service.setApiKey(apiKey);
    } else if (service is AnthropicService) {
      service.setApiKey(apiKey);
    } else if (service is GeminiService) {
      service.setApiKey(apiKey);
    } else if (service is DeepSeekService) {
      service.setApiKey(apiKey);
    } else if (service is MistralService) {
      service.setApiKey(apiKey);
    } else if (service is GrokService) {
      service.setApiKey(apiKey);
    } else if (service is OpenRouterService) {
      service.setApiKey(apiKey);
    } else if (service is QwenService) {
      service.setApiKey(apiKey);
    } else if (service is ZhipuService) {
      service.setApiKey(apiKey);
    } else if (service is HuggingFaceService) {
      service.setApiKey(apiKey);
    }
  }

  /// Send a message and automatically fall back to alternate providers on error.
  Future<Either<Failure, String>> completeWithFallback({
    required List<MessageEntity> messages,
    required ModelConfigEntity primaryConfig,
    String? systemPrompt,
    List<AIProvider> fallbackOrder = const [
      AIProvider.openai,
      AIProvider.anthropic,
      AIProvider.zhipu,
      AIProvider.google,
      AIProvider.openrouter,
    ],
  }) async {
    final providers = [
      primaryConfig.provider,
      ...fallbackOrder.where((p) => p != primaryConfig.provider),
    ];

    Failure? lastFailure;
    for (final provider in providers) {
      final serviceResult = await getService(provider);
      if (serviceResult.isLeft()) {
        lastFailure = serviceResult.fold(
          (l) => l,
          (r) => null,
        );
        continue;
      }

      final service = serviceResult.getOrElse(() => throw StateError(''));
      final config = provider == primaryConfig.provider
          ? primaryConfig
          : primaryConfig.copyWith(provider: provider);

      final result = await service.complete(
        messages: messages,
        config: config,
        systemPrompt: systemPrompt,
      );

      if (result.isRight()) return result;
      lastFailure = result.fold((l) => l, (r) => null);
    }

    return Left(
      lastFailure ?? const ProviderFailure(message: 'All providers failed'),
    );
  }

  /// Auto-select the best provider based on task type and health status.
  Future<Either<Failure, AIChatService>> autoSelect({
    required ChatTaskType taskType,
  }) async {
    final preferences = _taskPreferences[taskType] ??
        [
          AIProvider.openai,
          AIProvider.anthropic,
          AIProvider.google,
        ];

    for (final provider in preferences) {
      if (!await _isHealthy(provider)) continue;
      final result = await getService(provider);
      if (result.isRight()) return result;
    }

    return const Left(
      ProviderFailure(
        message: 'No healthy providers available for this task',
      ),
    );
  }

  Future<bool> _isHealthy(AIProvider provider) async {
    final lastCheck = _lastHealthCheck[provider];
    final cached = _healthStatus[provider];
    if (lastCheck != null &&
        cached != null &&
        DateTime.now().difference(lastCheck) < const Duration(minutes: 5)) {
      return cached;
    }

    final serviceResult = await getService(provider);
    if (serviceResult.isLeft()) {
      _healthStatus[provider] = false;
      _lastHealthCheck[provider] = DateTime.now();
      return false;
    }

    final service = serviceResult.getOrElse(() => throw StateError(''));
    final result = await service.healthCheck();
    final healthy = result.getOrElse(() => false);
    _healthStatus[provider] = healthy;
    _lastHealthCheck[provider] = DateTime.now();
    return healthy;
  }

  /// Refresh API key cache (call after user updates a key in settings).
  Future<void> refreshKey(AIProvider provider) async {
    _cache.remove(provider);
    _healthStatus.remove(provider);
    _lastHealthCheck.remove(provider);
  }

  static const Map<ChatTaskType, List<AIProvider>> _taskPreferences = {
    ChatTaskType.reasoning: [
      AIProvider.anthropic,
      AIProvider.openai,
      AIProvider.zhipu,
      AIProvider.google,
    ],
    ChatTaskType.coding: [
      AIProvider.anthropic,
      AIProvider.openai,
      AIProvider.zhipu,
      AIProvider.deepseek,
      AIProvider.mistral,
    ],
    ChatTaskType.creative: [
      AIProvider.anthropic,
      AIProvider.openai,
      AIProvider.google,
      AIProvider.zhipu,
    ],
    ChatTaskType.vision: [
      AIProvider.openai,
      AIProvider.google,
      AIProvider.anthropic,
      AIProvider.zhipu,
    ],
    ChatTaskType.longContext: [
      AIProvider.google,
      AIProvider.zhipu,
      AIProvider.anthropic,
      AIProvider.openai,
    ],
    ChatTaskType.cheap: [
      AIProvider.zhipu,
      AIProvider.deepseek,
      AIProvider.google,
      AIProvider.openai,
    ],
    ChatTaskType.local: [
      AIProvider.ollama,
      AIProvider.lmstudio,
    ],
  };
}

enum ChatTaskType {
  reasoning,
  coding,
  creative,
  vision,
  longContext,
  cheap,
  local,
}
