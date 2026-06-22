// OpenAI Embeddings Service - text-embedding-3-small/large, ada-002
import 'package:dartz/dartz.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/dio_client.dart';
import 'ai_embedding_service.dart';

class OpenAIEmbeddingService implements AIEmbeddingService {
  OpenAIEmbeddingService();

  String? _apiKey;
  void setApiKey(String key) => _apiKey = key;

  String _model = 'text-embedding-3-small';

  void setModel(String model) => _model = model;

  @override
  int get dimension => switch (_model) {
        'text-embedding-3-small' => 1536,
        'text-embedding-3-large' => 3072,
        'text-embedding-ada-002' => 1536,
        _ => 1536,
      };

  @override
  String get providerId => 'openai';

  @override
  int get maxInputTokens => 8191;

  @override
  Future<Either<Failure, List<double>>> embed(String text) async {
    if (_apiKey == null) {
      return const Left(
        UnauthorizedFailure(
          message: 'OpenAI API key not configured for embeddings.',
        ),
      );
    }
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl:
            dotenv.maybeGet('OPENAI_BASE_URL') ?? 'https://api.openai.com/v1',
        apiKey: _apiKey,
      );
      final response = await dio.post(
        '/embeddings',
        data: {
          'model': _model,
          'input': text,
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'OpenAI embed returned non-map: ${data.runtimeType}',
        );
      }
      final items = (data['data'] as List?) ?? <dynamic>[];
      if (items.isEmpty) {
        throw const ProviderFailure(
          message: 'OpenAI embed returned empty data array',
        );
      }
      final firstItem = items.first;
      if (firstItem is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'OpenAI embed data[0] is non-map: ${firstItem.runtimeType}',
        );
      }
      final embedding = firstItem['embedding'];
      if (embedding is! List) {
        throw ProviderFailure(
          message:
              'OpenAI embed data[0].embedding is non-list: ${embedding.runtimeType}',
        );
      }
      return embedding.cast<double>();
    });
  }

  @override
  Future<Either<Failure, List<List<double>>>> embedBatch(
    List<String> texts,
  ) async {
    if (_apiKey == null) {
      return const Left(UnauthorizedFailure(message: 'API key not set'));
    }
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl:
            dotenv.maybeGet('OPENAI_BASE_URL') ?? 'https://api.openai.com/v1',
        apiKey: _apiKey,
      );
      final response = await dio.post(
        '/embeddings',
        data: {
          'model': _model,
          'input': texts,
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ProviderFailure(
          message: 'OpenAI embedBatch returned non-map: ${data.runtimeType}',
        );
      }
      final items = (data['data'] as List?) ?? <dynamic>[];
      if (items.isEmpty) {
        throw const ProviderFailure(
          message: 'OpenAI embedBatch returned empty data array',
        );
      }
      final typedItems = items.whereType<Map<String, dynamic>>().toList();
      typedItems.sort((a, b) {
        final ai = a['index'];
        final bi = b['index'];
        final aIdx = (ai is int) ? ai : int.tryParse(ai.toString()) ?? 0;
        final bIdx = (bi is int) ? bi : int.tryParse(bi.toString()) ?? 0;
        return aIdx.compareTo(bIdx);
      });
      return typedItems.map<List<double>>((item) {
        final emb = item['embedding'];
        if (emb is! List) {
          throw ProviderFailure(
            message:
                'OpenAI embedBatch item.embedding is non-list: ${emb.runtimeType}',
          );
        }
        return emb.cast<double>();
      }).toList();
    });
  }
}
