import 'package:dartz/dartz.dart';

import '../../../core/constants/ai_providers.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/repositories/api_key_repository.dart';

class DeleteApiKeyUseCase {
  DeleteApiKeyUseCase({required this.repository});
  final IApiKeyRepository repository;

  Future<Either<Failure, void>> call(AIProvider provider) =>
      repository.deleteKey(provider);
}
