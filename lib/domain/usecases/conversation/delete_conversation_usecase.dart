import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/repositories/conversation_repository.dart';

class DeleteConversationUseCase {
  DeleteConversationUseCase({required this.repository});
  final IConversationRepository repository;

  Future<Either<Failure, void>> call(String id) => repository.delete(id);
}
