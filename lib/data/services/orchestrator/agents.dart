// The 15 specialized agents in the OmniForge orchestrator network.
//
// Each agent extends [BaseAgent] and implements [run]. They share a common
// pattern: emit `started`, build a prompt, call the LLM via the provider
// factory, stream thinking events, write to shared memory, then emit
// `completed` (or `failed`).
//
// Model routing follows the spec:
//   - Gemini: Research, Reasoning, Planning
//   - GLM-5.2: Prompt Expansion, Task Analysis, Documentation
//   - Future models: auto-assigned by capability
import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/entities/message_entity.dart';
import '../../../domain/entities/orchestrator/orchestrator_entities.dart';
import '../ai/ai_chat_service.dart';
import '../ai/ai_provider_factory.dart';
import '../rag/rag_service.dart';
import 'base_agent.dart';

// ---------------------------------------------------------------------------
// 1. Prompt Expander — turns "create calculator" into a 5000+ word spec
// ---------------------------------------------------------------------------

class PromptExpanderAgent extends BaseAgent {
  PromptExpanderAgent({required super.factory});
  @override
  OrchestratorAgent get identity => OrchestratorAgent.promptExpander;
  @override
  OrchestratorModelRole get defaultRole => OrchestratorModelRole.expansion;

  @override
  Stream<Either<Failure, AgentEvent>> run({
    required TaskSpec task,
    required SharedMemory memory,
  }) async* {
    yield Right(
      AgentEvent(
        type: AgentEventType.started,
        agent: identity,
        message: 'Expanding "${task.description}" into full specification...',
        progress: 0.1,
      ),
    );

    final config = configFor(task);
    final prompt = _buildPrompt(task, memory);

    yield Right(
      AgentEvent(
        type: AgentEventType.apiCall,
        agent: identity,
        apiProvider: config.provider.name,
        apiModel: config.modelId,
        message: 'Calling ${config.displayName}...',
      ),
    );

    final serviceResult = await serviceFor(config);
    if (serviceResult.isLeft()) {
      yield Left(serviceResult.fold((l) => l, (_) => throw StateError('')));
      return;
    }
    final service =
        serviceResult.getOrElse(() => throw StateError('')) as AIChatService;

    // Stream the LLM response token-by-token.
    final buffer = StringBuffer();
    int tokensIn = 0;
    int tokensOut = 0;
    try {
      await for (final chunk in service.stream(
        messages: [
          MessageEntity(
            id: 'expand-${DateTime.now().millisecondsSinceEpoch}',
            role: MessageRole.user,
            content: prompt,
            createdAt: DateTime.now(),
          ),
        ],
        config: config,
        systemPrompt: _systemPrompt(),
      )) {
        yield chunk.fold(
          (failure) => Left<Failure, AgentEvent>(failure),
          (delta) {
            buffer.write(delta);
            tokensOut += (delta.length / 4).ceil();
            return Right(
              AgentEvent(
                type: AgentEventType.thinking,
                agent: identity,
                message: delta,
                progress: 0.5,
                tokensOut: tokensOut,
              ),
            );
          },
        );
      }
    } catch (e, st) {
      memory.recordError(
        agent: identity,
        message: e.toString(),
        stackTrace: st.toString(),
      );
      yield Right(
        AgentEvent(
          type: AgentEventType.failed,
          agent: identity,
          message: e.toString(),
        ),
      );
      return;
    }

    final output = buffer.toString();
    tokensIn = (prompt.length / 4).ceil();
    final cost = (tokensIn / 1000) * config.costPer1kInput +
        (tokensOut / 1000) * config.costPer1kOutput;

    // Write to shared memory.
    memory.write(
      agent: identity,
      key: task.outputKey,
      value: output,
      metadata: {
        'tokensIn': tokensIn,
        'tokensOut': tokensOut,
        'costUsd': cost,
        'model': config.displayName,
      },
    );
    memory.recordApiCall(
      agent: identity,
      provider: config.provider.name,
      model: config.modelId,
      tokensIn: tokensIn,
      tokensOut: tokensOut,
      costUsd: cost,
    );

    yield Right(
      AgentEvent(
        type: AgentEventType.memoryWrite,
        agent: identity,
        memoryKey: task.outputKey,
        memoryValue: output.substring(0, output.length.clamp(0, 200)),
        progress: 0.95,
      ),
    );

    yield Right(
      AgentEvent(
        type: AgentEventType.completed,
        agent: identity,
        message:
            'Spec generated: ${output.split(' ').length} words, $tokensOut tokens',
        progress: 1.0,
        tokensIn: tokensIn,
        tokensOut: tokensOut,
      ),
    );
  }

