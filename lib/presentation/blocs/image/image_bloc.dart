// Image Bloc
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/logger.dart';
import '../../../domain/usecases/image/generate_image_usecase.dart';
import 'image_event.dart';
import 'image_state.dart';

class ImageBloc extends Bloc<ImageEvent, ImageState> {
  ImageBloc({required GenerateImageUseCase generateImageUseCase})
      : _generateUseCase = generateImageUseCase,
        super(const ImageState.initial()) {
    on<GenerateImage>(_onGenerate);
    on<LoadGallery>(_onLoadGallery);
    on<ToggleFavorite>(_onToggleFavorite);
    on<DeleteImage>(_onDelete);
  }

  final GenerateImageUseCase _generateUseCase;

  Future<void> _onGenerate(
    GenerateImage event,
    Emitter<ImageState> emit,
  ) async {
    emit(state.copyWith(status: ImageStatus.generating));
    final result = await _generateUseCase(event.request);
    result.fold(
      (f) => emit(
        state.copyWith(
          status: ImageStatus.error,
          error: f.userMessage,
        ),
      ),
      (images) {
        final updated = [...images, ...state.gallery];
        emit(
          state.copyWith(
            status: ImageStatus.ready,
            gallery: updated,
            lastGenerated: images,
          ),
        );
      },
    );
  }

  Future<void> _onLoadGallery(
    LoadGallery event,
    Emitter<ImageState> emit,
  ) async {
    // Gallery persistence is not wired to a repository in this bloc; preserve
    // any images already in state instead of faking a load.
    AppLogger.d('Gallery persistence is not wired; preserving current images.');
    emit(state.copyWith(status: ImageStatus.ready));
  }

  void _onToggleFavorite(
    ToggleFavorite event,
    Emitter<ImageState> emit,
  ) {
    final updated = state.gallery.map((i) {
      if (i.id == event.imageId) {
        return i.copyWith(favorite: !i.favorite);
      }
      return i;
    }).toList();
    emit(state.copyWith(gallery: updated));
  }

  void _onDelete(DeleteImage event, Emitter<ImageState> emit) {
    final updated = state.gallery.where((i) => i.id != event.imageId).toList();
    emit(state.copyWith(gallery: updated));
  }
}
