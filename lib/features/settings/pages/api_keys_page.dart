// API Keys Page - manage encrypted credentials for all providers
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/ai_providers.dart';
import '../../../injection/injection.dart';
import '../../../presentation/blocs/api_key/api_key_bloc.dart';
import '../../../presentation/blocs/api_key/api_key_event.dart';
import '../../../presentation/blocs/api_key/api_key_state.dart';

class ApiKeysPage extends StatelessWidget {
  const ApiKeysPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ApiKeyBloc>()..add(const LoadApiKeys()),
      child: BlocBuilder<ApiKeyBloc, ApiKeyState>(
        builder: (context, state) {
          if (state.status == ApiKeyStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              ...AIProvider.values.map(
                (provider) => _ProviderKeyCard(
                  provider: provider,
                  configured: state.configured[provider] ?? false,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Secure Storage',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'All API keys are encrypted with AES-256-GCM and stored in the Android Keystore. '
              'Keys never leave your device unencrypted.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderKeyCard extends StatelessWidget {
  const _ProviderKeyCard({
    required this.provider,
    required this.configured,
  });

  final AIProvider provider;
  final bool configured;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: provider.brandColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.key, color: Colors.white, size: 18),
        ),
        title: Text(provider.displayName),
        subtitle: Text(provider.description),
        trailing: configured
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.add_circle_outline, color: Colors.grey),
        onTap: () => _showKeyDialog(context),
      ),
    );
  }

  void _showKeyDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${provider.displayName} API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              provider.requiresApiKey
                  ? 'Enter your ${provider.displayName} API key.'
                  : 'Local provider. Enter base URL to connect.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'sk-...',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            if (provider.requiresApiKey)
              Text(
                'Get your key at ${_signupUrl(provider)}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          if (configured)
            TextButton(
              onPressed: () {
                context.read<ApiKeyBloc>().add(DeleteApiKey(provider));
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Remove'),
            ),
          FilledButton(
            onPressed: () {
              if (controller.text.isEmpty) return;
              context
                  .read<ApiKeyBloc>()
                  .add(SaveApiKey(provider, controller.text));
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _signupUrl(AIProvider provider) {
    switch (provider) {
      case AIProvider.openai:
        return 'platform.openai.com/api-keys';
      case AIProvider.anthropic:
        return 'console.anthropic.com';
      case AIProvider.google:
        return 'aistudio.google.com';
      case AIProvider.xai:
        return 'console.x.ai';
      case AIProvider.deepseek:
        return 'platform.deepseek.com';
      case AIProvider.mistral:
        return 'console.mistral.ai';
      case AIProvider.alibaba:
        return 'dashscope.console.aliyun.com';
      case AIProvider.zhipu:
        return 'open.bigmodel.cn/usercenter/apikeys';
      case AIProvider.openrouter:
        return 'openrouter.ai/keys';
      case AIProvider.huggingface:
        return 'huggingface.co/settings/tokens';
      case AIProvider.stability:
        return 'platform.stability.ai';
      case AIProvider.flux:
        return 'bfl.ai';
      case AIProvider.ideogram:
        return 'ideogram.ai/api';
      case AIProvider.recraft:
        return 'recraft.ai/api';
      case AIProvider.leonardo:
        return 'app.leonardo.ai/api';
      case AIProvider.runway:
        return 'runwayml.com/api';
      case AIProvider.pika:
        return 'pika.art/api';
      case AIProvider.luma:
        return 'lumalabs.ai/api';
      case AIProvider.kling:
        return 'klingai.com/api';
      case AIProvider.suno:
        return 'suno.com/api';
      case AIProvider.udio:
        return 'udio.com/api';
      case AIProvider.elevenlabs:
        return 'elevenlabs.io/api';
      case AIProvider.assemblyai:
        return 'assemblyai.com/app/account';
      default:
        return 'docs.example.com';
    }
  }
}
