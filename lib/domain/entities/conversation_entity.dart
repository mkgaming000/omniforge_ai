// Conversation entity - represents a chat thread
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

import 'message_entity.dart';
import 'model_config_entity.dart';

part 'conversation_entity.g.dart';

@HiveType(typeId: 1)
class ConversationEntity extends Equatable {
  const ConversationEntity({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.messages = const [],
    this.modelConfigs = const [],
    this.pinned = false,
    this.archived = false,
    this.folderId,
    this.tags = const [],
    this.systemPrompt,
    this.summary,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final DateTime updatedAt;

  @HiveField(4)
  final List<MessageEntity> messages;

  @HiveField(5)
  final List<ModelConfigEntity> modelConfigs;

  @HiveField(6)
  final bool pinned;

  @HiveField(7)
  final bool archived;

  @HiveField(8)
  final String? folderId;

  @HiveField(9)
  final List<String> tags;

  @HiveField(10)
  final String? systemPrompt;

  @HiveField(11)
  final String? summary;

  ConversationEntity copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<MessageEntity>? messages,
    List<ModelConfigEntity>? modelConfigs,
    bool? pinned,
    bool? archived,
    String? folderId,
    List<String>? tags,
    String? systemPrompt,
    String? summary,
  }) {
    return ConversationEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
      modelConfigs: modelConfigs ?? this.modelConfigs,
      pinned: pinned ?? this.pinned,
      archived: archived ?? this.archived,
      folderId: folderId ?? this.folderId,
      tags: tags ?? this.tags,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      summary: summary ?? this.summary,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        createdAt,
        updatedAt,
        messages,
        modelConfigs,
        pinned,
        archived,
        folderId,
        tags,
        systemPrompt,
        summary,
      ];
}
