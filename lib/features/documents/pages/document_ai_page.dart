// Document AI Page - PDF, Word, Excel, PowerPoint, Markdown processing
import 'package:flutter/material.dart';

class DocumentAIPage extends StatelessWidget {
  const DocumentAIPage({super.key});

  @override
  Widget build(BuildContext context) {
    final operations = [
      (
        'Summarize',
        'Get a concise summary',
        Icons.summarize,
        const Color(0xFF6750A4)
      ),
      (
        'Extract Data',
        'Pull structured data from documents',
        Icons.data_object,
        const Color(0xFF00E5FF)
      ),
      (
        'Translate',
        'Translate to any language',
        Icons.translate,
        const Color(0xFFFF6B6B)
      ),
      (
        'Q&A',
        'Ask questions about content',
        Icons.question_answer,
        const Color(0xFF10A37F)
      ),
      (
        'Convert',
        'PDF ↔ Word ↔ Markdown ↔ HTML',
        Icons.swap_horiz,
        const Color(0xFFFF7000)
      ),
      (
        'Analyze',
        'Sentiment, key topics, entities',
        Icons.analytics,
        const Color(0xFF7D5260)
      ),
      (
        'Generate',
        'Create new documents from prompts',
        Icons.auto_awesome,
        const Color(0xFF6467F2)
      ),
      (
        'OCR',
        'Extract text from images/scans',
        Icons.document_scanner,
        const Color(0xFF4285F4)
      ),
    ];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6750A4), Color(0xFF00E5FF)],
            ),
          ),
          child: Column(
            children: [
              const Icon(Icons.description, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                'Document AI',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Process PDF, Word, Excel, PowerPoint, Markdown & more',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Document'),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: operations
                        .map(
                          (op) => _OperationCard(
                            name: op.$1,
                            description: op.$2,
                            icon: op.$3,
                            color: op.$4,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OperationCard extends StatelessWidget {
  const _OperationCard({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String name;
  final String description;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
