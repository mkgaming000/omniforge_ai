// Send Message Use Case - one-shot completion
import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/entities/message_entity.dart';
import '../../../domain/entities/model_config_entity.dart';
import '../../../domain/repositories/chat_repository.dart';

class SendMessageUseCase {
  SendMessageUseCase({required this.chatRepository});

  final IChatRepository chatRepository;

  Future<Either<Failure, MessageEntity>> call({
    required List<MessageEntity> messages,
    required ModelConfigEntity config,
    String? systemPrompt,
    String? conversationId,
  }) {
    return chatRepository.sendMessage(
      messages: messages,
      config: config,
      systemPrompt: systemPrompt,
      conversationId: conversationId,
    );
  }
}
