// Usage Repository Interface
import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/usage_entity.dart';

abstract class IUsageRepository {
  Future<Either<Failure, void>> track(UsageEntity usage);
  Future<Either<Failure, UsageStats>> getStats({DateTime? since});
  Future<Either<Failure, List<UsageEntity>>> getRecent({int limit = 100});
  Future<Either<Failure, void>> clear();
}
