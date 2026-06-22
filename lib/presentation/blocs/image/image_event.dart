import 'package:equatable/equatable.dart';

import '../../../domain/entities/image_entity.dart';

abstract class ImageEvent extends Equatable {
  const ImageEvent();
}

class GenerateImage extends ImageEvent {
  const GenerateImage(this.request);
  final ImageGenerationRequest request;
  @override
  List<Object?> get props => [request];
}

class LoadGallery extends ImageEvent {
  const LoadGallery({this.folderId});
  final String? folderId;
  @override
  List<Object?> get props => [folderId];
}

class ToggleFavorite extends ImageEvent {
  const ToggleFavorite(this.imageId);
  final String imageId;
  @override
  List<Object?> get props => [imageId];
}

class DeleteImage extends ImageEvent {
  const DeleteImage(this.imageId);
  final String imageId;
  @override
  List<Object?> get props => [imageId];
}
