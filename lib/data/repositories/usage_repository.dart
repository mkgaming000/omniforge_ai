// Usage Repository - tracks token consumption and costs
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/usage_entity.dart';
import '../../domain/repositories/usage_repository.dart';
import '../services/local_storage_service.dart';

class UsageRepository implements IUsageRepository {
  UsageRepository({required this.localStorage});

  final LocalStorageService localStorage;
  static const _prefix = 'usage_';
  final _uuid = const Uuid();

  @override
  Future<Either<Failure, void>> track(UsageEntity usage) async {
    try {
      final entity = UsageEntity(
        id: usage.id.isEmpty ? _uuid.v4() : usage.id,
        provider: usage.provider,
        model: usage.model,
        timestamp: usage.timestamp,
        tokensIn: usage.tokensIn,
        tokensOut: usage.tokensOut,
        costUsd: usage.costUsd,
        operation: usage.operation,
        conversationId: usage.conversationId,
        metadata: usage.metadata,
      );
      await localStorage.write('$_prefix${entity.id}', entity);
      return const Right(null);
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to track usage',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, UsageStats>> getStats({DateTime? since}) async {
    try {
      final records = localStorage.readWhere<UsageEntity>(
        (key, value) => key.startsWith(_prefix) && value is UsageEntity,
      );

      final filtered = since != null
          ? records.where((u) => u.timestamp.isAfter(since)).toList()
          : records;

      int totalTokensIn = 0;
      int totalTokensOut = 0;
      double totalCost = 0;
      final byProvider = <String, ProviderStats>{};
      final byDay = <String, DailyStats>{};
      final byOperation = <UsageOperation, int>{};

      for (final u in filtered) {
        totalTokensIn += u.tokensIn;
        totalTokensOut += u.tokensOut;
        totalCost += u.costUsd;

        final providerKey = u.provider.name;
        byProvider[providerKey] = ProviderStats(
          tokensIn: (byProvider[providerKey]?.tokensIn ?? 0) + u.tokensIn,
          tokensOut: (byProvider[providerKey]?.tokensOut ?? 0) + u.tokensOut,
          costUsd: (byProvider[providerKey]?.costUsd ?? 0) + u.costUsd,
          requests: (byProvider[providerKey]?.requests ?? 0) + 1,
        );

        final dayKey =
            '${u.timestamp.year}-${u.timestamp.month.toString().padLeft(2, '0')}-${u.timestamp.day.toString().padLeft(2, '0')}';
        byDay[dayKey] = DailyStats(
          tokensIn: (byDay[dayKey]?.tokensIn ?? 0) + u.tokensIn,
          tokensOut: (byDay[dayKey]?.tokensOut ?? 0) + u.tokensOut,
          costUsd: (byDay[dayKey]?.costUsd ?? 0) + u.costUsd,
          requests: (byDay[dayKey]?.requests ?? 0) + 1,
        );

        byOperation[u.operation] = (byOperation[u.operation] ?? 0) + 1;
      }

      return Right(
        UsageStats(
          totalTokensIn: totalTokensIn,
          totalTokensOut: totalTokensOut,
          totalCostUsd: totalCost,
          totalRequests: filtered.length,
          byProvider: byProvider,
          byDay: byDay,
          byOperation: byOperation,
        ),
      );
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to compute stats',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<UsageEntity>>> getRecent({
    int limit = 100,
  }) async {
    try {
      final records = localStorage.readWhere<UsageEntity>(
        (key, value) => key.startsWith(_prefix) && value is UsageEntity,
      );
      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return Right(records.take(limit).toList());
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to list usage',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> clear() async {
    try {
      final keys = localStorage.box.keys
          .whereType<String>()
          .where((k) => k.startsWith(_prefix))
          .toList();
      for (final k in keys) {
        await localStorage.delete(k);
      }
      return const Right(null);
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to clear usage',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }
}
