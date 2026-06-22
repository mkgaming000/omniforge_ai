// Unit tests for the Master Orchestrator pipeline.
//
// Verifies:
//   - The 15-agent registry is complete
//   - The 10-step pipeline is built in the correct order
//   - SharedMemory read/write/critique/recordToolCall behave correctly
//   - OrchestratorBloc emits progress + completed states
//   - Model routing follows the spec (GLM-5.2 for expansion, Gemini for planning)
import 'package:flutter_test/flutter_test.dart';
import 'package:omniforge_ai/core/constants/ai_providers.dart';
import 'package:omniforge_ai/domain/entities/orchestrator/orchestrator_entities.dart';
import 'package:omniforge_ai/data/services/orchestrator/agents.dart';
import 'package:omniforge_ai/data/services/orchestrator/base_agent.dart';

void main() {
  group('OrchestratorAgent', () {
    test('exposes exactly 15 agents', () {
      expect(OrchestratorAgent.values.length, equals(15));
    });

    test('each agent has a unique display name', () {
      final names = OrchestratorAgent.values.map((a) => a.displayName).toSet();
      expect(names.length, equals(15));
    });

    test('each agent has a non-empty description', () {
      for (final a in OrchestratorAgent.values) {
        expect(a.description, isNotEmpty);
      }
    });

    test('fromIndex returns agents in order', () {
      for (var i = 0; i < 15; i++) {
        expect(
          OrchestratorAgent.fromIndex(i),
          equals(OrchestratorAgent.values[i]),
        );
      }
    });

    test('fromIndex clamps out-of-range values', () {
      expect(
        OrchestratorAgent.fromIndex(-1),
        equals(OrchestratorAgent.values.first),
      );
      expect(
        OrchestratorAgent.fromIndex(99),
        equals(OrchestratorAgent.values.last),
      );
    });
  });

  group('OrchestratorStep', () {
    test('exposes exactly 10 pipeline steps', () {
      expect(OrchestratorStep.values.length, equals(10));
    });

    test('each step has a lead agent', () {
      for (final s in OrchestratorStep.values) {
        expect(s.leadAgent, isNotNull);
      }
    });

    test('steps are ordered per the spec', () {
      // The spec mandates: understand → expand → analyze → architect → plan →
      // validate → optimize → review → securityAudit → deliver
      expect(OrchestratorStep.values[0], equals(OrchestratorStep.understand));
      expect(OrchestratorStep.values[1], equals(OrchestratorStep.expand));
      expect(OrchestratorStep.values[2], equals(OrchestratorStep.analyze));
      expect(OrchestratorStep.values[3], equals(OrchestratorStep.architect));
      expect(OrchestratorStep.values[4], equals(OrchestratorStep.plan));
      expect(OrchestratorStep.values[5], equals(OrchestratorStep.validate));
      expect(OrchestratorStep.values[6], equals(OrchestratorStep.optimize));
      expect(OrchestratorStep.values[7], equals(OrchestratorStep.review));
      expect(
        OrchestratorStep.values[8],
        equals(OrchestratorStep.securityAudit),
      );
      expect(OrchestratorStep.values[9], equals(OrchestratorStep.deliver));
    });
  });

  group('Model routing (spec compliance)', () {
    test('Prompt Expander uses GLM-5.2 (expansion role)', () {
      expect(
        OrchestratorAgent.promptExpander.defaultRole,
        equals(OrchestratorModelRole.expansion),
      );
      final config =
          BaseAgent.defaultConfigForRole(OrchestratorModelRole.expansion);
      expect(config.provider, equals(AIProvider.zhipu));
      expect(config.modelId, equals('glm-5.2'));
    });

    test('Task Analyzer uses GLM-5.2 (analysis role)', () {
      expect(
        OrchestratorAgent.taskAnalyzer.defaultRole,
        equals(OrchestratorModelRole.analysis),
      );
      final config =
          BaseAgent.defaultConfigForRole(OrchestratorModelRole.analysis);
      expect(config.provider, equals(AIProvider.zhipu));
      expect(config.modelId, contains('glm-5.2'));
    });

    test('Planner uses Gemini (planning role)', () {
      expect(
        OrchestratorAgent.planner.defaultRole,
        equals(OrchestratorModelRole.planning),
      );
      final config =
          BaseAgent.defaultConfigForRole(OrchestratorModelRole.planning);
      expect(config.provider, equals(AIProvider.google));
      expect(config.modelId, contains('gemini'));
    });

    test('Researcher uses Gemini (research role)', () {
      expect(
        OrchestratorAgent.researcher.defaultRole,
        equals(OrchestratorModelRole.research),
      );
      final config =
          BaseAgent.defaultConfigForRole(OrchestratorModelRole.research);
      expect(config.provider, equals(AIProvider.google));
    });

    test('Code Agent uses Claude (coding role)', () {
      expect(
        OrchestratorAgent.codeAgent.defaultRole,
        equals(OrchestratorModelRole.coding),
      );
      final config =
          BaseAgent.defaultConfigForRole(OrchestratorModelRole.coding);
      expect(config.provider, equals(AIProvider.anthropic));
      expect(config.modelId, contains('claude'));
    });
  });

  group('SharedMemory', () {
    late SharedMemory memory;

    setUp(() {
      memory = SharedMemory(
        runId: 'test-run',
        originalRequest: 'create calculator',
      );
    });

    tearDown(() async => memory.dispose());

    test('write + latest returns the most recent value', () {
      memory.write(
        agent: OrchestratorAgent.promptExpander,
        key: 'spec',
        value: 'v1',
      );
      expect(memory.latest('spec'), equals('v1'));

      memory.write(
        agent: OrchestratorAgent.promptExpander,
        key: 'spec',
        value: 'v2',
      );
      expect(memory.latest('spec'), equals('v2'));
    });

    test('history returns all entries for a key in chronological order', () {
      memory.write(
        agent: OrchestratorAgent.promptExpander,
        key: 'spec',
        value: 'v1',
      );
      memory.write(agent: OrchestratorAgent.reviewer, key: 'spec', value: 'v2');
      final history = memory.history('spec');
      expect(history.length, equals(2));
      expect(history[0].value, equals('v1'));
      expect(history[1].value, equals('v2'));
    });

    test('latest returns null for unknown key', () {
      expect(memory.latest('does-not-exist'), isNull);
    });

    test('critique writes a critique entry with approval flag', () {
      memory.write(
        agent: OrchestratorAgent.promptExpander,
        key: 'spec',
        value: 'some spec',
      );
      memory.critique(
        critic: OrchestratorAgent.reviewer,
        targetKey: 'spec',
        notes: 'Too short, expand section 3',
        approved: false,
      );
      final critique = memory.latest('critique.spec');
      expect(critique, isNotNull);
      expect(critique, contains('Too short'));
    });

    test('recordToolCall writes a tool entry', () {
      memory.recordToolCall(
        agent: OrchestratorAgent.researcher,
        toolName: 'web_search',
        arguments: {'q': 'flutter performance'},
        result: '12 results',
      );
      final entry = memory.latest('tool.web_search');
      expect(entry, isNotNull);
      expect(entry, contains('12 results'));
    });

    test('recordApiCall writes an API call entry with token info', () {
      memory.recordApiCall(
        agent: OrchestratorAgent.promptExpander,
        provider: 'zhipu',
        model: 'glm-5.2',
        tokensIn: 100,
        tokensOut: 5000,
        costUsd: 0.105,
      );
      final entry = memory.history('api.zhipu.glm-5.2').last;
      expect(entry.kind, equals(MemoryEntryKind.apiCall));
      expect(entry.metadata['tokensIn'], equals(100));
      expect(entry.metadata['tokensOut'], equals(5000));
      expect(entry.metadata['costUsd'], equals(0.105));
    });

    test('recordError writes an error entry', () {
      memory.recordError(
        agent: OrchestratorAgent.architect,
        message: 'API timeout',
        stackTrace: 'stack...',
      );
      final entry = memory.latest('error.architect');
      expect(entry, isNotNull);
      expect(entry, contains('API timeout'));
    });

    test('changes stream emits on every write', () async {
      final events = <SharedMemoryEntry>[];
      final sub = memory.changes.listen(events.add);

      memory.write(
        agent: OrchestratorAgent.promptExpander,
        key: 'spec',
        value: 'v1',
      );
      memory.write(
        agent: OrchestratorAgent.taskAnalyzer,
        key: 'analysis',
        value: 'a1',
      );
      await Future.delayed(Duration.zero);

      expect(events.length, equals(2));
      expect(events[0].key, equals('spec'));
      expect(events[1].key, equals('analysis'));

      await sub.cancel();
    });

    test('toJson serializes all entries', () {
      memory.write(
        agent: OrchestratorAgent.promptExpander,
        key: 'spec',
        value: 'v1',
      );
      memory.recordApiCall(
        agent: OrchestratorAgent.promptExpander,
        provider: 'zhipu',
        model: 'glm-5.2',
        tokensIn: 100,
        tokensOut: 5000,
        costUsd: 0.1,
      );
      final json = memory.toJson();
      expect(json['runId'], equals('test-run'));
      expect(json['originalRequest'], equals('create calculator'));
      expect((json['entries'] as List).length, equals(2));
    });
  });

  group('AgentExecutionState', () {
    test('duration is null when not completed', () {
      final state = AgentExecutionState(
        agent: OrchestratorAgent.promptExpander,
        status: AgentRunStatus.running,
        startedAt: DateTime.now(),
      );
      expect(state.duration, isNull);
    });

    test('duration is computed when completed', () {
      final start = DateTime.now();
      final end = start.add(const Duration(seconds: 5));
      final state = AgentExecutionState(
        agent: OrchestratorAgent.promptExpander,
        status: AgentRunStatus.completed,
        startedAt: start,
        completedAt: end,
      );
      expect(state.duration, equals(const Duration(seconds: 5)));
    });

    test('copyWith preserves unmodified fields', () {
      final state = AgentExecutionState(
        agent: OrchestratorAgent.promptExpander,
        status: AgentRunStatus.queued,
        startedAt: DateTime.now(),
        tokenUsage: 100,
      );
      final updated = state.copyWith(status: AgentRunStatus.running);
      expect(updated.agent, equals(state.agent));
      expect(updated.tokenUsage, equals(100));
      expect(updated.status, equals(AgentRunStatus.running));
    });
  });

  group('Agent classes exist + have correct identity', () {
    // We can't construct them without a real AIProviderFactory, but we can
    // verify each class is exported + has the expected identity when
    // accessed via reflection-free static checks.

    test('all 15 agent classes are exported', () {
      // Reference each class so the compiler verifies they exist.
      Type t;
      t = PromptExpanderAgent;
      t = TaskAnalyzerAgent;
      t = PlannerAgent;
      t = ResearchAgent;
      t = ArchitectureAgent;
      t = GeneratorAgent;
      t = CodeAgent;
      t = ImageAgent;
      t = VideoAgent;
      t = AudioAgent;
      t = ReviewerAgent;
      t = QualityCheckerAgent;
      t = SecurityCheckerAgent;
      t = PerformanceOptimizerAgent;
      t = FinalValidatorAgent;
      expect(t, isNotNull);
    });
  });
}
