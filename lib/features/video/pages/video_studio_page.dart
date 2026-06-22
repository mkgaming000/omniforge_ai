// Video Studio Page - text-to-video, image-to-video, status tracking
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/ai_providers.dart';

class VideoStudioPage extends StatefulWidget {
  const VideoStudioPage({super.key});

  @override
  State<VideoStudioPage> createState() => _VideoStudioPageState();
}

class _VideoStudioPageState extends State<VideoStudioPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _promptController = TextEditingController();
  AIProvider _selectedProvider = AIProvider.runway;
  int _duration = 5;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Text to Video', icon: Icon(Icons.text_fields)),
            Tab(text: 'Image to Video', icon: Icon(Icons.image)),
            Tab(text: 'Video to Video', icon: Icon(Icons.video_library)),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTextInput(context),
              _buildImageInput(context),
              _buildVideoInput(context),
            ],
          ),
        ),
        _buildControls(context),
      ],
    );
  }

  Widget _buildTextInput(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.movie_creation, size: 64, color: Color(0xFF6750A4))
                .animate()
                .fadeIn(duration: 500.ms),
            const SizedBox(height: 16),
            Text(
              'Generate videos from text prompts',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Runway Gen-3 • Pika • Luma • Kling • Veo • PixVerse • Hailuo',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageInput(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.add_photo_alternate,
            size: 64,
            color: Color(0xFF00E5FF),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.upload_file),
            label: const Text('Select Reference Image'),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoInput(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.video_call, size: 64, color: Color(0xFFFF6B6B)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.upload_file),
            label: const Text('Select Source Video'),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<AIProvider>(
                    value: _selectedProvider,
                    decoration: const InputDecoration(labelText: 'Provider'),
                    items: AIProvider.values
                        .where((p) => p.isVideo)
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.displayName),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedProvider = v!),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 100,
                  child: DropdownButtonFormField<int>(
                    value: _duration,
                    decoration: const InputDecoration(labelText: 'Duration'),
                    items: const [
                      DropdownMenuItem(value: 3, child: Text('3s')),
                      DropdownMenuItem(value: 5, child: Text('5s')),
                      DropdownMenuItem(value: 10, child: Text('10s')),
                    ],
                    onChanged: (v) => setState(() => _duration = v ?? 5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _promptController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Prompt',
                hintText: 'Describe the video scene...',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  // Trigger video generation
                },
                icon: const Icon(Icons.videocam),
                label: const Text('Generate Video'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
