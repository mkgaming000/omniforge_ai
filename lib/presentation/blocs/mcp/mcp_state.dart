import 'package:equatable/equatable.dart';

import '../../../data/services/mcp/mcp_entities.dart';

enum McpStatus { initial, loading, ready, executing, error }

class McpState extends Equatable {
  const McpState({
    this.status = McpStatus.initial,
    this.tools = const [],
    this.discoveredTools = const [],
    this.lastResult,
    this.error,
  });

  const McpState.initial() : this();

  final McpStatus status;
  final List<McpToolEntity> tools;
  final List<McpToolEntity> discoveredTools;
  final McpToolResult? lastResult;
  final String? error;

  McpState copyWith({
    McpStatus? status,
    List<McpToolEntity>? tools,
    List<McpToolEntity>? discoveredTools,
    McpToolResult? lastResult,
    String? error,
  }) {
    return McpState(
      status: status ?? this.status,
      tools: tools ?? this.tools,
      discoveredTools: discoveredTools ?? this.discoveredTools,
      lastResult: lastResult ?? this.lastResult,
      error: error,
    );
  }

  @override
  List<Object?> get props =>
      [status, tools, discoveredTools, lastResult, error];
}
