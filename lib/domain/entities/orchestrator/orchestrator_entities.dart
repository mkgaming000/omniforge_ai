// Orchestrator Entities - shared memory, agent identities, pipeline state
//
// The Master Orchestrator coordinates 15 specialized AI agents through a
// 10-step pipeline. All agents share a single in-memory + persisted
// SharedMemory snapshot that they can read from and write to.
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'orchestrator_entities.g.dart';

// ---------------------------------------------------------------------------
// Agent identities
// ---------------------------------------------------------------------------

/// The 15 specialized agents in the OmniForge orchestrator network.
@HiveType(typeId: 200)
enum OrchestratorAgent {
  @HiveField(0)
  promptExpander(
    'Prompt Expander',
    'Expands simple requests into full specs',
    OrchestratorModelRole.expansion,
  ),
  @HiveField(1)
  taskAnalyzer(
    'Task Analyzer',
    'Analyzes requirements + scope',
    OrchestratorModelRole.analysis,
  ),
  @HiveField(2)
  planner(
    'Planner',
    'Generates step-by-step execution plan',
    OrchestratorModelRole.planning,
  ),
  @HiveField(3)
  researcher(
    'Research Agent',
    'Gathers context from web + knowledge base',
    OrchestratorModelRole.research,
  ),
  @HiveField(4)
  architect(
    'Architecture Agent',
    'Designs system architecture',
    OrchestratorModelRole.planning,
  ),
  @HiveField(5)
  generator(
    'Generator Agent',
    'Generates content (text, copy, docs)',
    OrchestratorModelRole.generation,
  ),
  @HiveField(6)
  codeAgent(
    'Code Agent',
    'Writes/refactors code',
    OrchestratorModelRole.coding,
  ),
  @HiveField(7)
  imageAgent(
    'Image Agent',
    'Generates + edits images',
    OrchestratorModelRole.image,
  ),
  @HiveField(8)
  videoAgent(
    'Video Agent',
    'Generates + edits videos',
    OrchestratorModelRole.video,
  ),
  @HiveField(9)
  audioAgent(
    'Audio Agent',
    'TTS, STT, music generation',
    OrchestratorModelRole.audio,
  ),
  @HiveField(10)
  reviewer(
    'Reviewer',
    'Critiques outputs of other agents',
    OrchestratorModelRole.analysis,
  ),
  @HiveField(11)
  qualityChecker(
    'Quality Checker',
    'Verifies completeness + consistency',
    OrchestratorModelRole.analysis,
  ),
  @HiveField(12)
  securityChecker(
    'Security Checker',
    'Audits for vulnerabilities + leaks',
    OrchestratorModelRole.analysis,
  ),
  @HiveField(13)
  performanceOptimizer(
    'Performance Optimizer',
    'Optimizes code + UI for 60-120fps',
    OrchestratorModelRole.analysis,
  ),
  @HiveField(14)
  finalValidator(
    'Final Validator',
    'Final gate before delivery',
    OrchestratorModelRole.analysis,
  );

  const OrchestratorAgent(this.displayName, this.description, this.defaultRole);

  final String displayName;
  final String description;
  final OrchestratorModelRole defaultRole;

  /// Suggested model preference for this agent's task type.
  /// Routed through [AIProviderFactory.autoSelect] at runtime.
  static OrchestratorAgent fromIndex(int i) =>
      OrchestratorAgent.values[i.clamp(0, OrchestratorAgent.values.length - 1)];
}

/// Maps an agent to a model-routing bucket. The orchestrator uses this to
/// pick the best provider per task (Gemini for research/planning, GLM for
/// expansion/analysis/docs, etc.).
enum OrchestratorModelRole {
  expansion, // GLM-5.2
  analysis, // GLM-5.2 / Claude
  planning, // Gemini 1.5 Pro
  research, // Gemini 1.5 Pro
  generation, // GPT-4o / Claude
  coding, // Claude 3.5 Sonnet
  image, // FLUX/SDXL/DALL-E
  video, // Runway/Pika/Luma/Kling
  audio, // ElevenLabs + Whisper
}

