// Abstract embedding service for RAG / vector search
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';

abstract class AIEmbeddingService {
  /// Generate an embedding vector for the given text.
  Future<Either<Failure, List<double>>> embed(String text);

  /// Batch embed multiple texts in one request.
  Future<Either<Failure, List<List<double>>>> embedBatch(List<String> texts);

  /// Embedding dimension for this provider.
  int get dimension;

  /// Provider identifier.
  String get providerId;

  /// Maximum input tokens per request.
  int get maxInputTokens;
}
