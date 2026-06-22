// Model Defaults Page - configure default models per task type
import 'package:flutter/material.dart';

import '../../../core/constants/ai_providers.dart';

class ModelDefaultsPage extends StatefulWidget {
  const ModelDefaultsPage({super.key});

  @override
  State<ModelDefaultsPage> createState() => _ModelDefaultsPageState();
}

class _ModelDefaultsPageState extends State<ModelDefaultsPage> {
  late AIProvider _chatDefault;
  late AIProvider _imageDefault;
  late AIProvider _videoDefault;
  late AIProvider _musicDefault;
  late AIProvider _codeDefault;
  late AIProvider _reasoningDefault;
  late AIProvider _visionDefault;

  @override
  void initState() {
    super.initState();
    _chatDefault = AIProvider.openai;
    _imageDefault = AIProvider.openai;
    _videoDefault = AIProvider.runway;
    _musicDefault = AIProvider.suno;
    _codeDefault = AIProvider.anthropic;
    _reasoningDefault = AIProvider.anthropic;
    _visionDefault = AIProvider.google;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle('Conversational Tasks'),
        _ProviderDropdown(
          label: 'Default Chat Model',
          value: _chatDefault,
          providers: AIProvider.values.where((p) => p.isChat).toList(),
          onChanged: (v) => setState(() => _chatDefault = v!),
        ),
        _ProviderDropdown(
          label: 'Default Reasoning Model',
          value: _reasoningDefault,
          providers: AIProvider.values.where((p) => p.isChat).toList(),
          onChanged: (v) => setState(() => _reasoningDefault = v!),
        ),
        _ProviderDropdown(
          label: 'Default Vision Model',
          value: _visionDefault,
          providers: AIProvider.values
              .where((p) => p.isChat)
              .where((p) => p != AIProvider.deepseek)
              .toList(),
          onChanged: (v) => setState(() => _visionDefault = v!),
        ),
        _ProviderDropdown(
          label: 'Default Code Model',
          value: _codeDefault,
          providers: AIProvider.values.where((p) => p.isChat).toList(),
          onChanged: (v) => setState(() => _codeDefault = v!),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('Generative Tasks'),
        _ProviderDropdown(
          label: 'Default Image Model',
          value: _imageDefault,
          providers: AIProvider.values.where((p) => p.isImage).toList(),
          onChanged: (v) => setState(() => _imageDefault = v!),
        ),
        _ProviderDropdown(
          label: 'Default Video Model',
          value: _videoDefault,
          providers: AIProvider.values.where((p) => p.isVideo).toList(),
          onChanged: (v) => setState(() => _videoDefault = v!),
        ),
        _ProviderDropdown(
          label: 'Default Music Model',
          value: _musicDefault,
          providers: AIProvider.values.where((p) => p.isMusic).toList(),
          onChanged: (v) => setState(() => _musicDefault = v!),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('AI Routing'),
        const Card(
          child: ListTile(
            leading: Icon(Icons.auto_awesome),
            title: Text('Auto-route to best model'),
            subtitle: Text('OmniForge will pick the optimal provider '
                'based on task type, cost, and health'),
            trailing: Switch(value: true, onChanged: null),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.swap_horiz),
            title: Text('Provider fallback'),
            subtitle: Text('Try alternate providers if the primary fails'),
            trailing: Switch(value: true, onChanged: null),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.savings),
            title: Text('Cost-aware routing'),
            subtitle: Text('Prefer cheaper models for simple tasks'),
            trailing: Switch(value: false, onChanged: null),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _ProviderDropdown extends StatelessWidget {
  const _ProviderDropdown({
    required this.label,
    required this.value,
    required this.providers,
    required this.onChanged,
  });

  final String label;
  final AIProvider value;
  final List<AIProvider> providers;
  final ValueChanged<AIProvider?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: DropdownButtonFormField<AIProvider>(
          value: value,
          decoration: InputDecoration(
            labelText: label,
            border: InputBorder.none,
          ),
          items: providers
              .map(
                (p) => DropdownMenuItem(
                  value: p,
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: p.brandColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(p.displayName),
                            Text(
                              p.description,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
