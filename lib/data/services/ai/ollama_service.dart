// Ollama local model service - runs models on device
import 'ai_chat_service.dart';
import 'openai_compatible_service.dart';

class OllamaService extends OpenAICompatibleService implements AIChatService {
  OllamaService()
      : super(
          providerId: 'ollama',
          defaultBaseUrl: 'http://localhost:11434/v1',
          envBaseUrlKey: 'OLLAMA_BASE_URL',
          staticModels: const [
            ModelInfo(
              id: 'llama3.1:8b',
              displayName: 'Llama 3.1 8B (Local)',
              provider: 'ollama',
              contextWindow: 128000,
              costPer1kInput: 0.0,
              costPer1kOutput: 0.0,
              maxOutputTokens: 4096,
            ),
            ModelInfo(
              id: 'llama3.1:70b',
              displayName: 'Llama 3.1 70B (Local)',
              provider: 'ollama',
              contextWindow: 128000,
              costPer1kInput: 0.0,
              costPer1kOutput: 0.0,
              maxOutputTokens: 4096,
            ),
            ModelInfo(
              id: 'mistral:7b',
              displayName: 'Mistral 7B (Local)',
              provider: 'ollama',
              contextWindow: 32768,
              costPer1kInput: 0.0,
              costPer1kOutput: 0.0,
              maxOutputTokens: 4096,
            ),
            ModelInfo(
              id: 'phi3:14b',
              displayName: 'Phi-3 14B (Local)',
              provider: 'ollama',
              contextWindow: 128000,
              costPer1kInput: 0.0,
              costPer1kOutput: 0.0,
              maxOutputTokens: 4096,
            ),
            ModelInfo(
              id: 'qwen2.5:7b',
              displayName: 'Qwen 2.5 7B (Local)',
              provider: 'ollama',
              contextWindow: 32768,
              costPer1kInput: 0.0,
              costPer1kOutput: 0.0,
              maxOutputTokens: 4096,
            ),
          ],
        );
}
