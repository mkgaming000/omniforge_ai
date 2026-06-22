import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/entities/conversation_entity.dart';
import '../../../domain/repositories/conversation_repository.dart';

class GetConversationsUseCase {
  GetConversationsUseCase({required this.repository});
  final IConversationRepository repository;

  Future<Either<Failure, List<ConversationEntity>>> call({
    String? folderId,
    bool includeArchived = false,
    int limit = 50,
  }) {
    return repository.getAll(
      folderId: folderId,
      includeArchived: includeArchived,
      limit: limit,
    );
  }
}
