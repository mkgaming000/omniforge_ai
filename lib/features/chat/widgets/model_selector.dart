// Model Selector - bottom sheet for picking AI provider/model
import 'package:flutter/material.dart';

import '../../../core/constants/ai_providers.dart';
import '../../../domain/entities/model_config_entity.dart';

class ModelSelector extends StatelessWidget {
  const ModelSelector({
    super.key,
    required this.activeModel,
    required this.onModelSelected,
  });

  final ModelConfigEntity activeModel;
  final void Function(ModelConfigEntity) onModelSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showSelector(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: activeModel.provider.brandColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.smart_toy, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activeModel.displayName ?? activeModel.modelId,
                    style: Theme.of(context).textTheme.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    activeModel.provider.displayName,
                    style: Theme.of(context).textTheme.labelSmall,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 18),
          ],
        ),
      ),
    );
  }

  void _showSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _ModelSelectorSheet(
          activeModel: activeModel,
          onModelSelected: onModelSelected,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

class _ModelSelectorSheet extends StatelessWidget {
  const _ModelSelectorSheet({
    required this.activeModel,
    required this.onModelSelected,
    required this.scrollController,
  });

  final ModelConfigEntity activeModel;
  final void Function(ModelConfigEntity) onModelSelected;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final chatProviders = AIProvider.values.where((p) => p.isChat).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Select Model',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: chatProviders.length,
            itemBuilder: (context, index) {
              final provider = chatProviders[index];
              return _ProviderSection(
                provider: provider,
                activeModel: activeModel,
                onModelSelected: (config) {
                  onModelSelected(config);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProviderSection extends StatelessWidget {
  const _ProviderSection({
    required this.provider,
    required this.activeModel,
    required this.onModelSelected,
  });

  final AIProvider provider;
  final ModelConfigEntity activeModel;
  final void Function(ModelConfigEntity) onModelSelected;

  @override
  Widget build(BuildContext context) {
    final models = _modelsForProvider(provider);
    final isExpanded = activeModel.provider == provider;

    return ExpansionTile(
      initiallyExpanded: isExpanded,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: provider.brandColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.smart_toy, size: 18, color: Colors.white),
      ),
      title: Text(provider.displayName),
      subtitle: Text(provider.description),
      children: models.map((model) {
        final isActive = activeModel.provider == provider &&
            activeModel.modelId == model.modelId;
        return RadioListTile<String>(
          value: model.modelId,
          groupValue: isActive ? activeModel.modelId : null,
          title: Text(model.displayName ?? model.modelId),
          subtitle: Text(
            '${model.contextWindow ~/ 1000}K ctx • '
            '\$${model.costPer1kInput.toStringAsFixed(4)}/1K in',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          onChanged: (_) => onModelSelected(model),
        );
      }).toList(),
    );
  }

  List<ModelConfigEntity> _modelsForProvider(AIProvider provider) {
    switch (provider) {
      case AIProvider.openai:
        return const [
          ModelConfigEntity(
            provider: AIProvider.openai,
            modelId: 'gpt-4o',
            displayName: 'GPT-4o',
            temperature: 0.7,
            costPer1kInput: 0.0025,
            costPer1kOutput: 0.01,
            contextWindow: 128000,
            supportsVision: true,
            supportsTools: true,
          ),
          ModelConfigEntity(
            provider: AIProvider.openai,
            modelId: 'gpt-4o-mini',
            displayName: 'GPT-4o Mini',
            temperature: 0.7,
            costPer1kInput: 0.00015,
            costPer1kOutput: 0.0006,
            contextWindow: 128000,
            supportsVision: true,
            supportsTools: true,
          ),
          ModelConfigEntity(
            provider: AIProvider.openai,
            modelId: 'o1-preview',
            displayName: 'o1 Preview',
            temperature: 1.0,
            costPer1kInput: 0.015,
            costPer1kOutput: 0.06,
            contextWindow: 200000,
            supportsTools: false,
            supportsStreaming: false,
          ),
        ];
      case AIProvider.anthropic:
        return const [
          ModelConfigEntity(
            provider: AIProvider.anthropic,
            modelId: 'claude-3-5-sonnet-20241022',
            displayName: 'Claude 3.5 Sonnet v2',
            temperature: 0.7,
            costPer1kInput: 0.003,
            costPer1kOutput: 0.015,
            contextWindow: 200000,
            supportsVision: true,
            supportsTools: true,
          ),
          ModelConfigEntity(
            provider: AIProvider.anthropic,
            modelId: 'claude-3-5-haiku-20241022',
            displayName: 'Claude 3.5 Haiku',
            temperature: 0.7,
            costPer1kInput: 0.0008,
            costPer1kOutput: 0.004,
            contextWindow: 200000,
            supportsVision: true,
            supportsTools: true,
          ),
          ModelConfigEntity(
            provider: AIProvider.anthropic,
            modelId: 'claude-3-opus-20240229',
            displayName: 'Claude 3 Opus',
            temperature: 0.7,
            costPer1kInput: 0.015,
            costPer1kOutput: 0.075,
            contextWindow: 200000,
            supportsVision: true,
            supportsTools: true,
          ),
        ];
      case AIProvider.google:
        return const [
          ModelConfigEntity(
            provider: AIProvider.google,
            modelId: 'gemini-2.0-flash',
            displayName: 'Gemini 2.0 Flash',
            temperature: 0.7,
            costPer1kInput: 0.0001,
            costPer1kOutput: 0.0004,
            contextWindow: 1048576,
            supportsVision: true,
            supportsTools: true,
          ),
          ModelConfigEntity(
            provider: AIProvider.google,
            modelId: 'gemini-1.5-pro',
            displayName: 'Gemini 1.5 Pro',
            temperature: 0.7,
            costPer1kInput: 0.00125,
            costPer1kOutput: 0.005,
            contextWindow: 2097152,
            supportsVision: true,
            supportsTools: true,
          ),
        ];
      case AIProvider.deepseek:
        return const [
          ModelConfigEntity(
            provider: AIProvider.deepseek,
            modelId: 'deepseek-chat',
            displayName: 'DeepSeek-V3',
            temperature: 0.7,
            costPer1kInput: 0.00014,
            costPer1kOutput: 0.00028,
            contextWindow: 64000,
            supportsTools: true,
          ),
          ModelConfigEntity(
            provider: AIProvider.deepseek,
            modelId: 'deepseek-reasoner',
            displayName: 'DeepSeek-R1',
            temperature: 0.7,
            costPer1kInput: 0.00055,
            costPer1kOutput: 0.00219,
            contextWindow: 64000,
            supportsStreaming: false,
          ),
        ];
      case AIProvider.mistral:
        return const [
          ModelConfigEntity(
            provider: AIProvider.mistral,
            modelId: 'mistral-large-latest',
            displayName: 'Mistral Large 2',
            temperature: 0.7,
            costPer1kInput: 0.002,
            costPer1kOutput: 0.006,
            contextWindow: 128000,
            supportsTools: true,
            supportsVision: true,
          ),
          ModelConfigEntity(
            provider: AIProvider.mistral,
            modelId: 'codestral-latest',
            displayName: 'Codestral',
            temperature: 0.7,
            costPer1kInput: 0.0003,
            costPer1kOutput: 0.0009,
            contextWindow: 256000,
          ),
        ];
      case AIProvider.xai:
        return const [
          ModelConfigEntity(
            provider: AIProvider.xai,
            modelId: 'grok-2-latest',
            displayName: 'Grok 2',
            temperature: 0.7,
            costPer1kInput: 0.002,
            costPer1kOutput: 0.01,
            contextWindow: 131072,
            supportsTools: true,
            supportsVision: true,
          ),
        ];
      case AIProvider.alibaba:
        return const [
          ModelConfigEntity(
            provider: AIProvider.alibaba,
            modelId: 'qwen-max',
            displayName: 'Qwen Max',
            temperature: 0.7,
            costPer1kInput: 0.0024,
            costPer1kOutput: 0.0096,
            contextWindow: 32768,
            supportsTools: true,
          ),
        ];
      case AIProvider.zhipu:
        return const [
          ModelConfigEntity(
            provider: AIProvider.zhipu,
            modelId: 'glm-5.2',
            displayName: 'GLM-5.2',
            temperature: 0.7,
            costPer1kInput: 0.005,
            costPer1kOutput: 0.02,
            contextWindow: 256000,
            supportsVision: true,
            supportsTools: true,
          ),
          ModelConfigEntity(
            provider: AIProvider.zhipu,
            modelId: 'glm-5.2-flash',
            displayName: 'GLM-5.2 Flash',
            temperature: 0.7,
            costPer1kInput: 0.0005,
            costPer1kOutput: 0.002,
            contextWindow: 256000,
            supportsVision: true,
            supportsTools: true,
          ),
          ModelConfigEntity(
            provider: AIProvider.zhipu,
            modelId: 'glm-5',
            displayName: 'GLM-5',
            temperature: 0.7,
            costPer1kInput: 0.003,
            costPer1kOutput: 0.012,
            contextWindow: 200000,
            supportsVision: true,
            supportsTools: true,
          ),
          ModelConfigEntity(
            provider: AIProvider.zhipu,
            modelId: 'glm-4-plus',
            displayName: 'GLM-4-Plus',
            temperature: 0.7,
            costPer1kInput: 0.0035,
            costPer1kOutput: 0.014,
            contextWindow: 128000,
            supportsVision: true,
            supportsTools: true,
          ),
          ModelConfigEntity(
            provider: AIProvider.zhipu,
            modelId: 'glm-4-air',
            displayName: 'GLM-4-Air',
            temperature: 0.7,
            costPer1kInput: 0.0005,
            costPer1kOutput: 0.001,
            contextWindow: 128000,
            supportsTools: true,
          ),
          ModelConfigEntity(
            provider: AIProvider.zhipu,
            modelId: 'glm-4-long',
            displayName: 'GLM-4-Long (1M ctx)',
            temperature: 0.7,
            costPer1kInput: 0.001,
            costPer1kOutput: 0.001,
            contextWindow: 1000000,
            supportsTools: true,
          ),
          ModelConfigEntity(
            provider: AIProvider.zhipu,
            modelId: 'glm-4-flash',
            displayName: 'GLM-4-Flash (Free)',
            temperature: 0.7,
            costPer1kInput: 0.0,
            costPer1kOutput: 0.0,
            contextWindow: 128000,
            supportsTools: true,
          ),
          ModelConfigEntity(
            provider: AIProvider.zhipu,
            modelId: 'glm-4v-plus',
            displayName: 'GLM-4V Plus (Vision)',
            temperature: 0.7,
            costPer1kInput: 0.005,
            costPer1kOutput: 0.01,
            contextWindow: 8000,
            supportsVision: true,
          ),
          ModelConfigEntity(
            provider: AIProvider.zhipu,
            modelId: 'codegeex-4',
            displayName: 'CodeGeeX-4',
            temperature: 0.2,
            costPer1kInput: 0.0005,
            costPer1kOutput: 0.001,
            contextWindow: 128000,
            supportsTools: true,
          ),
        ];
      case AIProvider.openrouter:
        return const [
          ModelConfigEntity(
            provider: AIProvider.openrouter,
            modelId: 'anthropic/claude-3.5-sonnet',
            displayName: 'Claude 3.5 Sonnet (OpenRouter)',
            temperature: 0.7,
            costPer1kInput: 0.003,
            costPer1kOutput: 0.015,
            contextWindow: 200000,
            supportsVision: true,
            supportsTools: true,
          ),
        ];
      case AIProvider.huggingface:
        return const [
          ModelConfigEntity(
            provider: AIProvider.huggingface,
            modelId: 'meta-llama/Llama-3.3-70B-Instruct',
            displayName: 'Llama 3.3 70B',
            temperature: 0.7,
            costPer1kInput: 0.0008,
            costPer1kOutput: 0.0008,
            contextWindow: 128000,
          ),
        ];
      case AIProvider.ollama:
        return const [
          ModelConfigEntity(
            provider: AIProvider.ollama,
            modelId: 'llama3.1:8b',
            displayName: 'Llama 3.1 8B (Local)',
            temperature: 0.7,
            costPer1kInput: 0.0,
            costPer1kOutput: 0.0,
            contextWindow: 128000,
          ),
        ];
      case AIProvider.lmstudio:
        return const [
          ModelConfigEntity(
            provider: AIProvider.lmstudio,
            modelId: 'local-model',
            displayName: 'Local Model (LM Studio)',
            temperature: 0.7,
            costPer1kInput: 0.0,
            costPer1kOutput: 0.0,
          ),
        ];
      default:
        return [];
    }
  }
}
