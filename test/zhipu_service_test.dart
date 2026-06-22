// Unit tests for ZhipuService and GLM model catalog
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:omniforge_ai/core/constants/ai_providers.dart';
import 'package:omniforge_ai/data/services/ai/ai_chat_service.dart'
    show ModelInfo;
import 'package:omniforge_ai/data/services/ai/zhipu_service.dart';
import 'package:omniforge_ai/domain/entities/model_config_entity.dart';

void main() {
  group('ZhipuService', () {
    late ZhipuService service;

    setUp(() {
      service = ZhipuService();
    });

    test('returns UnauthorizedFailure when no API key is set', () async {
      // Trigger a reload of dotenv by importing it lazily — in tests we skip
      // the dotenv.load step, so this also exercises the unconfigured path.
      final result = await service.complete(
        messages: const [],
        config: const ModelConfigEntity(
          provider: AIProvider.zhipu,
          modelId: 'glm-5.2',
        ),
      );
      expect(result.isLeft(), isTrue);
      final failure = result.fold((l) => l, (_) => null);
      expect(failure, isNotNull);
      expect(failure!.userMessage.toLowerCase(), contains('zhipu'));
    });

    test('healthCheck returns false without API key', () async {
      final result = await service.healthCheck();
      expect(result.isRight(), isTrue);
      final healthy = result.getOrElse(() => false);
      expect(healthy, isFalse);
    });

    test('listModels returns static catalog including GLM-5.2', () async {
      final result = await service.listModels();
      expect(result.isRight(), isTrue);
      final models = result.getOrElse(() => const <ModelInfo>[]);
      expect(models, isNotEmpty);

      final glm52 = models.firstWhere(
        (m) => m.id == 'glm-5.2',
        orElse: () => throw StateError('GLM-5.2 not found'),
      );
      expect(glm52.displayName, equals('GLM-5.2'));
      expect(glm52.provider, equals('zhipu'));
      expect(glm52.supportsVision, isTrue);
      expect(glm52.supportsTools, isTrue);
      expect(glm52.supportsStreaming, isTrue);
      expect(glm52.contextWindow, equals(256000));
      expect(glm52.maxOutputTokens, equals(16384));
      expect(glm52.costPer1kInput, greaterThan(0));
      expect(glm52.costPer1kOutput, greaterThan(0));
    });

    test('catalog includes free tier models (GLM-4-Flash and FlashX)',
        () async {
      final result = await service.listModels();
      final models = result.getOrElse(() => const <ModelInfo>[]);

      final flash = models.firstWhere((m) => m.id == 'glm-4-flash');
      expect(flash.costPer1kInput, equals(0.0));
      expect(flash.costPer1kOutput, equals(0.0));

      final flashX = models.firstWhere((m) => m.id == 'glm-4-flashx');
      expect(flashX.costPer1kInput, equals(0.0));
      expect(flashX.costPer1kOutput, equals(0.0));
    });

    test('catalog includes long-context model with 1M tokens', () async {
      final result = await service.listModels();
      final models = result.getOrElse(() => const <ModelInfo>[]);

      final longModel = models.firstWhere((m) => m.id == 'glm-4-long');
      expect(longModel.contextWindow, equals(1000000));
    });

    test('catalog includes vision-specialist model (GLM-4V Plus)', () async {
      final result = await service.listModels();
      final models = result.getOrElse(() => const <ModelInfo>[]);

      final vision = models.firstWhere((m) => m.id == 'glm-4v-plus');
      expect(vision.supportsVision, isTrue);
      expect(vision.supportsTools, isFalse);
    });

    test('catalog includes coding specialist (CodeGeeX-4)', () async {
      final result = await service.listModels();
      final models = result.getOrElse(() => const <ModelInfo>[]);

      final codegeex = models.firstWhere((m) => m.id == 'codegeex-4');
      expect(codegeex.displayName, equals('CodeGeeX-4'));
      expect(codegeex.supportsTools, isTrue);
    });

    test('setApiKey stores key without throwing', () {
      expect(() => service.setApiKey('test-key-xyz'), returnsNormally);
    });
  });

  group('AIProvider.zhipu', () {
    test('is categorized as a chat provider', () {
      expect(AIProvider.zhipu.isChat, isTrue);
    });

    test('is categorized as an image provider (CogView support)', () {
      expect(AIProvider.zhipu.isImage, isTrue);
    });

    test('is NOT categorized as a video/audio/music provider', () {
      expect(AIProvider.zhipu.isVideo, isFalse);
      expect(AIProvider.zhipu.isAudio, isFalse);
      expect(AIProvider.zhipu.isMusic, isFalse);
    });

    test('requires an API key (not local)', () {
      expect(AIProvider.zhipu.requiresApiKey, isTrue);
      expect(AIProvider.zhipu.isLocal, isFalse);
    });

    test('has a non-trivial brand color', () {
      // Brand color should be a saturated blue-ish tone for Zhipu.
      final c = AIProvider.zhipu.brandColor;
      expect(c, isNot(equals(const Color(0x00000000))));
      expect(c.alpha, equals(255));
    });

    test('has display name "Zhipu AI" and mentions GLM-5.2 in description', () {
      expect(AIProvider.zhipu.displayName, equals('Zhipu AI'));
      expect(AIProvider.zhipu.description, contains('GLM-5.2'));
    });
  });
}
