// Abstract AI provider service - contract for all chat providers
import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/entities/message_entity.dart';
import '../../../domain/entities/model_config_entity.dart';

abstract class AIChatService {
  /// Send a one-shot completion request.
  Future<Either<Failure, String>> complete({
    required List<MessageEntity> messages,
    required ModelConfigEntity config,
    String? systemPrompt,
  });

  /// Stream a completion token-by-token via SSE.
  Stream<Either<Failure, String>> stream({
    required List<MessageEntity> messages,
    required ModelConfigEntity config,
    String? systemPrompt,
  });

  /// List available models for this provider.
  Future<Either<Failure, List<ModelInfo>>> listModels();

  /// Health-check ping.
  Future<Either<Failure, bool>> healthCheck();
}

class ModelInfo {
  const ModelInfo({
    required this.id,
    required this.displayName,
    required this.provider,
    this.contextWindow = 8192,
    this.supportsVision = false,
    this.supportsTools = false,
    this.supportsStreaming = true,
    this.costPer1kInput = 0.0,
    this.costPer1kOutput = 0.0,
    this.description,
    this.maxOutputTokens = 4096,
  });

  final String id;
  final String displayName;
  final String provider;
  final int contextWindow;
  final bool supportsVision;
  final bool supportsTools;
  final bool supportsStreaming;
  final double costPer1kInput;
  final double costPer1kOutput;
  final String? description;
  final int maxOutputTokens;
}