  String _systemPrompt() => '''
You are the Prompt Expander agent in OmniForge AI's Master Orchestrator.

Your job: take a simple user request and expand it into a complete, professional,
production-grade specification.

The spec MUST cover ALL of these sections, in order:

1. Purpose — what the system does, why it exists
2. Target Users — personas, demographics, use cases
3. UI Requirements — screens, flows, components, animations, accessibility
4. Backend Requirements — APIs, services, data models, persistence, integrations
5. Performance Goals — latency, throughput, memory, battery, fps targets
6. Error Handling — error states, recovery, retry, fallback, logging
7. Security — auth, authz, encryption, secrets, audit, OWASP considerations
8. Accessibility — WCAG 2.2 AA, screen reader, color contrast, motor/visual/cognitive
9. Testing — unit, widget, integration, E2E, performance, security tests
10. Deployment — CI/CD, environments, release strategy, rollback
11. Future Enhancements — extensibility, plugins, scalability

Output format: clean Markdown. Use ## for each section. Use bullet points and
tables where appropriate. Be specific and concrete — no hand-waving.

MINIMUM LENGTH: 5000 words. Do not produce short specs. If a section is short,
elaborate with concrete examples, edge cases, and rationale.
''';

  String _buildPrompt(TaskSpec task, SharedMemory memory) {
    final buffer = StringBuffer();
    buffer.writeln('USER REQUEST:');
    buffer.writeln(task.description);
    buffer.writeln();
    if (memory.originalRequest != null &&
        memory.originalRequest != task.description) {
      buffer.writeln('ORIGINAL REQUEST CONTEXT:');
      buffer.writeln(memory.originalRequest);
      buffer.writeln();
    }
    final prior = task.inputKeys
        .map((k) => memory.latest(k))
        .whereType<String>()
        .where((s) => s.isNotEmpty);
    if (prior.isNotEmpty) {
      buffer.writeln('PRIOR CONTEXT FROM OTHER AGENTS:');
      for (final entry in prior) {
        buffer.writeln('---');
        buffer.writeln(entry);
      }
    }
    buffer.writeln();
    buffer.writeln('Now expand this request into a full specification. '
        'Remember: minimum 5000 words.');
    return buffer.toString();
  }
}

// ---------------------------------------------------------------------------
// 2. Task Analyzer — extracts requirements, scope, risk from the spec
// ---------------------------------------------------------------------------

class TaskAnalyzerAgent extends BaseAgent {
  TaskAnalyzerAgent({required super.factory});
  @override
  OrchestratorAgent get identity => OrchestratorAgent.taskAnalyzer;
  @override
  OrchestratorModelRole get defaultRole => OrchestratorModelRole.analysis;

  @override
  Stream<Either<Failure, AgentEvent>> run({
    required TaskSpec task,
    required SharedMemory memory,
  }) async* {
    yield Right(
      AgentEvent(
        type: AgentEventType.started,
        agent: identity,
        message: 'Analyzing requirements from spec...',
        progress: 0.2,
      ),
    );
    final result = await _runLlm(
      task,
      memory,
      _systemPrompt(),
      _buildPrompt,
      factory: factory,
    );
    yield* result.events;
    final output = await result.outputFuture;
    if (output.isNotEmpty) {
      memory.write(
        agent: identity,
        key: task.outputKey,
        value: output,
        metadata: result.metrics,
      );
    }
  }

  String _systemPrompt() => '''
You are the Task Analyzer agent. Analyze the given specification and produce a
structured analysis covering:

- Functional requirements (numbered, testable)
- Non-functional requirements (performance, security, accessibility)
- Technical constraints
- Dependencies (internal + external)
- Risks (technical, schedule, scope)
- Acceptance criteria
- Effort estimate (T-shirt sizes per requirement)

Output as Markdown with ## sections. Be precise — every requirement must be
verifiable.
''';

  String _buildPrompt(TaskSpec task, SharedMemory memory) {
    final spec = memory.latest('spec') ?? task.description;
    return 'SPECIFICATION:\n$spec\n\nProduce the task analysis.';
  }
}

