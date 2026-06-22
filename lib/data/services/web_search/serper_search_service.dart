// Serper Search Service - Google Search API wrapper
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import 'web_search_service.dart';

class SerperSearchService implements WebSearchService {
  SerperSearchService();
  String? _apiKey;
  void setApiKey(String key) => _apiKey = key;

  @override
  String get providerId => 'serper';

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
          message: 'Serper API key not configured. Get one at serper.dev',
        ),
      );
    }
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: 'https://google.serper.dev',
        apiKey: _apiKey,
        apiKeyHeader: 'X-API-KEY',
      );
      final endpoint = switch (type) {
        SearchType.news => '/news',
        SearchType.images => '/images',
        SearchType.videos => '/videos',
        SearchType.academic => '/scholar',
        SearchType.shopping => '/shopping',
        SearchType.web => '/search',
      };
      final response = await dio.post(
        endpoint,
        data: {
          'q': query,
          'num': maxResults,
          if (gl != null) 'gl': gl,
          if (hl != null) 'hl': hl,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final organic = (data['organic'] as List?) ?? [];
      return organic
          .map<SearchResult>(
            (r) => SearchResult(
              title: r['title'] as String,
              url: r['link'] as String,
              snippet: r['snippet'] as String? ?? '',
              source: _extractSource(r['link'] as String),
              publishedAt: r['date'] != null
                  ? DateTime.tryParse(r['date'] as String)
                  : null,
              metadata: Map<String, dynamic>.from(r as Map),
            ),
          )
          .toList();
    });
  }

  @override
  Future<Either<Failure, String>> fetchContent(String url) async {
    // Serper doesn't have content extraction; use a separate fetcher
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
    final isGov = domain.endsWith('.gov') || domain.endsWith('.mil');
    final isEdu = domain.endsWith('.edu');
    final isNews = {'reuters.com', 'apnews.com', 'bbc.com', 'nytimes.com'}
        .contains(domain);
    final score = isGov
        ? 0.99
        : isEdu
            ? 0.95
            : isNews
                ? 0.9
                : 0.6;
    return Right(
      SourceCredibility(
        score: score,
        tier: score > 0.8
            ? CredibilityTier.trusted
            : score > 0.6
                ? CredibilityTier.reliable
                : CredibilityTier.mixed,
        reasons: [
          if (isGov) 'Government source',
          if (isEdu) 'Educational institution',
          if (isNews) 'Reputable news organization',
        ],
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
