// Music Studio Page - lyrics generation, song generation, voice cloning
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/ai_providers.dart';

class MusicStudioPage extends StatefulWidget {
  const MusicStudioPage({super.key});

  @override
  State<MusicStudioPage> createState() => _MusicStudioPageState();
}

class _MusicStudioPageState extends State<MusicStudioPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _promptController = TextEditingController();
  final _lyricsController = TextEditingController();
  AIProvider _selectedProvider = AIProvider.suno;
  bool _instrumental = false;
  int _duration = 30;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _promptController.dispose();
    _lyricsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Generate'),
            Tab(text: 'Lyrics'),
            Tab(text: 'Voice Clone'),
            Tab(text: 'Library'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildGenerateTab(context),
              _buildLyricsTab(context),
              _buildVoiceCloneTab(context),
              _buildLibraryTab(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<AIProvider>(
            value: _selectedProvider,
            decoration: const InputDecoration(labelText: 'Provider'),
            items: AIProvider.values
                .where((p) => p.isMusic)
                .map(
                  (p) => DropdownMenuItem(
                    value: p,
                    child: Text(p.displayName),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _selectedProvider = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _promptController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Song description',
              hintText: 'A lofi hip-hop track about rain in Tokyo...',
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Instrumental only'),
            value: _instrumental,
            onChanged: (v) => setState(() => _instrumental = v),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Duration'),
              Expanded(
                child: Slider(
                  value: _duration.toDouble(),
                  min: 10,
                  max: 120,
                  divisions: 11,
                  label: '${_duration}s',
                  onChanged: (v) => setState(() => _duration = v.toInt()),
                ),
              ),
              Text('${_duration}s'),
            ],
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.music_note),
            label: const Text('Generate Song'),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _lyricsController,
            maxLines: 12,
            decoration: const InputDecoration(
              labelText: 'Write or paste lyrics',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Generate with AI'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.library_music),
                  label: const Text('Use for Song'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceCloneTab(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.record_voice_over,
              size: 64,
              color: Color(0xFF6750A4),
            ).animate().fadeIn(),
            const SizedBox(height: 16),
            Text(
              'Clone your voice',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload 30 seconds of clean audio to create a custom voice model. '
              'Use it for TTS, speech-to-speech, and song generation.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.mic),
              label: const Text('Record Sample'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Audio'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryTab(BuildContext context) {
    return const Center(
      child: Text('Your generated songs will appear here'),
    );
  }
}
