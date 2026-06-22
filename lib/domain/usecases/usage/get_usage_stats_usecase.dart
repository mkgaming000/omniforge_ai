import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/entities/usage_entity.dart';
import '../../../domain/repositories/usage_repository.dart';

class GetUsageStatsUseCase {
  GetUsageStatsUseCase({required this.repository});
  final IUsageRepository repository;

  Future<Either<Failure, UsageStats>> call({DateTime? since}) =>
      repository.getStats(since: since);
}
