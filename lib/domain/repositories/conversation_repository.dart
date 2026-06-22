// Conversation Repository Interface
import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/conversation_entity.dart';

abstract class IConversationRepository {
  Future<Either<Failure, ConversationEntity>> create(ConversationEntity c);
  Future<Either<Failure, ConversationEntity?>> getById(String id);
  Future<Either<Failure, List<ConversationEntity>>> getAll({
    String? folderId,
    bool includeArchived = false,
    int limit = 50,
  });
  Future<Either<Failure, ConversationEntity>> update(ConversationEntity c);
  Future<Either<Failure, void>> delete(String id);
  Future<Either<Failure, void>> archive(String id, bool archived);
  Future<Either<Failure, void>> pin(String id, bool pinned);
  Future<Either<Failure, List<ConversationEntity>>> search(String query);
}
