// Usage Page - token/cost/request statistics dashboard
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/ai_providers.dart';
import '../../../injection/injection.dart';
import '../../../presentation/blocs/usage/usage_bloc.dart';
import '../../../presentation/blocs/usage/usage_event.dart';
import '../../../presentation/blocs/usage/usage_state.dart';

class UsagePage extends StatelessWidget {
  const UsagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<UsageBloc>()..add(const LoadUsageStats()),
      child: BlocBuilder<UsageBloc, UsageState>(
        builder: (context, state) {
          if (state.status == UsageStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final stats = state.stats;
          if (stats == null) {
            return const Center(child: Text('No usage data yet'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryCards(stats: stats),
              const SizedBox(height: 24),
              _CostChart(stats: stats),
              const SizedBox(height: 24),
              _ProviderBreakdown(stats: stats),
              const SizedBox(height: 24),
              _OperationBreakdown(stats: stats),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.stats});
  final dynamic stats; // UsageStats

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          title: 'Total Tokens',
          value: _formatNumber(stats.totalTokens as int),
          icon: Icons.token,
          color: const Color(0xFF6750A4),
        ),
        _StatCard(
          title: 'Total Cost',
          value: '\$${(stats.totalCostUsd as double).toStringAsFixed(2)}',
          icon: Icons.attach_money,
          color: const Color(0xFF00E5FF),
        ),
        _StatCard(
          title: 'Requests',
          value: _formatNumber(stats.totalRequests as int),
          icon: Icons.api,
          color: const Color(0xFFFF6B6B),
        ),
        _StatCard(
          title: 'Avg Cost/Req',
          value:
              '\$${(stats.totalRequests == 0 ? 0 : stats.totalCostUsd / stats.totalRequests).toStringAsFixed(4)}',
          icon: Icons.trending_up,
          color: const Color(0xFF10A37F),
        ),
      ],
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const Spacer(),
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _CostChart extends StatelessWidget {
  const _CostChart({required this.stats});
  final dynamic stats;

  @override
  Widget build(BuildContext context) {
    final byDay = stats.byDay as Map<String, dynamic>;
    if (byDay.isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.bar_chart),
          title: Text('Daily Cost'),
          subtitle: Text('No data yet'),
        ),
      );
    }
    final days = byDay.keys.toList()..sort();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Daily Cost', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: days.asMap().entries.map((e) {
                        final day = e.value;
                        final cost = (byDay[day] as dynamic).costUsd as double;
                        return FlSpot(e.key.toDouble(), cost);
                      }).toList(),
                      isCurved: true,
                      color: const Color(0xFF6750A4),
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF6750A4).withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderBreakdown extends StatelessWidget {
  const _ProviderBreakdown({required this.stats});
  final dynamic stats;

  @override
  Widget build(BuildContext context) {
    final byProvider = stats.byProvider as Map<String, dynamic>;
    if (byProvider.isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.donut_large),
          title: Text('By Provider'),
          subtitle: Text('No data yet'),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('By Provider', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...byProvider.entries.map((entry) {
              final provider = AIProvider.values.firstWhere(
                (p) => p.name == entry.key,
                orElse: () => AIProvider.openai,
              );
              final pStats = entry.value;
              return ListTile(
                dense: true,
                leading: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: provider.brandColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                title: Text(provider.displayName),
                subtitle:
                    Text('${(pStats.tokensIn + pStats.tokensOut)} tokens'),
                trailing:
                    Text('\$${(pStats.costUsd as double).toStringAsFixed(4)}'),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _OperationBreakdown extends StatelessWidget {
  const _OperationBreakdown({required this.stats});
  final dynamic stats;

  @override
  Widget build(BuildContext context) {
    final byOp = stats.byOperation as Map<dynamic, dynamic>;
    if (byOp.isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.category),
          title: Text('By Operation'),
          subtitle: Text('No data yet'),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'By Operation',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: byOp.entries.map((entry) {
                return Chip(
                  label: Text('${entry.key.name}: ${entry.value}'),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
