// Alibaba Qwen Chat Service
import 'ai_chat_service.dart';
import 'openai_compatible_service.dart';

class QwenService extends OpenAICompatibleService implements AIChatService {
  QwenService()
      : super(
          providerId: 'qwen',
          defaultBaseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
          envBaseUrlKey: 'QWEN_BASE_URL',
          staticModels: const [
            ModelInfo(
              id: 'qwen-max',
              displayName: 'Qwen Max',
              provider: 'qwen',
              contextWindow: 32768,
              supportsTools: true,
              costPer1kInput: 0.0024,
              costPer1kOutput: 0.0096,
              maxOutputTokens: 8192,
            ),
            ModelInfo(
              id: 'qwen-plus',
              displayName: 'Qwen Plus',
              provider: 'qwen',
              contextWindow: 131072,
              supportsTools: true,
              costPer1kInput: 0.0004,
              costPer1kOutput: 0.0012,
              maxOutputTokens: 8192,
            ),
            ModelInfo(
              id: 'qwen-turbo',
              displayName: 'Qwen Turbo',
              provider: 'qwen',
              contextWindow: 1000000,
              supportsTools: true,
              costPer1kInput: 0.00005,
              costPer1kOutput: 0.0002,
              maxOutputTokens: 8192,
            ),
            ModelInfo(
              id: 'qwen2.5-72b-instruct',
              displayName: 'Qwen 2.5 72B',
              provider: 'qwen',
              contextWindow: 131072,
              supportsTools: true,
              costPer1kInput: 0.0004,
              costPer1kOutput: 0.0012,
              maxOutputTokens: 8192,
            ),
            ModelInfo(
              id: 'qwen2.5-coder-32b-instruct',
              displayName: 'Qwen 2.5 Coder 32B',
              provider: 'qwen',
              contextWindow: 131072,
              supportsTools: true,
              costPer1kInput: 0.0004,
              costPer1kOutput: 0.0012,
              maxOutputTokens: 8192,
            ),
            ModelInfo(
              id: 'qwen-vl-max',
              displayName: 'Qwen VL Max',
              provider: 'qwen',
              contextWindow: 32768,
              supportsVision: true,
              costPer1kInput: 0.0028,
              costPer1kOutput: 0.0096,
              maxOutputTokens: 2048,
            ),
          ],
        );
}
