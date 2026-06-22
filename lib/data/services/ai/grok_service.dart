// xAI Grok Chat Service
import 'ai_chat_service.dart';
import 'openai_compatible_service.dart';

class GrokService extends OpenAICompatibleService implements AIChatService {
  GrokService()
      : super(
          providerId: 'grok',
          defaultBaseUrl: 'https://api.x.ai/v1',
          envBaseUrlKey: 'GROK_BASE_URL',
          staticModels: const [
            ModelInfo(
              id: 'grok-2-latest',
              displayName: 'Grok 2',
              provider: 'grok',
              contextWindow: 131072,
              supportsTools: true,
              supportsVision: true,
              costPer1kInput: 0.002,
              costPer1kOutput: 0.01,
              maxOutputTokens: 4096,
            ),
            ModelInfo(
              id: 'grok-2-vision-latest',
              displayName: 'Grok 2 Vision',
              provider: 'grok',
              contextWindow: 32768,
              supportsVision: true,
              supportsTools: true,
              costPer1kInput: 0.002,
              costPer1kOutput: 0.01,
              maxOutputTokens: 4096,
            ),
            ModelInfo(
              id: 'grok-beta',
              displayName: 'Grok Beta',
              provider: 'grok',
              contextWindow: 131072,
              costPer1kInput: 0.005,
              costPer1kOutput: 0.015,
              maxOutputTokens: 4096,
            ),
          ],
        );
}
