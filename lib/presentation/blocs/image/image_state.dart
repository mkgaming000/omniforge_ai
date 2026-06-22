import 'package:equatable/equatable.dart';

import '../../../domain/entities/image_entity.dart';

enum ImageStatus { initial, loading, ready, generating, error }

class ImageState extends Equatable {
  const ImageState({
    this.status = ImageStatus.initial,
    this.gallery = const [],
    this.lastGenerated = const [],
    this.error,
  });

  const ImageState.initial() : this();

  final ImageStatus status;
  final List<ImageEntity> gallery;
  final List<ImageEntity> lastGenerated;
  final String? error;

  ImageState copyWith({
    ImageStatus? status,
    List<ImageEntity>? gallery,
    List<ImageEntity>? lastGenerated,
    String? error,
  }) {
    return ImageState(
      status: status ?? this.status,
      gallery: gallery ?? this.gallery,
      lastGenerated: lastGenerated ?? this.lastGenerated,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, gallery, lastGenerated, error];
}
