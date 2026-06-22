// Orchestrator Pipeline - the 10-step execution engine.
//
// For each user request, the pipeline:
//   1. Understands the request
//   2. Expands it into a 5000+ word spec (PromptExpander)
//   3. Analyzes requirements (TaskAnalyzer)
//   4. Designs architecture (ArchitectureAgent)
//   5. Generates implementation plan (Planner)
//   6. Validates the plan (QualityChecker)
//   7. Optimizes outputs (PerformanceOptimizer)
//   8. Reviews (Reviewer)
//   9. Security audit (SecurityChecker)
//   10. Final delivery (FinalValidator)
//
// Each step:
//   - Wraps the agent in retry/fallback/repair
//   - Streams live [OrchestratorProgress] events for UI
//   - Writes to [SharedMemory] so downstream agents can read prior outputs
import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/entities/orchestrator/orchestrator_entities.dart';
import '../ai/ai_provider_factory.dart';
import '../rag/rag_service.dart';
import 'agents.dart';
import 'base_agent.dart';

class OrchestratorPipeline {
  OrchestratorPipeline({required this.factory, this.ragService}) {
    _agents = _buildAgents();
  }

  final AIProviderFactory factory;
  final RagService? ragService;
  late final Map<OrchestratorAgent, BaseAgent> _agents;

  Map<OrchestratorAgent, BaseAgent> _buildAgents() => {
        OrchestratorAgent.promptExpander: PromptExpanderAgent(factory: factory),
        OrchestratorAgent.taskAnalyzer: TaskAnalyzerAgent(factory: factory),
        OrchestratorAgent.planner: PlannerAgent(factory: factory),
        OrchestratorAgent.researcher:
            ResearchAgent(factory: factory, ragService: ragService),
        OrchestratorAgent.architect: ArchitectureAgent(factory: factory),
        OrchestratorAgent.generator: GeneratorAgent(factory: factory),
        OrchestratorAgent.codeAgent: CodeAgent(factory: factory),
        OrchestratorAgent.imageAgent: ImageAgent(factory: factory),
        OrchestratorAgent.videoAgent: VideoAgent(factory: factory),
        OrchestratorAgent.audioAgent: AudioAgent(factory: factory),
        OrchestratorAgent.reviewer: ReviewerAgent(factory: factory),
        OrchestratorAgent.qualityChecker: QualityCheckerAgent(factory: factory),
        OrchestratorAgent.securityChecker:
            SecurityCheckerAgent(factory: factory),
        OrchestratorAgent.performanceOptimizer:
            PerformanceOptimizerAgent(factory: factory),
        OrchestratorAgent.finalValidator: FinalValidatorAgent(factory: factory),
      };

