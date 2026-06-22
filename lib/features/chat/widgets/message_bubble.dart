// Message Bubble - renders a single chat message with markdown support
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';

import '../../../domain/entities/message_entity.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.onRegenerate,
    this.onDelete,
    this.onEdit,
  });

  final MessageEntity message;
  final VoidCallback? onRegenerate;
  final VoidCallback? onDelete;
  final void Function(String newContent)? onEdit;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role.name == 'user';
    final isError = message.status == MessageStatus.error;
    final isStreaming = message.status == MessageStatus.streaming;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  colors: [Color(0xFF6750A4), Color(0xFF7C5CBF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isUser
              ? null
              : (isError
                  ? Theme.of(context).colorScheme.errorContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Model badge
            if (!isUser && message.modelConfig != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: message.modelConfig!.provider.brandColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.smart_toy,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      message.modelConfig!.displayName ??
                          message.modelConfig!.modelId,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isUser
                                ? Colors.white70
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                          ),
                    ),
                    if (isStreaming) ...[
                      const SizedBox(width: 6),
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      ),
                    ],
                  ],
                ),
              ),
            // Message content
            MarkdownBody(
              data: message.content.isEmpty && isStreaming
                  ? '_Generating..._'
                  : message.content,
              styleSheet:
                  MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isUser
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                code: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 13,
                      backgroundColor: isUser
                          ? Colors.white.withOpacity(0.15)
                          : Colors.black.withOpacity(0.05),
                      color: isUser
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                codeblockDecoration: BoxDecoration(
                  color: isUser
                      ? Colors.white.withOpacity(0.1)
                      : const Color(0xFF1E1E2E),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            // Attachments
            if (message.attachments.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: message.attachments.map((a) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      a.thumbnailUrl ?? a.url,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  );
                }).toList(),
              ),
            ],
            // Token info + actions
            if (!isUser && !isStreaming) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.tokensIn > 0 || message.tokensOut > 0)
                    Text(
                      '${message.tokensIn + message.tokensOut} tokens',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  if (message.costUsd > 0) ...[
                    const SizedBox(width: 8),
                    Text(
                      '\$${message.costUsd.toStringAsFixed(4)}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                  const Spacer(),
                  _ActionButton(
                    icon: Icons.content_copy,
                    onTap: () => _copy(context, message.content),
                  ),
                  _ActionButton(
                    icon: Icons.share,
                    onTap: () => Share.share(message.content),
                  ),
                  if (onRegenerate != null)
                    _ActionButton(
                      icon: Icons.refresh,
                      onTap: onRegenerate,
                    ),
                  if (onEdit != null)
                    _ActionButton(
                      icon: Icons.edit_outlined,
                      onTap: () => _showEditDialog(context),
                    ),
                  if (onDelete != null)
                    _ActionButton(
                      icon: Icons.delete_outline,
                      onTap: onDelete,
                    ),
                ],
              ),
            ],
            if (isError && message.error != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      message.error!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _copy(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: message.content);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit message'),
        content: TextField(
          controller: controller,
          maxLines: 8,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              onEdit?.call(controller.text);
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 14),
      ),
    );
  }
}
