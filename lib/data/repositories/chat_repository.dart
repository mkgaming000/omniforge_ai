// Chat Repository - orchestrates AI providers, tracks usage, persists messages
import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/ai_providers.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/logger.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/model_config_entity.dart';
import '../../domain/entities/usage_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../services/ai/ai_chat_service.dart';
import '../services/ai/ai_provider_factory.dart';
import 'usage_repository.dart';

class ChatRepository implements IChatRepository {
  ChatRepository({
    required this.providerFactory,
    required this.usageRepository,
  });

  final AIProviderFactory providerFactory;
  final UsageRepository usageRepository;
  final _uuid = const Uuid();

  @override
  Future<Either<Failure, MessageEntity>> sendMessage({
    required List<MessageEntity> messages,
    required ModelConfigEntity config,
    String? systemPrompt,
    String? conversationId,
  }) async {
    final serviceResult = await providerFactory.getService(config.provider);
    if (serviceResult.isLeft()) {
      return serviceResult.map((r) => throw StateError('unreachable'));
    }
    final service = serviceResult.getOrElse(() => throw StateError(''));

    final result = await service.complete(
      messages: messages,
      config: config,
      systemPrompt: systemPrompt,
    );

    if (result.isLeft()) {
      return result.fold(
        (failure) => Left<Failure, MessageEntity>(failure),
        (_) => throw StateError('unreachable'),
      );
    }
    final response = result.getOrElse(() => throw StateError(''));

    // Approximate token count (4 chars ~= 1 token)
    final tokensIn = messages.fold<int>(
      0,
      (sum, m) => sum + (m.content.length / 4).ceil(),
    );
    final tokensOut = (response.length / 4).ceil();
    final cost = (tokensIn / 1000) * config.costPer1kInput +
        (tokensOut / 1000) * config.costPer1kOutput;

    // Track usage
    final trackResult = await usageRepository.track(
      UsageEntity(
        id: _uuid.v4(),
        provider: config.provider,
        model: config.modelId,
        timestamp: DateTime.now(),
        tokensIn: tokensIn,
        tokensOut: tokensOut,
        costUsd: cost,
        operation: UsageOperation.chat,
        conversationId: conversationId,
      ),
    );
    trackResult.fold(
      (f) => AppLogger.w('Usage tracking failed: ${f.userMessage}'),
      (_) {},
    );

    return Right(
      MessageEntity(
        id: _uuid.v4(),
        role: MessageRole.assistant,
        content: response,
        createdAt: DateTime.now(),
        modelConfig: config,
        status: MessageStatus.complete,
        tokensIn: tokensIn,
        tokensOut: tokensOut,
        costUsd: cost,
      ),
    );
  }

  @override
  Stream<Either<Failure, MessageEntity>> streamMessage({
    required List<MessageEntity> messages,
    required ModelConfigEntity config,
    String? systemPrompt,
    String? conversationId,
  }) async* {
    final serviceResult = await providerFactory.getService(config.provider);
    if (serviceResult.isLeft()) {
      yield serviceResult.fold(
        (l) => Left<Failure, MessageEntity>(l),
        (r) => throw StateError(''),
      );
      return;
    }
    final service = serviceResult.getOrElse(() => throw StateError(''));

    final messageId = _uuid.v4();
    final buffer = StringBuffer();
    final startTime = DateTime.now();

    yield Right(
      MessageEntity(
        id: messageId,
        role: MessageRole.assistant,
        content: '',
        createdAt: startTime,
        modelConfig: config,
        status: MessageStatus.streaming,
        streamingText: '',
      ),
    );

    final stream = service.stream(
      messages: messages,
      config: config,
      systemPrompt: systemPrompt,
    );

    try {
      await for (final event in stream) {
        yield event.fold(
          (failure) => Left<Failure, MessageEntity>(failure),
          (chunk) {
            buffer.write(chunk);
            return Right(
              MessageEntity(
                id: messageId,
                role: MessageRole.assistant,
                content: buffer.toString(),
                createdAt: startTime,
                modelConfig: config,
                status: MessageStatus.streaming,
                streamingText: buffer.toString(),
              ),
            );
          },
        );
      }
    } finally {
      // Guarantee usage tracking + a terminal complete message are emitted
      // even when the consumer cancels the subscription mid-stream —
      // otherwise token/cost accounting is silently lost and the UI never
      // sees a "complete" status.
      final finalContent = buffer.toString();
      final tokensIn = messages.fold<int>(
        0,
        (sum, m) => sum + (m.content.length / 4).ceil(),
      );
      final tokensOut = (finalContent.length / 4).ceil();
      final cost = (tokensIn / 1000) * config.costPer1kInput +
          (tokensOut / 1000) * config.costPer1kOutput;

      final trackResult = await usageRepository.track(
        UsageEntity(
          id: _uuid.v4(),
          provider: config.provider,
          model: config.modelId,
          timestamp: DateTime.now(),
          tokensIn: tokensIn,
          tokensOut: tokensOut,
          costUsd: cost,
          operation: UsageOperation.streaming,
          conversationId: conversationId,
        ),
      );
      trackResult.fold(
        (f) => AppLogger.w('Usage tracking failed: ${f.userMessage}'),
        (_) {},
      );

      yield Right(
        MessageEntity(
          id: messageId,
          role: MessageRole.assistant,
          content: finalContent,
          createdAt: startTime,
          modelConfig: config,
          status: MessageStatus.complete,
          tokensIn: tokensIn,
          tokensOut: tokensOut,
          costUsd: cost,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<ModelInfo>>> listModels(
    AIProvider provider,
  ) async {
    final serviceResult = await providerFactory.getService(provider);
    if (serviceResult.isLeft()) {
      return serviceResult.map((r) => throw StateError(''));
    }
    final service = serviceResult.getOrElse(() => throw StateError(''));
    return service.listModels();
  }

  @override
  Future<Either<Failure, Map<AIProvider, bool>>> healthCheckAll() async {
    final result = <AIProvider, bool>{};
    for (final provider in AIProvider.values.where((p) => p.isChat)) {
      final serviceResult = await providerFactory.getService(provider);
      if (serviceResult.isLeft()) {
        result[provider] = false;
        continue;
      }
      final service = serviceResult.getOrElse(() => throw StateError(''));
      final health = await service.healthCheck();
      result[provider] = health.getOrElse(() => false);
    }
    return Right(result);
  }
}
