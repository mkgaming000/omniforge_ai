// Music Repository - persists music generation records
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/music_entity.dart';
import '../services/local_storage_service.dart';

class MusicRepository {
  MusicRepository({required this.localStorage});

  final LocalStorageService localStorage;
  static const _prefix = 'music_';
  final _uuid = const Uuid();

  Future<Either<Failure, MusicEntity>> persist(MusicEntity music) async {
    try {
      final entity = music.copyWith(
        id: music.id.isEmpty ? _uuid.v4() : music.id,
        createdAt: music.id.isEmpty ? DateTime.now() : music.createdAt,
      );
      await localStorage.write('$_prefix${entity.id}', entity);
      return Right(entity);
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to save music',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  Future<Either<Failure, MusicEntity?>> getById(String id) async {
    try {
      return Right(localStorage.read<MusicEntity>('$_prefix$id'));
    } catch (e) {
      return const Left(CacheFailure(message: 'Failed to read music'));
    }
  }

  Future<Either<Failure, List<MusicEntity>>> getAll() async {
    try {
      final items = localStorage.readWhere<MusicEntity>(
        (key, value) => key.startsWith(_prefix) && value is MusicEntity,
      );
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Right(items);
    } catch (e) {
      return const Left(CacheFailure(message: 'Failed to list music'));
    }
  }

  Future<Either<Failure, void>> update(MusicEntity music) async {
    try {
      await localStorage.write('$_prefix${music.id}', music);
      return const Right(null);
    } catch (e) {
      return const Left(CacheFailure(message: 'Failed to update music'));
    }
  }

  Future<Either<Failure, void>> delete(String id) async {
    try {
      await localStorage.delete('$_prefix$id');
      return const Right(null);
    } catch (e) {
      return const Left(CacheFailure(message: 'Failed to delete music'));
    }
  }
}
