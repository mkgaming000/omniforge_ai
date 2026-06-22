// Unit tests for AI Provider enum
import 'package:flutter_test/flutter_test.dart';
import 'package:omniforge_ai/core/constants/ai_providers.dart';

void main() {
  group('AIProvider', () {
    test('all providers have unique display names', () {
      final names = AIProvider.values.map((p) => p.displayName).toList();
      final unique = names.toSet();
      expect(
        names.length,
        equals(unique.length),
        reason: 'Duplicate display names detected',
      );
    });

    test('all providers have brand colors', () {
      for (final p in AIProvider.values) {
        expect(p.brandColor, isNotNull);
      }
    });

    test('all providers have descriptions', () {
      for (final p in AIProvider.values) {
        expect(p.description, isNotEmpty);
      }
    });

    test('local providers do not require API keys', () {
      expect(AIProvider.ollama.requiresApiKey, isFalse);
      expect(AIProvider.lmstudio.requiresApiKey, isFalse);
    });

    test('local providers are flagged as local', () {
      expect(AIProvider.ollama.isLocal, isTrue);
      expect(AIProvider.lmstudio.isLocal, isTrue);
      expect(AIProvider.openai.isLocal, isFalse);
    });

    test('chat providers are correctly categorized', () {
      expect(AIProvider.openai.isChat, isTrue);
      expect(AIProvider.anthropic.isChat, isTrue);
      expect(AIProvider.google.isChat, isTrue);
      expect(AIProvider.zhipu.isChat, isTrue);
      expect(AIProvider.runway.isChat, isFalse);
    });

    test('image providers are correctly categorized', () {
      expect(AIProvider.openai.isImage, isTrue);
      expect(AIProvider.stability.isImage, isTrue);
      expect(AIProvider.flux.isImage, isTrue);
      expect(AIProvider.openai.isImage, isTrue);
      expect(AIProvider.zhipu.isImage, isTrue);
      expect(AIProvider.runway.isImage, isFalse);
    });

    test('video providers are correctly categorized', () {
      expect(AIProvider.runway.isVideo, isTrue);
      expect(AIProvider.pika.isVideo, isTrue);
      expect(AIProvider.luma.isVideo, isTrue);
      expect(AIProvider.kling.isVideo, isTrue);
      expect(AIProvider.openai.isVideo, isFalse);
    });

    test('music providers are correctly categorized', () {
      expect(AIProvider.suno.isMusic, isTrue);
      expect(AIProvider.udio.isMusic, isTrue);
      expect(AIProvider.openai.isMusic, isFalse);
    });

    test('audio providers are correctly categorized', () {
      expect(AIProvider.openai.isAudio, isTrue);
      expect(AIProvider.elevenlabs.isAudio, isTrue);
      expect(AIProvider.assemblyai.isAudio, isTrue);
      expect(AIProvider.openai.isMusic, isFalse);
    });
  });
}
