// Chat Repository Interface
import 'package:dartz/dartz.dart';

import '../../core/constants/ai_providers.dart';
import '../../core/errors/failures.dart';
import '../entities/message_entity.dart';
import '../entities/model_config_entity.dart';
import '../../data/services/ai/ai_chat_service.dart' show ModelInfo;

abstract class IChatRepository {
  Future<Either<Failure, MessageEntity>> sendMessage({
    required List<MessageEntity> messages,
    required ModelConfigEntity config,
    String? systemPrompt,
    String? conversationId,
  });

  Stream<Either<Failure, MessageEntity>> streamMessage({
    required List<MessageEntity> messages,
    required ModelConfigEntity config,
    String? systemPrompt,
    String? conversationId,
  });

  Future<Either<Failure, List<ModelInfo>>> listModels(AIProvider provider);
  Future<Either<Failure, Map<AIProvider, bool>>> healthCheckAll();
}