  /// Run the full 10-step pipeline. Streams live progress for UI.
  Stream<OrchestratorProgress> run({
    required String userRequest,
    int maxRetries = 2,
    Duration stepTimeout = const Duration(minutes: 5),
  }) async* {
    final memory = SharedMemory(
      runId: DateTime.now().microsecondsSinceEpoch.toString(),
      originalRequest: userRequest,
    );

    final agentStates = <OrchestratorAgent, AgentExecutionState>{};
    final startedAt = DateTime.now();
    var totalTokensIn = 0;
    var totalTokensOut = 0;
    var totalCost = 0.0;

    final steps = _buildPipelineSteps(userRequest);

    for (var i = 0; i < steps.length; i++) {
      final step = steps[i];
      final progress = (i + 1) / steps.length;

      yield OrchestratorProgress(
        currentStep: step.step,
        currentAgent: step.task.agent,
        stepStatus: OrchestratorStepStatus.running,
        overallProgress: progress * 0.5, // first half = execution
        message: '${step.step.label}: ${_truncate(step.task.description, 60)}',
      );

      // Retry loop with error recovery.
      var attempt = 0;
      Failure? lastFailure;
      while (attempt <= maxRetries) {
        // Reset per-attempt failure state so a transient error on attempt 1
        // doesn't poison the success check on a clean attempt 2.
        lastFailure = null;
        try {
          final agent = _agents[step.task.agent]!;
          final resultStream = _runAgentWithTimeout(
            agent: agent,
            task: step.task,
            memory: memory,
            timeout: stepTimeout,
            onProgress: (event) {
              // Forward agent events to the pipeline stream as progress.
              // (Caller's listen() will see these in real time.)
            },
          );

          await for (final either in resultStream) {
            either.fold(
              (failure) {
                lastFailure = failure;
                memory.recordError(
                  agent: step.task.agent,
                  message: failure.userMessage,
                  stackTrace: failure.stackTrace?.toString() ?? '',
                );
              },
              (event) {
                agentStates[step.task.agent] = AgentExecutionState(
                  agent: step.task.agent,
                  status: event.type == AgentEventType.failed
                      ? AgentRunStatus.failed
                      : event.type == AgentEventType.completed
                          ? AgentRunStatus.completed
                          : AgentRunStatus.running,
                  startedAt: startedAt,
                  currentTask: event.message,
                  modelUsed: event.apiModel,
                  tokenUsage: (event.tokensIn ?? 0) + (event.tokensOut ?? 0),
                );
                if (event.type == AgentEventType.apiCall) {
                  totalTokensIn += event.tokensIn ?? 0;
                  totalTokensOut += event.tokensOut ?? 0;
                }
                if (event.type == AgentEventType.completed) {
                  // Sum up all API-call costs recorded in shared memory for
                  // this agent. The agent writes one recordApiCall() per LLM
                  // invocation; we sum the costUsd fields.
                  for (final entry in memory.entries.where(
                    (e) =>
                        e.kind == MemoryEntryKind.apiCall &&
                        e.agent == step.task.agent,
                  )) {
                    final cost = entry.metadata['costUsd'];
                    if (cost is num) {
                      totalCost += cost.toDouble();
                    }
                  }
                }
              },
            );
          }

          // Step succeeded if no lastFailure on this attempt.
          if (lastFailure == null) {
            yield OrchestratorProgress(
              currentStep: step.step,
              currentAgent: step.task.agent,
              stepStatus: OrchestratorStepStatus.completed,
              overallProgress: progress,
              message: '${step.step.label} completed',
            );
            break;
          }

          // Step failed — retry if attempts remain.
          attempt++;
          if (attempt <= maxRetries) {
            yield OrchestratorProgress(
              currentStep: step.step,
              currentAgent: step.task.agent,
              stepStatus: OrchestratorStepStatus.running,
              overallProgress: progress,
              message:
                  'Retrying ${step.step.label} (attempt $attempt/$maxRetries): '
                  '${lastFailure?.userMessage ?? 'Unknown error'}',
            );
            // Exponential backoff so we don't hammer a rate-limited or
            // struggling endpoint with immediate retries.
            await Future.delayed(Duration(seconds: 1 << (attempt - 1)));
            // Fallback: try a different provider via autoSelect.
            // (The agent itself uses factory.autoSelect internally if its
            // preferred model fails.)
          }
        } on TimeoutException {
          attempt++;
          lastFailure = TimeoutFailure(
            message: '${step.step.label} timed out after $stepTimeout',
          );
          if (attempt <= maxRetries) {
            yield OrchestratorProgress(
              currentStep: step.step,
              currentAgent: step.task.agent,
              stepStatus: OrchestratorStepStatus.running,
              overallProgress: progress,
              message: 'Step timed out, retrying (attempt $attempt)',
            );
            await Future.delayed(Duration(seconds: 1 << (attempt - 1)));
          }
        } catch (e, st) {
          attempt++;
          lastFailure = UnknownFailure(
            message: e.toString(),
            originalError: e,
            stackTrace: st,
          );
          memory.recordError(
            agent: step.task.agent,
            message: e.toString(),
            stackTrace: st.toString(),
          );
          if (attempt <= maxRetries) {
            yield OrchestratorProgress(
              currentStep: step.step,
              currentAgent: step.task.agent,
              stepStatus: OrchestratorStepStatus.running,
              overallProgress: progress,
              message: 'Step failed, retrying: $e',
            );
            await Future.delayed(Duration(seconds: 1 << (attempt - 1)));
          }
        }
      }

      // If all retries exhausted, mark step as failed but continue pipeline
      // (don't crash — the spec says "Never crash. Never stop workflow.").
      if (lastFailure != null) {
        yield OrchestratorProgress(
          currentStep: step.step,
          currentAgent: step.task.agent,
          stepStatus: OrchestratorStepStatus.failed,
          overallProgress: progress,
          message: '${step.step.label} failed after $maxRetries retries: '
              '${lastFailure?.userMessage ?? 'Unknown error'}. Continuing pipeline.',
        );
      }
    }

    // Final delivery.
    final deliverable = OrchestratorDeliverable(
      spec: memory.latest('spec') ?? '',
      architecture: memory.latest('architecture') ?? '',
      plan: memory.latest('plan') ?? '',
      finalOutput: memory.latest('final') ??
          memory.latest('code') ??
          memory.latest('content') ??
          '',
      securityAudit: memory.latest('security') ?? '',
      qualityReport: memory.latest('quality') ?? '',
      totalTokensIn: totalTokensIn,
      totalTokensOut: totalTokensOut,
      totalCostUsd: totalCost,
      duration: DateTime.now().difference(startedAt),
      agentStates: agentStates,
      memory: memory,
    );

    yield OrchestratorProgress(
      currentStep: OrchestratorStep.deliver,
      currentAgent: OrchestratorAgent.finalValidator,
      stepStatus: OrchestratorStepStatus.completed,
      overallProgress: 1.0,
      message:
          '✓ Pipeline complete. ${deliverable.finalOutput.split(RegExp(r'\\s+')).where((s) => s.isNotEmpty).length} '
          'words delivered. $totalTokensIn in / $totalTokensOut out tokens.',
      memoryUpdate: SharedMemoryEntry(
        id: 'final',
        agent: OrchestratorAgent.finalValidator,
        key: 'deliverable',
        value: deliverable.finalOutput,
        timestamp: DateTime.now(),
      ),
    );

    await memory.dispose();
  }

