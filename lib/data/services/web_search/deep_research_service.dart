// Deep Research Service - orchestrates multi-step research with citations
// Searches the web, evaluates sources, synthesizes answers with LLMs.
import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../../core/constants/ai_providers.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/entities/message_entity.dart';
import '../../../domain/entities/model_config_entity.dart';
import '../ai/ai_provider_factory.dart';
import '../web_search/web_search_service.dart';

class DeepResearchService {
  DeepResearchService({
    required this.searchService,
    required this.providerFactory,
  });

  final WebSearchService searchService;
  final AIProviderFactory providerFactory;

  /// Run a single-shot research query.
  Future<Either<Failure, ResearchReport>> research({
    required String query,
    int maxSources = 8,
    bool deepMode = false,
    bool factCheck = true,
  }) async {
    // Step 1: web search
    final searchResult = await searchService.search(
      query: query,
      maxResults: maxSources,
      includeContent: deepMode,
    );

    if (searchResult.isLeft()) {
      return searchResult.fold(
        (failure) => Left<Failure, ResearchReport>(failure),
        (_) => throw StateError('unreachable'),
      );
    }
    final results = searchResult.getOrElse(() => throw StateError(''));

    if (results.isEmpty) {
      return const Left(
        NotFoundFailure(
          message: 'No search results found for your query',
        ),
      );
    }

    // Step 2: optionally fact-check sources
    List<SearchResult> verifiedResults = results;
    if (factCheck) {
      final checked = <SearchResult>[];
      for (final r in results) {
        final cred = await searchService.checkCredibility(r.url);
        cred.fold(
          (_) => checked.add(r),
          (c) => checked.add(
            SearchResult(
              title: r.title,
              url: r.url,
              snippet: r.snippet,
              source: r.source,
              publishedAt: r.publishedAt,
              content: r.content,
              score: r.score,
              credibility: c,
              citations: r.citations,
              metadata: r.metadata,
            ),
          ),
        );
      }
      verifiedResults = checked;
    }

    // Step 3: synthesize answer with LLM
    final synthesisResult = await _synthesize(
      query: query,
      sources: verifiedResults,
      deepMode: deepMode,
    );

    if (synthesisResult.isLeft()) {
      return synthesisResult.fold(
        (failure) => Left<Failure, ResearchReport>(failure),
        (_) => throw StateError('unreachable'),
      );
    }
    final synthesis = synthesisResult.getOrElse(() => throw StateError(''));

    return Right(
      ResearchReport(
        query: query,
        answer: synthesis,
        sources: verifiedResults,
        confidence: _computeConfidence(verifiedResults),
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Run a deep multi-step research with sub-query expansion.
  Stream<Either<Failure, ResearchProgress>> deepResearch({
    required String query,
    int maxSubQueries = 5,
    int sourcesPerQuery = 4,
  }) async* {
    yield const Right(
      ResearchProgress(
        phase: ResearchPhase.expanding,
        message: 'Expanding query into sub-questions...',
        progress: 0.1,
      ),
    );

    // Step 1: Use LLM to generate sub-queries
    final subQueriesResult = await _generateSubQueries(query, maxSubQueries);
    List<String> subQueries;
    if (subQueriesResult.isLeft()) {
      subQueries = [query];
    } else {
      subQueries = subQueriesResult.getOrElse(() => [query]);
    }

    yield Right(
      ResearchProgress(
        phase: ResearchPhase.searching,
        message: 'Searching ${subQueries.length} sub-queries...',
        progress: 0.3,
        subQueries: subQueries,
      ),
    );

    // Step 2: Search each sub-query in parallel
    final allResults = <SearchResult>[];
    final searchFutures = subQueries.map(
      (sq) => searchService.search(
        query: sq,
        maxResults: sourcesPerQuery,
        includeContent: true,
      ),
    );

    final searchResults = await Future.wait(searchFutures);
    for (final r in searchResults) {
      r.fold(
        (_) {},
        (results) => allResults.addAll(results),
      );
    }

    // Deduplicate by URL
    final seen = <String>{};
    final deduped = allResults.where((r) => seen.add(r.url)).toList();

    yield Right(
      ResearchProgress(
        phase: ResearchPhase.evaluating,
        message: 'Evaluating ${deduped.length} sources...',
        progress: 0.6,
        sources: deduped,
      ),
    );

    // Step 3: Synthesize
    yield const Right(
      ResearchProgress(
        phase: ResearchPhase.synthesizing,
        message: 'Synthesizing final answer with citations...',
        progress: 0.8,
      ),
    );

    final synthesisResult = await _synthesize(
      query: query,
      sources: deduped,
      deepMode: true,
    );

    yield synthesisResult.fold(
      (failure) => Left<Failure, ResearchProgress>(failure),
      (synthesis) => Right(
        ResearchProgress(
          phase: ResearchPhase.complete,
          message: 'Research complete',
          progress: 1.0,
          report: ResearchReport(
            query: query,
            answer: synthesis,
            sources: deduped,
            confidence: _computeConfidence(deduped),
            createdAt: DateTime.now(),
          ),
        ),
      ),
    );
  }

  Future<Either<Failure, List<String>>> _generateSubQueries(
    String query,
    int max,
  ) async {
    // Heuristic sub-query expansion. A future enhancement could use an LLM
    // via providerFactory.autoSelect() to generate more nuanced expansions.
    return Right(
      [
        query,
        'what is $query',
        '$query explained',
        '$query latest news',
        '$query examples',
      ].take(max).toList(),
    );
  }

  Future<Either<Failure, String>> _synthesize({
    required String query,
    required List<SearchResult> sources,
    required bool deepMode,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('You are a research assistant. Answer the user\'s question '
        'using ONLY the provided sources. Cite each claim with [Source N].');
    buffer.writeln();
    buffer.writeln('User question: $query');
    buffer.writeln();
    buffer.writeln('=== Sources ===');
    for (var i = 0; i < sources.length; i++) {
      final s = sources[i];
      buffer.writeln('\n[Source ${i + 1}] ${s.title}');
      buffer.writeln('URL: ${s.url}');
      buffer.writeln('Source: ${s.source}');
      if (s.publishedAt != null) {
        buffer.writeln('Published: ${s.publishedAt}');
      }
      buffer.writeln('Content: ${s.content ?? s.snippet}');
    }
    buffer.writeln('\n=== End Sources ===\n');
    buffer.writeln('Provide a comprehensive answer with inline citations.');

    // Use first available provider for synthesis.
    final serviceResult = await providerFactory.autoSelect(
      taskType: ChatTaskType.reasoning,
    );
    if (serviceResult.isLeft()) {
      return serviceResult.fold(
        (failure) => Left<Failure, String>(failure),
        (_) => throw StateError('unreachable'),
      );
    }
    final service = serviceResult.getOrElse(() => throw StateError(''));
    return service.complete(
      messages: [
        MessageEntity(
          id: 'research-${DateTime.now().millisecondsSinceEpoch}',
          role: MessageRole.user,
          content: query,
          createdAt: DateTime.now(),
        ),
      ],
      config: _defaultConfig,
      systemPrompt: buffer.toString(),
    );
  }

  double _computeConfidence(List<SearchResult> sources) {
    if (sources.isEmpty) return 0.0;
    final credibleCount = sources.where((s) {
      final c = s.credibility;
      return c != null && c.tier == CredibilityTier.trusted;
    }).length;
    return (credibleCount / sources.length).clamp(0.0, 1.0);
  }
}

class ResearchReport {
  const ResearchReport({
    required this.query,
    required this.answer,
    required this.sources,
    required this.confidence,
    required this.createdAt,
  });

  final String query;
  final String answer;
  final List<SearchResult> sources;
  final double confidence;
  final DateTime createdAt;
}

enum ResearchPhase { expanding, searching, evaluating, synthesizing, complete }

class ResearchProgress {
  const ResearchProgress({
    required this.phase,
    required this.message,
    required this.progress,
    this.subQueries = const [],
    this.sources = const [],
    this.report,
  });

  final ResearchPhase phase;
  final String message;
  final double progress;
  final List<String> subQueries;
  final List<SearchResult> sources;
  final ResearchReport? report;
}

// Default model config for synthesis
const _defaultConfig = ModelConfigEntity(
  provider: AIProvider.openai,
  modelId: 'gpt-4o',
  displayName: 'GPT-4o',
  temperature: 0.3,
  maxTokens: 8192,
);
