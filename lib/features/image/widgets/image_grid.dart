// Image Grid - displays generated images in a responsive grid
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';

import '../../../domain/entities/image_entity.dart';

class ImageGrid extends StatelessWidget {
  const ImageGrid({super.key, required this.images});

  final List<ImageEntity> images;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final image = images[index];
        return _ImageCard(image: image)
            .animate()
            .fadeIn(delay: (index * 50).ms, duration: 300.ms)
            .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
      },
    );
  }
}

class _ImageCard extends StatelessWidget {
  const _ImageCard({required this.image});

  final ImageEntity image;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openViewer(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: image.url,
              fit: BoxFit.cover,
              progressIndicatorBuilder: (context, url, progress) => Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Center(
                  child: CircularProgressIndicator(
                    value: progress.progress,
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                color: Theme.of(context).colorScheme.errorContainer,
                child: const Icon(Icons.broken_image),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      image.provider.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      image.prompt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (image.favorite)
              const Positioned(
                top: 4,
                right: 4,
                child: Icon(Icons.favorite, color: Colors.red, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  void _openViewer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ImageViewerPage(image: image),
      ),
    );
  }
}

class _ImageViewerPage extends StatelessWidget {
  const _ImageViewerPage({required this.image});

  final ImageEntity image;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(image.provider.displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => Share.share(image.url),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Download started')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PhotoView(
              imageProvider: CachedNetworkImageProvider(image.url),
              backgroundDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prompt',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 4),
                Text(image.prompt),
                if (image.negativePrompt != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Negative',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  Text(image.negativePrompt!),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    _meta(context, 'Model', image.model),
                    _meta(context, 'Size', '${image.width}×${image.height}'),
                    if (image.seed != null)
                      _meta(context, 'Seed', image.seed.toString()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _meta(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
