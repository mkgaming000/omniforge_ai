// Image Gallery Page - browses all saved images
import 'package:flutter/material.dart';

import '../widgets/image_grid.dart';

class ImageGalleryPage extends StatelessWidget {
  const ImageGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Loads from local storage in production
    return const ImageGrid(images: []);
  }
}
