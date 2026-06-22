// Agent Repository - persists AI agents
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/agent_entity.dart';
import '../services/local_storage_service.dart';

class AgentRepository {
  AgentRepository({required this.localStorage});

  final LocalStorageService localStorage;
  static const _prefix = 'agent_';
  final _uuid = const Uuid();

  Future<Either<Failure, AgentEntity>> create(AgentEntity agent) async {
    try {
      final entity = agent.copyWith(
        id: agent.id.isEmpty ? _uuid.v4() : agent.id,
        createdAt: DateTime.now(),
      );
      await localStorage.write('$_prefix${entity.id}', entity);
      return Right(entity);
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to create agent',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  Future<Either<Failure, AgentEntity?>> getById(String id) async {
    try {
      return Right(localStorage.read<AgentEntity>('$_prefix$id'));
    } catch (_) {
      return const Left(CacheFailure(message: 'Failed to read agent'));
    }
  }

  Future<Either<Failure, List<AgentEntity>>> getAll() async {
    try {
      final items = localStorage.readWhere<AgentEntity>(
        (key, value) => key.startsWith(_prefix) && value is AgentEntity,
      );
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Right(items);
    } catch (_) {
      return const Left(CacheFailure(message: 'Failed to list agents'));
    }
  }

  Future<Either<Failure, AgentEntity>> update(AgentEntity agent) async {
    try {
      await localStorage.write('$_prefix${agent.id}', agent);
      return Right(agent);
    } catch (_) {
      return const Left(CacheFailure(message: 'Failed to update agent'));
    }
  }

  Future<Either<Failure, void>> delete(String id) async {
    try {
      await localStorage.delete('$_prefix$id');
      return const Right(null);
    } catch (_) {
      return const Left(CacheFailure(message: 'Failed to delete agent'));
    }
  }
}
