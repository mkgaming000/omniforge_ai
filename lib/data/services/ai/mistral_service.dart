// Mistral AI Chat Service
import 'ai_chat_service.dart';
import 'openai_compatible_service.dart';

class MistralService extends OpenAICompatibleService implements AIChatService {
  MistralService()
      : super(
          providerId: 'mistral',
          defaultBaseUrl: 'https://api.mistral.ai/v1',
          envBaseUrlKey: 'MISTRAL_BASE_URL',
          staticModels: const [
            ModelInfo(
              id: 'mistral-large-latest',
              displayName: 'Mistral Large 2',
              provider: 'mistral',
              contextWindow: 128000,
              supportsTools: true,
              supportsVision: true,
              costPer1kInput: 0.002,
              costPer1kOutput: 0.006,
              maxOutputTokens: 8192,
            ),
            ModelInfo(
              id: 'codestral-latest',
              displayName: 'Codestral',
              provider: 'mistral',
              contextWindow: 256000,
              supportsTools: true,
              costPer1kInput: 0.0003,
              costPer1kOutput: 0.0009,
              maxOutputTokens: 8192,
            ),
            ModelInfo(
              id: 'mistral-small-latest',
              displayName: 'Mistral Small',
              provider: 'mistral',
              contextWindow: 32000,
              supportsTools: true,
              costPer1kInput: 0.0002,
              costPer1kOutput: 0.0006,
              maxOutputTokens: 8192,
            ),
            ModelInfo(
              id: 'open-mixtral-8x7b',
              displayName: 'Mixtral 8x7B',
              provider: 'mistral',
              contextWindow: 32000,
              costPer1kInput: 0.00024,
              costPer1kOutput: 0.00024,
              maxOutputTokens: 8192,
            ),
            ModelInfo(
              id: 'open-mistral-7b',
              displayName: 'Mistral 7B',
              provider: 'mistral',
              contextWindow: 32000,
              costPer1kInput: 0.0001,
              costPer1kOutput: 0.0001,
              maxOutputTokens: 8192,
            ),
          ],
        );
}
