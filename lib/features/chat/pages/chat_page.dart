// Chat Page - main chat interface with multi-model support
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/ai_providers.dart';
import '../../../domain/entities/message_entity.dart';
import '../../../domain/entities/model_config_entity.dart';
import '../../../presentation/blocs/chat/chat_bloc.dart';
import '../../../presentation/blocs/chat/chat_event.dart';
import '../../../presentation/blocs/chat/chat_state.dart';
import '../widgets/message_bubble.dart';
import '../widgets/model_selector.dart';
import '../widgets/chat_input.dart';
import '../widgets/streaming_indicator.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key, this.conversationId});

  final String? conversationId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        return Column(
          children: [
            // Model selector bar
            const _ModelBar(),
            // Messages list
            Expanded(
              child: state.messages.isEmpty
                  ? const _EmptyChatState()
                  : _MessagesList(messages: state.messages),
            ),
            // Streaming indicator
            if (state.status == ChatStatus.streaming)
              const StreamingIndicator(),
            // Input bar
            const ChatInput(),
          ],
        );
      },
    );
  }
}

class _ModelBar extends StatelessWidget {
  const _ModelBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              Expanded(
                child: ModelSelector(
                  activeModel: state.activeModel,
                  onModelSelected: (config) {
                    context.read<ChatBloc>().add(ModelChanged(config));
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.compare_arrows),
                tooltip: 'Compare models',
                onPressed: () => _showCompareDialog(context),
              ),
              IconButton(
                icon: const Icon(Icons.tune),
                tooltip: 'Model parameters',
                onPressed: () =>
                    _showParametersDialog(context, state.activeModel),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCompareDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _CompareModelsDialog(),
    );
  }

  void _showParametersDialog(BuildContext context, ModelConfigEntity config) {
    showDialog(
      context: context,
      builder: (context) => _ParametersDialog(config: config),
    );
  }
}

class _MessagesList extends StatelessWidget {
  const _MessagesList({required this.messages});

  final List<MessageEntity> messages;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[messages.length - 1 - index];
        return MessageBubble(
          message: message,
          onRegenerate: () {
            context.read<ChatBloc>().add(MessageRegenerated(message.id));
          },
          onDelete: () {
            context.read<ChatBloc>().add(MessageDeleted(message.id));
          },
          onEdit: (newContent) {
            context.read<ChatBloc>().add(MessageEdited(message.id, newContent));
          },
        ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.05, end: 0);
      },
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState();

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      ('Explain quantum computing simply', Icons.science_outlined),
      ('Write a Python web scraper', Icons.code),
      ('Generate a business plan', Icons.business_center_outlined),
      ('Translate "Hello" to 10 languages', Icons.translate),
      ('Summarize the latest AI news', Icons.newspaper),
      ('Help me debug my React code', Icons.bug_report_outlined),
    ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6750A4), Color(0xFF00E5FF)],
                ),
              ),
              child:
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
            ).animate().scale(duration: 500.ms),
            const SizedBox(height: 24),
            Text(
              'How can I help you today?',
              style: Theme.of(context).textTheme.headlineSmall,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            Text(
              'Powered by 20+ AI models. Switch instantly.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 32),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: suggestions
                  .map(
                    (s) => _SuggestionChip(
                      text: s.$1,
                      icon: s.$2,
                      onTap: () {
                        context
                            .read<ChatBloc>()
                            .add(UserMessageSent(content: s.$1));
                      },
                    ),
                  )
                  .toList(),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  final String text;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(text),
      onPressed: onTap,
    );
  }
}

class _CompareModelsDialog extends StatefulWidget {
  const _CompareModelsDialog();

  @override
  State<_CompareModelsDialog> createState() => _CompareModelsDialogState();
}

class _CompareModelsDialogState extends State<_CompareModelsDialog> {
  final _selected = <ModelConfigEntity>[];
  final _promptController = TextEditingController();

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Compare Models'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                labelText: 'Prompt',
                hintText: 'Enter a prompt to send to all selected models',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            const Text('Select models to compare:'),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: AIProvider.values.where((p) => p.isChat).length,
                itemBuilder: (context, index) {
                  final provider =
                      AIProvider.values.where((p) => p.isChat).elementAt(index);
                  final isSelected = _selected.any(
                    (c) => c.provider == provider,
                  );
                  return CheckboxListTile(
                    value: isSelected,
                    title: Text(provider.displayName),
                    subtitle: Text(provider.description),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selected.add(
                            ModelConfigEntity(
                              provider: provider,
                              modelId: 'default',
                            ),
                          );
                        } else {
                          _selected.removeWhere(
                            (c) => c.provider == provider,
                          );
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selected.length < 2 || _promptController.text.isEmpty
              ? null
              : () {
                  context.read<ChatBloc>().add(
                        MultiModelCompare(
                          content: _promptController.text,
                          configs: _selected,
                        ),
                      );
                  Navigator.of(context).pop();
                },
          child: const Text('Compare'),
        ),
      ],
    );
  }
}

class _ParametersDialog extends StatefulWidget {
  const _ParametersDialog({required this.config});
  final ModelConfigEntity config;

  @override
  State<_ParametersDialog> createState() => _ParametersDialogState();
}

class _ParametersDialogState extends State<_ParametersDialog> {
  late double _temperature;
  late double _maxTokens;
  late double _topP;

  @override
  void initState() {
    super.initState();
    _temperature = widget.config.temperature;
    _maxTokens = widget.config.maxTokens.toDouble();
    _topP = widget.config.topP;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Model Parameters'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Temperature: ${_temperature.toStringAsFixed(2)}'),
          Slider(
            value: _temperature,
            min: 0,
            max: 2,
            divisions: 20,
            onChanged: (v) => setState(() => _temperature = v),
          ),
          Text('Max Tokens: ${_maxTokens.toInt()}'),
          Slider(
            value: _maxTokens,
            min: 256,
            max: 32768,
            divisions: 50,
            onChanged: (v) => setState(() => _maxTokens = v),
          ),
          Text('Top P: ${_topP.toStringAsFixed(2)}'),
          Slider(
            value: _topP,
            min: 0,
            max: 1,
            divisions: 20,
            onChanged: (v) => setState(() => _topP = v),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final updated = widget.config.copyWith(
              temperature: _temperature,
              maxTokens: _maxTokens.toInt(),
              topP: _topP,
            );
            context.read<ChatBloc>().add(ModelChanged(updated));
            Navigator.of(context).pop();
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
