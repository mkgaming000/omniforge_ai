// Model configuration entity - per-message model settings
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

import '../../core/constants/ai_providers.dart';

part 'model_config_entity.g.dart';

@HiveType(typeId: 7)
class ModelConfigEntity extends Equatable {
  const ModelConfigEntity({
    required this.provider,
    required this.modelId,
    this.displayName,
    this.temperature = 0.7,
    this.maxTokens = 4096,
    this.topP = 1.0,
    this.frequencyPenalty = 0.0,
    this.presencePenalty = 0.0,
    this.stopSequences = const [],
    this.stream = true,
    this.tools = const [],
    this.toolChoice,
    this.responseFormat,
    this.seed,
    this.customHeaders = const {},
    this.customParams = const {},
    this.costPer1kInput = 0.0,
    this.costPer1kOutput = 0.0,
    this.contextWindow = 8192,
    this.supportsVision = false,
    this.supportsTools = false,
    this.supportsStreaming = true,
  });

  @HiveField(0)
  final AIProvider provider;

  @HiveField(1)
  final String modelId;

  @HiveField(2)
  final String? displayName;

  @HiveField(3)
  final double temperature;

  @HiveField(4)
  final int maxTokens;

  @HiveField(5)
  final double topP;

  @HiveField(6)
  final double frequencyPenalty;

  @HiveField(7)
  final double presencePenalty;

  @HiveField(8)
  final List<String> stopSequences;

  @HiveField(9)
  final bool stream;

  @HiveField(10)
  final List<String> tools;

  @HiveField(11)
  final String? toolChoice;

  @HiveField(12)
  final String? responseFormat;

  @HiveField(13)
  final int? seed;

  @HiveField(14)
  final Map<String, String> customHeaders;

  @HiveField(15)
  final Map<String, dynamic> customParams;

  @HiveField(16)
  final double costPer1kInput;

  @HiveField(17)
  final double costPer1kOutput;

  @HiveField(18)
  final int contextWindow;

  @HiveField(19)
  final bool supportsVision;

  @HiveField(20)
  final bool supportsTools;

  @HiveField(21)
  final bool supportsStreaming;

  String get fullId => '${provider.name}/$modelId';

  ModelConfigEntity copyWith({
    AIProvider? provider,
    String? modelId,
    String? displayName,
    double? temperature,
    int? maxTokens,
    double? topP,
    double? frequencyPenalty,
    double? presencePenalty,
    List<String>? stopSequences,
    bool? stream,
    List<String>? tools,
    String? toolChoice,
    String? responseFormat,
    int? seed,
    Map<String, String>? customHeaders,
    Map<String, dynamic>? customParams,
    double? costPer1kInput,
    double? costPer1kOutput,
    int? contextWindow,
    bool? supportsVision,
    bool? supportsTools,
    bool? supportsStreaming,
  }) {
    return ModelConfigEntity(
      provider: provider ?? this.provider,
      modelId: modelId ?? this.modelId,
      displayName: displayName ?? this.displayName,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      topP: topP ?? this.topP,
      frequencyPenalty: frequencyPenalty ?? this.frequencyPenalty,
      presencePenalty: presencePenalty ?? this.presencePenalty,
      stopSequences: stopSequences ?? this.stopSequences,
      stream: stream ?? this.stream,
      tools: tools ?? this.tools,
      toolChoice: toolChoice ?? this.toolChoice,
      responseFormat: responseFormat ?? this.responseFormat,
      seed: seed ?? this.seed,
      customHeaders: customHeaders ?? this.customHeaders,
      customParams: customParams ?? this.customParams,
      costPer1kInput: costPer1kInput ?? this.costPer1kInput,
      costPer1kOutput: costPer1kOutput ?? this.costPer1kOutput,
      contextWindow: contextWindow ?? this.contextWindow,
      supportsVision: supportsVision ?? this.supportsVision,
      supportsTools: supportsTools ?? this.supportsTools,
      supportsStreaming: supportsStreaming ?? this.supportsStreaming,
    );
  }

  @override
  List<Object?> get props => [
        provider,
        modelId,
        displayName,
        temperature,
        maxTokens,
        topP,
        frequencyPenalty,
        presencePenalty,
        stopSequences,
        stream,
        tools,
        toolChoice,
        responseFormat,
        seed,
        customHeaders,
        customParams,
        costPer1kInput,
        costPer1kOutput,
        contextWindow,
        supportsVision,
        supportsTools,
        supportsStreaming,
      ];
}
