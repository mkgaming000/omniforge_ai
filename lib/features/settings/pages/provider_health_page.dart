// Provider Health Page - monitor AI provider availability in real-time
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/ai_providers.dart';
import '../../../injection/injection.dart';
import '../../../data/services/ai/ai_provider_factory.dart';

class ProviderHealthPage extends StatefulWidget {
  const ProviderHealthPage({super.key});

  @override
  State<ProviderHealthPage> createState() => _ProviderHealthPageState();
}

class _ProviderHealthPageState extends State<ProviderHealthPage> {
  final Map<AIProvider, bool> _health = {};
  final Map<AIProvider, DateTime> _lastCheck = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAll();
  }

  Future<void> _checkAll() async {
    setState(() => _isLoading = true);
    final factory = getIt<AIProviderFactory>();
    for (final provider in AIProvider.values) {
      if (!provider.isChat && !provider.isImage && !provider.isVideo) continue;
      final result = await factory.getService(provider);
      bool healthy = false;
      result.fold(
        (_) => healthy = false,
        (service) async {
          // Use chat service health check
          final h = await service.healthCheck();
          healthy = h.getOrElse(() => false);
        },
      );
      // Wait briefly since getService is async
      await Future.delayed(const Duration(milliseconds: 100));
      setState(() {
        _health[provider] = healthy;
        _lastCheck[provider] = DateTime.now();
      });
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _checkAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryCard(health: _health),
          const SizedBox(height: 16),
          ...AIProvider.values
              .where((p) => p.isChat || p.isImage || p.isVideo)
              .map(
                (p) => _ProviderHealthCard(
                  provider: p,
                  healthy: _health[p] ?? false,
                  lastCheck: _lastCheck[p],
                ).animate().fadeIn(delay: 50.ms),
              ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.health});
  final Map<AIProvider, bool> health;

  @override
  Widget build(BuildContext context) {
    final total = health.length;
    final healthy = health.values.where((h) => h).length;
    final percent = total == 0 ? 0 : (healthy * 100 / total).round();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat(
                  label: 'Healthy',
                  value: '$healthy',
                  color: Colors.green,
                ),
                _Stat(
                  label: 'Total',
                  value: '$total',
                  color: Colors.blue,
                ),
                _Stat(
                  label: 'Uptime',
                  value: '$percent%',
                  color: percent >= 80
                      ? Colors.green
                      : percent >= 50
                          ? Colors.orange
                          : Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

class _ProviderHealthCard extends StatelessWidget {
  const _ProviderHealthCard({
    required this.provider,
    required this.healthy,
    required this.lastCheck,
  });

  final AIProvider provider;
  final bool healthy;
  final DateTime? lastCheck;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: provider.brandColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              provider.displayName[0],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(provider.displayName),
        subtitle: Text(
          lastCheck != null
              ? 'Last check: ${lastCheck!.toString().substring(11, 19)}'
              : 'Not checked yet',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (healthy ? Colors.green : Colors.red).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                healthy ? Icons.check_circle : Icons.error,
                color: healthy ? Colors.green : Colors.red,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                healthy ? 'Healthy' : 'Down',
                style: TextStyle(
                  color: healthy ? Colors.green : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
