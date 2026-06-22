// Conversation List Page - home page showing all conversations
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../injection/injection.dart';
import '../../../presentation/blocs/conversation/conversation_bloc.dart';
import '../../../presentation/blocs/conversation/conversation_event.dart';
import '../../../presentation/blocs/conversation/conversation_state.dart';

class ConversationListPage extends StatelessWidget {
  const ConversationListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ConversationBloc>()..add(const LoadConversations()),
      child: BlocBuilder<ConversationBloc, ConversationState>(
        builder: (context, state) {
          if (state.status == ConversationStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.conversations.isEmpty) {
            return const _EmptyConversationState();
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.conversations.length,
            itemBuilder: (context, index) {
              final conversation = state.conversations[index];
              return Card(
                child: ListTile(
                  title: Text(
                    conversation.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    conversation.messages.isNotEmpty
                        ? conversation.messages.last.content
                        : 'No messages yet',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    _formatTime(conversation.updatedAt),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  onTap: () => context.push('/chat/${conversation.id}'),
                ),
              )
                  .animate()
                  .fadeIn(delay: (index * 50).ms, duration: 300.ms)
                  .slideY(begin: 0.05, end: 0);
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${time.month}/${time.day}';
  }
}

class _EmptyConversationState extends StatelessWidget {
  const _EmptyConversationState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFF6750A4), Color(0xFF00E5FF)],
              ),
            ),
            child:
                const Icon(Icons.auto_awesome, size: 48, color: Colors.white),
          ).animate().scale(duration: 500.ms),
          const SizedBox(height: 24),
          Text(
            'Welcome to OmniForge AI',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to start a new chat',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _startNewChat(context),
            icon: const Icon(Icons.add),
            label: const Text('New Chat'),
          ),
        ],
      ),
    );
  }

  void _startNewChat(BuildContext context) {
    context.read<ConversationBloc>().add(
          const CreateConversation(title: 'New Chat'),
        );
    final state = context.read<ConversationBloc>().state;
    if (state.selectedId != null) {
      context.push('/chat/${state.selectedId}');
    }
  }
}
