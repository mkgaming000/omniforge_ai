// Vector Store - in-memory + persisted vector database for RAG
// Uses cosine similarity for nearest-neighbor search.
import 'dart:math';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/entities/vector_document_entity.dart';

class VectorStore {
  VectorStore._(this._box);

  final Box<VectorDocumentEntity> _box;
  final _uuid = const Uuid();

  static const _boxName = 'omniforge_vectors';

  static Future<VectorStore> create() async {
    if (!Hive.isAdapterRegistered(50)) {
      Hive.registerAdapter(VectorDocumentEntityAdapter());
    }
    if (!Hive.isAdapterRegistered(51)) {
      Hive.registerAdapter(DocumentChunkEntityAdapter());
    }
    final box = await Hive.openBox<VectorDocumentEntity>(_boxName);
    return VectorStore._(box);
  }

  /// Add a document with its embedding vector to the store.
  Future<Either<Failure, String>> addDocument({
    required String title,
    required String content,
    required List<double> embedding,
    String? source,
    String? knowledgeBaseId,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final id = _uuid.v4();
      final doc = VectorDocumentEntity(
        id: id,
        title: title,
        content: content,
        embedding: embedding,
        source: source,
        knowledgeBaseId: knowledgeBaseId,
        metadata: metadata,
        createdAt: DateTime.now(),
      );
      await _box.put(id, doc);
      return Right(id);
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Failed to add document',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Search for top-k most similar documents using cosine similarity.
  Future<Either<Failure, List<VectorSearchResult>>> search({
    required List<double> queryEmbedding,
    int topK = 5,
    String? knowledgeBaseId,
    double minScore = 0.0,
  }) async {
    try {
      final results = <VectorSearchResult>[];
      for (final doc in _box.values) {
        if (knowledgeBaseId != null && doc.knowledgeBaseId != knowledgeBaseId) {
          continue;
        }
        final score = _cosineSimilarity(queryEmbedding, doc.embedding);
        if (score >= minScore) {
          results.add(VectorSearchResult(document: doc, score: score));
        }
      }
      results.sort((a, b) => b.score.compareTo(a.score));
      return Right(results.take(topK).toList());
    } catch (e, st) {
      return Left(
        CacheFailure(
          message: 'Vector search failed',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// List all documents, optionally filtered by knowledge base.
  Either<Failure, List<VectorDocumentEntity>> list({
    String? knowledgeBaseId,
  }) {
    try {
      final docs = _box.values.where((d) {
        if (knowledgeBaseId == null) return true;
        return d.knowledgeBaseId == knowledgeBaseId;
      }).toList();
      return Right(docs);
    } catch (e) {
      return const Left(CacheFailure(message: 'Failed to list documents'));
    }
  }

  /// Delete a document by ID.
  Future<Either<Failure, void>> delete(String id) async {
    try {
      await _box.delete(id);
      return const Right(null);
    } catch (e) {
      return const Left(CacheFailure(message: 'Failed to delete document'));
    }
  }

  /// Clear all documents in a knowledge base.
  Future<Either<Failure, int>> clearKnowledgeBase(String kbId) async {
    try {
      final toDelete = _box.values
          .where((d) => d.knowledgeBaseId == kbId)
          .map((d) => d.id)
          .toList();
      for (final id in toDelete) {
        await _box.delete(id);
      }
      return Right(toDelete.length);
    } catch (e) {
      return const Left(CacheFailure(message: 'Failed to clear KB'));
    }
  }

  /// Total document count.
  int get count => _box.length;

  /// Cosine similarity between two equal-length vectors.
  static double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) return 0.0;
    double dot = 0;
    double normA = 0;
    double normB = 0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0 || normB == 0) return 0.0;
    return dot / (sqrt(normA) * sqrt(normB));
  }

  /// Test-only accessor for the private cosine-similarity implementation.
  ///
  /// Exposed via [visibleForTesting] so unit tests can verify the math
  /// directly without having to bootstrap a Hive box and run a full
  /// [search] pass.
  @visibleForTesting
  static double cosineSimilarityForTesting(List<double> a, List<double> b) =>
      _cosineSimilarity(a, b);
}

class VectorSearchResult {
  const VectorSearchResult({
    required this.document,
    required this.score,
  });

  final VectorDocumentEntity document;
  final double score;
}
