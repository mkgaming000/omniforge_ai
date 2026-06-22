// Image Repository - persists generated images locally + delegates to AI providers
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/ai_providers.dart';
import '../../core/errors/failures.dart';
import '../../core/security/encryption_service.dart';
import '../../domain/entities/image_entity.dart';
import '../../domain/repositories/image_repository.dart';
import '../services/ai/image/ai_image_service.dart';
import '../services/ai/image/flux_image_service.dart';
import '../services/ai/image/ideogram_image_service.dart';
import '../services/ai/image/leonardo_image_service.dart';
import '../services/ai/image/openai_image_service.dart';
import '../services/ai/image/recraft_image_service.dart';
import '../services/ai/image/stability_image_service.dart';
import '../services/local_storage_service.dart';

class ImageRepository implements IImageRepository {
  ImageRepository({
    required this.localStorage,
    required this.encryptionService,
    required this.openai,
    required this.stability,
    required this.flux,
    required this.ideogram,
    required this.recraft,
    required this.leonardo,
  });

  final LocalStorageService localStorage;
  final EncryptionService encryptionService;

  final OpenAIImageService openai;
  final StabilityImageService stability;
  final FluxImageService flux;
  final IdeogramImageService ideogram;
  final RecraftImageService recraft;
  final LeonardoImageService leonardo;

  static const _prefix = 'image_';
  final _uuid = const Uuid();

  @override
  Future<Either<Failure, List<ImageEntity>>> generate(
    ImageGenerationRequest request,
  ) async {
    final serviceResult = _selectService(request.provider);
    if (serviceResult.isLeft()) {
      return serviceResult.fold(
        (l) => Left<Failure, List<ImageEntity>>(l),
        (_) => throw StateError('unreachable'),
      );
    }
    final service = serviceResult.getOrElse(() => throw StateError(''));

    // Inject API key if the provider requires one.
    if (request.provider.requiresApiKey) {
      final key = await encryptionService.getApiKey(request.provider.name);
      if (key == null || key.isEmpty) {
        return Left(
          UnauthorizedFailure(
            message: '${request.provider.displayName} API key not set. '
                'Add it in Settings → API Keys.',
          ),
        );
      }
      _injectApiKey(service, key);
    }

    final result = await service.generate(request);
    if (result.isLeft()) {
      return result.fold(
        (failure) => Left<Failure, List<ImageEntity>>(failure),
        (_) => throw StateError('unreachable'),
      );
    }
    final images = result.getOrElse(() => throw StateError(''));

    // Persist each generated image.
    final persisted = <ImageEntity>[];
    for (final img in images) {
      final withId = img.copyWith(
        id: img.id.isEmpty ? _uuid.v4() : img.id,
        createdAt: img.id.isEmpty ? DateTime.now() : img.createdAt,
      );
      await localStorage.write('$_prefix${withId.id}', withId);
      persisted.add(withId);
    }
    return Right(persisted);
  }

  /// Resolve an AIImageService implementation for the given provider.
  Either<Failure, AIImageService> _selectService(AIProvider provider) {
    switch (provider) {
      case AIProvider.openai:
        return Right(openai);
      case AIProvider.stability:
        return Right(stability);
      case AIProvider.flux:
        return Right(flux);
      case AIProvider.ideogram:
        return Right(ideogram);
      case AIProvider.recraft:
        return Right(recraft);
      case AIProvider.leonardo:
        return Right(leonardo);
      case AIProvider.zhipu:
        return const Left(
          ProviderFailure(
            message: 'Zhipu CogView image generation is not yet wired. '
                'Use the chat provider with a vision-capable GLM model instead.',
          ),
        );
      default:
        return Left(
          ProviderFailure(
            message: '${provider.displayName} is not an image provider.',
          ),
        );
    }
  }

  void _injectApiKey(AIImageService service, String apiKey) {
    if (service is OpenAIImageService) {
      service.setApiKey(apiKey);
    } else if (service is StabilityImageService) {
      service.setApiKey(apiKey);
    } else if (service is FluxImageService) {
      service.setApiKey(apiKey);
    } else if (service is IdeogramImageService) {
      service.setApiKey(apiKey);
    } else if (service is RecraftImageService) {
      service.setApiKey(apiKey);
    } else if (service is LeonardoImageService) {
      service.setApiKey(apiKey);
    }
  }

  Future<Either<Failure, ImageEntity>> persist(ImageEntity image) async {
    try {
      final entity = image.copyWith(
        id: image.id.isEmpty ? _uuid.v4() : image.id,
        createdAt: image.id.isEmpty ? DateTime.now() : image.createdAt,
      );
      await localStorage.write('$_prefix${entity.id}', entity);
      return Right(entity);
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to save image',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<ImageEntity>>> getAll({String? folderId}) async {
    try {
      final items = localStorage.readWhere<ImageEntity>(
        (key, value) => key.startsWith(_prefix) && value is ImageEntity,
      );
      final filtered = folderId == null
          ? items
          : items.where((i) => i.folderId == folderId).toList();
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Right(filtered);
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to list images',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> delete(String id) async {
    try {
      await localStorage.delete('$_prefix$id');
      return const Right(null);
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to delete image',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> favorite(String id, bool fav) async {
    try {
      final entity = localStorage.read<ImageEntity>('$_prefix$id');
      if (entity == null) {
        return const Left(NotFoundFailure(message: 'Image not found'));
      }
      await localStorage.write(
        '$_prefix$id',
        entity.copyWith(favorite: fav),
      );
      return const Right(null);
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to favorite image',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, ImageEntity>> update(ImageEntity image) async {
    try {
      await localStorage.write('$_prefix${image.id}', image);
      return Right(image);
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to update image',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }
}
