// Knowledge Base Repository - manages KB metadata
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/failures.dart';
import '../services/local_storage_service.dart';
import '../../domain/entities/knowledge_base_entity.dart';

class KnowledgeBaseRepository {
  KnowledgeBaseRepository({required this.localStorage});

  final LocalStorageService localStorage;
  static const _prefix = 'kb_';
  final _uuid = const Uuid();

  Future<Either<Failure, KnowledgeBaseEntity>> create({
    required String name,
    String? description,
    String? embeddingProvider,
  }) async {
    try {
      final id = _uuid.v4();
      final kb = KnowledgeBaseEntity(
        id: id,
        name: name,
        description: description,
        embeddingProvider: embeddingProvider ?? 'openai',
        documentCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await localStorage.write('$_prefix$id', kb);
      return Right(kb);
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to create knowledge base',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  Future<Either<Failure, KnowledgeBaseEntity?>> getById(String id) async {
    try {
      return Right(localStorage.read<KnowledgeBaseEntity>('$_prefix$id'));
    } catch (_) {
      return const Left(CacheFailure(message: 'Failed to read KB'));
    }
  }

  Future<Either<Failure, List<KnowledgeBaseEntity>>> getAll() async {
    try {
      final items = localStorage.readWhere<KnowledgeBaseEntity>(
        (key, value) => key.startsWith(_prefix) && value is KnowledgeBaseEntity,
      );
      items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return Right(items);
    } catch (_) {
      return const Left(CacheFailure(message: 'Failed to list KBs'));
    }
  }

  Future<Either<Failure, void>> delete(String id) async {
    try {
      await localStorage.delete('$_prefix$id');
      return const Right(null);
    } catch (_) {
      return const Left(CacheFailure(message: 'Failed to delete KB'));
    }
  }

  Future<Either<Failure, void>> incrementDocumentCount(String id) async {
    try {
      final kb = localStorage.read<KnowledgeBaseEntity>('$_prefix$id');
      if (kb == null) {
        return const Left(NotFoundFailure(message: 'KB not found'));
      }
      await localStorage.write(
        '$_prefix$id',
        kb.copyWith(
          documentCount: kb.documentCount + 1,
          updatedAt: DateTime.now(),
        ),
      );
      return const Right(null);
    } catch (_) {
      return const Left(CacheFailure(message: 'Failed to update KB'));
    }
  }
}
