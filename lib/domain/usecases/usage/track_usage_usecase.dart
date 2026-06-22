import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/entities/usage_entity.dart';
import '../../../domain/repositories/usage_repository.dart';

class TrackUsageUseCase {
  TrackUsageUseCase({required this.repository});
  final IUsageRepository repository;

  Future<Either<Failure, void>> call(UsageEntity usage) =>
      repository.track(usage);
}
