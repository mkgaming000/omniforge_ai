import 'package:dartz/dartz.dart';

import '../../../core/constants/ai_providers.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/repositories/api_key_repository.dart';

class GetApiKeyUseCase {
  GetApiKeyUseCase({required this.repository});
  final IApiKeyRepository repository;

  Future<Either<Failure, String?>> call(AIProvider provider) =>
      repository.getKey(provider);
}
