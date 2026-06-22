// API Key Repository - manages encrypted API keys per provider
import 'package:dartz/dartz.dart';

import '../../core/constants/ai_providers.dart';
import '../../core/errors/failures.dart';
import '../../core/security/encryption_service.dart';
import '../../domain/repositories/api_key_repository.dart';

class ApiKeyRepository implements IApiKeyRepository {
  ApiKeyRepository({required this.encryptionService});

  final EncryptionService encryptionService;

  @override
  Future<Either<Failure, void>> saveKey(
    AIProvider provider,
    String apiKey,
  ) async {
    try {
      if (apiKey.isEmpty) {
        return const Left(
          ValidationFailure(message: 'API key cannot be empty'),
        );
      }
      await encryptionService.storeApiKey(provider.name, apiKey);
      return const Right(null);
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to save API key',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, String?>> getKey(AIProvider provider) async {
    try {
      final key = await encryptionService.getApiKey(provider.name);
      return Right(key);
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to read API key',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deleteKey(AIProvider provider) async {
    try {
      await encryptionService.deleteApiKey(provider.name);
      return const Right(null);
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to delete API key',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Map<AIProvider, bool>>>
      listConfiguredProviders() async {
    try {
      final stored = await encryptionService.listStoredProviders();
      final result = <AIProvider, bool>{};
      for (final provider in AIProvider.values) {
        result[provider] = stored.contains(provider.name);
      }
      return Right(result);
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to list providers',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> isConfigured(AIProvider provider) async {
    try {
      final key = await encryptionService.getApiKey(provider.name);
      return Right(key != null && key.isNotEmpty);
    } catch (_) {
      return const Right(false);
    }
  }
}
