// MCP (Model Context Protocol) Client
// Discovers, registers, and executes MCP tools from local servers and marketplaces.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/errors/failures.dart';
import '../../../core/utils/logger.dart';
import '../../../core/network/dio_client.dart';
import 'mcp_entities.dart';

class McpClient {
  McpClient._(this._box);

  final Box<McpToolEntity> _box;
  final _uuid = const Uuid();

  static const _boxName = 'omniforge_mcp_tools';

  static Future<McpClient> create() async {
    if (!Hive.isAdapterRegistered(60)) {
      Hive.registerAdapter(McpToolEntityAdapter());
    }
    if (!Hive.isAdapterRegistered(61)) {
      Hive.registerAdapter(McpToolPermissionAdapter());
    }
    if (!Hive.isAdapterRegistered(62)) {
      Hive.registerAdapter(McpToolStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(63)) {
      Hive.registerAdapter(McpToolTransportAdapter());
    }
    final box = await Hive.openBox<McpToolEntity>(_boxName);
    return McpClient._(box);
  }

  /// Install/register a new MCP tool.
  Future<Either<Failure, String>> installTool({
    required String name,
    required String displayName,
    required String description,
    required String endpoint,
    required McpToolTransport transport,
    List<McpToolPermission> requiredPermissions = const [],
    Map<String, dynamic> config = const {},
  }) async {
    try {
      final id = _uuid.v4();
      final tool = McpToolEntity(
        id: id,
        name: name,
        displayName: displayName,
        description: description,
        endpoint: endpoint,
        transport: transport,
        requiredPermissions: requiredPermissions,
        config: config,
        status: McpToolStatus.installed,
        installedAt: DateTime.now(),
        lastUsedAt: null,
        usageCount: 0,
      );
      await _box.put(id, tool);
      return Right(id);
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to install MCP tool',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Uninstall a tool by ID.
  Future<Either<Failure, void>> uninstallTool(String id) async {
    try {
      await _box.delete(id);
      return const Right(null);
    } catch (e) {
      return const Left(CacheFailure(message: 'Failed to uninstall tool'));
    }
  }

  /// List all installed tools.
  Either<Failure, List<McpToolEntity>> listTools() {
    try {
      return Right(_box.values.toList());
    } catch (_) {
      return const Left(CacheFailure(message: 'Failed to list tools'));
    }
  }

  /// Discover tools available from a remote MCP server.
  Future<Either<Failure, List<McpToolEntity>>> discoverTools(
    String serverUrl,
  ) async {
    try {
      final uri = Uri.parse(serverUrl);
      final channel = WebSocketChannel.connect(uri);
      final completer = Completer<List<McpToolEntity>>();

      final subscription = channel.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message as String) as Map<String, dynamic>;
            if (data['type'] == 'tools/list') {
              final tools = (data['tools'] as List)
                  .map(
                    (t) => McpToolEntity(
                      id: _uuid.v4(),
                      name: t['name'] as String,
                      displayName: (t['displayName'] as String?) ??
                          (t['name'] as String),
                      description: t['description'] as String? ?? '',
                      endpoint: serverUrl,
                      transport: McpToolTransport.websocket,
                      // Surface server-advertised permissions if present so
                      // the security gate can act on them at execute time.
                      requiredPermissions: _parsePermissions(t['permissions']),
                      config: Map<String, dynamic>.from(t as Map),
                      status: McpToolStatus.available,
                      installedAt: DateTime.now(),
                      lastUsedAt: null,
                      usageCount: 0,
                    ),
                  )
                  .toList();
              if (!completer.isCompleted) {
                completer.complete(tools);
              }
            }
          } catch (e) {
            // Malformed response from the MCP server — logged so discovery
            // failures are diagnosable instead of silently timing out empty.
            AppLogger.d('MCP tools/list: failed to parse server message: $e');
          }
        },
        onError: (e) {
          if (!completer.isCompleted) {
            completer.completeError(
              NetworkFailure(
                message: 'MCP discovery stream error: $e',
              ),
            );
          }
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.complete(<McpToolEntity>[]);
          }
        },
        cancelOnError: true,
      );

      channel.sink.add(jsonEncode({'type': 'list_tools'}));