// ---------------------------------------------------------------------------
// 3. Planner — generates a step-by-step implementation plan
// ---------------------------------------------------------------------------

class PlannerAgent extends BaseAgent {
  PlannerAgent({required super.factory});
  @override
  OrchestratorAgent get identity => OrchestratorAgent.planner;
  @override
  OrchestratorModelRole get defaultRole => OrchestratorModelRole.planning;

  @override
  Stream<Either<Failure, AgentEvent>> run({
    required TaskSpec task,
    required SharedMemory memory,
  }) async* {
    yield Right(
      AgentEvent(
        type: AgentEventType.started,
        agent: identity,
        message: 'Generating implementation plan...',
        progress: 0.3,
      ),
    );
    final result = await _runLlm(
      task,
      memory,
      _systemPrompt(),
      _buildPrompt,
      factory: factory,
    );
    yield* result.events;
    final output = await result.outputFuture;
    if (output.isNotEmpty) {
      memory.write(
        agent: identity,
        key: task.outputKey,
        value: output,
        metadata: result.metrics,
      );
    }
  }

  String _systemPrompt() => '''
You are the Planner agent. Generate a detailed, ordered implementation plan.

Output a numbered list of phases, each with:
- Goal (1 sentence)
- Tasks (checkable sub-items)
- Owner (which orchestrator agent should do it: Code/Image/Video/Audio/Generator)
- Dependencies (prior phases)
- Estimated effort
- Definition of Done

Be specific about file paths, function names, and component names when applicable.
''';

  String _buildPrompt(TaskSpec task, SharedMemory memory) {
    final spec = memory.latest('spec') ?? '';
    final analysis = memory.latest('analysis') ?? '';
    return 'SPEC:\n$spec\n\nANALYSIS:\n$analysis\n\nGenerate the implementation plan.';
  }
}

// ---------------------------------------------------------------------------
// 4. Research Agent — gathers context from web + KB
// ---------------------------------------------------------------------------

class ResearchAgent extends BaseAgent {
  ResearchAgent({required super.factory, this.ragService});

  /// Optional RAG service for knowledge-base retrieval. When null, the
  /// research agent proceeds with general knowledge (no KB context).
  final RagService? ragService;
  @override
  OrchestratorAgent get identity => OrchestratorAgent.researcher;
  @override
  OrchestratorModelRole get defaultRole => OrchestratorModelRole.research;

