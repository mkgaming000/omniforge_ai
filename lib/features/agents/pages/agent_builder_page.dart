// Agent Builder Page - create multi-agent teams, RAG, knowledge base
import 'package:flutter/material.dart';

class AgentBuilderPage extends StatelessWidget {
  const AgentBuilderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'My Agents'),
              Tab(text: 'Agent Builder'),
              Tab(text: 'Knowledge Base'),
              Tab(text: 'Workflows'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildAgentsList(),
                _buildBuilder(),
                _buildKnowledgeBase(),
                _buildWorkflows(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentsList() {
    final agents = [
      ('Research Assistant', 'GPT-4o', Icons.search),
      ('Code Reviewer', 'Claude 3.5 Sonnet', Icons.code),
      ('Travel Planner', 'Gemini 1.5 Pro', Icons.flight),
      ('Personal Chef', 'GPT-4o', Icons.restaurant),
      ('Fitness Coach', 'DeepSeek-V3', Icons.fitness_center),
      ('Language Tutor', 'Mistral Large', Icons.translate),
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: agents.length,
      itemBuilder: (context, index) {
        final a = agents[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(a.$3),
            ),
            title: Text(a.$1),
            subtitle: Text('Powered by ${a.$2}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        );
      },
    );
  }

  Widget _buildBuilder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.smart_toy, size: 64, color: Color(0xFF6750A4)),
            const SizedBox(height: 16),
            const Text('Build Custom Agents', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            const Text(
              'Create specialized AI agents with custom instructions, '
              'memory, tools, and knowledge bases.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: null,
              icon: const Icon(Icons.add),
              label: const Text('New Agent'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKnowledgeBase() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Card(
          child: ListTile(
            leading: Icon(Icons.menu_book, color: Color(0xFF6750A4)),
            title: Text('Documentation KB'),
            subtitle: Text('847 documents • Vector index ready'),
            trailing: Chip(label: Text('Active')),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.business, color: Color(0xFF00E5FF)),
            title: Text('Company Wiki'),
            subtitle: Text('2,341 documents • Indexed'),
            trailing: Chip(label: Text('Active')),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.code, color: Color(0xFFFF6B6B)),
            title: Text('Code Repository'),
            subtitle: Text('156 files • Embeddings computed'),
            trailing: Chip(label: Text('Active')),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkflows() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Card(
          child: ListTile(
            leading: Icon(Icons.account_tree, color: Color(0xFF6750A4)),
            title: Text('Content Pipeline'),
            subtitle: Text('Research → Draft → Review → Publish'),
            trailing: Icon(Icons.play_arrow),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.bug_report, color: Color(0xFFFF6B6B)),
            title: Text('Bug Triage'),
            subtitle: Text('Classify → Assign → Notify'),
            trailing: Icon(Icons.play_arrow),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.email, color: Color(0xFF00E5FF)),
            title: Text('Email Assistant'),
            subtitle: Text('Filter → Categorize → Draft reply'),
            trailing: Icon(Icons.play_arrow),
          ),
        ),
      ],
    );
  }
}
