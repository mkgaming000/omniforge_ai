// Generate Image Use Case
import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/entities/image_entity.dart';
import '../../../domain/repositories/image_repository.dart';

class GenerateImageUseCase {
  GenerateImageUseCase({required this.repository});

  final IImageRepository repository;

  Future<Either<Failure, List<ImageEntity>>> call(
    ImageGenerationRequest request,
  ) {
    return repository.generate(request);
  }
}
