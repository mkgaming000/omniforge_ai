// MCP Marketplace Page - Model Context Protocol tools registry
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class McpMarketplacePage extends StatelessWidget {
  const McpMarketplacePage({super.key});

  @override
  Widget build(BuildContext context) {
    final tools = [
      ('Filesystem', 'Read, write, search files', Icons.folder, true),
      ('Web Browser', 'Navigate, click, type on any page', Icons.web, true),
      ('Database', 'Query SQL/NoSQL databases', Icons.storage, false),
      ('Git', 'Clone, commit, push, pull', Icons.code, true),
      ('Slack', 'Send messages, search history', Icons.chat, false),
      ('Linear', 'Create issues, manage projects', Icons.task, false),
      ('Notion', 'Read/write Notion pages', Icons.note, false),
      ('Postman', 'Run HTTP requests', Icons.api, false),
      ('Docker', 'Manage containers', Icons.inventory_2, false),
      (
        'Kubernetes',
        'Pod, deployment, service management',
        Icons.settings_input_component,
        false
      ),
      ('AWS', 'S3, EC2, Lambda operations', Icons.cloud, false),
      ('Stripe', 'Create charges, manage customers', Icons.payment, false),
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: tools.length,
      itemBuilder: (context, index) {
        final t = tools[index];
        return _ToolCard(
          name: t.$1,
          description: t.$2,
          icon: t.$3,
          installed: t.$4,
        ).animate().fadeIn(delay: (index * 50).ms).scale(
              begin: const Offset(0.95, 0.95),
              end: const Offset(1, 1),
            );
      },
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.name,
    required this.description,
    required this.icon,
    required this.installed,
  });

  final String name;
  final String description;
  final IconData icon;
  final bool installed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const Spacer(),
                if (installed)
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: Theme.of(context).textTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: installed
                  ? OutlinedButton(
                      onPressed: () {},
                      child: const Text('Configure'),
                    )
                  : FilledButton(
                      onPressed: () {},
                      child: const Text('Install'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
