// Video Repository - persists video generation records
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/video_entity.dart';
import '../services/local_storage_service.dart';

class VideoRepository {
  VideoRepository({required this.localStorage});

  final LocalStorageService localStorage;
  static const _prefix = 'video_';
  final _uuid = const Uuid();

  Future<Either<Failure, VideoEntity>> persist(VideoEntity video) async {
    try {
      final entity = video.copyWith(
        id: video.id.isEmpty ? _uuid.v4() : video.id,
        createdAt: video.id.isEmpty ? DateTime.now() : video.createdAt,
      );
      await localStorage.write('$_prefix${entity.id}', entity);
      return Right(entity);
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to save video',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  Future<Either<Failure, VideoEntity?>> getById(String id) async {
    try {
      return Right(localStorage.read<VideoEntity>('$_prefix$id'));
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to read video',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  Future<Either<Failure, List<VideoEntity>>> getAll({
    String? projectId,
  }) async {
    try {
      final items = localStorage.readWhere<VideoEntity>(
        (key, value) => key.startsWith(_prefix) && value is VideoEntity,
      );
      final filtered = projectId == null
          ? items
          : items.where((v) => v.projectId == projectId).toList();
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Right(filtered);
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to list videos',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  Future<Either<Failure, void>> update(VideoEntity video) async {
    try {
      await localStorage.write('$_prefix${video.id}', video);
      return const Right(null);
    } catch (e) {
      return const Left(CacheFailure(message: 'Failed to update video'));
    }
  }

  Future<Either<Failure, void>> delete(String id) async {
    try {
      await localStorage.delete('$_prefix$id');
      return const Right(null);
    } catch (e) {
      return const Left(CacheFailure(message: 'Failed to delete video'));
    }
  }
}