  /// Run a single agent with a per-step timeout.
  Stream<Either<Failure, AgentEvent>> _runAgentWithTimeout({
    required BaseAgent agent,
    required TaskSpec task,
    required SharedMemory memory,
    required Duration timeout,
    required void Function(AgentEvent) onProgress,
  }) {
    final controller = StreamController<Either<Failure, AgentEvent>>();
    Timer? watchdog;
    StreamSubscription<Either<Failure, AgentEvent>>? sub;

    void cleanup() {
      watchdog?.cancel();
      watchdog = null;
      sub?.cancel();
      sub = null;
    }

    sub = agent.run(task: task, memory: memory).listen(
      (either) {
        if (controller.isClosed) return;
        either.fold(
          (_) => controller.add(either),
          (event) {
            onProgress(event);
            controller.add(either);
          },
        );
      },
      onError: (e, st) {
        if (!controller.isClosed) {
          controller.add(
            Left(
              UnknownFailure(
                message: e.toString(),
                originalError: e,
                stackTrace: st as StackTrace?,
              ),
            ),
          );
        }
      },
      onDone: () {
        watchdog?.cancel();
        if (!controller.isClosed) {
          controller.close();
        }
      },
    );

    // If the pipeline consumer cancels this stream, also cancel the inner
    // agent subscription so the agent doesn't keep running (and burning API
    // tokens) in the background.
    controller.onCancel = cleanup;

    // Watchdog: force-close the stream if the agent takes too long. Cancel
    // the inner subscription FIRST so its callbacks stop firing before we
    // close the controller (avoids "Cannot add new events after close").
    watchdog = Timer(timeout, () {
      if (!controller.isClosed) {
        sub?.cancel();
        controller.add(
          Left(
            TimeoutFailure(
              message: 'Agent ${agent.identity.name} exceeded $timeout',
            ),
          ),
        );
        controller.close();
      }
    });

    return controller.stream;
  }

