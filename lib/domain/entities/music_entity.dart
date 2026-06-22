// Music entity - generated music records
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

import '../../core/constants/ai_providers.dart';

part 'music_entity.g.dart';

@HiveType(typeId: 40)
class MusicEntity extends Equatable {
  const MusicEntity({
    required this.id,
    required this.prompt,
    required this.provider,
    required this.model,
    required this.createdAt,
    this.audioUrl,
    this.title,
    this.lyrics,
    this.duration = 30,
    this.tags = const [],
    this.style,
    this.status = MusicStatus.pending,
    this.metadata = const {},
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String prompt;

  @HiveField(2)
  final AIProvider provider;

  @HiveField(3)
  final String model;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final String? audioUrl;

  @HiveField(6)
  final String? title;

  @HiveField(7)
  final String? lyrics;

  @HiveField(8)
  final int duration;

  @HiveField(9)
  final List<String> tags;

  @HiveField(10)
  final String? style;

  @HiveField(11)
  final MusicStatus status;

  @HiveField(12)
  final Map<String, dynamic> metadata;

  MusicEntity copyWith({
    String? id,
    String? prompt,
    AIProvider? provider,
    String? model,
    DateTime? createdAt,
    String? audioUrl,
    String? title,
    String? lyrics,
    int? duration,
    List<String>? tags,
    String? style,
    MusicStatus? status,
    Map<String, dynamic>? metadata,
  }) {
    return MusicEntity(
      id: id ?? this.id,
      prompt: prompt ?? this.prompt,
      provider: provider ?? this.provider,
      model: model ?? this.model,
      createdAt: createdAt ?? this.createdAt,
      audioUrl: audioUrl ?? this.audioUrl,
      title: title ?? this.title,
      lyrics: lyrics ?? this.lyrics,
      duration: duration ?? this.duration,
      tags: tags ?? this.tags,
      style: style ?? this.style,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        prompt,
        provider,
        model,
        createdAt,
        audioUrl,
        title,
        lyrics,
        duration,
        tags,
        style,
        status,
        metadata,
      ];
}

@HiveType(typeId: 41)
enum MusicStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  processing,
  @HiveField(2)
  complete,
  @HiveField(3)
  failed,
  @HiveField(4)
  streaming,
}

@HiveType(typeId: 42)
class MusicGenerationRequest extends Equatable {
  const MusicGenerationRequest({
    required this.provider,
    required this.model,
    required this.prompt,
    this.lyrics,
    this.title,
    this.duration = 30,
    this.tags = const [],
    this.style,
    this.instrumental = false,
    this.metadata = const {},
  });

  @HiveField(0)
  final AIProvider provider;

  @HiveField(1)
  final String model;

  @HiveField(2)
  final String prompt;

  @HiveField(3)
  final String? lyrics;

  @HiveField(4)
  final String? title;

  @HiveField(5)
  final int duration;

  @HiveField(6)
  final List<String> tags;

  @HiveField(7)
  final String? style;

  @HiveField(8)
  final bool instrumental;

  @HiveField(9)
  final Map<String, dynamic> metadata;

  @override
  List<Object?> get props => [
        provider,
        model,
        prompt,
        lyrics,
        title,
        duration,
        tags,
        style,
        instrumental,
        metadata,
      ];
}
