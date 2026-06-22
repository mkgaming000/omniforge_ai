// Knowledge Base Entity
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'knowledge_base_entity.g.dart';

@HiveType(typeId: 80)
class KnowledgeBaseEntity extends Equatable {
  const KnowledgeBaseEntity({
    required this.id,
    required this.name,
    required this.embeddingProvider,
    required this.documentCount,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.metadata = const {},
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final String embeddingProvider;

  @HiveField(4)
  final int documentCount;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime updatedAt;

  @HiveField(7)
  final Map<String, dynamic> metadata;

  KnowledgeBaseEntity copyWith({
    String? id,
    String? name,
    String? description,
    String? embeddingProvider,
    int? documentCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return KnowledgeBaseEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      embeddingProvider: embeddingProvider ?? this.embeddingProvider,
      documentCount: documentCount ?? this.documentCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        embeddingProvider,
        documentCount,
        createdAt,
        updatedAt,
        metadata,
      ];
}
