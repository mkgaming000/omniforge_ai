// OpenRouter Chat Service - aggregator of 300+ models
import 'ai_chat_service.dart';
import 'openai_compatible_service.dart';

class OpenRouterService extends OpenAICompatibleService
    implements AIChatService {
  OpenRouterService()
      : super(
          providerId: 'openrouter',
          defaultBaseUrl: 'https://openrouter.ai/api/v1',
          envBaseUrlKey: 'OPENROUTER_BASE_URL',
          staticModels: const [
            ModelInfo(
              id: 'anthropic/claude-3.5-sonnet',
              displayName: 'Claude 3.5 Sonnet (via OpenRouter)',
              provider: 'openrouter',
              contextWindow: 200000,
              supportsVision: true,
              supportsTools: true,
              costPer1kInput: 0.003,
              costPer1kOutput: 0.015,
              maxOutputTokens: 8192,
            ),
            ModelInfo(
              id: 'openai/gpt-4o',
              displayName: 'GPT-4o (via OpenRouter)',
              provider: 'openrouter',
              contextWindow: 128000,
              supportsVision: true,
              supportsTools: true,
              costPer1kInput: 0.0025,
              costPer1kOutput: 0.01,
              maxOutputTokens: 16384,
            ),
            ModelInfo(
              id: 'google/gemini-pro-1.5',
              displayName: 'Gemini 1.5 Pro (via OpenRouter)',
              provider: 'openrouter',
              contextWindow: 2097152,
              supportsVision: true,
              costPer1kInput: 0.00125,
              costPer1kOutput: 0.005,
              maxOutputTokens: 8192,
            ),
            ModelInfo(
              id: 'meta-llama/llama-3.1-405b-instruct',
              displayName: 'Llama 3.1 405B Instruct',
              provider: 'openrouter',
              contextWindow: 131072,
              supportsTools: true,
              costPer1kInput: 0.008,
              costPer1kOutput: 0.024,
              maxOutputTokens: 4096,
            ),
            ModelInfo(
              id: 'qwen/qwen-2.5-72b-instruct',
              displayName: 'Qwen 2.5 72B',
              provider: 'openrouter',
              contextWindow: 32768,
              costPer1kInput: 0.0004,
              costPer1kOutput: 0.0004,
              maxOutputTokens: 8192,
            ),
            ModelInfo(
              id: 'mistralai/mistral-large',
              displayName: 'Mistral Large (via OpenRouter)',
              provider: 'openrouter',
              contextWindow: 128000,
              supportsTools: true,
              costPer1kInput: 0.002,
              costPer1kOutput: 0.006,
              maxOutputTokens: 8192,
            ),
            ModelInfo(
              id: 'deepseek/deepseek-chat',
              displayName: 'DeepSeek V3 (via OpenRouter)',
              provider: 'openrouter',
              contextWindow: 64000,
              costPer1kInput: 0.00014,
              costPer1kOutput: 0.00028,
              maxOutputTokens: 8192,
            ),
          ],
        );
}
