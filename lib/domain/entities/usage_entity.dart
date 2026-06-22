// Usage tracking entity - tokens, costs, requests per provider/model
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

import '../../core/constants/ai_providers.dart';

part 'usage_entity.g.dart';

@HiveType(typeId: 20)
class UsageEntity extends Equatable {
  const UsageEntity({
    required this.id,
    required this.provider,
    required this.model,
    required this.timestamp,
    required this.tokensIn,
    required this.tokensOut,
    required this.costUsd,
    required this.operation,
    this.conversationId,
    this.metadata = const {},
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final AIProvider provider;

  @HiveField(2)
  final String model;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final int tokensIn;

  @HiveField(5)
  final int tokensOut;

  @HiveField(6)
  final double costUsd;

  @HiveField(7)
  final UsageOperation operation;

  @HiveField(8)
  final String? conversationId;

  @HiveField(9)
  final Map<String, dynamic> metadata;

  int get totalTokens => tokensIn + tokensOut;

  @override
  List<Object?> get props => [
        id,
        provider,
        model,
        timestamp,
        tokensIn,
        tokensOut,
        costUsd,
        operation,
        conversationId,
        metadata,
      ];
}

@HiveType(typeId: 21)
enum UsageOperation {
  @HiveField(0)
  chat,
  @HiveField(1)
  streaming,
  @HiveField(2)
  imageGeneration,
  @HiveField(3)
  imageEdit,
  @HiveField(4)
  videoGeneration,
  @HiveField(5)
  audioTranscription,
  @HiveField(6)
  textToSpeech,
  @HiveField(7)
  musicGeneration,
  @HiveField(8)
  embedding,
  @HiveField(9)
  fineTuning,
  @HiveField(10)
  moderation,
}

@HiveType(typeId: 22)
class UsageStats extends Equatable {
  const UsageStats({
    this.totalTokensIn = 0,
    this.totalTokensOut = 0,
    this.totalCostUsd = 0.0,
    this.totalRequests = 0,
    this.byProvider = const {},
    this.byDay = const {},
    this.byOperation = const {},
  });

  @HiveField(0)
  final int totalTokensIn;

  @HiveField(1)
  final int totalTokensOut;

  @HiveField(2)
  final double totalCostUsd;

  @HiveField(3)
  final int totalRequests;

  @HiveField(4)
  final Map<String, ProviderStats> byProvider;

  @HiveField(5)
  final Map<String, DailyStats> byDay;

  @HiveField(6)
  final Map<UsageOperation, int> byOperation;

  int get totalTokens => totalTokensIn + totalTokensOut;

  @override
  List<Object?> get props => [
        totalTokensIn,
        totalTokensOut,
        totalCostUsd,
        totalRequests,
        byProvider,
        byDay,
        byOperation,
      ];
}

@HiveType(typeId: 23)
class ProviderStats extends Equatable {
  const ProviderStats({
    this.tokensIn = 0,
    this.tokensOut = 0,
    this.costUsd = 0.0,
    this.requests = 0,
  });

  @HiveField(0)
  final int tokensIn;

  @HiveField(1)
  final int tokensOut;

  @HiveField(2)
  final double costUsd;

  @HiveField(3)
  final int requests;

  @override
  List<Object?> get props => [tokensIn, tokensOut, costUsd, requests];
}

@HiveType(typeId: 24)
class DailyStats extends Equatable {
  const DailyStats({
    this.tokensIn = 0,
    this.tokensOut = 0,
    this.costUsd = 0.0,
    this.requests = 0,
  });

  @HiveField(0)
  final int tokensIn;

  @HiveField(1)
  final int tokensOut;

  @HiveField(2)
  final double costUsd;

  @HiveField(3)
  final int requests;

  @override
  List<Object?> get props => [tokensIn, tokensOut, costUsd, requests];
}
