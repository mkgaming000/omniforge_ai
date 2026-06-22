// Web Search Service - abstract interface for search providers
import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';

abstract class WebSearchService {
  /// Run a web search and return ranked results.
  Future<Either<Failure, List<SearchResult>>> search({
    required String query,
    int maxResults = 10,
    bool includeContent = false,
    SearchType type = SearchType.web,
    String? gl,
    String? hl,
  });

  /// Fetch the full content of a URL (for deep research).
  Future<Either<Failure, String>> fetchContent(String url);

  /// Verify the credibility of a source.
  Future<Either<Failure, SourceCredibility>> checkCredibility(String url);

  String get providerId;
}

enum SearchType { web, news, images, videos, academic, shopping }

class SearchResult {
  const SearchResult({
    required this.title,
    required this.url,
    required this.snippet,
    required this.source,
    this.publishedAt,
    this.content,
    this.score,
    this.credibility,
    this.citations = const [],
    this.metadata = const {},
  });

  final String title;
  final String url;
  final String snippet;
  final String source;
  final DateTime? publishedAt;
  final String? content;
  final double? score;
  final SourceCredibility? credibility;
  final List<String> citations;
  final Map<String, dynamic> metadata;
}

class SourceCredibility {
  const SourceCredibility({
    required this.score,
    required this.tier,
    this.reasons = const [],
  });

  final double score;
  final CredibilityTier tier;
  final List<String> reasons;
}

enum CredibilityTier { trusted, reliable, mixed, unreliable, unknown }
