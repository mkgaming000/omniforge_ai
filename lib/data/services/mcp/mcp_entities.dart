// MCP Tool entities
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'mcp_entities.g.dart';

@HiveType(typeId: 60)
class McpToolEntity extends Equatable {
  const McpToolEntity({
    required this.id,
    required this.name,
    required this.displayName,
    required this.description,
    required this.endpoint,
    required this.transport,
    required this.requiredPermissions,
    required this.config,
    required this.status,
    required this.installedAt,
    required this.lastUsedAt,
    required this.usageCount,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String displayName;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final String endpoint;

  @HiveField(5)
  final McpToolTransport transport;

  @HiveField(6)
  final List<McpToolPermission> requiredPermissions;

  @HiveField(7)
  final Map<String, dynamic> config;

  @HiveField(8)
  final McpToolStatus status;

  @HiveField(9)
  final DateTime installedAt;

  @HiveField(10)
  final DateTime? lastUsedAt;

  @HiveField(11)
  final int usageCount;

  McpToolEntity copyWith({
    String? id,
    String? name,
    String? displayName,
    String? description,
    String? endpoint,
    McpToolTransport? transport,
    List<McpToolPermission>? requiredPermissions,
    Map<String, dynamic>? config,
    McpToolStatus? status,
    DateTime? installedAt,
    DateTime? lastUsedAt,
    int? usageCount,
  }) {
    return McpToolEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      endpoint: endpoint ?? this.endpoint,
      transport: transport ?? this.transport,
      requiredPermissions: requiredPermissions ?? this.requiredPermissions,
      config: config ?? this.config,
      status: status ?? this.status,
      installedAt: installedAt ?? this.installedAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      usageCount: usageCount ?? this.usageCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        displayName,
        description,
        endpoint,
        transport,
        requiredPermissions,
        config,
        status,
        installedAt,
        lastUsedAt,
        usageCount,
      ];
}

@HiveType(typeId: 61)
enum McpToolPermission {
  @HiveField(0)
  filesystem,
  @HiveField(1)
  network,
  @HiveField(2)
  process,
  @HiveField(3)
  secrets,
  @HiveField(4)
  userData,
}

@HiveType(typeId: 62)
enum McpToolStatus {
  @HiveField(0)
  available,
  @HiveField(1)
  installed,
  @HiveField(2)
  enabled,
  @HiveField(3)
  disabled,
  @HiveField(4)
  error,
}

@HiveType(typeId: 63)
enum McpToolTransport {
  @HiveField(0)
  websocket,
  @HiveField(1)
  http,
  @HiveField(2)
  stdio,
}

class McpToolResult {
  const McpToolResult({
    required this.success,
    this.output,
    this.error,
  });
  final bool success;
  final dynamic output;
  final String? error;
}
