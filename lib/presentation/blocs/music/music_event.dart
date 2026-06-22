import 'package:equatable/equatable.dart';

import '../../../core/constants/ai_providers.dart';

abstract class MusicEvent extends Equatable {
  const MusicEvent();
}

class GenerateMusic extends MusicEvent {
  const GenerateMusic({
    required this.provider,
    required this.model,
    required this.prompt,
    this.title,
    this.lyrics,
    this.duration = 30,
    this.tags = const [],
    this.style,
  });

  final AIProvider provider;
  final String model;
  final String prompt;
  final String? title;
  final String? lyrics;
  final int duration;
  final List<String> tags;
  final String? style;

  @override
  List<Object?> get props =>
      [provider, model, prompt, title, lyrics, duration, tags, style];
}

class LoadMusic extends MusicEvent {
  const LoadMusic();
  @override
  List<Object?> get props => [];
}

class DeleteMusic extends MusicEvent {
  const DeleteMusic(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}
