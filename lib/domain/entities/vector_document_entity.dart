// Vector Document entity - persisted in Hive for RAG retrieval
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'vector_document_entity.g.dart';

@HiveType(typeId: 50)
class VectorDocumentEntity extends Equatable {
  const VectorDocumentEntity({
    required this.id,
    required this.title,
    required this.content,
    required this.embedding,
    required this.createdAt,
    this.source,
    this.knowledgeBaseId,
    this.metadata = const {},
    this.chunks = const [],
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String content;

  @HiveField(3)
  final List<double> embedding;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final String? source;

  @HiveField(6)
  final String? knowledgeBaseId;

  @HiveField(7)
  final Map<String, dynamic> metadata;

  @HiveField(8)
  final List<DocumentChunkEntity> chunks;

  VectorDocumentEntity copyWith({
    String? id,
    String? title,
    String? content,
    List<double>? embedding,
    DateTime? createdAt,
    String? source,
    String? knowledgeBaseId,
    Map<String, dynamic>? metadata,
    List<DocumentChunkEntity>? chunks,
  }) {
    return VectorDocumentEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      embedding: embedding ?? this.embedding,
      createdAt: createdAt ?? this.createdAt,
      source: source ?? this.source,
      knowledgeBaseId: knowledgeBaseId ?? this.knowledgeBaseId,
      metadata: metadata ?? this.metadata,
      chunks: chunks ?? this.chunks,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        embedding,
        createdAt,
        source,
        knowledgeBaseId,
        metadata,
        chunks,
      ];
}

@HiveType(typeId: 51)
class DocumentChunkEntity extends Equatable {
  const DocumentChunkEntity({
    required this.id,
    required this.text,
    required this.embedding,
    this.startOffset,
    this.endOffset,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String text;

  @HiveField(2)
  final List<double> embedding;

  @HiveField(3)
  final int? startOffset;

  @HiveField(4)
  final int? endOffset;

  @override
  List<Object?> get props => [id, text, embedding, startOffset, endOffset];
}
