// Tavily Search Service - AI-optimized search API
import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import 'web_search_service.dart';

class TavilySearchService implements WebSearchService {
  TavilySearchService();
  String? _apiKey;
  void setApiKey(String key) => _apiKey = key;

  @override
  String get providerId => 'tavily';

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
          message: 'Tavily API key not configured. Get one at tavily.com',
        ),
      );
    }
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: 'https://api.tavily.com',
        apiKey: _apiKey,
      );
      final response = await dio.post(
        '/search',
        data: {
          'api_key': _apiKey,
          'query': query,
          'max_results': maxResults,
          'include_answer': true,
          'include_raw_content': includeContent,
          'search_depth': includeContent ? 'advanced' : 'basic',
        },
      );
      final data = response.data as Map<String, dynamic>;
      final results = data['results'] as List;
      return results
          .map<SearchResult>(
            (r) => SearchResult(
              title: r['title'] as String,
              url: r['url'] as String,
              snippet: r['content'] as String? ?? '',
              source: _extractSource(r['url'] as String),
              publishedAt: r['published_date'] != null
                  ? DateTime.tryParse(r['published_date'] as String)
                  : null,
              content: r['raw_content'] as String?,
              score: (r['score'] as num?)?.toDouble(),
              metadata: Map<String, dynamic>.from(r as Map),
            ),
          )
          .toList();
    });
  }

  @override
  Future<Either<Failure, String>> fetchContent(String url) async {
    if (_apiKey == null) {
      return const Left(UnauthorizedFailure(message: 'API key not set'));
    }
    return safeApiCall(() async {
      final dio = DioClient.create(
        baseUrl: 'https://api.tavily.com',
        apiKey: _apiKey,
      );
      final response = await dio.post(
        '/extract',
        data: {
          'urls': [url],
        },
      );
      final data = response.data as Map<String, dynamic>;
      final results = data['results'] as List;
      return (results.first as Map<String, dynamic>)['raw_content'] as String;
    });
  }

  @override
  Future<Either<Failure, SourceCredibility>> checkCredibility(
    String url,
  ) async {
    // Tavily doesn't expose credibility directly; derive from domain heuristics
    final domain = Uri.parse(url).host.replaceAll('www.', '');
    final trustedDomains = {
      'wikipedia.org',
      'nature.com',
      'science.org',
      'ieee.org',
      'arxiv.org',
      'pubmed.ncbi.nlm.nih.gov',
      'government websites (.gov, .mil)',
      'reuters.com',
      'bbc.com',
      'nytimes.com',
      'apnews.com',
    };
    final score = trustedDomains.any((d) => domain.contains(d)) ? 0.95 : 0.5;
    return Right(
      SourceCredibility(
        score: score,
        tier: score > 0.8
            ? CredibilityTier.trusted
            : score > 0.6
                ? CredibilityTier.reliable
                : score > 0.4
                    ? CredibilityTier.mixed
                    : CredibilityTier.unreliable,
        reasons: [
          'Domain: $domain',
          if (score > 0.8) 'Whitelisted trusted source',
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
