// Knowledge Base Management Page - create KBs, index documents, search
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../domain/entities/knowledge_base_entity.dart';

class KnowledgeBaseManagementPage extends StatefulWidget {
  const KnowledgeBaseManagementPage({super.key});

  @override
  State<KnowledgeBaseManagementPage> createState() =>
      _KnowledgeBaseManagementPageState();
}

class _KnowledgeBaseManagementPageState
    extends State<KnowledgeBaseManagementPage> {
  // In production, would come from KnowledgeBaseRepository via BLoC
  final List<KnowledgeBaseEntity> _kbs = [
    KnowledgeBaseEntity(
      id: '1',
      name: 'Documentation KB',
      description: 'Internal product docs and API references',
      embeddingProvider: 'openai',
      documentCount: 847,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    KnowledgeBaseEntity(
      id: '2',
      name: 'Company Wiki',
      description: 'HR policies, processes, and team pages',
      embeddingProvider: 'openai',
      documentCount: 2341,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    KnowledgeBaseEntity(
      id: '3',
      name: 'Code Repository',
      description: 'Source code embeddings for code search',
      embeddingProvider: 'cohere',
      documentCount: 156,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Knowledge Bases', icon: Icon(Icons.menu_book)),
              Tab(text: 'Documents', icon: Icon(Icons.description)),
              Tab(text: 'Search Test', icon: Icon(Icons.search)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildKbList(),
                _buildDocuments(),
                _buildSearchTest(),
              ],
            ),
          ),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildKbList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _kbs.length,
      itemBuilder: (context, index) {
        final kb = _kbs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: const Icon(Icons.folder_special),
            ),
            title: Text(kb.name),
            subtitle: Text(
              '${kb.documentCount} docs • ${kb.embeddingProvider} • '
              'Updated ${_relative(kb.updatedAt)}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            children: [
              ListTile(
                dense: true,
                leading: const Icon(Icons.description, size: 18),
                title: Text(kb.description ?? 'No description'),
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.upload_file, size: 18),
                title: const Text('Upload documents'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showUploadDialog(context, kb),
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.search, size: 18),
                title: const Text('Test retrieval'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                dense: true,
                leading: Icon(
                  Icons.delete,
                  size: 18,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Delete KB',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () => _confirmDelete(context, kb),
              ),
            ],
          ),
        ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.05, end: 0);
      },
    );
  }

  Widget _buildDocuments() {
    final docs = [
      ('API Reference.pdf', 'Documentation KB', 'PDF', 1.2),
      ('User Guide.md', 'Documentation KB', 'Markdown', 0.4),
      ('Architecture.docx', 'Documentation KB', 'Word', 0.8),
      ('HR Policies.pdf', 'Company Wiki', 'PDF', 2.1),
      ('Onboarding Guide.docx', 'Company Wiki', 'Word', 1.5),
      ('main.dart', 'Code Repository', 'Code', 0.05),
      ('README.md', 'Code Repository', 'Markdown', 0.08),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final d = docs[index];
        return Card(
          child: ListTile(
            leading: Icon(
              _iconFor(d.$3),
              color: _colorFor(d.$3),
            ),
            title: Text(d.$1),
            subtitle: Text('${d.$2} • ${d.$3} • ${d.$4}MB'),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {},
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchTest() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const TextField(
            decoration: InputDecoration(
              labelText: 'Test query',
              hintText: 'Type a query to test retrieval quality',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.search),
            label: const Text('Run Retrieval Test'),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: const [
                _SearchResult(
                  title: 'API Authentication',
                  snippet: 'All API requests require a Bearer token in the '
                      'Authorization header...',
                  score: 0.92,
                  kb: 'Documentation KB',
                ),
                _SearchResult(
                  title: 'OAuth 2.0 Flow',
                  snippet: 'OmniForge uses the standard authorization code '
                      'flow with PKCE for mobile apps...',
                  score: 0.87,
                  kb: 'Documentation KB',
                ),
                _SearchResult(
                  title: 'Session Management',
                  snippet: 'Sessions expire after 24 hours of inactivity...',
                  score: 0.81,
                  kb: 'Company Wiki',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _showCreateDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('New Knowledge Base'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Knowledge Base'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration:
                  const InputDecoration(labelText: 'Embedding Provider'),
              value: 'openai',
              items: const [
                DropdownMenuItem(value: 'openai', child: Text('OpenAI')),
                DropdownMenuItem(value: 'cohere', child: Text('Cohere')),
              ],
              onChanged: (_) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showUploadDialog(BuildContext context, KnowledgeBaseEntity kb) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Upload to ${kb.name}'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Supported formats: PDF, DOCX, TXT, MD, CSV, JSON, HTML'),
            SizedBox(height: 16),
            LinearProgressIndicator(),
            SizedBox(height: 8),
            Text('Ready to upload'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.upload_file),
            label: const Text('Pick Files'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, KnowledgeBaseEntity kb) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${kb.name}?'),
        content: Text(
          'This will permanently delete the knowledge base and all '
          '${kb.documentCount} indexed documents. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              setState(() {
                _kbs.removeWhere((k) => k.id == kb.id);
              });
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'PDF':
        return Icons.picture_as_pdf;
      case 'Word':
        return Icons.description;
      case 'Markdown':
        return Icons.article;
      case 'Code':
        return Icons.code;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'PDF':
        return Colors.red;
      case 'Word':
        return Colors.blue;
      case 'Markdown':
        return Colors.purple;
      case 'Code':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _relative(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${t.month}/${t.day}';
  }
}

class _SearchResult extends StatelessWidget {
  const _SearchResult({
    required this.title,
    required this.snippet,
    required this.score,
    required this.kb,
  });
  final String title;
  final String snippet;
  final double score;
  final String kb;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: score > 0.85
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(score * 100).toStringAsFixed(0)}% match',
                    style: TextStyle(
                      fontSize: 11,
                      color: score > 0.85 ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(snippet, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text('Source: $kb', style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
