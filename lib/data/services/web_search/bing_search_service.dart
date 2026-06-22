// Bing Search Service - Microsoft Bing Search API
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import 'web_search_service.dart';

class BingSearchService implements WebSearchService {
  BingSearchService();
  String? _apiKey;
  void setApiKey(String key) => _apiKey = key;

  @override
  String get providerId => 'bing';

  @override
  Future<Either<Failure, List<SearchResult>>> search({
    required String query,
    int maxResults = 10,
    bool includeContent = false,
    SearchType type = SearchType.web,
    String? gl,
    String? hl,
  }) async {
    if (_apiKey == null) {
      return const Left(
        UnauthorizedFailure(
          message: 'Bing Search API key not configured.',
        ),
      );
    }
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: 'https://api.bing.microsoft.com/v7.0',
        apiKey: _apiKey,
        apiKeyHeader: 'Ocp-Apim-Subscription-Key',
      );
      final endpoint = switch (type) {
        SearchType.news => '/news/search',
        SearchType.images => '/images/search',
        SearchType.videos => '/videos/search',
        _ => '/search',
      };
      final response = await dio.get(
        endpoint,
        queryParameters: {
          'q': query,
          'count': maxResults,
          if (gl != null) 'mkt': gl,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final webPages = (data['webPages']?['value'] as List?) ?? [];
      return webPages
          .map<SearchResult>(
            (r) => SearchResult(
              title: r['name'] as String,
              url: r['url'] as String,
              snippet: r['snippet'] as String? ?? '',
              source: _extractSource(r['url'] as String),
              publishedAt: r['datePublished'] != null
                  ? DateTime.tryParse(r['datePublished'] as String)
                  : null,
              metadata: Map<String, dynamic>.from(r as Map),
            ),
          )
          .toList();
    });
  }

  @override
  Future<Either<Failure, String>> fetchContent(String url) async {
    return safeApiCall(() async {
      final dio = DioClient.create(baseUrl: '');
      final response = await dio.get(
        url,
        options: Options(responseType: ResponseType.plain),
      );
      return response.data as String;
    });
  }

  @override
  Future<Either<Failure, SourceCredibility>> checkCredibility(
    String url,
  ) async {
    final domain = Uri.parse(url).host.replaceAll('www.', '');
    return Right(
      SourceCredibility(
        score: 0.7,
        tier: CredibilityTier.reliable,
        reasons: ['Domain: $domain'],
      ),
    );
  }

  String _extractSource(String url) {
    try {
      return Uri.parse(url).host.replaceAll('www.', '');
    } catch (_) {
      return url;
    }
  }
}
