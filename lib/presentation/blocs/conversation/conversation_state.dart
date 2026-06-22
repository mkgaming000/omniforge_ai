// Conversation State
import 'package:equatable/equatable.dart';

import '../../../domain/entities/conversation_entity.dart';

enum ConversationStatus { initial, loading, ready, error }

class ConversationState extends Equatable {
  const ConversationState({
    this.status = ConversationStatus.initial,
    this.conversations = const [],
    this.selectedId,
    this.error,
  });

  const ConversationState.initial() : this();

  final ConversationStatus status;
  final List<ConversationEntity> conversations;
  final String? selectedId;
  final String? error;

  ConversationState copyWith({
    ConversationStatus? status,
    List<ConversationEntity>? conversations,
    String? selectedId,
    String? error,
  }) {
    return ConversationState(
      status: status ?? this.status,
      conversations: conversations ?? this.conversations,
      selectedId: selectedId ?? this.selectedId,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, conversations, selectedId, error];
}
