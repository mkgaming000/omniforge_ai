// RAG Service - Retrieval Augmented Generation orchestrator
// Chunks documents, embeds them, retrieves relevant context for LLM prompts.
//
// Chunking strategy: each chunk is stored as its OWN VectorDocumentEntity
// (with its own embedding) rather than averaging all chunk embeddings into a
// single document vector. Averaging destroys retrieval granularity — a query
// matches the whole document or nothing. Per-chunk storage means a query can
// surface the single most relevant paragraph, which is the entire point of
// chunked RAG. Chunks carry metadata linking them back to the parent title
// and recording their index/offsets so citations can point to the source.
import 'dart:math';

import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../ai/embedding/ai_embedding_service.dart';
import '../vector_store/vector_store.dart';

class RagService {
  RagService({
    required this.embeddingService,
    required this.vectorStore,
    this.chunkSize = 1000,
    this.chunkOverlap = 200,
    this.maxContextChars = 16000,
  }) : assert(
          chunkOverlap < chunkSize,
          'chunkOverlap ($chunkOverlap) must be < chunkSize ($chunkSize) '
          'or the chunker will never advance',
        );

  final AIEmbeddingService embeddingService;
  final VectorStore vectorStore;
  final int chunkSize;
  final int chunkOverlap;

  /// Hard cap on the total context body injected into a prompt, in
  /// characters. Prevents a large top-K retrieval from overflowing the
  /// model's context window. ~4 chars per token → 16k chars ≈ 4k tokens.
  final int maxContextChars;