      final tools = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => <McpToolEntity>[],
      );
      await subscription.cancel();
      await channel.sink.close();
      return Right(tools);
    } catch (e, st) {
      return Left(
        NetworkFailure(
          message: 'Failed to discover tools from $serverUrl',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Execute a tool with the given arguments.
  Future<Either<Failure, McpToolResult>> executeTool({
    required String toolId,
    required Map<String, dynamic> arguments,
  }) async {
    final tool = _box.get(toolId);
    if (tool == null) {
      return const Left(NotFoundFailure(message: 'Tool not found'));
    }

    // Security gate: never execute tools that are disabled or in an error
    // state, and require explicit `enabled` status for tools that touch
    // sensitive capabilities (secrets / process execution). This prevents
    // an untrusted MCP server's tool from silently reading secrets or
    // spawning processes the moment it is installed.
    if (tool.status == McpToolStatus.disabled ||
        tool.status == McpToolStatus.error) {
      return Left(
        SecurityFailure(
          message: 'Tool ${tool.name} is ${tool.status.name} and cannot be '
              'executed',
        ),
      );
    }
    final sensitive = tool.requiredPermissions.any(
      (p) => p == McpToolPermission.secrets || p == McpToolPermission.process,
    );
    if (sensitive && tool.status != McpToolStatus.enabled) {
      return const Left(
        SecurityFailure(
          message: 'Tool requires sensitive permissions — enable it explicitly '
              'in MCP settings before execution',
        ),
      );
    }

    try {
      final result = await _invokeTool(tool, arguments);

      // Update usage stats
      final updated = tool.copyWith(
        lastUsedAt: DateTime.now(),
        usageCount: tool.usageCount + 1,
      );
      await _box.put(toolId, updated);

      return Right(result);
    } catch (e, st) {
      return Left(
        ProviderFailure(
          message: 'Tool execution failed: ${tool.name}',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  Future<McpToolResult> _invokeTool(
    McpToolEntity tool,
    Map<String, dynamic> arguments,
  ) async {
    switch (tool.transport) {
      case McpToolTransport.websocket:
        return _invokeWebSocket(tool, arguments);
      case McpToolTransport.http:
        return _invokeHttp(tool, arguments);
      case McpToolTransport.stdio:
        return _invokeStdio(tool, arguments);
    }
  }

  Future<McpToolResult> _invokeWebSocket(
    McpToolEntity tool,
    Map<String, dynamic> arguments,
  ) async {
    final channel = WebSocketChannel.connect(Uri.parse(tool.endpoint));
    final requestId = _uuid.v4();
    final completer = Completer<McpToolResult>();

    final subscription = channel.stream.listen((message) {
      try {
        final data = jsonDecode(message as String) as Map<String, dynamic>;
        if (data['requestId'] == requestId) {
          completer.complete(
            McpToolResult(
              success: data['success'] as bool? ?? true,
              output: data['output'],
              error: data['error'] as String?,
            ),
          );
        }
      } catch (e) {
        AppLogger.d('MCP tool invoke: failed to parse server message: $e');
      }
    });

    channel.sink.add(
      jsonEncode({
        'requestId': requestId,
        'type': 'invoke',
        'tool': tool.name,
        'arguments': arguments,
      }),
    );

    final result = await completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () => const McpToolResult(
        success: false,
        error: 'Tool execution timed out',
      ),
    );
    await subscription.cancel();
    await channel.sink.close();
    return result;
  }

  Future<McpToolResult> _invokeHttp(
    McpToolEntity tool,
    Map<String, dynamic> arguments,
  ) async {
    try {
      final dio = DioClient.create(baseUrl: tool.endpoint);
      // POST the tool name + arguments as JSON. Tools are expected to
      // expose a single `/invoke` endpoint per the MCP HTTP spec.
      final response = await dio.post(
        '/invoke',
        data: {
          'tool': tool.name,
          'arguments': arguments,
        },
        options: Options(
          responseType: ResponseType.json,
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return McpToolResult(
          success: (data['success'] as bool?) ?? true,
          output: data['output'] ?? data,
          error: data['error'] as String?,
        );
      }
      return McpToolResult(success: true, output: data);
    } catch (e) {
      return McpToolResult(
        success: false,
        error: 'HTTP transport error: $e',
      );
    }
  }

  Future<McpToolResult> _invokeStdio(
    McpToolEntity tool,
    Map<String, dynamic> arguments,
  ) async {
    // stdio-based tools require local process execution (flutter_pty)
    return const McpToolResult(
      success: false,
      error: 'stdio transport requires flutter_pty integration',
    );
  }

  /// Check installed tool health by resolving the tool's endpoint host.
  /// This performs a real network reachability probe (DNS lookup) per tool
  /// with a short timeout — it never reports a tool as healthy without
  /// confirming the endpoint resolves.
  Future<Either<Failure, Map<String, bool>>> healthCheckAll() async {
    try {
      final results = <String, bool>{};
      for (final tool in _box.values) {
        try {
          final uri = Uri.parse(tool.endpoint);
          if (uri.host.isEmpty) {
            results[tool.id] = false;
            continue;
          }
          await InternetAddress.lookup(uri.host)
              .timeout(const Duration(seconds: 3));
          results[tool.id] = true;
        } catch (e) {
          AppLogger.d('MCP healthCheck ${tool.name}: unreachable ($e)');
          results[tool.id] = false;
        }
      }
      return Right(results);
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Health check failed',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Close the underlying Hive box. Per-call WebSocket/HTTP connections are
  /// already closed inline by their callers, so there are no pooled channels
  /// to tear down here.
  Future<void> dispose() async {
    await _box.close();
  }

  /// Parse a server-advertised permission list into typed [McpToolPermission]s.
  /// Unknown values are dropped (fail-closed: an unrecognised permission is
  /// not silently granted).
  List<McpToolPermission> _parsePermissions(dynamic raw) {
    if (raw is! List) return const [];
    final parsed = <McpToolPermission>{};
    for (final entry in raw) {
      final name = entry?.toString();
      if (name == null) continue;
      for (final p in McpToolPermission.values) {
        if (p.name == name) {
          parsed.add(p);
          break;
        }
      }
    }
    return parsed.toList();
  }
}
