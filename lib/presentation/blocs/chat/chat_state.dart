// Chat State
import 'package:equatable/equatable.dart';

import '../../../core/constants/ai_providers.dart';
import '../../../domain/entities/message_entity.dart';
import '../../../domain/entities/model_config_entity.dart';

enum ChatStatus { initial, ready, sending, streaming, comparing, error }

class ChatState extends Equatable {
  const ChatState({
    this.status = ChatStatus.initial,
    this.messages = const [],
    this.activeModel = _defaultModel,
    this.systemPrompt,
    this.error,
    this.conversationId,
  });

  const ChatState.initial() : this();

  static const _defaultModel = ModelConfigEntity(
    provider: AIProvider.openai,
    modelId: 'gpt-4o',
    displayName: 'GPT-4o',
  );

  final ChatStatus status;
  final List<MessageEntity> messages;
  final ModelConfigEntity activeModel;
  final String? systemPrompt;
  final String? error;
  final String? conversationId;

  bool get isBusy =>
      status == ChatStatus.sending ||
      status == ChatStatus.streaming ||
      status == ChatStatus.comparing;

  ChatState copyWith({
    ChatStatus? status,
    List<MessageEntity>? messages,
    ModelConfigEntity? activeModel,
    String? systemPrompt,
    String? error,
    String? conversationId,
  }) {
    return ChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      activeModel: activeModel ?? this.activeModel,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      error: error,
      conversationId: conversationId ?? this.conversationId,
    );
  }

  @override
  List<Object?> get props => [
        status,
        messages,
        activeModel,
        systemPrompt,
        error,
        conversationId,
      ];
}
