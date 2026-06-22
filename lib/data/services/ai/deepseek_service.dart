// DeepSeek Chat Service
import 'ai_chat_service.dart';
import 'openai_compatible_service.dart';

class DeepSeekService extends OpenAICompatibleService implements AIChatService {
  DeepSeekService()
      : super(
          providerId: 'deepseek',
          defaultBaseUrl: 'https://api.deepseek.com/v1',
          envBaseUrlKey: 'DEEPSEEK_BASE_URL',
          staticModels: const [
            ModelInfo(
              id: 'deepseek-chat',
              displayName: 'DeepSeek-V3',
              provider: 'deepseek',
              contextWindow: 64000,
              supportsTools: true,
              costPer1kInput: 0.00014,
              costPer1kOutput: 0.00028,
              maxOutputTokens: 8192,
            ),
            ModelInfo(
              id: 'deepseek-reasoner',
              displayName: 'DeepSeek-R1',
              provider: 'deepseek',
              contextWindow: 64000,
              supportsTools: false,
              supportsStreaming: false,
              costPer1kInput: 0.00055,
              costPer1kOutput: 0.00219,
              maxOutputTokens: 8192,
            ),
          ],
        );
}
