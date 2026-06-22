// Research Page - deep research with citation engine and fact checking.
// Wires UI to the DeepResearchService for real research results.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/services/web_search/deep_research_service.dart';
import '../../../data/services/web_search/web_search_service.dart';
import '../../../injection/injection.dart';

enum _ResearchMode { quick, deep, factCheck }

class ResearchPage extends StatefulWidget {
  const ResearchPage({super.key});

  @override
  State<ResearchPage> createState() => _ResearchPageState();
}

class _ResearchPageState extends State<ResearchPage> {
  final _queryController = TextEditingController();
  final _results = <ResearchReport>[];
  _ResearchMode _mode = _ResearchMode.quick;
  bool _isLoading = false;
  String? _progressMessage;
  StreamSubscription<dynamic>? _activeSubscription;

  @override
  void dispose() {
    _activeSubscription?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _queryController,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: 'Research query',
                  hintText: 'Ask anything. Get cited, fact-checked answers.',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onSubmitted: _search,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _ModeChip(
                    label: 'Quick Search',
                    selected: _mode == _ResearchMode.quick,
                    onTap: () => setState(() => _mode = _ResearchMode.quick),
                  ),
                  const SizedBox(width: 8),
                  _ModeChip(
                    label: 'Deep Research',
                    selected: _mode == _ResearchMode.deep,
                    onTap: () => setState(() => _mode = _ResearchMode.deep),
                  ),
                  const SizedBox(width: 8),
                  _ModeChip(
                    label: 'Fact Check',
                    selected: _mode == _ResearchMode.factCheck,
                    onTap: () =>
                        setState(() => _mode = _ResearchMode.factCheck),
                  ),
                ],
              ),
              if (_isLoading && _progressMessage != null) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(value: null),
                const SizedBox(height: 4),
                Text(
                  _progressMessage!,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: _results.isEmpty
              ? const _EmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _results.length,
                  itemBuilder: (context, index) =>
                      _ResultCard(report: _results[index]),
                ),
        ),
      ],
    );
  }

  Future<void> _search(String query) async {
    final q = query.trim();
    if (q.isEmpty || _isLoading) return;
    _queryController.clear();
    setState(() {
      _isLoading = true;
      _progressMessage = _mode == _ResearchMode.deep
          ? 'Expanding into sub-queries...'
          : 'Searching the web...';
    });

    final service = getIt<DeepResearchService>();
    final useDeep = _mode == _ResearchMode.deep;
    final factCheck = _mode == _ResearchMode.factCheck;

    if (useDeep) {
      // Streamed deep research with progress.
      _activeSubscription = service.deepResearch(query: q).listen(
        (event) {
          event.fold(
            (failure) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _progressMessage = null;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(failure.userMessage)),
                );
              }
            },
            (progress) {
              if (!mounted) return;
              setState(() {
                _progressMessage = progress.message;
                if (progress.phase == ResearchPhase.complete &&
                    progress.report != null) {
                  _results.insert(0, progress.report!);
                  _isLoading = false;
                  _progressMessage = null;
                }
              });
            },
          );
        },
        onDone: () {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _progressMessage = null;
            });
          }
        },
        onError: (e) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _progressMessage = null;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Research failed: $e')),
            );
          }
        },
      );
    } else {
      // Single-shot quick research or fact-check.
      final result = await service.research(
        query: q,
        maxSources: 8,
        deepMode: false,
        factCheck: factCheck,
      );
      if (!mounted) return;
      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _progressMessage = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.userMessage)),
          );
        },
        (report) {
          setState(() {
            _results.insert(0, report);
            _isLoading = false;
            _progressMessage = null;
          });
        },
      );
    }
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.report});
  final ResearchReport report;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Q: ${report.query}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(
                  label: Text('${(report.confidence * 100).toInt()}% conf'),
                  backgroundColor: report.confidence > 0.8
                      ? Colors.green.shade100
                      : report.confidence > 0.5
                          ? Colors.orange.shade100
                          : Colors.red.shade100,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(report.answer, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Text(
              'Sources (${report.sources.length}):',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            ...report.sources.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _credibilityIcon(s.credibility),
                      size: 14,
                      color: _credibilityColor(s.credibility),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.title,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            s.url,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Researched at ${report.createdAt.toString().substring(0, 19)}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }

  IconData _credibilityIcon(SourceCredibility? c) {
    if (c == null) return Icons.help_outline;
    switch (c.tier) {
      case CredibilityTier.trusted:
        return Icons.verified;
      case CredibilityTier.reliable:
        return Icons.check_circle_outline;
      case CredibilityTier.mixed:
        return Icons.warning_amber;
      case CredibilityTier.unreliable:
        return Icons.error_outline;
      case CredibilityTier.unknown:
        return Icons.help_outline;
    }
  }

  Color _credibilityColor(SourceCredibility? c) {
    if (c == null) return Colors.grey;
    switch (c.tier) {
      case CredibilityTier.trusted:
        return Colors.green;
      case CredibilityTier.reliable:
        return Colors.lightBlue;
      case CredibilityTier.mixed:
        return Colors.orange;
      case CredibilityTier.unreliable:
        return Colors.red;
      case CredibilityTier.unknown:
        return Colors.grey;
    }
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) => onTap(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.manage_search, size: 64, color: Color(0xFF6750A4)),
          const SizedBox(height: 16),
          Text(
            'Research anything',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Web search • Deep research • Citations • Fact-checking',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
