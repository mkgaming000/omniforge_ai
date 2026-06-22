// Image generation entity
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

import '../../core/constants/ai_providers.dart';

part 'image_entity.g.dart';

@HiveType(typeId: 10)
class ImageEntity extends Equatable {
  const ImageEntity({
    required this.id,
    required this.url,
    required this.prompt,
    required this.provider,
    required this.model,
    required this.createdAt,
    this.width = 1024,
    this.height = 1024,
    this.style,
    this.negativePrompt,
    this.seed,
    this.steps,
    this.cfgScale,
    this.thumbnailUrl,
    this.localPath,
    this.metadata = const {},
    this.folderId,
    this.collectionIds = const [],
    this.favorite = false,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String url;

  @HiveField(2)
  final String prompt;

  @HiveField(3)
  final AIProvider provider;

  @HiveField(4)
  final String model;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final int width;

  @HiveField(7)
  final int height;

  @HiveField(8)
  final String? style;

  @HiveField(9)
  final String? negativePrompt;

  @HiveField(10)
  final int? seed;

  @HiveField(11)
  final int? steps;

  @HiveField(12)
  final double? cfgScale;

  @HiveField(13)
  final String? thumbnailUrl;

  @HiveField(14)
  final String? localPath;

  @HiveField(15)
  final Map<String, dynamic> metadata;

  @HiveField(16)
  final String? folderId;

  @HiveField(17)
  final List<String> collectionIds;

  @HiveField(18)
  final bool favorite;

  ImageEntity copyWith({
    String? id,
    String? url,
    String? prompt,
    AIProvider? provider,
    String? model,
    DateTime? createdAt,
    int? width,
    int? height,
    String? style,
    String? negativePrompt,
    int? seed,
    int? steps,
    double? cfgScale,
    String? thumbnailUrl,
    String? localPath,
    Map<String, dynamic>? metadata,
    String? folderId,
    List<String>? collectionIds,
    bool? favorite,
  }) {
    return ImageEntity(
      id: id ?? this.id,
      url: url ?? this.url,
      prompt: prompt ?? this.prompt,
      provider: provider ?? this.provider,
      model: model ?? this.model,
      createdAt: createdAt ?? this.createdAt,
      width: width ?? this.width,
      height: height ?? this.height,
      style: style ?? this.style,
      negativePrompt: negativePrompt ?? this.negativePrompt,
      seed: seed ?? this.seed,
      steps: steps ?? this.steps,
      cfgScale: cfgScale ?? this.cfgScale,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      localPath: localPath ?? this.localPath,
      metadata: metadata ?? this.metadata,
      folderId: folderId ?? this.folderId,
      collectionIds: collectionIds ?? this.collectionIds,
      favorite: favorite ?? this.favorite,
    );
  }

  @override
  List<Object?> get props => [
        id,
        url,
        prompt,
        provider,
        model,
        createdAt,
        width,
        height,
        style,
        negativePrompt,
        seed,
        steps,
        cfgScale,
        thumbnailUrl,
        localPath,
        metadata,
        folderId,
        collectionIds,
        favorite,
      ];
}

@HiveType(typeId: 11)
class ImageGenerationRequest extends Equatable {
  const ImageGenerationRequest({
    required this.provider,
    required this.model,
    required this.prompt,
    this.negativePrompt,
    this.width = 1024,
    this.height = 1024,
    this.count = 1,
    this.style,
    this.seed,
    this.steps,
    this.cfgScale,
    this.referenceImageUrl,
    this.maskUrl,
    this.strength,
    this.responseFormat = 'url',
    this.metadata = const {},
  });

  @HiveField(0)
  final AIProvider provider;

  @HiveField(1)
  final String model;

  @HiveField(2)
  final String prompt;

  @HiveField(3)
  final String? negativePrompt;

  @HiveField(4)
  final int width;

  @HiveField(5)
  final int height;

  @HiveField(6)
  final int count;

  @HiveField(7)
  final String? style;

  @HiveField(8)
  final int? seed;

  @HiveField(9)
  final int? steps;

  @HiveField(10)
  final double? cfgScale;

  @HiveField(11)
  final String? referenceImageUrl;

  @HiveField(12)
  final String? maskUrl;

  @HiveField(13)
  final double? strength;

  @HiveField(14)
  final String responseFormat;

  @HiveField(15)
  final Map<String, dynamic> metadata;

  @override
  List<Object?> get props => [
        provider,
        model,
        prompt,
        negativePrompt,
        width,
        height,
        count,
        style,
        seed,
        steps,
        cfgScale,
        referenceImageUrl,
        maskUrl,
        strength,
        responseFormat,
        metadata,
      ];
}
