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
    // IMPORTANT: capture the bloc reference here, BEFORE showDialog creates a
    // new Navigator route with a new BuildContext. Inside the dialog's builder,
    // `context` refers to the dialog's own context — a child of the Navigator,
    // not of the BlocProvider — so context.read<ApiKeyBloc>() would throw a
    // ProviderNotFoundException and the Save/Delete buttons would silently do
    // nothing. Capturing it here (while we're still inside the BlocProvider
    // subtree) is the correct Flutter pattern for using blocs in dialogs.
    final bloc = context.read<ApiKeyBloc>();
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
                style: Theme.of(dialogContext).textTheme.labelSmall,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          if (configured)
            TextButton(
              onPressed: () {
                // Use the captured `bloc`, not context.read() — see note above.
                bloc.add(DeleteApiKey(provider));
                Navigator.of(dialogContext).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              child: const Text('Remove'),
            ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              // Use the captured `bloc`, not context.read() — see note above.
              bloc.add(SaveApiKey(provider, controller.text.trim()));
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((_) => controller.dispose()); // dispose controller when dialog closes
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
