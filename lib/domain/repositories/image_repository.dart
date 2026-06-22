// Image Repository Interface
import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/image_entity.dart';

abstract class IImageRepository {
  Future<Either<Failure, List<ImageEntity>>> generate(
    ImageGenerationRequest req,
  );
  Future<Either<Failure, List<ImageEntity>>> getAll({String? folderId});
  Future<Either<Failure, void>> delete(String id);
  Future<Either<Failure, void>> favorite(String id, bool fav);
  Future<Either<Failure, ImageEntity>> update(ImageEntity image);
}
