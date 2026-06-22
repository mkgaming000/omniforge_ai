// Stream Message Use Case - SSE streaming
import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/entities/message_entity.dart';
import '../../../domain/entities/model_config_entity.dart';
import '../../../domain/repositories/chat_repository.dart';

class StreamMessageUseCase {
  StreamMessageUseCase({required this.chatRepository});

  final IChatRepository chatRepository;

  Stream<Either<Failure, MessageEntity>> call({
    required List<MessageEntity> messages,
    required ModelConfigEntity config,
    String? systemPrompt,
    String? conversationId,
  }) {
    return chatRepository.streamMessage(
      messages: messages,
      config: config,
      systemPrompt: systemPrompt,
      conversationId: conversationId,
    );
  }
}
