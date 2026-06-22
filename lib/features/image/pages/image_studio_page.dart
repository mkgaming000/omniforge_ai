// Image Studio Page - prompt input, model selection, generation
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/ai_providers.dart';
import '../../../domain/entities/image_entity.dart';
import '../../../injection/injection.dart';
import '../../../presentation/blocs/image/image_bloc.dart';
import '../../../presentation/blocs/image/image_event.dart';
import '../../../presentation/blocs/image/image_state.dart';
import '../widgets/image_grid.dart';

class ImageStudioPage extends StatefulWidget {
  const ImageStudioPage({super.key});

  @override
  State<ImageStudioPage> createState() => _ImageStudioPageState();
}

class _ImageStudioPageState extends State<ImageStudioPage> {
  final _promptController = TextEditingController();
  final _negativeController = TextEditingController();
  AIProvider _selectedProvider = AIProvider.openai;
  String _selectedModel = 'gpt-image-1';
  double _width = 1024;
  double _height = 1024;
  int _count = 1;

  @override
  void dispose() {
    _promptController.dispose();
    _negativeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ImageBloc>(),
      child: BlocBuilder<ImageBloc, ImageState>(
        builder: (context, state) {
          return Column(
            children: [
              Expanded(
                child: state.gallery.isEmpty
                    ? const _EmptyImageState()
                    : ImageGrid(images: state.gallery),
              ),
              _buildInputPanel(context, state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInputPanel(BuildContext context, ImageState state) {
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
            // Provider selector
            DropdownButtonFormField<AIProvider>(
              value: _selectedProvider,
              decoration: const InputDecoration(labelText: 'Provider'),
              items: AIProvider.values
                  .where((p) => p.isImage)
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
                          Text(p.displayName),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() {
                _selectedProvider = v!;
                _selectedModel = _defaultModelFor(v);
              }),
            ),
            const SizedBox(height: 12),
            // Prompt input
            TextField(
              controller: _promptController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Prompt',
                hintText: 'Describe the image you want to create...',
              ),
            ),
            const SizedBox(height: 12),
            // Size selector
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: '${_width.toInt()}x${_height.toInt()}',
                    decoration: const InputDecoration(labelText: 'Size'),
                    items: const [
                      DropdownMenuItem(
                        value: '1024x1024',
                        child: Text('Square 1024'),
                      ),
                      DropdownMenuItem(
                        value: '1792x1024',
                        child: Text('Landscape'),
                      ),
                      DropdownMenuItem(
                        value: '1024x1792',
                        child: Text('Portrait'),
                      ),
                      DropdownMenuItem(
                        value: '512x512',
                        child: Text('Small 512'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      final parts = v.split('x');
                      setState(() {
                        _width = double.parse(parts[0]);
                        _height = double.parse(parts[1]);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 80,
                  child: DropdownButtonFormField<int>(
                    value: _count,
                    decoration: const InputDecoration(labelText: 'Count'),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1')),
                      DropdownMenuItem(value: 2, child: Text('2')),
                      DropdownMenuItem(value: 4, child: Text('4')),
                    ],
                    onChanged: (v) => setState(() => _count = v ?? 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: state.status == ImageStatus.generating
                    ? null
                    : () => _generate(context),
                icon: state.status == ImageStatus.generating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  state.status == ImageStatus.generating
                      ? 'Generating...'
                      : 'Generate',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _generate(BuildContext context) {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;
    context.read<ImageBloc>().add(
          GenerateImage(
            ImageGenerationRequest(
              provider: _selectedProvider,
              model: _selectedModel,
              prompt: prompt,
              width: _width.toInt(),
              height: _height.toInt(),
              count: _count,
              negativePrompt: _negativeController.text.trim().isEmpty
                  ? null
                  : _negativeController.text.trim(),
            ),
          ),
        );
    _promptController.clear();
  }

  String _defaultModelFor(AIProvider provider) {
    switch (provider) {
      case AIProvider.openai:
        return 'gpt-image-1';
      case AIProvider.stability:
        return 'stable-image-ultra';
      case AIProvider.flux:
        return 'flux-pro-1.1';
      case AIProvider.ideogram:
        return 'V_2';
      case AIProvider.recraft:
        return 'recraftv3';
      case AIProvider.leonardo:
        return '6bef9f1b-29cb-40c7-b9df-32b51c1f67d3';
      default:
        return 'default';
    }
  }
}

class _EmptyImageState extends StatelessWidget {
  const _EmptyImageState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_outlined, size: 64)
              .animate()
              .fadeIn(duration: 500.ms),
          const SizedBox(height: 16),
          Text(
            'Generate your first image',
            style: Theme.of(context).textTheme.titleMedium,
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            'Powered by DALL-E 3, FLUX, SDXL, Ideogram & more',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}