// ---------------------------------------------------------------------------
// Pipeline state
// ---------------------------------------------------------------------------

/// 10-step execution pipeline. Each step maps to one or more agents.
enum OrchestratorStep {
  understand('Understand request', OrchestratorAgent.taskAnalyzer),
  expand('Expand request into spec', OrchestratorAgent.promptExpander),
  analyze('Analyze requirements', OrchestratorAgent.taskAnalyzer),
  architect('Generate architecture', OrchestratorAgent.architect),
  plan('Generate implementation plan', OrchestratorAgent.planner),
  validate('Validate plan', OrchestratorAgent.qualityChecker),
  optimize('Optimize', OrchestratorAgent.performanceOptimizer),
  review('Review outputs', OrchestratorAgent.reviewer),
  securityAudit('Security audit', OrchestratorAgent.securityChecker),
  deliver('Final delivery', OrchestratorAgent.finalValidator);

  const OrchestratorStep(this.label, this.leadAgent);
  final String label;
  final OrchestratorAgent leadAgent;
}

enum OrchestratorStepStatus { pending, running, completed, failed, skipped }

// ---------------------------------------------------------------------------
// Shared memory
// ---------------------------------------------------------------------------

/// The shared scratchpad all agents read from and write to during a single
/// orchestrator run. Each entry is timestamped + attributed so the UI can
/// render a full execution timeline.
@HiveType(typeId: 210)
class SharedMemoryEntry extends Equatable {
  const SharedMemoryEntry({
    required this.id,
    required this.agent,
    required this.key,
    required this.value,
    required this.timestamp,
    this.kind = MemoryEntryKind.output,
    this.metadata = const {},
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final OrchestratorAgent agent;

  @HiveField(2)
  final String key; // e.g. 'spec', 'architecture', 'plan', 'review.notes'

  @HiveField(3)
  final String value;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  final MemoryEntryKind kind;

  @HiveField(6)
  final Map<String, dynamic> metadata;

  SharedMemoryEntry copyWith({
    String? id,
    OrchestratorAgent? agent,
    String? key,
    String? value,
    DateTime? timestamp,
    MemoryEntryKind? kind,
    Map<String, dynamic>? metadata,
  }) =>
      SharedMemoryEntry(
        id: id ?? this.id,
        agent: agent ?? this.agent,
        key: key ?? this.key,
        value: value ?? this.value,
        timestamp: timestamp ?? this.timestamp,
        kind: kind ?? this.kind,
        metadata: metadata ?? this.metadata,
      );

  @override
  List<Object?> get props => [id, agent, key, value, timestamp, kind, metadata];
}

@HiveType(typeId: 211)
enum MemoryEntryKind {
  @HiveField(0)
  context, // read by agents
  @HiveField(1)
  output, // produced by an agent
  @HiveField(2)
  critique, // reviewer feedback
  @HiveField(3)
  revision, // improved version of an output
  @HiveField(4)
  toolCall, // MCP/external tool invocation
  @HiveField(5)
  apiCall, // provider API call log
  @HiveField(6)
  error, // failure recorded
}

/// Shared memory snapshot. Live-updated as the pipeline runs. Every agent
/// can read every prior entry; writes are append-only (with optional
/// supersede flag).
class SharedMemory {
  SharedMemory({this.runId, this.originalRequest}) : _entries = [];

  final String? runId;
  final String? originalRequest;
  final List<SharedMemoryEntry> _entries;
  final _controller = StreamController<SharedMemoryEntry>.broadcast();

  Stream<SharedMemoryEntry> get changes => _controller.stream;
  List<SharedMemoryEntry> get entries => List.unmodifiable(_entries);

  /// Read the latest value for a given key (or null).
  String? latest(String key) {
    for (var i = _entries.length - 1; i >= 0; i--) {
      if (_entries[i].key == key) return _entries[i].value;
    }
    return null;
  }

  /// Read ALL values for a given key, in chronological order.
  List<SharedMemoryEntry> history(String key) =>
      _entries.where((e) => e.key == key).toList();

  /// Append a new entry. Returns the entry so callers can chain.
  SharedMemoryEntry write({
    required OrchestratorAgent agent,
    required String key,
    required String value,
    MemoryEntryKind kind = MemoryEntryKind.output,
    Map<String, dynamic> metadata = const {},
  }) {
    final entry = SharedMemoryEntry(
      id: '${DateTime.now().microsecondsSinceEpoch}-${_entries.length}',
      agent: agent,
      key: key,
      value: value,
      timestamp: DateTime.now(),
      kind: kind,
      metadata: metadata,
    );
    _entries.add(entry);
    _controller.add(entry);
    return entry;
  }

  /// Append a critique (reviewer feedback on another agent's output).
  SharedMemoryEntry critique({
    required OrchestratorAgent critic,
    required String targetKey,
    required String notes,
    required bool approved,
  }) =>
      write(
        agent: critic,
        key: 'critique.$targetKey',
        value: notes,
        kind: MemoryEntryKind.critique,
        metadata: {'approved': approved, 'targetKey': targetKey},
      );

  /// Record a tool call (MCP, web search, code exec).
  SharedMemoryEntry recordToolCall({
    required OrchestratorAgent agent,
    required String toolName,
    required Map<String, dynamic> arguments,
    required dynamic result,
  }) =>
      write(
        agent: agent,
        key: 'tool.$toolName',
        value: result?.toString() ?? '',
        kind: MemoryEntryKind.toolCall,
        metadata: {'tool': toolName, 'arguments': arguments, 'result': result},
      );

  /// Record a provider API call.
  SharedMemoryEntry recordApiCall({
    required OrchestratorAgent agent,
    required String provider,
    required String model,
    required int tokensIn,
    required int tokensOut,
    required double costUsd,
  }) =>
      write(
        agent: agent,
        key: 'api.$provider.$model',
        value:
            '$tokensIn in / $tokensOut out / \$${costUsd.toStringAsFixed(4)}',
        kind: MemoryEntryKind.apiCall,
        metadata: {
          'provider': provider,
          'model': model,
          'tokensIn': tokensIn,
          'tokensOut': tokensOut,
          'costUsd': costUsd,
        },
      );

  /// Record a failure (used by the error-recovery subsystem).
  SharedMemoryEntry recordError({
    required OrchestratorAgent agent,
    required String message,
    required String stackTrace,
  }) =>
      write(
        agent: agent,
        key: 'error.${agent.name}',
        value: message,
        kind: MemoryEntryKind.error,
        metadata: {'stackTrace': stackTrace},
      );

  /// Snapshot as JSON-serializable map (for persistence + UI replay).
  Map<String, dynamic> toJson() => {
        'runId': runId,
        'originalRequest': originalRequest,
        'entries': _entries
            .map(
              (e) => {
                'id': e.id,
                'agent': e.agent.name,
                'key': e.key,
                'value': e.value,
                'timestamp': e.timestamp.toIso8601String(),
                'kind': e.kind.name,
                'metadata': e.metadata,
              },
            )
            .toList(),
      };

  Future<void> dispose() async => _controller.close();
}

// ---------------------------------------------------------------------------
// Per-agent execution state (for UI)
// ---------------------------------------------------------------------------

@HiveType(typeId: 212)
class AgentExecutionState extends Equatable {
  const AgentExecutionState({
    required this.agent,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.currentTask,
    this.outputKey,
    this.error,
    this.tokenUsage = 0,
    this.modelUsed,
    this.revisionCount = 0,
  });

  @HiveField(0)
  final OrchestratorAgent agent;

  @HiveField(1)
  final AgentRunStatus status;

  @HiveField(2)
  final DateTime startedAt;

  @HiveField(3)
  final DateTime? completedAt;

  @HiveField(4)
  final String? currentTask;

  @HiveField(5)
  final String? outputKey;

  @HiveField(6)
  final String? error;

  @HiveField(7)
  final int tokenUsage;

  @HiveField(8)
  final String? modelUsed;

  @HiveField(9)
  final int revisionCount;

  Duration? get duration => completedAt?.difference(startedAt);

  AgentExecutionState copyWith({
    OrchestratorAgent? agent,
    AgentRunStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    String? currentTask,
    String? outputKey,
    String? error,
    int? tokenUsage,
    String? modelUsed,
    int? revisionCount,
  }) =>
      AgentExecutionState(
        agent: agent ?? this.agent,
        status: status ?? this.status,
        startedAt: startedAt ?? this.startedAt,
        completedAt: completedAt ?? this.completedAt,
        currentTask: currentTask ?? this.currentTask,
        outputKey: outputKey ?? this.outputKey,
        error: error,
        tokenUsage: tokenUsage ?? this.tokenUsage,
        modelUsed: modelUsed ?? this.modelUsed,
        revisionCount: revisionCount ?? this.revisionCount,
      );

  @override
  List<Object?> get props => [
        agent,
        status,
        startedAt,
        completedAt,
        currentTask,
        outputKey,
        error,
        tokenUsage,
        modelUsed,
        revisionCount,
      ];
}

@HiveType(typeId: 213)
enum AgentRunStatus {
  @HiveField(0)
  queued,
  @HiveField(1)
  running,
  @HiveField(2)
  completed,
  @HiveField(3)
  failed,
  @HiveField(4)
  retrying,
}

// ---------------------------------------------------------------------------
// Pipeline progress (for UI timeline)
// ---------------------------------------------------------------------------

class OrchestratorProgress extends Equatable {
  const OrchestratorProgress({
    required this.currentStep,
    required this.currentAgent,
    required this.stepStatus,
    required this.overallProgress,
    this.message,
    this.toolCall,
    this.apiCall,
    this.memoryUpdate,
  });

  final OrchestratorStep currentStep;
  final OrchestratorAgent currentAgent;
  final OrchestratorStepStatus stepStatus;
  final double overallProgress; // 0.0 - 1.0
  final String? message;
  final String? toolCall;
  final String? apiCall;
  final SharedMemoryEntry? memoryUpdate;

  @override
  List<Object?> get props => [
        currentStep,
        currentAgent,
        stepStatus,
        overallProgress,
        message,
        toolCall,
        apiCall,
        memoryUpdate,
      ];
}

// ---------------------------------------------------------------------------
// Final deliverable
// ---------------------------------------------------------------------------

class OrchestratorDeliverable extends Equatable {
  const OrchestratorDeliverable({
    required this.spec,
    required this.architecture,
    required this.plan,
    required this.finalOutput,
    required this.securityAudit,
    required this.qualityReport,
    required this.totalTokensIn,
    required this.totalTokensOut,
    required this.totalCostUsd,
    required this.duration,
    required this.agentStates,
    required this.memory,
  });

  final String spec;
  final String architecture;
  final String plan;
  final String finalOutput;
  final String securityAudit;
  final String qualityReport;
  final int totalTokensIn;
  final int totalTokensOut;
  final double totalCostUsd;
  final Duration duration;
  final Map<OrchestratorAgent, AgentExecutionState> agentStates;
  final SharedMemory memory;

  @override
  List<Object?> get props => [
        spec,
        architecture,
        plan,
        finalOutput,
        securityAudit,
        qualityReport,
        totalTokensIn,
        totalTokensOut,
        totalCostUsd,
        duration,
        agentStates,
        memory,
      ];
}