  /// Truncate [text] to at most [max] characters, appending an ellipsis when
  /// truncation occurs. Safe for inputs shorter than [max].
  String _truncate(String text, int max) {
    if (text.length <= max) return text;
    return '${text.substring(0, max)}…';
  }

  /// Define the 10 pipeline steps for a given user request.
  /// Each step maps to a [TaskSpec] with its required input keys.
  List<_PipelineStep> _buildPipelineSteps(String userRequest) {
    return [
      _PipelineStep(
        step: OrchestratorStep.understand,
        task: TaskSpec(
          description: userRequest,
          outputKey: 'understood',
          agent: OrchestratorAgent.taskAnalyzer,
        ),
      ),
      _PipelineStep(
        step: OrchestratorStep.expand,
        task: TaskSpec(
          description: userRequest,
          outputKey: 'spec',
          agent: OrchestratorAgent.promptExpander,
          inputKeys: ['understood'],
        ),
      ),
      const _PipelineStep(
        step: OrchestratorStep.analyze,
        task: TaskSpec(
          description: 'Analyze the expanded spec',
          outputKey: 'analysis',
          agent: OrchestratorAgent.taskAnalyzer,
          inputKeys: ['spec'],
        ),
      ),
      const _PipelineStep(
        step: OrchestratorStep.architect,
        task: TaskSpec(
          description: 'Design system architecture',
          outputKey: 'architecture',
          agent: OrchestratorAgent.architect,
          inputKeys: ['spec', 'analysis'],
        ),
      ),
      const _PipelineStep(
        step: OrchestratorStep.plan,
        task: TaskSpec(
          description: 'Generate implementation plan',
          outputKey: 'plan',
          agent: OrchestratorAgent.planner,
          inputKeys: ['spec', 'analysis', 'architecture'],
        ),
      ),
      const _PipelineStep(
        step: OrchestratorStep.validate,
        task: TaskSpec(
          description: 'Validate the plan for completeness',
          outputKey: 'validation',
          agent: OrchestratorAgent.qualityChecker,
          inputKeys: ['spec', 'plan'],
        ),
      ),
      const _PipelineStep(
        step: OrchestratorStep.optimize,
        task: TaskSpec(
          description: 'Optimize the generated code/output for performance',
          outputKey: 'performance',
          agent: OrchestratorAgent.performanceOptimizer,
          inputKeys: ['plan', 'architecture'],
        ),
      ),
      const _PipelineStep(
        step: OrchestratorStep.review,
        task: TaskSpec(
          description: 'Review all outputs',
          outputKey: 'review',
          agent: OrchestratorAgent.reviewer,
          inputKeys: ['plan', 'architecture'],
        ),
      ),
      const _PipelineStep(
        step: OrchestratorStep.securityAudit,
        task: TaskSpec(
          description: 'Security audit',
          outputKey: 'security',
          agent: OrchestratorAgent.securityChecker,
          inputKeys: ['architecture', 'plan'],
        ),
      ),
      const _PipelineStep(
        step: OrchestratorStep.deliver,
        task: TaskSpec(
          description: 'Final validation + delivery',
          outputKey: 'final',
          agent: OrchestratorAgent.finalValidator,
          inputKeys: [
            'spec',
            'plan',
            'architecture',
            'validation',
            'performance',
            'review',
            'security',
          ],
        ),
      ),
    ];
  }
}

class _PipelineStep {
  const _PipelineStep({required this.step, required this.task});
  final OrchestratorStep step;
  final TaskSpec task;
}
