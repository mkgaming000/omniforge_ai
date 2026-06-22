// Message entity - chat message with multi-model support
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

import 'model_config_entity.dart';

part 'message_entity.g.dart';

@HiveType(typeId: 0)
enum MessageRole {
  @HiveField(0)
  system,
  @HiveField(1)
  user,
  @HiveField(2)
  assistant,
  @HiveField(3)
  tool,
  @HiveField(4)
  function,
}

@HiveType(typeId: 8)
enum MessageStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  sending,
  @HiveField(2)
  streaming,
  @HiveField(3)
  complete,
  @HiveField(4)
  error,
  @HiveField(5)
  cancelled,
}

@HiveType(typeId: 2)
class MessageEntity extends Equatable {
  const MessageEntity({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.modelConfig,
    this.status = MessageStatus.complete,
    this.tokensIn = 0,
    this.tokensOut = 0,
    this.costUsd = 0.0,
    this.attachments = const [],
    this.toolCalls = const [],
    this.toolCallId,
    this.metadata = const {},
    this.error,
    this.streamingText,
    this.translations = const {},
    this.rating,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final MessageRole role;

  @HiveField(2)
  final String content;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final ModelConfigEntity? modelConfig;

  @HiveField(5)
  final MessageStatus status;

  @HiveField(6)
  final int tokensIn;

  @HiveField(7)
  final int tokensOut;

  @HiveField(8)
  final double costUsd;

  @HiveField(9)
  final List<MessageAttachment> attachments;

  @HiveField(10)
  final List<ToolCall> toolCalls;

  @HiveField(11)
  final String? toolCallId;

  @HiveField(12)
  final Map<String, dynamic> metadata;

  @HiveField(13)
  final String? error;

  @HiveField(14)
  final String? streamingText;

  @HiveField(15)
  final Map<String, String> translations;

  @HiveField(16)
  final int? rating;

  MessageEntity copyWith({
    String? id,
    MessageRole? role,
    String? content,
    DateTime? createdAt,
    ModelConfigEntity? modelConfig,
    MessageStatus? status,
    int? tokensIn,
    int? tokensOut,
    double? costUsd,
    List<MessageAttachment>? attachments,
    List<ToolCall>? toolCalls,
    String? toolCallId,
    Map<String, dynamic>? metadata,
    String? error,
    String? streamingText,
    Map<String, String>? translations,
    int? rating,
  }) {
    return MessageEntity(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      modelConfig: modelConfig ?? this.modelConfig,
      status: status ?? this.status,
      tokensIn: tokensIn ?? this.tokensIn,
      tokensOut: tokensOut ?? this.tokensOut,
      costUsd: costUsd ?? this.costUsd,
      attachments: attachments ?? this.attachments,
      toolCalls: toolCalls ?? this.toolCalls,
      toolCallId: toolCallId ?? this.toolCallId,
      metadata: metadata ?? this.metadata,
      error: error ?? this.error,
      streamingText: streamingText ?? this.streamingText,
      translations: translations ?? this.translations,
      rating: rating ?? this.rating,
    );
  }

  @override
  List<Object?> get props => [
        id,
        role,
        content,
        createdAt,
        modelConfig,
        status,
        tokensIn,
        tokensOut,
        costUsd,
        attachments,
        toolCalls,
        toolCallId,
        metadata,
        error,
        streamingText,
        translations,
        rating,
      ];
}

@HiveType(typeId: 3)
class MessageAttachment extends Equatable {
  const MessageAttachment({
    required this.id,
    required this.type,
    required this.url,
    this.mimeType,
    this.size,
    this.name,
    this.thumbnailUrl,
    this.metadata = const {},
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final AttachmentType type;

  @HiveField(2)
  final String url;

  @HiveField(3)
  final String? mimeType;

  @HiveField(4)
  final int? size;

  @HiveField(5)
  final String? name;

  @HiveField(6)
  final String? thumbnailUrl;

  @HiveField(7)
  final Map<String, dynamic> metadata;

  @override
  List<Object?> get props =>
      [id, type, url, mimeType, size, name, thumbnailUrl, metadata];
}

@HiveType(typeId: 4)
enum AttachmentType {
  @HiveField(0)
  image,
  @HiveField(1)
  video,
  @HiveField(2)
  audio,
  @HiveField(3)
  file,
  @HiveField(4)
  code,
}

@HiveType(typeId: 5)
class ToolCall extends Equatable {
  const ToolCall({
    required this.id,
    required this.name,
    required this.arguments,
    this.result,
    this.status = ToolCallStatus.pending,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String arguments;

  @HiveField(3)
  final String? result;

  @HiveField(4)
  final ToolCallStatus status;

  @override
  List<Object?> get props => [id, name, arguments, result, status];
}

@HiveType(typeId: 6)
enum ToolCallStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  running,
  @HiveField(2)
  success,
  @HiveField(3)
  error,
}
