// Cohere Embeddings Service - embed-english-v3 / embed-multilingual-v3
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/dio_client.dart';
import 'ai_embedding_service.dart';

class CohereEmbeddingService implements AIEmbeddingService {
  CohereEmbeddingService();

  String? _apiKey;
  void setApiKey(String key) => _apiKey = key;

  final String _model = 'embed-english-v3.0';

  @override
  int get dimension => switch (_model) {
        'embed-english-v3.0' => 1024,
        'embed-english-light-v3.0' => 384,
        'embed-multilingual-v3.0' => 1024,
        'embed-multilingual-light-v3.0' => 384,
        _ => 1024,
      };

  @override
  String get providerId => 'cohere';

  @override
  int get maxInputTokens => 512;

  @override
  Future<Either<Failure, List<double>>> embed(String text) async {
    if (_apiKey == null) {
      return const Left(UnauthorizedFailure(message: 'Cohere key not set'));
    }
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: 'https://api.cohere.com/v1',
        apiKey: _apiKey,
      );
      final response = await dio.post(
        '/embed',
        data: {
          'model': _model,
          'texts': [text],
          'input_type': 'search_document',
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'Cohere embed returned non-map: ${data.runtimeType}',
        );
      }
      final embeddings = (data['embeddings'] as List?) ?? <dynamic>[];
      if (embeddings.isEmpty) {
        throw const ProviderFailure(
          message: 'Cohere embed returned empty embeddings array',
        );
      }
      final first = embeddings.first;
      if (first is! List) {
        throw ProviderFailure(
          message:
              'Cohere embed embeddings[0] is non-list: ${first.runtimeType}',
        );
      }
      return first.cast<double>();
    });
  }

  @override
  Future<Either<Failure, List<List<double>>>> embedBatch(
    List<String> texts,
  ) async {
    if (_apiKey == null) {
      return const Left(UnauthorizedFailure(message: 'Cohere key not set'));
    }
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: 'https://api.cohere.com/v1',
        apiKey: _apiKey,
      );
      final response = await dio.post(
        '/embed',
        data: {
          'model': _model,
          'texts': texts,
          'input_type': 'search_document',
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'Cohere embedBatch returned non-map: ${data.runtimeType}',
        );
      }
      final embeddings = (data['embeddings'] as List?) ?? <dynamic>[];
      if (embeddings.isEmpty) {
        throw const ProviderFailure(
          message: 'Cohere embedBatch returned empty embeddings array',
        );
      }
      return embeddings.map<List<double>>((e) {
        if (e is! List) {
          throw ProviderFailure(
            message: 'Cohere embedBatch item is non-list: ${e.runtimeType}',
          );
        }
        return e.cast<double>();
      }).toList();
    });
  }
}
