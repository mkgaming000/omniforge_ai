// MCP Events
import 'package:equatable/equatable.dart';

import '../../../data/services/mcp/mcp_entities.dart';

abstract class McpEvent extends Equatable {
  const McpEvent();
}

class LoadMcpTools extends McpEvent {
  const LoadMcpTools();
  @override
  List<Object?> get props => [];
}

class InstallMcpTool extends McpEvent {
  const InstallMcpTool({
    required this.name,
    required this.displayName,
    required this.description,
    required this.endpoint,
    required this.transport,
    this.permissions = const [],
  });

  final String name;
  final String displayName;
  final String description;
  final String endpoint;
  final McpToolTransport transport;
  final List<McpToolPermission> permissions;

  @override
  List<Object?> get props =>
      [name, displayName, description, endpoint, transport, permissions];
}

class UninstallMcpTool extends McpEvent {
  const UninstallMcpTool(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

class DiscoverMcpTools extends McpEvent {
  const DiscoverMcpTools(this.serverUrl);
  final String serverUrl;
  @override
  List<Object?> get props => [serverUrl];
}

class ExecuteMcpTool extends McpEvent {
  const ExecuteMcpTool({
    required this.toolId,
    required this.arguments,
  });
  final String toolId;
  final Map<String, dynamic> arguments;
  @override
  List<Object?> get props => [toolId, arguments];
}
