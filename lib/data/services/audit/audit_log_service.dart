// Audit Log Service - records all security-relevant operations
import 'package:dartz/dartz.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/failures.dart';
import 'audit_log_entity.dart';

class AuditLogService {
  AuditLogService._(this._box);
  final Box<AuditLogEntry> _box;
  final _uuid = const Uuid();

  static const _boxName = 'omniforge_audit_log';

  static Future<AuditLogService> create() async {
    if (!Hive.isAdapterRegistered(90)) {
      Hive.registerAdapter(AuditLogEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(91)) {
      Hive.registerAdapter(AuditLogActionAdapter());
    }
    if (!Hive.isAdapterRegistered(92)) {
      Hive.registerAdapter(AuditLogLevelAdapter());
    }
    final box = await Hive.openBox<AuditLogEntry>(_boxName);
    return AuditLogService._(box);
  }

  Future<Either<Failure, void>> log({
    required AuditLogAction action,
    required String message,
    AuditLogLevel level = AuditLogLevel.info,
    String? userId,
    String? resourceType,
    String? resourceId,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final entry = AuditLogEntry(
        id: _uuid.v4(),
        timestamp: DateTime.now(),
        action: action,
        level: level,
        message: message,
        userId: userId,
        resourceType: resourceType,
        resourceId: resourceId,
        metadata: metadata,
      );
      await _box.put(entry.id, entry);
      return const Right(null);
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to write audit log',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  Either<Failure, List<AuditLogEntry>> getAll({
    AuditLogLevel? minLevel,
    int limit = 500,
  }) {
    try {
      var entries = _box.values.toList();
      if (minLevel != null) {
        entries =
            entries.where((e) => e.level.index >= minLevel.index).toList();
      }
      entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return Right(entries.take(limit).toList());
    } catch (_) {
      return const Left(CacheFailure(message: 'Failed to read audit log'));
    }
  }

  Either<Failure, List<AuditLogEntry>> getByAction(AuditLogAction action) {
    try {
      final entries = _box.values.where((e) => e.action == action).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return Right(entries);
    } catch (_) {
      return const Left(CacheFailure(message: 'Failed to filter audit log'));
    }
  }

  Future<Either<Failure, int>> clearOlderThan(Duration age) async {
    try {
      final cutoff = DateTime.now().subtract(age);
      final toDelete = _box.values
          .where((e) => e.timestamp.isBefore(cutoff))
          .map((e) => e.id)
          .toList();
      for (final id in toDelete) {
        await _box.delete(id);
      }
      return Right(toDelete.length);
    } catch (_) {
      return const Left(CacheFailure(message: 'Failed to purge audit log'));
    }
  }

  int get count => _box.length;
}
