// MCP Bloc
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/services/mcp/mcp_client.dart';
import 'mcp_event.dart';
import 'mcp_state.dart';

class McpBloc extends Bloc<McpEvent, McpState> {
  McpBloc({required this.client}) : super(const McpState.initial()) {
    on<LoadMcpTools>(_onLoad);
    on<InstallMcpTool>(_onInstall);
    on<UninstallMcpTool>(_onUninstall);
    on<DiscoverMcpTools>(_onDiscover);
    on<ExecuteMcpTool>(_onExecute);
  }

  final McpClient client;

  Future<void> _onLoad(LoadMcpTools event, Emitter<McpState> emit) async {
    emit(state.copyWith(status: McpStatus.loading));
    final result = client.listTools();
    result.fold(
      (_) => emit(state.copyWith(status: McpStatus.error)),
      (tools) => emit(
        state.copyWith(
          status: McpStatus.ready,
          tools: tools,
        ),
      ),
    );
  }

  Future<void> _onInstall(
    InstallMcpTool event,
    Emitter<McpState> emit,
  ) async {
    final result = await client.installTool(
      name: event.name,
      displayName: event.displayName,
      description: event.description,
      endpoint: event.endpoint,
      transport: event.transport,
      requiredPermissions: event.permissions,
    );
    result.fold(
      (_) => emit(state.copyWith(status: McpStatus.error)),
      (_) => add(const LoadMcpTools()),
    );
  }

  Future<void> _onUninstall(
    UninstallMcpTool event,
    Emitter<McpState> emit,
  ) async {
    await client.uninstallTool(event.id);
    add(const LoadMcpTools());
  }

  Future<void> _onDiscover(
    DiscoverMcpTools event,
    Emitter<McpState> emit,
  ) async {
    emit(state.copyWith(status: McpStatus.loading));
    final result = await client.discoverTools(event.serverUrl);
    result.fold(
      (_) => emit(state.copyWith(status: McpStatus.error)),
      (tools) => emit(
        state.copyWith(
          status: McpStatus.ready,
          discoveredTools: tools,
        ),
      ),
    );
  }

  Future<void> _onExecute(
    ExecuteMcpTool event,
    Emitter<McpState> emit,
  ) async {
    emit(state.copyWith(status: McpStatus.executing));
    final result = await client.executeTool(
      toolId: event.toolId,
      arguments: event.arguments,
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: McpStatus.error,
          error: failure.userMessage,
        ),
      ),
      (r) => emit(
        state.copyWith(
          status: McpStatus.ready,
          lastResult: r,
        ),
      ),
    );
  }
}
