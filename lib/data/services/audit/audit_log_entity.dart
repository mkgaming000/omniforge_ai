// Audit Log Entity - Hive-persisted audit log entries
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'audit_log_entity.g.dart';

@HiveType(typeId: 90)
class AuditLogEntry extends Equatable {
  const AuditLogEntry({
    required this.id,
    required this.timestamp,
    required this.action,
    required this.level,
    required this.message,
    this.userId,
    this.resourceType,
    this.resourceId,
    this.metadata = const {},
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime timestamp;

  @HiveField(2)
  final AuditLogAction action;

  @HiveField(3)
  final AuditLogLevel level;

  @HiveField(4)
  final String message;

  @HiveField(5)
  final String? userId;

  @HiveField(6)
  final String? resourceType;

  @HiveField(7)
  final String? resourceId;

  @HiveField(8)
  final Map<String, dynamic> metadata;

  @override
  List<Object?> get props => [
        id,
        timestamp,
        action,
        level,
        message,
        userId,
        resourceType,
        resourceId,
        metadata,
      ];
}

@HiveType(typeId: 91)
enum AuditLogAction {
  @HiveField(0)
  login,
  @HiveField(1)
  logout,
  @HiveField(2)
  apiKeySaved,
  @HiveField(3)
  apiKeyDeleted,
  @HiveField(4)
  apiKeyUsed,
  @HiveField(5)
  conversationCreated,
  @HiveField(6)
  conversationDeleted,
  @HiveField(7)
  messageSent,
  @HiveField(8)
  imageGenerated,
  @HiveField(9)
  videoGenerated,
  @HiveField(10)
  musicGenerated,
  @HiveField(11)
  documentProcessed,
  @HiveField(12)
  mcpToolExecuted,
  @HiveField(13)
  agentRun,
  @HiveField(14)
  fileUploaded,
  @HiveField(15)
  fileDownloaded,
  @HiveField(16)
  fileDeleted,
  @HiveField(17)
  permissionGranted,
  @HiveField(18)
  permissionRevoked,
  @HiveField(19)
  securityBlocked,
  @HiveField(20)
  configChanged,
  @HiveField(21)
  dataExported,
  @HiveField(22)
  dataDeleted,
}

@HiveType(typeId: 92)
enum AuditLogLevel {
  @HiveField(0)
  debug,
  @HiveField(1)
  info,
  @HiveField(2)
  warning,
  @HiveField(3)
  error,
  @HiveField(4)
  critical,
}
