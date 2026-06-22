// Chat Events
import 'package:equatable/equatable.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/entities/message_entity.dart';
import '../../../domain/entities/model_config_entity.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();
}

class UserMessageSent extends ChatEvent {
  const UserMessageSent({
    required this.content,
    this.attachments = const [],
    this.config,
    this.systemPrompt,
  });
  final String content;
  final List<MessageAttachment> attachments;
  final ModelConfigEntity? config;
  final String? systemPrompt;

  @override
  List<Object?> get props => [content, attachments, config, systemPrompt];
}

class StreamingCancelled extends ChatEvent {
  const StreamingCancelled(this.failure);
  final Failure? failure;

  @override
  List<Object?> get props => [failure];
}

class MessagesCleared extends ChatEvent {
  const MessagesCleared();
  @override
  List<Object?> get props => [];
}

class ModelChanged extends ChatEvent {
  const ModelChanged(this.config);
  final ModelConfigEntity config;
  @override
  List<Object?> get props => [config];
}

class SystemPromptChanged extends ChatEvent {
  const SystemPromptChanged(this.prompt);
  final String? prompt;
  @override
  List<Object?> get props => [prompt];
}

class MessageDeleted extends ChatEvent {
  const MessageDeleted(this.messageId);
  final String messageId;
  @override
  List<Object?> get props => [messageId];
}

class MessageEdited extends ChatEvent {
  const MessageEdited(this.messageId, this.newContent);
  final String messageId;
  final String newContent;
  @override
  List<Object?> get props => [messageId, newContent];
}

class MessageRegenerated extends ChatEvent {
  const MessageRegenerated(this.messageId);
  final String messageId;
  @override
  List<Object?> get props => [messageId];
}

class MultiModelCompare extends ChatEvent {
  const MultiModelCompare({
    required this.content,
    required this.configs,
  });
  final String content;
  final List<ModelConfigEntity> configs;
  @override
  List<Object?> get props => [content, configs];
}
