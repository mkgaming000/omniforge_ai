// API Key Repository Interface
import 'package:dartz/dartz.dart';

import '../../core/constants/ai_providers.dart';
import '../../core/errors/failures.dart';

abstract class IApiKeyRepository {
  Future<Either<Failure, void>> saveKey(AIProvider provider, String apiKey);
  Future<Either<Failure, String?>> getKey(AIProvider provider);
  Future<Either<Failure, void>> deleteKey(AIProvider provider);
  Future<Either<Failure, Map<AIProvider, bool>>> listConfiguredProviders();
  Future<Either<Failure, bool>> isConfigured(AIProvider provider);
}
