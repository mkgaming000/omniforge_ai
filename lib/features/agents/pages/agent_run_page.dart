// Agent Run Page - chat-like UI for running an agent
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart' show Failure, UnknownFailure;
import '../../../domain/entities/agent_entity.dart';
import '../../../injection/injection.dart';
import '../../../presentation/blocs/agent/agent_bloc.dart';
import '../../../presentation/blocs/agent/agent_event.dart';
import '../../../presentation/blocs/agent/agent_state.dart';
import '../../../presentation/widgets/error_state.dart';
import '../../../presentation/widgets/loading_states.dart';

class AgentRunPage extends StatelessWidget {
  const AgentRunPage({super.key, required this.agent});

  final AgentEntity agent;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AgentBloc>(),
      child: BlocBuilder<AgentBloc, AgentState>(
        builder: (context, state) {
          return Column(
            children: [
              _AgentHeader(agent: agent),
              Expanded(child: _StepsList(state: state)),
              if (state.status == AgentStatus.running) const _RunningBanner(),
              _AgentInput(agent: agent),
            ],
          );
        },
      ),
    );
  }
}

class _AgentHeader extends StatelessWidget {
  const _AgentHeader({required this.agent});
  final AgentEntity agent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: agent.model.provider.brandColor,
            child: Text(
              agent.name[0].toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agent.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${agent.model.provider.displayName} • ${agent.model.displayName ?? agent.model.modelId}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (agent.knowledgeBaseId != null)
            const Chip(
              avatar: Icon(Icons.menu_book, size: 14),
              label: Text('RAG'),
            ),
          if (agent.allowedTools.isNotEmpty)
            Chip(
              avatar: const Icon(Icons.extension, size: 14),
              label: Text('${agent.allowedTools.length} tools'),
            ),
        ],
      ),
    );
  }
}

class _StepsList extends StatelessWidget {
  const _StepsList({required this.state});
  final AgentState state;

  @override
  Widget build(BuildContext context) {
    if (state.runSteps.isEmpty && state.status != AgentStatus.running) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.smart_toy, size: 64, color: Color(0xFF6750A4))
                .animate()
                .fadeIn(duration: 500.ms),
            const SizedBox(height: 16),
            Text(
              'Ready to run',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Describe a task and the agent will reason, use tools, '
              'and produce a final answer.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (state.status == AgentStatus.error && state.runSteps.isEmpty) {
      return ErrorState(
        failure: _stateErrorToFailure(state.error),
        onRetry: () {},
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.runSteps.length,
      itemBuilder: (context, index) {
        final step = state.runSteps[index];
        return _StepCard(step: step)
            .animate()
            .fadeIn(delay: (index * 50).ms)
            .slideY(begin: 0.05, end: 0);
      },
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step});
  final AgentStep step;

  @override
  Widget build(BuildContext context) {
    final config = _styleFor(step.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: config.color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(config.icon, size: 16, color: config.color),
              const SizedBox(width: 8),
              Text(
                config.label,
                style: TextStyle(
                  color: config.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                step.timestamp.toString().substring(11, 19),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            step.content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (step.metadata != null && step.metadata!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                step.metadata.toString(),
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  _StepStyle _styleFor(AgentStepType type) {
    switch (type) {
      case AgentStepType.thinking:
        return const _StepStyle(
          label: 'THINKING',
          icon: Icons.psychology,
          color: Color(0xFF6750A4),
        );
      case AgentStepType.toolCall:
        return const _StepStyle(
          label: 'TOOL CALL',
          icon: Icons.extension,
          color: Color(0xFF00E5FF),
        );
      case AgentStepType.toolResult:
        return const _StepStyle(
          label: 'TOOL RESULT',
          icon: Icons.integration_instructions,
          color: Color(0xFF10A37F),
        );
      case AgentStepType.finalAnswer:
        return const _StepStyle(
          label: 'FINAL ANSWER',
          icon: Icons.check_circle,
          color: Color(0xFFFF6B6B),
        );
    }
  }
}

class _StepStyle {
  const _StepStyle({
    required this.label,
    required this.icon,
    required this.color,
  });
  final String label;
  final IconData icon;
  final Color color;
}

class _RunningBanner extends StatelessWidget {
  const _RunningBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Row(
        children: [
          const PulsingDots(size: 6),
          const SizedBox(width: 12),
          Text(
            'Agent is working...',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () {
              context.read<AgentBloc>().add(const CancelAgentRun());
            },
            icon: const Icon(Icons.stop_circle, size: 16),
            label: const Text('Stop'),
          ),
        ],
      ),
    );
  }
}

class _AgentInput extends StatelessWidget {
  const _AgentInput({required this.agent});
  final AgentEntity agent;

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.3),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: context.select<AgentBloc, bool>(
                  (bloc) => bloc.state.status != AgentStatus.running,
                ),
                decoration: InputDecoration(
                  hintText: 'Describe a task for ${agent.name}...',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                onSubmitted: (text) => _run(context, controller, text),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6750A4), Color(0xFF00E5FF)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: IconButton(
                icon: const Icon(Icons.play_arrow, color: Colors.white),
                onPressed: () => _run(context, controller, controller.text),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _run(
    BuildContext context,
    TextEditingController controller,
    String input,
  ) {
    if (input.trim().isEmpty) return;
    context.read<AgentBloc>().add(RunAgent(agent: agent, input: input.trim()));
    controller.clear();
  }
}

// Helper to convert error string back to a Failure for the ErrorState widget
Failure _stateErrorToFailure(String? error) => UnknownFailure(message: error);
