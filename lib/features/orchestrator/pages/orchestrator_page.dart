// Orchestrator Page — the "Live AI Thinking" command center.
//
// Shows:
//   - Current agent + current task
//   - Overall progress (10-step pipeline)
//   - Execution timeline (chronological list of all agent messages)
//   - Tool calls (MCP/external)
//   - API calls (provider + model + tokens + cost)
//   - Memory updates (live shared memory writes)
//   - Final deliverable (when complete)
//
// Mobile-first, glassmorphism, 60fps animations, one-hand operation.
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../injection/injection.dart';
import '../../../presentation/blocs/orchestrator/orchestrator_bloc.dart';
import '../../../presentation/blocs/orchestrator/orchestrator_event.dart';
import '../../../presentation/blocs/orchestrator/orchestrator_state.dart';
import '../../../domain/entities/orchestrator/orchestrator_entities.dart';

class OrchestratorPage extends StatelessWidget {
  const OrchestratorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OrchestratorBloc>(),
      child: const _OrchestratorView(),
    );
  }
}

class _OrchestratorView extends StatelessWidget {
  const _OrchestratorView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrchestratorBloc, OrchestratorState>(
      builder: (context, state) {
        return Column(
          children: [
            const _RequestInput(),
            _ProgressBar(progress: state.overallProgress),
            _CurrentAgentBanner(state: state),
            Expanded(
              child: state.progress.isEmpty
                  ? const _IdleState()
                  : _Timeline(progress: state.progress),
            ),
            if (state.deliverable != null)
              _DeliverableBanner(deliverable: state.deliverable!),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Request input
// ---------------------------------------------------------------------------

class _RequestInput extends StatefulWidget {
  const _RequestInput();

  @override
  State<_RequestInput> createState() => _RequestInputState();
}

class _RequestInputState extends State<_RequestInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !context.select<OrchestratorBloc, bool>(
                  (bloc) => bloc.state.isRunning,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. "create calculator"',
                  prefixIcon: const Icon(Icons.auto_awesome, size: 18),
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
                onSubmitted: (value) => _run(context, value),
              ),
            ),
            const SizedBox(width: 8),
            BlocBuilder<OrchestratorBloc, OrchestratorState>(
              buildWhen: (a, b) => a.isRunning != b.isRunning,
              builder: (context, state) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6750A4), Color(0xFF00E5FF)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    icon: state.isRunning
                        ? const Icon(Icons.stop, color: Colors.white)
                        : const Icon(Icons.play_arrow, color: Colors.white),
                    onPressed: state.isRunning
                        ? () => context
                            .read<OrchestratorBloc>()
                            .add(const OrchestratorCancelled())
                        : () => _run(context, _controller.text),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _run(BuildContext context, String request) {
    final r = request.trim();
    if (r.isEmpty) return;
    _controller.clear();
    context.read<OrchestratorBloc>().add(OrchestratorRunRequested(r));
  }
}

// ---------------------------------------------------------------------------
// Overall progress bar (10 steps)
// ---------------------------------------------------------------------------

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: progress,
      minHeight: 4,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      valueColor: AlwaysStoppedAnimation(
        Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Current agent banner — shows who's working + what they're doing
// ---------------------------------------------------------------------------

class _CurrentAgentBanner extends StatelessWidget {
  const _CurrentAgentBanner({required this.state});
  final OrchestratorState state;

  @override
  Widget build(BuildContext context) {
    if (state.currentAgent == null) return const SizedBox.shrink();
    final agent = state.currentAgent!;
    final step = state.currentStep;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            agent.defaultRole.color(),
            agent.defaultRole.color().withOpacity(0.7),
          ],
        ),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  agent.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (state.currentMessage != null)
                  Text(
                    state.currentMessage!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          if (step != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Step ${step.index + 1}/10',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    ).animate(key: ValueKey(agent.name)).slideY(begin: -0.1, end: 0);
  }
}

// ---------------------------------------------------------------------------
// Timeline — chronological list of every progress event
// ---------------------------------------------------------------------------

class _Timeline extends StatelessWidget {
  const _Timeline({required this.progress});
  final List<OrchestratorProgress> progress;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      reverse: true,
      itemCount: progress.length,
      itemBuilder: (context, index) {
        final event = progress[progress.length - 1 - index];
        return _TimelineEntry(event: event)
            .animate(key: ValueKey(event.hashCode))
            .fadeIn(duration: 200.ms)
            .slideY(begin: 0.05, end: 0);
      },
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({required this.event});
  final OrchestratorProgress event;

  @override
  Widget build(BuildContext context) {
    final color = event.stepStatus.color();
    final icon = event.stepStatus.icon();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      event.currentAgent.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      event.currentStep.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (event.message != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    event.message!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (event.toolCall != null) ...[
                  const SizedBox(height: 4),
                  _Chip(
                    icon: Icons.extension,
                    label: 'Tool: ${event.toolCall}',
                    color: Colors.purple,
                  ),
                ],
                if (event.apiCall != null) ...[
                  const SizedBox(height: 4),
                  _Chip(
                    icon: Icons.cloud,
                    label: 'API: ${event.apiCall}',
                    color: Colors.blue,
                  ),
                ],
              ],
            ),
          ),
          Text(
            '${(event.overallProgress * 100).toInt()}%',
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Idle state — shown before the user submits a request
// ---------------------------------------------------------------------------

class _IdleState extends StatelessWidget {
  const _IdleState();

  @override
  Widget build(BuildContext context) {
    const agents = OrchestratorAgent.values;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF6750A4), Color(0xFF00E5FF)],
              ),
            ),
            child: const Icon(Icons.hub, color: Colors.white, size: 40),
          ).animate().scale(duration: 500.ms),
          const SizedBox(height: 16),
          Text(
            'Master Orchestrator',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            '15 agents. 10-step pipeline. Production-grade output.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            'Agent Network',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: agents
                .map(
                  (a) => Chip(
                    avatar: Icon(
                      Icons.smart_toy,
                      size: 14,
                      color: a.defaultRole.color(),
                    ),
                    label: Text(
                      a.displayName,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Model Routing',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  _routeRow('Gemini 1.5 Pro', 'Research · Planning'),
                  _routeRow('GLM-5.2', 'Prompt Expansion · Analysis · Docs'),
                  _routeRow('Claude 3.5 Sonnet', 'Code · Generation'),
                  _routeRow('FLUX/SDXL', 'Image generation'),
                  _routeRow('Runway/Luma/Kling', 'Video generation'),
                  _routeRow('ElevenLabs/Whisper', 'Audio · TTS · STT'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _routeRow(String model, String tasks) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              model,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              tasks,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Deliverable banner — shown when the pipeline completes
// ---------------------------------------------------------------------------

class _DeliverableBanner extends StatelessWidget {
  const _DeliverableBanner({required this.deliverable});
  final OrchestratorDeliverable deliverable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        border: Border(
          top: BorderSide(color: Colors.green.withOpacity(0.3), width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Delivered in ${deliverable.duration.inSeconds}s',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    '${deliverable.totalTokensIn + deliverable.totalTokensOut} tokens · '
                    '\$${deliverable.totalCostUsd.toStringAsFixed(4)}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _showDeliverable(context),
              child: const Text('View'),
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 0.3, end: 0);
  }

  void _showDeliverable(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.3,
        maxChildSize: 1.0,
        expand: false,
        builder: (context, scrollController) => _DeliverableViewer(
          deliverable: deliverable,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

class _DeliverableViewer extends StatelessWidget {
  const _DeliverableViewer({
    required this.deliverable,
    required this.scrollController,
  });
  final OrchestratorDeliverable deliverable;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Text('Specification', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(deliverable.spec),
        const Divider(height: 32),
        Text('Architecture', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(deliverable.architecture),
        const Divider(height: 32),
        Text(
          'Implementation Plan',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(deliverable.plan),
        const Divider(height: 32),
        Text('Final Output', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(deliverable.finalOutput),
        const Divider(height: 32),
        Text('Security Audit', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(deliverable.securityAudit),
        const Divider(height: 32),
        Text('Quality Report', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(deliverable.qualityReport),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Extensions for nice colors + icons
// ---------------------------------------------------------------------------

extension on OrchestratorModelRole {
  Color color() {
    switch (this) {
      case OrchestratorModelRole.expansion:
        return const Color(0xFF3B5BFE); // Zhipu blue
      case OrchestratorModelRole.analysis:
        return const Color(0xFF6750A4); // Violet
      case OrchestratorModelRole.planning:
        return const Color(0xFF4285F4); // Google blue
      case OrchestratorModelRole.research:
        return const Color(0xFF4285F4);
      case OrchestratorModelRole.generation:
        return const Color(0xFFD97757); // Anthropic
      case OrchestratorModelRole.coding:
        return const Color(0xFF10A37F); // OpenAI green
      case OrchestratorModelRole.image:
        return const Color(0xFFFF7028); // Stability orange
      case OrchestratorModelRole.video:
        return const Color(0xFF00E5FF);
      case OrchestratorModelRole.audio:
        return const Color(0xFFFF6B35);
    }
  }
}

extension on OrchestratorStepStatus {
  Color color() {
    switch (this) {
      case OrchestratorStepStatus.pending:
        return Colors.grey;
      case OrchestratorStepStatus.running:
        return Colors.blue;
      case OrchestratorStepStatus.completed:
        return Colors.green;
      case OrchestratorStepStatus.failed:
        return Colors.red;
      case OrchestratorStepStatus.skipped:
        return Colors.orange;
    }
  }

  IconData icon() {
    switch (this) {
      case OrchestratorStepStatus.pending:
        return Icons.schedule;
      case OrchestratorStepStatus.running:
        return Icons.play_arrow;
      case OrchestratorStepStatus.completed:
        return Icons.check_circle;
      case OrchestratorStepStatus.failed:
        return Icons.error;
      case OrchestratorStepStatus.skipped:
        return Icons.skip_next;
    }
  }
}
