// Either type alias for clean error handling
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../errors/failures.dart';

/// Either<Failure, T> convenience wrappers.
typedef Result<T> = Future<Either<Failure, T>>;
typedef StreamResult<T> = Stream<Either<Failure, T>>;

/// Generic params for pagination
class PaginationParams extends Equatable {
  const PaginationParams({
    this.page = 1,
    this.pageSize = 20,
    this.query,
  });

  final int page;
  final int pageSize;
  final String? query;

  int get offset => (page - 1) * pageSize;

  @override
  List<Object?> get props => [page, pageSize, query];
}
