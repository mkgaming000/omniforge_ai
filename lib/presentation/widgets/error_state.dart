// Error State Widget - displays friendly error messages with retry
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/errors/failures.dart';

class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.failure,
    this.onRetry,
    this.title,
  });

  final Failure failure;
  final VoidCallback? onRetry;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _iconFor(failure),
                size: 40,
                color: Theme.of(context).colorScheme.error,
              ),
            ).animate().fadeIn(duration: 400.ms).scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1, 1),
                ),
            const SizedBox(height: 20),
            Text(
              title ?? _titleFor(failure),
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            Text(
              failure.userMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ).animate().fadeIn(delay: 400.ms),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconFor(Failure failure) {
    if (failure is NetworkFailure) return Icons.wifi_off;
    if (failure is UnauthorizedFailure) return Icons.lock_outline;
    if (failure is RateLimitFailure) return Icons.speed;
    if (failure is TimeoutFailure) return Icons.hourglass_empty;
    if (failure is NotFoundFailure) return Icons.search_off;
    if (failure is ValidationFailure) return Icons.error_outline;
    if (failure is SecurityFailure) return Icons.security;
    if (failure is ProviderFailure) return Icons.cloud_off;
    if (failure is CacheFailure) return Icons.storage;
    return Icons.error_outline;
  }

  String _titleFor(Failure failure) {
    if (failure is NetworkFailure) return 'Connection Error';
    if (failure is UnauthorizedFailure) return 'Authentication Required';
    if (failure is RateLimitFailure) return 'Too Many Requests';
    if (failure is TimeoutFailure) return 'Request Timed Out';
    if (failure is NotFoundFailure) return 'Not Found';
    if (failure is ValidationFailure) return 'Invalid Input';
    if (failure is SecurityFailure) return 'Security Check Failed';
    if (failure is ProviderFailure) return 'Provider Error';
    if (failure is CacheFailure) return 'Storage Error';
    return 'Something Went Wrong';
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 72,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ).animate().fadeIn(delay: 400.ms),
            ],
          ],
        ),
      ),
    );
  }
}
