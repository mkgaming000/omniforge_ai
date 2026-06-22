// Conversation Repository - manages chat threads
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/repositories/conversation_repository.dart';
import '../services/local_storage_service.dart';

class ConversationRepository implements IConversationRepository {
  ConversationRepository({required this.localStorage});

  final LocalStorageService localStorage;
  static const _prefix = 'conversation_';
  final _uuid = const Uuid();

  @override
  Future<Either<Failure, ConversationEntity>> create(
    ConversationEntity conversation,
  ) async {
    try {
      final entity = conversation.copyWith(
        id: conversation.id.isEmpty ? _uuid.v4() : conversation.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await localStorage.write('$_prefix${entity.id}', entity);
      return Right(entity);
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to create conversation',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, ConversationEntity?>> getById(String id) async {
    try {
      final result = localStorage.read<ConversationEntity>('$_prefix$id');
      return Right(result);
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to read conversation',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<ConversationEntity>>> getAll({
    String? folderId,
    bool includeArchived = false,
    int limit = 50,
  }) async {
    try {
      final items = localStorage.readWhere<ConversationEntity>(
        (key, value) => key.startsWith(_prefix) && value is ConversationEntity,
      );

      var filtered = items.where((c) {
        if (!includeArchived && c.archived) return false;
        if (folderId != null && c.folderId != folderId) return false;
        return true;
      }).toList();

      filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      filtered = filtered.take(limit).toList();

      return Right(filtered);
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to list conversations',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, ConversationEntity>> update(
    ConversationEntity conversation,
  ) async {
    try {
      final updated = conversation.copyWith(updatedAt: DateTime.now());
      await localStorage.write('$_prefix${updated.id}', updated);
      return Right(updated);
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to update conversation',
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
          message: 'Failed to delete conversation',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> archive(String id, bool archived) async {
    try {
      final entity = localStorage.read<ConversationEntity>('$_prefix$id');
      if (entity == null) {
        return const Left(NotFoundFailure(message: 'Conversation not found'));
      }
      await localStorage.write(
        '$_prefix$id',
        entity.copyWith(archived: archived, updatedAt: DateTime.now()),
      );
      return const Right(null);
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to archive conversation',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> pin(String id, bool pinned) async {
    try {
      final entity = localStorage.read<ConversationEntity>('$_prefix$id');
      if (entity == null) {
        return const Left(NotFoundFailure(message: 'Conversation not found'));
      }
      await localStorage.write(
        '$_prefix$id',
        entity.copyWith(pinned: pinned, updatedAt: DateTime.now()),
      );
      return const Right(null);
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to pin conversation',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<ConversationEntity>>> search(String query) async {
    try {
      final q = query.toLowerCase();
      final results = localStorage
          .readWhere<ConversationEntity>(
            (key, value) =>
                key.startsWith(_prefix) && value is ConversationEntity,
          )
          .where(
            (c) =>
                c.title.toLowerCase().contains(q) ||
                (c.summary?.toLowerCase().contains(q) ?? false) ||
                c.messages.any((m) => m.content.toLowerCase().contains(q)),
          )
          .toList();
      results.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return Right(results);
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to search conversations',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }
}