  /// Index a document: split into chunks, embed each chunk, and store every
  /// chunk as its own searchable [VectorDocumentEntity]. Returns the id of
  /// the first stored chunk (or an empty string if there were none).
  Future<Either<Failure, String>> indexDocument({
    required String title,
    required String content,
    String? source,
    String? knowledgeBaseId,
    Map<String, dynamic> metadata = const {},
  }) async {
    if (content.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Cannot index an empty document',
        ),
      );
    }

    final chunks = _chunkText(content);

    // Embed all chunks in a single batch request (provider-side efficiency).
    final embedsResult = await embeddingService.embedBatch(
      chunks.map((c) => c.text).toList(),
    );
    if (embedsResult.isLeft()) {
      return embedsResult.fold(
        (failure) => Left<Failure, String>(failure),
        (_) => throw StateError('unreachable'),
      );
    }
    final embeddings = embedsResult.getOrElse(() => throw StateError(''));

    if (embeddings.length != chunks.length) {
      return Left(
        ProviderFailure(
          message: 'Embedding provider returned ${embeddings.length} vectors '
              'for ${chunks.length} chunks',
        ),
      );
    }

    // Store each chunk as its own document so retrieval can surface the
    // single most relevant paragraph instead of an averaged whole-doc vector.
    String? firstId;
    Failure? lastFailure;
    for (var i = 0; i < chunks.length; i++) {
      final chunkMeta = {
        ...metadata,
        'parentTitle': title,
        'chunkIndex': i,
        'chunkCount': chunks.length,
        'chunkStart': chunks[i].start,
        'chunkEnd': chunks[i].end,
      };
      final result = await vectorStore.addDocument(
        title: chunks.length == 1
            ? title
            : '$title (chunk ${i + 1}/${chunks.length})',
        content: chunks[i].text,
        embedding: embeddings[i],
        source: source,
        knowledgeBaseId: knowledgeBaseId,
        metadata: chunkMeta,
      );
      result.fold(
        (f) => lastFailure = f,
        (id) {
          firstId ??= id;
        },
      );
    }

    if (firstId == null) {
      return Left(
        lastFailure ?? const CacheFailure(message: 'Failed to index any chunk'),
      );
    }
    return Right(firstId!);
  }

  /// Retrieve relevant context for a query.
  Future<Either<Failure, List<VectorSearchResult>>> retrieve({
    required String query,
    int topK = 5,
    String? knowledgeBaseId,
    double minScore = 0.3,
  }) async {
    final embedResult = await embeddingService.embed(query);
    if (embedResult.isLeft()) {
      return embedResult.fold(
        (failure) => Left<Failure, List<VectorSearchResult>>(failure),
        (_) => throw StateError('unreachable'),
      );
    }
    final queryEmbedding = embedResult.getOrElse(() => throw StateError(''));
    return vectorStore.search(
      queryEmbedding: queryEmbedding,
      topK: topK,
      knowledgeBaseId: knowledgeBaseId,
      minScore: minScore,
    );
  }

  /// Build an augmented prompt with retrieved context.
  ///
  /// The system prompt is ALWAYS included (even when retrieval returns no
  /// results) so downstream LLM callers see consistent framing. Context is
  /// capped at [maxContextChars] to avoid overflowing the model's window.
  Future<Either<Failure, String>> augmentPrompt({
    required String userQuery,
    String? knowledgeBaseId,
    int topK = 5,
    String systemPrompt =
        'Use the following context to answer the user\'s question. '
            'If the context does not contain the answer, say so honestly.',
  }) async {
    final retrievalResult = await retrieve(
      query: userQuery,
      topK: topK,
      knowledgeBaseId: knowledgeBaseId,
    );

    if (retrievalResult.isLeft()) {
      return retrievalResult.fold(
        (failure) => Left<Failure, String>(failure),
        (_) => throw StateError('unreachable'),
      );
    }
    final results = retrievalResult.getOrElse(() => throw StateError(''));

    if (results.isEmpty) {
      // No context found — still return the system prompt + question so the
      // caller's framing stays consistent across the hit/miss cases.
      return Right('$systemPrompt\n\nUser question: $userQuery');
    }

    final contextBuffer = StringBuffer();
    contextBuffer.writeln('=== Context ===');
    var usedChars = 0;
    for (var i = 0; i < results.length; i++) {
      final doc = results[i].document;
      final chunk = '[$i] (score: ${results[i].score.toStringAsFixed(3)}) '
          '${doc.title}'
          '${doc.source != null && doc.source!.isNotEmpty ? ' — ${doc.source}' : ''}\n'
          '${doc.content}\n';
      if (usedChars + chunk.length > maxContextChars) {
        // Truncate this final chunk to fit the remaining budget rather than
        // dropping it entirely — a partial match is still useful context.
        final remaining = maxContextChars - usedChars;
        if (remaining > 64) {
          contextBuffer.writeln(chunk.substring(0, remaining));
          contextBuffer.writeln('…[truncated]');
        }
        break;
      }
      contextBuffer.writeln(chunk);
      usedChars += chunk.length;
    }
    contextBuffer.writeln('=== End Context ===\n');
    contextBuffer.writeln('User question: $userQuery');
    return Right('$systemPrompt\n\n${contextBuffer.toString()}');
  }

  List<_TextChunk> _chunkText(String text) {
    final chunks = <_TextChunk>[];
    if (text.length <= chunkSize) {
      chunks.add(_TextChunk(text: text, start: 0, end: text.length));
      return chunks;
    }
    var start = 0;
    while (start < text.length) {
      final end = min(start + chunkSize, text.length);
      var actualEnd = end;
      // Try to break on a sentence boundary in the second half of the chunk
      // so chunks don't split mid-sentence.
      if (end < text.length) {
        final lastSentence = text.substring(start, end).lastIndexOf('. ');
        if (lastSentence > chunkSize * 0.5) {
          actualEnd = start + lastSentence + 2;
        }
      }
      chunks.add(
        _TextChunk(
          text: text.substring(start, actualEnd),
          start: start,
          end: actualEnd,
        ),
      );
      // Advance past the overlap. Guard against zero/negative progress
      // (would otherwise infinite-loop) — the constructor assert already
      // ensures chunkOverlap < chunkSize, but defend at runtime too.
      final next = actualEnd - chunkOverlap;
      if (next <= start) {
        start = actualEnd;
      } else {
        start = next;
      }
    }
    return chunks;
  }
}

class _TextChunk {
  const _TextChunk({
    required this.text,
    required this.start,
    required this.end,
  });
  final String text;
  final int start;
  final int end;
}