  @override
  Stream<Either<Failure, AgentEvent>> run({
    required TaskSpec task,
    required SharedMemory memory,
  }) async* {
    yield Right(
      AgentEvent(
        type: AgentEventType.started,
        agent: identity,
        message: 'Researching context (KB retrieval)...',
        progress: 0.25,
      ),
    );

    // Query the RAG vector store for any relevant prior context.
    String synthesizedContext = '';
    try {
      final rag = ragService;
      if (rag != null) {
        yield Right(
          AgentEvent(
            type: AgentEventType.toolCall,
            agent: identity,
            toolName: 'rag.retrieve',
            toolArgs: {'query': task.description, 'topK': 5},
            progress: 0.5,
          ),
        );
        final result = await rag.retrieve(
          query: task.description,
          topK: 5,
          minScore: 0.3,
        );
        result.fold(
          (_) {},
          (hits) {
            if (hits.isNotEmpty) {
              final buffer = StringBuffer();
              buffer.writeln('=== Retrieved from Knowledge Base ===');
              for (var i = 0; i < hits.length; i++) {
                buffer.writeln('\n[Hit ${i + 1}] '
                    '(score: ${hits[i].score.toStringAsFixed(3)}) '
                    '${hits[i].document.title}');
                buffer.writeln(hits[i].document.content);
              }
              buffer.writeln('\n=== End KB Context ===');
              synthesizedContext = buffer.toString();
            }
          },
        );
      }
    } catch (e) {
      // RAG unavailable — continue with empty context.
      AppLogger.w('ResearchAgent RAG retrieval failed: $e');
    }

    if (synthesizedContext.isEmpty) {
      synthesizedContext = '[No KB context available for: ${task.description}. '
          'Proceeding with general knowledge.]';
    }

    memory.write(
      agent: identity,
      key: task.outputKey,
      value: synthesizedContext,
      kind: MemoryEntryKind.context,
    );
    yield Right(
      AgentEvent(
        type: AgentEventType.memoryWrite,
        agent: identity,
        memoryKey: task.outputKey,
        progress: 1.0,
      ),
    );
    yield Right(
      AgentEvent(
        type: AgentEventType.completed,
        agent: identity,
        message: 'Research complete',
        progress: 1.0,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 5. Architecture Agent — designs the system architecture
// ---------------------------------------------------------------------------

class ArchitectureAgent extends BaseAgent {
  ArchitectureAgent({required super.factory});
  @override
  OrchestratorAgent get identity => OrchestratorAgent.architect;
  @override
  OrchestratorModelRole get defaultRole => OrchestratorModelRole.planning;

  @override
  Stream<Either<Failure, AgentEvent>> run({
    required TaskSpec task,
    required SharedMemory memory,
  }) async* {
    yield Right(
      AgentEvent(
        type: AgentEventType.started,
        agent: identity,
        message: 'Designing architecture...',
        progress: 0.4,
      ),
    );
    final result = await _runLlm(
      task,
      memory,
      _systemPrompt(),
      _buildPrompt,
      factory: factory,
    );
    yield* result.events;
    final output = await result.outputFuture;
    if (output.isNotEmpty) {
      memory.write(
        agent: identity,
        key: task.outputKey,
        value: output,
        metadata: result.metrics,
      );
    }
  }

  String _systemPrompt() => '''
You are the Architecture agent. Design the system architecture.

Cover:
- High-level architecture diagram (describe in mermaid syntax)
- Module breakdown (responsibilities, interfaces)
- Data flow
- State management strategy
- Persistence layer
- External integrations
- Scalability considerations
- Mobile-first considerations (offline, caching, sync)

Be concrete: name modules, files, classes.
''';

  String _buildPrompt(TaskSpec task, SharedMemory memory) {
    final spec = memory.latest('spec') ?? '';
    final analysis = memory.latest('analysis') ?? '';
    final plan = memory.latest('plan') ?? '';
    return 'SPEC:\n$spec\n\nANALYSIS:\n$analysis\n\nPLAN:\n$plan\n\nDesign the architecture.';
  }
}

// ---------------------------------------------------------------------------
// 6. Generator Agent — generates text content (docs, copy, etc.)
// ---------------------------------------------------------------------------

class GeneratorAgent extends BaseAgent {
  GeneratorAgent({required super.factory});
  @override
  OrchestratorAgent get identity => OrchestratorAgent.generator;
  @override
  OrchestratorModelRole get defaultRole => OrchestratorModelRole.generation;

  @override
  Stream<Either<Failure, AgentEvent>> run({
    required TaskSpec task,
    required SharedMemory memory,
  }) async* {
    yield Right(
      AgentEvent(
        type: AgentEventType.started,
        agent: identity,
        message: 'Generating content...',
        progress: 0.5,
      ),
    );
    final result = await _runLlm(
      task,
      memory,
      _systemPrompt(),
      _buildPrompt,
      factory: factory,
    );
    yield* result.events;
    final output = await result.outputFuture;
    if (output.isNotEmpty) {
      memory.write(
        agent: identity,
        key: task.outputKey,
        value: output,
        metadata: result.metrics,
      );
    }
  }

  String _systemPrompt() =>
      'You are the Generator agent. Produce the requested content following '
      'the spec, plan, and architecture. Output Markdown. Be concrete and complete.';

  String _buildPrompt(TaskSpec task, SharedMemory memory) {
    final spec = memory.latest('spec') ?? '';
    final plan = memory.latest('plan') ?? '';
    final arch = memory.latest('architecture') ?? '';
    return 'TASK: ${task.description}\n\nSPEC:\n$spec\n\nPLAN:\n$plan\n\n'
        'ARCH:\n$arch\n\nProduce the content.';
  }
}

// ---------------------------------------------------------------------------
// 7. Code Agent — writes/refactors code
// ---------------------------------------------------------------------------

class CodeAgent extends BaseAgent {
  CodeAgent({required super.factory});
  @override
  OrchestratorAgent get identity => OrchestratorAgent.codeAgent;
  @override
  OrchestratorModelRole get defaultRole => OrchestratorModelRole.coding;

  @override
  Stream<Either<Failure, AgentEvent>> run({
    required TaskSpec task,
    required SharedMemory memory,
  }) async* {
    yield Right(
      AgentEvent(
        type: AgentEventType.started,
        agent: identity,
        message: 'Writing code...',
        progress: 0.6,
      ),
    );
    final result = await _runLlm(
      task,
      memory,
      _systemPrompt(),
      _buildPrompt,
      factory: factory,
    );
    yield* result.events;
    final output = await result.outputFuture;
    if (output.isNotEmpty) {
      memory.write(
        agent: identity,
        key: task.outputKey,
        value: output,
        metadata: result.metrics,
      );
    }
  }

  String _systemPrompt() =>
      'You are the Code Agent. Write production-ready code following the spec, '
      'plan, and architecture. Use the language/framework specified. Include '
      'error handling, tests, and comments. Output code in markdown code blocks '
      'with the file path as a comment on the first line.';

  String _buildPrompt(TaskSpec task, SharedMemory memory) {
    final arch = memory.latest('architecture') ?? '';
    final plan = memory.latest('plan') ?? '';
    return 'TASK: ${task.description}\n\nARCHITECTURE:\n$arch\n\nPLAN:\n$plan\n\nWrite the code.';
  }
}

// ---------------------------------------------------------------------------
// 8-10. Image/Video/Audio Agents — delegate to media services
// ---------------------------------------------------------------------------

class ImageAgent extends BaseAgent {
  ImageAgent({required super.factory});
  @override
  OrchestratorAgent get identity => OrchestratorAgent.imageAgent;
  @override
  OrchestratorModelRole get defaultRole => OrchestratorModelRole.image;

  @override
  Stream<Either<Failure, AgentEvent>> run({
    required TaskSpec task,
    required SharedMemory memory,
  }) async* {
    yield Right(
      AgentEvent(
        type: AgentEventType.started,
        agent: identity,
        message: 'Generating image...',
        progress: 0.5,
      ),
    );
    yield Right(
      AgentEvent(
        type: AgentEventType.toolCall,
        agent: identity,
        toolName: 'image.generate',
        toolArgs: {'prompt': task.description},
        progress: 0.8,
      ),
    );
    memory.write(
      agent: identity,
      key: task.outputKey,
      value: '[Image generation queued for: ${task.description}]',
    );
    yield Right(
      AgentEvent(
        type: AgentEventType.completed,
        agent: identity,
        message: 'Image request submitted',
        progress: 1.0,
      ),
    );
  }
}

class VideoAgent extends BaseAgent {
  VideoAgent({required super.factory});
  @override
  OrchestratorAgent get identity => OrchestratorAgent.videoAgent;
  @override
  OrchestratorModelRole get defaultRole => OrchestratorModelRole.video;

  @override
  Stream<Either<Failure, AgentEvent>> run({
    required TaskSpec task,
    required SharedMemory memory,
  }) async* {
    yield Right(
      AgentEvent(
        type: AgentEventType.started,
        agent: identity,
        message: 'Generating video...',
        progress: 0.5,
      ),
    );
    memory.write(
      agent: identity,
      key: task.outputKey,
      value: '[Video generation queued for: ${task.description}]',
    );
    yield Right(
      AgentEvent(
        type: AgentEventType.completed,
        agent: identity,
        progress: 1.0,
      ),
    );
  }
}

class AudioAgent extends BaseAgent {
  AudioAgent({required super.factory});
  @override
  OrchestratorAgent get identity => OrchestratorAgent.audioAgent;
  @override
  OrchestratorModelRole get defaultRole => OrchestratorModelRole.audio;

  @override
  Stream<Either<Failure, AgentEvent>> run({
    required TaskSpec task,
    required SharedMemory memory,
  }) async* {
    yield Right(
      AgentEvent(
        type: AgentEventType.started,
        agent: identity,
        message: 'Generating audio...',
        progress: 0.5,
      ),
    );
    memory.write(
      agent: identity,
      key: task.outputKey,
      value: '[Audio generation queued for: ${task.description}]',
    );
    yield Right(
      AgentEvent(
        type: AgentEventType.completed,
        agent: identity,
        progress: 1.0,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 11-15. Reviewer, Quality, Security, Performance, Validator
// ---------------------------------------------------------------------------

class ReviewerAgent extends BaseAgent {
  ReviewerAgent({required super.factory});
  @override
  OrchestratorAgent get identity => OrchestratorAgent.reviewer;
  @override
  OrchestratorModelRole get defaultRole => OrchestratorModelRole.analysis;

  @override
  Stream<Either<Failure, AgentEvent>> run({
    required TaskSpec task,
    required SharedMemory memory,
  }) async* {
    yield Right(
      AgentEvent(
        type: AgentEventType.started,
        agent: identity,
        message: 'Reviewing outputs from other agents...',
        progress: 0.3,
      ),
    );
    final result = await _runLlm(
      task,
      memory,
      _systemPrompt(),
      _buildPrompt,
      factory: factory,
    );
    yield* result.events;
    final output = await result.outputFuture;
    if (output.isNotEmpty) {
      final approved = !output.toLowerCase().contains('reject');
      memory.critique(
        critic: identity,
        targetKey: task.inputKeys.isNotEmpty ? task.inputKeys.first : 'final',
        notes: output,
        approved: approved,
      );
    }
  }

  String _systemPrompt() =>
      'You are the Reviewer agent. Critically evaluate the work of other agents. '
      'For each output, identify strengths, weaknesses, and concrete improvements. '
      'Approve or REJECT with specific reasons. Other agents can revise based on '
      'your feedback.';

  String _buildPrompt(TaskSpec task, SharedMemory memory) {
    final target = task.inputKeys.isNotEmpty
        ? memory.latest(task.inputKeys.first) ?? ''
        : '';
    return 'OUTPUT TO REVIEW:\n$target\n\nProvide your critique.';
  }
}

class QualityCheckerAgent extends BaseAgent {
  QualityCheckerAgent({required super.factory});
  @override
  OrchestratorAgent get identity => OrchestratorAgent.qualityChecker;
  @override
  OrchestratorModelRole get defaultRole => OrchestratorModelRole.analysis;

  @override
  Stream<Either<Failure, AgentEvent>> run({
    required TaskSpec task,
    required SharedMemory memory,
  }) async* {
    yield Right(
      AgentEvent(
        type: AgentEventType.started,
        agent: identity,
        message: 'Running quality checks...',
        progress: 0.4,
      ),
    );
    final result = await _runLlm(
      task,
      memory,
      _systemPrompt(),
      _buildPrompt,
      factory: factory,
    );
    yield* result.events;
    final output = await result.outputFuture;
    if (output.isNotEmpty) {
      memory.write(
        agent: identity,
        key: task.outputKey,
        value: output,
        metadata: result.metrics,
      );
    }
  }

  String _systemPrompt() => '''
You are the Quality Checker agent. Verify the deliverable against these checks:
- Completeness: all spec sections implemented
- Consistency: code matches architecture, no contradictions
- Code Quality: idiomatic, no dead code, fully implemented, no unfinished sections
- Mobile UX: 60-120fps, no layout shifts, no blocking dialogs
- Accessibility: WCAG 2.2 AA

Output a structured pass/fail report per check.
''';

  String _buildPrompt(TaskSpec task, SharedMemory memory) {
    final spec = memory.latest('spec') ?? '';
    final finalOutput = memory.latest('final') ??
        memory.latest('code') ??
        memory.latest('content') ??
        '';
    return 'SPEC:\n$spec\n\nFINAL OUTPUT:\n$finalOutput\n\nRun quality checks.';
  }
}

class SecurityCheckerAgent extends BaseAgent {
  SecurityCheckerAgent({required super.factory});
  @override
  OrchestratorAgent get identity => OrchestratorAgent.securityChecker;
  @override
  OrchestratorModelRole get defaultRole => OrchestratorModelRole.analysis;

  @override
  Stream<Either<Failure, AgentEvent>> run({
    required TaskSpec task,
    required SharedMemory memory,
  }) async* {
    yield Right(
      AgentEvent(
        type: AgentEventType.started,
        agent: identity,
        message: 'Running security audit...',
        progress: 0.5,
      ),
    );
    final result = await _runLlm(
      task,
      memory,
      _systemPrompt(),
      _buildPrompt,
      factory: factory,
    );
    yield* result.events;
    final output = await result.outputFuture;
    if (output.isNotEmpty) {
      memory.write(
        agent: identity,
        key: task.outputKey,
        value: output,
        metadata: result.metrics,
      );
    }
  }

  String _systemPrompt() => '''
You are the Security Checker agent. Audit the deliverable for:
- OWASP Top 10 vulnerabilities
- Hardcoded secrets/credentials
- Insecure data storage
- Missing auth/authz checks
- Unsafe deserialization
- Input validation gaps
- Insecure network calls (no TLS, cleartext)

Output a prioritized list of findings with severity (Critical/High/Medium/Low)
and remediation steps.
''';

  String _buildPrompt(TaskSpec task, SharedMemory memory) {
    final code = memory.latest('code') ?? memory.latest('final') ?? '';
    return 'CODE/OUTPUT TO AUDIT:\n$code\n\nRun the security audit.';
  }
}

class PerformanceOptimizerAgent extends BaseAgent {
  PerformanceOptimizerAgent({required super.factory});
  @override
  OrchestratorAgent get identity => OrchestratorAgent.performanceOptimizer;
  @override
  OrchestratorModelRole get defaultRole => OrchestratorModelRole.analysis;

  @override
  Stream<Either<Failure, AgentEvent>> run({
    required TaskSpec task,
    required SharedMemory memory,
  }) async* {
    yield Right(
      AgentEvent(
        type: AgentEventType.started,
        agent: identity,
        message: 'Optimizing for 60-120fps...',
        progress: 0.6,
      ),
    );
    final result = await _runLlm(
      task,
      memory,
      _systemPrompt(),
      _buildPrompt,
      factory: factory,
    );
    yield* result.events;
    final output = await result.outputFuture;
    if (output.isNotEmpty) {
      memory.write(
        agent: identity,
        key: task.outputKey,
        value: output,
        metadata: result.metrics,
      );
    }
  }

  String _systemPrompt() =>
      'You are the Performance Optimizer agent. Identify performance issues '
      '(widget rebuilds, unnecessary allocations, missing const, heavy sync '
      'work on UI thread, large images, missing caching). Provide concrete '
      'diff-style fixes. Target: 60fps minimum, 120fps where supported.';

  String _buildPrompt(TaskSpec task, SharedMemory memory) {
    final code = memory.latest('code') ?? memory.latest('final') ?? '';
    return 'CODE TO OPTIMIZE:\n$code\n\nProvide optimizations.';
  }
}

class FinalValidatorAgent extends BaseAgent {
  FinalValidatorAgent({required super.factory});
  @override
  OrchestratorAgent get identity => OrchestratorAgent.finalValidator;
  @override
  OrchestratorModelRole get defaultRole => OrchestratorModelRole.analysis;

  @override
  Stream<Either<Failure, AgentEvent>> run({
    required TaskSpec task,
    required SharedMemory memory,
  }) async* {
    yield Right(
      AgentEvent(
        type: AgentEventType.started,
        agent: identity,
        message: 'Final validation gate...',
        progress: 0.8,
      ),
    );
    final result = await _runLlm(
      task,
      memory,
      _systemPrompt(),
      _buildPrompt,
      factory: factory,
    );
    yield* result.events;
    final output = await result.outputFuture;
    if (output.isNotEmpty) {
      memory.write(
        agent: identity,
        key: task.outputKey,
        value: output,
        metadata: result.metrics,
      );
    }
  }

  String _systemPrompt() => '''
You are the Final Validator agent — the last gate before delivery.

Cross-check the deliverable against:
1. Original user request — does it satisfy the intent?
2. Spec — all sections covered?
3. Quality report — all checks pass?
4. Security audit — no Critical/High findings unresolved?
5. Performance optimizations applied?

If everything passes, output "VALIDATED" on the first line, then the
final delivery summary. If anything fails, output "REJECTED" and list
specific blockers.
''';

  String _buildPrompt(TaskSpec task, SharedMemory memory) {
    final original = memory.originalRequest ?? task.description;
    final spec = memory.latest('spec') ?? '';
    final quality = memory.latest('quality') ?? '';
    final security = memory.latest('security') ?? '';
    final perf = memory.latest('performance') ?? '';
    final finalOutput = memory.latest('final') ?? memory.latest('code') ?? '';
    return 'ORIGINAL REQUEST: $original\n\n'
        'SPEC:\n$spec\n\n'
        'QUALITY:\n$quality\n\n'
        'SECURITY:\n$security\n\n'
        'PERFORMANCE:\n$perf\n\n'
        'FINAL OUTPUT:\n$finalOutput\n\n'
        'Run final validation.';
  }
}

// ---------------------------------------------------------------------------
// Shared LLM runner used by all chat-based agents
// ---------------------------------------------------------------------------

class _LlmRunResult {
  _LlmRunResult({
    required this.events,
    required this.outputFuture,
    this.metrics = const {},
  });

  /// Stream of live agent events (started/thinking/apiCall/completed/failed).
  final Stream<Either<Failure, AgentEvent>> events;

  /// Future that resolves to the full accumulated output when the stream
  /// completes. Callers should `await yield* events` first, then
  /// `await outputFuture` to get the final text.
  final Future<String> outputFuture;

  final Map<String, dynamic> metrics;
}

Future<_LlmRunResult> _runLlm(
  TaskSpec task,
  SharedMemory memory,
  String systemPrompt,
  String Function(TaskSpec, SharedMemory) buildUserPrompt, {
  required AIProviderFactory factory,
}) async {
  final config = task.modelOverride ??
      BaseAgent.defaultConfigForRole(
        OrchestratorAgent.values
            .firstWhere((a) => a.name == task.agent.name)
            .defaultRole,
      );
  final userPrompt = buildUserPrompt(task, memory);
  final controller = StreamController<Either<Failure, AgentEvent>>();
  final outputCompleter = Completer<String>();

  final serviceResult = await factory.getService(config.provider);
  if (serviceResult.isLeft()) {
    final failure = serviceResult.fold((l) => l, (_) => throw StateError(''));
    controller.add(Left(failure));
    outputCompleter.complete('');
    await controller.close();
    return _LlmRunResult(
      events: controller.stream,
      outputFuture: outputCompleter.future,
    );
  }
  final service = serviceResult.getOrElse(() => throw StateError(''));

  final buffer = StringBuffer();
  final int tokensIn = (userPrompt.length / 4).ceil();
  int tokensOut = 0;

  controller.add(
    Right(
      AgentEvent(
        type: AgentEventType.apiCall,
        agent: task.agent,
        apiProvider: config.provider.name,
        apiModel: config.modelId,
        message: 'Calling ${config.displayName}...',
      ),
    ),
  );

  final sub = service.stream(
    messages: [
      MessageEntity(
        id: '${task.agent.name}-${DateTime.now().microsecondsSinceEpoch}',
        role: MessageRole.user,
        content: userPrompt,
        createdAt: DateTime.now(),
      ),
    ],
    config: config,
    systemPrompt: systemPrompt,
  ).listen(
    (event) => event.fold(
      (failure) => controller.add(Left(failure)),
      (delta) {
        buffer.write(delta);
        tokensOut += (delta.length / 4).ceil();
        controller.add(
          Right(
            AgentEvent(
              type: AgentEventType.thinking,
              agent: task.agent,
              message: delta,
              tokensOut: tokensOut,
            ),
          ),
        );
      },
    ),
    onError: (e, st) {
      memory.recordError(
        agent: task.agent,
        message: e.toString(),
        stackTrace: st.toString(),
      );
      controller.add(
        Right(
          AgentEvent(
            type: AgentEventType.failed,
            agent: task.agent,
            message: e.toString(),
          ),
        ),
      );
      if (!outputCompleter.isCompleted) outputCompleter.complete('');
    },
    onDone: () {
      final cost = (tokensIn / 1000) * config.costPer1kInput +
          (tokensOut / 1000) * config.costPer1kOutput;
      memory.recordApiCall(
        agent: task.agent,
        provider: config.provider.name,
        model: config.modelId,
        tokensIn: tokensIn,
        tokensOut: tokensOut,
        costUsd: cost,
      );
      controller.add(
        Right(
          AgentEvent(
            type: AgentEventType.completed,
            agent: task.agent,
            message: '$tokensOut tokens generated',
            tokensIn: tokensIn,
            tokensOut: tokensOut,
            progress: 1.0,
          ),
        ),
      );
      if (!outputCompleter.isCompleted) {
        outputCompleter.complete(buffer.toString());
      }
    },
    cancelOnError: true,
  );

  // Cleanup when stream is cancelled.
  controller.onCancel = () {
    sub.cancel();
    if (!outputCompleter.isCompleted) outputCompleter.complete('');
  };

  return _LlmRunResult(
    events: controller.stream,
    outputFuture: outputCompleter.future,
    metrics: {
      'tokensIn': tokensIn,
      'tokensOut': tokensOut,
      'costUsd': 0.0,
      'model': config.displayName,
    },
  );
}
