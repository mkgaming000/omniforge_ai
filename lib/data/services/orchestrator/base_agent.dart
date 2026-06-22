// Base Agent - the contract every specialized orchestrator agent implements.
//
// Each agent:
//   - Receives the current [SharedMemory] snapshot
//   - Receives a [TaskSpec] describing what it should produce
//   - Streams [AgentEvent]s (progress, tool calls, API calls, memory writes)
//   - Returns a final [AgentResult] containing its output + metrics
//
// The orchestrator wraps each agent run in retry/fallback/repair logic.
import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../../core/constants/ai_providers.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/entities/orchestrator/orchestrator_entities.dart';
import '../../../domain/entities/model_config_entity.dart';
import '../../../data/services/ai/ai_provider_factory.dart';

/// What an agent is being asked to produce.
class TaskSpec {
  const TaskSpec({
    required this.description,
    required this.outputKey,
    required this.agent,
    this.inputKeys = const [],
    this.constraints = const {},
    this.modelOverride,
  });

  final String description;
  final String outputKey; // key in shared memory
  final OrchestratorAgent agent;
  final List<String> inputKeys; // prior memory keys to consume
  final Map<String, dynamic> constraints;
  final ModelConfigEntity? modelOverride;
}

/// What an agent produced.
class AgentResult {
  const AgentResult({
    required this.output,
    required this.tokensIn,
    required this.tokensOut,
    required this.costUsd,
    required this.modelUsed,
    this.metadata = const {},
  });

  final String output;
  final int tokensIn;
  final int tokensOut;
  final double costUsd;
  final String modelUsed;
  final Map<String, dynamic> metadata;
}

/// Live events streamed by an agent during execution. The orchestrator
/// converts these into [OrchestratorProgress] updates for the UI.
class AgentEvent {
  const AgentEvent({
    required this.type,
    required this.agent,
    this.message,
    this.toolName,
    this.toolArgs,
    this.apiProvider,
    this.apiModel,
    this.memoryKey,
    this.memoryValue,
    this.progress, // 0.0 - 1.0 for this agent's run
    this.tokensIn,
    this.tokensOut,
  });

  final AgentEventType type;
  final OrchestratorAgent agent;
  final String? message;
  final String? toolName;
  final Map<String, dynamic>? toolArgs;
  final String? apiProvider;
  final String? apiModel;
  final String? memoryKey;
  final String? memoryValue;
  final double? progress;
  final int? tokensIn;
  final int? tokensOut;
}

enum AgentEventType {
  started,
  progress,
  thinking,
  toolCall,
  apiCall,
  memoryWrite,
  completed,
  failed,
}

/// The base contract every specialized agent implements.
abstract class BaseAgent {
  BaseAgent({required this.factory});

  final AIProviderFactory factory;

  /// Which agent identity this is.
  OrchestratorAgent get identity;

  /// Default model role this agent prefers.
  OrchestratorModelRole get defaultRole;

  /// Run the agent on the given task.
  ///
  /// Implementations MUST:
  ///   1. emit `AgentEvent(type: started)` first
  ///   2. emit periodic `progress` events
  ///   3. write outputs to [memory] via [SharedMemory.write]
  ///   4. emit `completed` (or `failed`) as the last event
  ///   5. return a populated [AgentResult]
  Stream<Either<Failure, AgentEvent>> run({
    required TaskSpec task,
    required SharedMemory memory,
  });

  /// Convenience: build the model config the agent wants to use, given an
  /// optional override from the caller.
  ModelConfigEntity configFor(TaskSpec task) {
    if (task.modelOverride != null) return task.modelOverride!;
    return defaultConfigForRole(defaultRole);
  }

  /// Default model per role. The orchestrator can override at the call site.
  ///
  /// Public so tests + the orchestrator pipeline can introspect routing.
  static ModelConfigEntity defaultConfigForRole(OrchestratorModelRole role) {
    switch (role) {
      case OrchestratorModelRole.expansion:
      case OrchestratorModelRole.analysis:
        return const ModelConfigEntity(
          provider: AIProvider.zhipu,
          modelId: 'glm-5.2',
          displayName: 'GLM-5.2',
          temperature: 0.7,
          maxTokens: 8192,
          contextWindow: 256000,
          supportsTools: true,
          supportsVision: true,
          costPer1kInput: 0.005,
          costPer1kOutput: 0.02,
        );
      case OrchestratorModelRole.planning:
      case OrchestratorModelRole.research:
        return const ModelConfigEntity(
          provider: AIProvider.google,
          modelId: 'gemini-1.5-pro',
          displayName: 'Gemini 1.5 Pro',
          temperature: 0.5,
          maxTokens: 8192,
          contextWindow: 2097152,
          supportsTools: true,
          supportsVision: true,
          costPer1kInput: 0.00125,
          costPer1kOutput: 0.005,
        );
      case OrchestratorModelRole.generation:
        return const ModelConfigEntity(
          provider: AIProvider.anthropic,
          modelId: 'claude-3-5-sonnet-20241022',
          displayName: 'Claude 3.5 Sonnet v2',
          temperature: 0.8,
          maxTokens: 8192,
          contextWindow: 200000,
          supportsTools: true,
          supportsVision: true,
          costPer1kInput: 0.003,
          costPer1kOutput: 0.015,
        );
      case OrchestratorModelRole.coding:
        return const ModelConfigEntity(
          provider: AIProvider.anthropic,
          modelId: 'claude-3-5-sonnet-20241022',
          displayName: 'Claude 3.5 Sonnet v2',
          temperature: 0.2,
          maxTokens: 8192,
          contextWindow: 200000,
          supportsTools: true,
          supportsVision: true,
          costPer1kInput: 0.003,
          costPer1kOutput: 0.015,
        );
      case OrchestratorModelRole.image:
      case OrchestratorModelRole.video:
      case OrchestratorModelRole.audio:
        // These roles don't use chat models directly; agents call the
        // image/video/audio services instead.
        return const ModelConfigEntity(
          provider: AIProvider.openai,
          modelId: 'gpt-4o',
          displayName: 'GPT-4o',
          temperature: 0.7,
          maxTokens: 4096,
        );
    }
  }

  /// Resolve the chat service for this agent's preferred model.
  /// Returns Left(failure) if the provider isn't configured.
  Future<Either<Failure, dynamic>> serviceFor(ModelConfigEntity config) {
    return factory.getService(config.provider);
  }
}
