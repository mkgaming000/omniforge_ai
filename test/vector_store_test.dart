// Unit tests for Vector Store
//
// The first group exercises the static cosine-similarity math directly via
// the `VectorStore.cosineSimilarityForTesting` accessor (annotated
// `@visibleForTesting`). The second group exercises the
// `VectorSearchResult` value object with a real `VectorDocumentEntity`.
import 'package:flutter_test/flutter_test.dart';
import 'package:omniforge_ai/data/services/vector_store/vector_store.dart';
import 'package:omniforge_ai/domain/entities/vector_document_entity.dart';

void main() {
  group('VectorStore.cosineSimilarityForTesting', () {
    test('identical unit vectors return 1.0', () {
      const a = <double>[1.0, 0.0, 0.0];
      const b = <double>[1.0, 0.0, 0.0];
      expect(
        VectorStore.cosineSimilarityForTesting(a, b),
        closeTo(1.0, 1e-9),
      );
    });

    test('orthogonal vectors return 0.0', () {
      const a = <double>[1.0, 0.0];
      const b = <double>[0.0, 1.0];
      expect(
        VectorStore.cosineSimilarityForTesting(a, b),
        closeTo(0.0, 1e-9),
      );
    });

    test('opposite vectors return -1.0', () {
      const a = <double>[1.0, 0.0];
      const b = <double>[-1.0, 0.0];
      expect(
        VectorStore.cosineSimilarityForTesting(a, b),
        closeTo(-1.0, 1e-9),
      );
    });

    test('empty vectors return 0.0', () {
      const a = <double>[];
      const b = <double>[];
      expect(
        VectorStore.cosineSimilarityForTesting(a, b),
        equals(0.0),
      );
    });

    test('mismatched lengths return 0.0', () {
      const a = <double>[1.0, 2.0, 3.0];
      const b = <double>[1.0, 2.0];
      expect(
        VectorStore.cosineSimilarityForTesting(a, b),
        equals(0.0),
      );
    });

    test('zero-norm vector returns 0.0 to avoid divide-by-zero', () {
      const a = <double>[0.0, 0.0];
      const b = <double>[1.0, 1.0];
      expect(
        VectorStore.cosineSimilarityForTesting(a, b),
        equals(0.0),
      );
    });

    test(
      'parallel non-normalized vectors still score 1.0 (magnitude-invariant)',
      () {
        const a = <double>[2.0, 0.0];
        const b = <double>[4.0, 0.0];
        expect(
          VectorStore.cosineSimilarityForTesting(a, b),
          closeTo(1.0, 1e-9),
        );
      },
    );

    test('45-degree vectors return ~0.7071', () {
      const a = <double>[1.0, 0.0];
      const b = <double>[1.0, 1.0];
      expect(
        VectorStore.cosineSimilarityForTesting(a, b),
        closeTo(0.70710678118, 1e-6),
      );
    });
  });

  group('VectorSearchResult', () {
    test('constructs correctly with a real VectorDocumentEntity', () {
      final document = VectorDocumentEntity(
        id: 'test',
        title: 't',
        content: 'c',
        embedding: const [1.0],
        createdAt: DateTime(2024),
      );
      final result = VectorSearchResult(
        document: document,
        score: 0.95,
      );
      expect(result.score, equals(0.95));
      expect(result.document.id, equals('test'));
      expect(result.document.embedding, equals(const <double>[1.0]));
    });
  });
}
