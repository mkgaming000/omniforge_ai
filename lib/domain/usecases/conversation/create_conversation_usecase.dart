import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/entities/conversation_entity.dart';
import '../../../domain/repositories/conversation_repository.dart';

class CreateConversationUseCase {
  CreateConversationUseCase({required this.repository});
  final IConversationRepository repository;

  Future<Either<Failure, ConversationEntity>> call({
    required String title,
    String? systemPrompt,
    String? folderId,
  }) {
    return repository.create(
      ConversationEntity(
        id: '',
        title: title,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        systemPrompt: systemPrompt,
        folderId: folderId,
      ),
    );
  }
}
