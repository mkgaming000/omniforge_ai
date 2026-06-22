// Agent entity - represents a configured AI agent
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

import 'model_config_entity.dart';

part 'agent_entity.g.dart';

@HiveType(typeId: 70)
class AgentEntity extends Equatable {
  const AgentEntity({
    required this.id,
    required this.name,
    required this.model,
    required this.systemPrompt,
    required this.createdAt,
    this.description,
    this.avatar,
    this.knowledgeBaseId,
    this.allowedTools = const [],
    this.memory = const [],
    this.maxIterations = 10,
    this.temperature = 0.7,
    this.metadata = const {},
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final ModelConfigEntity model;

  @HiveField(3)
  final String systemPrompt;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final String? description;

  @HiveField(6)
  final String? avatar;

  @HiveField(7)
  final String? knowledgeBaseId;

  @HiveField(8)
  final List<String> allowedTools;

  @HiveField(9)
  final List<AgentMemoryEntry> memory;

  @HiveField(10)
  final int maxIterations;

  @HiveField(11)
  final double temperature;

  @HiveField(12)
  final Map<String, dynamic> metadata;

  AgentEntity copyWith({
    String? id,
    String? name,
    ModelConfigEntity? model,
    String? systemPrompt,
    DateTime? createdAt,
    String? description,
    String? avatar,
    String? knowledgeBaseId,
    List<String>? allowedTools,
    List<AgentMemoryEntry>? memory,
    int? maxIterations,
    double? temperature,
    Map<String, dynamic>? metadata,
  }) {
    return AgentEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      model: model ?? this.model,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      avatar: avatar ?? this.avatar,
      knowledgeBaseId: knowledgeBaseId ?? this.knowledgeBaseId,
      allowedTools: allowedTools ?? this.allowedTools,
      memory: memory ?? this.memory,
      maxIterations: maxIterations ?? this.maxIterations,
      temperature: temperature ?? this.temperature,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        model,
        systemPrompt,
        createdAt,
        description,
        avatar,
        knowledgeBaseId,
        allowedTools,
        memory,
        maxIterations,
        temperature,
        metadata,
      ];
}

@HiveType(typeId: 71)
class AgentMemoryEntry extends Equatable {
  const AgentMemoryEntry({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.metadata = const {},
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final AgentRole role;

  @HiveField(2)
  final String content;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final Map<String, dynamic> metadata;

  @override
  List<Object?> get props => [id, role, content, timestamp, metadata];
}

@HiveType(typeId: 72)
enum AgentRole {
  @HiveField(0)
  system,
  @HiveField(1)
  user,
  @HiveField(2)
  assistant,
  @HiveField(3)
  tool,
}

class AgentMessage {
  const AgentMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });
  final AgentRole role;
  final String content;
  final DateTime timestamp;
}

enum AgentStepType { thinking, toolCall, toolResult, finalAnswer }

class AgentStep {
  const AgentStep({
    required this.type,
    required this.content,
    required this.timestamp,
    this.metadata,
  });
  final AgentStepType type;
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
}
