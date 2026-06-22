// Agent Runtime - executes multi-step agent workflows with tool use, memory, RAG
import 'dart:async';
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/failures.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/entities/agent_entity.dart';
import '../../../domain/entities/message_entity.dart';
import '../ai/ai_provider_factory.dart';
import '../mcp/mcp_client.dart';
import '../rag/rag_service.dart';

class AgentRuntime {
  AgentRuntime({
    required this.providerFactory,
    required this.mcpClient,
    required this.ragService,
  });

  final AIProviderFactory providerFactory;
  final McpClient mcpClient;
  final RagService ragService;
  final _uuid = const Uuid();

  /// Execute an agent on a single user input.
  ///
  /// [maxIterationsOverride] optionally overrides the agent's own
  /// `maxIterations` setting. If null, `agent.maxIterations` is used.
  Stream<Either<Failure, AgentStep>> run({
    required AgentEntity agent,
    required String userInput,
    String? sessionId,
    int? maxIterationsOverride,
  }) async* {
    final effectiveMaxIterations = maxIterationsOverride ?? agent.maxIterations;
    final history = <AgentMessage>[];
    final session = sessionId ?? _uuid.v4();

    final systemPrompt = _buildSystemPrompt(agent);

    String augmentedInput = userInput;
    if (agent.knowledgeBaseId != null) {
      final augmentResult = await ragService.augmentPrompt(
        userQuery: userInput,
        knowledgeBaseId: agent.knowledgeBaseId,
      );
      augmentResult.fold(
        (_) {},
        (augmented) => augmentedInput = augmented,
      );
    }

    history.add(
      AgentMessage(
        role: AgentRole.user,
        content: augmentedInput,
        timestamp: DateTime.now(),
      ),
    );

    yield Right(
      AgentStep(
        type: AgentStepType.thinking,
        content: 'Agent ${agent.name} starting task (session $session)',
        timestamp: DateTime.now(),
      ),
    );

    for (var i = 0; i < effectiveMaxIterations; i++) {
      final serviceResult =
          await providerFactory.getService(agent.model.provider);
      if (serviceResult.isLeft()) {
        yield Left(
          serviceResult.fold(
            (l) => l,
            (_) => const UnknownFailure(),
          ),
        );
        return;
      }
      final service = serviceResult.getOrElse(() => throw StateError(''));

      final completionResult = await service.complete(
        messages: history.map((m) => m.toMessageEntity()).toList(),
        config: agent.model,
        systemPrompt: systemPrompt,
      );

      final completion = completionResult.fold(
        (failure) => null,
        (text) => text,
      );

      if (completion == null) {
        yield Left(
          completionResult.fold(
            (l) => l,
            (_) => const UnknownFailure(),
          ),
        );
        return;
      }

      yield Right(
        AgentStep(
          type: AgentStepType.thinking,
          content: completion,
          timestamp: DateTime.now(),
        ),
      );

      final toolCall = _parseToolCall(completion);
      if (toolCall == null) {
        history.add(
          AgentMessage(
            role: AgentRole.assistant,
            content: completion,
            timestamp: DateTime.now(),
          ),
        );
        yield Right(
          AgentStep(
            type: AgentStepType.finalAnswer,
            content: completion,
            timestamp: DateTime.now(),
          ),
        );
        return;
      }

      yield Right(
        AgentStep(
          type: AgentStepType.toolCall,
          content: 'Calling tool: ${toolCall.name}',
          metadata: toolCall.arguments,
          timestamp: DateTime.now(),
        ),
      );

      final toolResult = await mcpClient.executeTool(
        toolId: toolCall.toolId,
        arguments: toolCall.arguments,
      );

      final toolOutput = toolResult.fold(
        (failure) => 'Error: ${failure.userMessage}',
        (result) => result.success
            ? result.output.toString()
            : 'Tool error: ${result.error}',
      );

      yield Right(
        AgentStep(
          type: AgentStepType.toolResult,
          content: toolOutput,
          timestamp: DateTime.now(),
        ),
      );

      history.add(
        AgentMessage(
          role: AgentRole.assistant,
          content: completion,
          timestamp: DateTime.now(),
        ),
      );
      history.add(
        AgentMessage(
          role: AgentRole.tool,
          content: toolOutput,
          timestamp: DateTime.now(),
        ),
      );
    }

    yield Right(
      AgentStep(
        type: AgentStepType.finalAnswer,
        content: 'Maximum iterations reached.',
        timestamp: DateTime.now(),
      ),
    );
  }

  String _buildSystemPrompt(AgentEntity agent) {
    final buffer = StringBuffer();
    buffer.writeln('You are ${agent.name}, an AI assistant.');
    if (agent.description != null) {
      buffer.writeln(agent.description);
    }
    buffer.writeln();
    buffer.writeln('System Prompt:');
    buffer.writeln(agent.systemPrompt);
    buffer.writeln();
    if (agent.allowedTools.isNotEmpty) {
      buffer.writeln('Available tools: ${agent.allowedTools.join(", ")}');
      buffer.writeln('To call a tool, respond with:');
      buffer.writeln('```tool_call');
      buffer.writeln('{"tool_id": "<id>", "tool": "<name>", '
          '"arguments": {"key": "value"}}');
      buffer.writeln('```');
    }
    return buffer.toString();
  }

  _ToolCall? _parseToolCall(String text) {
    final regex = RegExp(r'```tool_call\s+([\s\S]+?)\s+```');
    final match = regex.firstMatch(text);
    if (match == null) return null;
    try {
      final json = jsonDecode(match.group(1)!) as Map<String, dynamic>;
      return _ToolCall(
        toolId: json['tool_id'] as String? ??
            json['tool'] as String? ??
            json['name'] as String? ??
            '',
        name: json['tool'] as String? ?? json['name'] as String? ?? '',
        arguments: Map<String, dynamic>.from(json['arguments'] as Map? ?? {}),
      );
    } catch (e) {
      AppLogger.w('Failed to parse tool_call from LLM output: $e');
      return null;
    }
  }
}

class _ToolCall {
  const _ToolCall({
    required this.toolId,
    required this.name,
    required this.arguments,
  });
  final String toolId;
  final String name;
  final Map<String, dynamic> arguments;
}

extension on AgentMessage {
  MessageEntity toMessageEntity() {
    return MessageEntity(
      id: timestamp.millisecondsSinceEpoch.toString(),
      role: switch (role) {
        AgentRole.user => MessageRole.user,
        AgentRole.assistant => MessageRole.assistant,
        AgentRole.system => MessageRole.system,
        AgentRole.tool => MessageRole.tool,
      },
      content: content,
      createdAt: timestamp,
    );
  }
}
