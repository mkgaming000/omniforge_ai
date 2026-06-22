// Domain-agnostic Failure types - inspired by DDD principles
import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  const Failure({
    this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  final String? message;
  final String? code;
  final Object? originalError;
  final StackTrace? stackTrace;

  String get userMessage =>
      message ?? 'An unexpected error occurred. Please try again.';

  @override
  List<Object?> get props => [message, code];
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage =>
      message ?? 'Network error. Check your connection and try again.';
}

class ServerFailure extends Failure {
  const ServerFailure({
    super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage =>
      message ?? 'Server error. The AI service is temporarily unavailable.';
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage =>
      message ??
      'Authentication failed. Please check your API key in Settings.';
}

class RateLimitFailure extends Failure {
  const RateLimitFailure({
    super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage =>
      message ?? 'Rate limit exceeded. Please wait a moment and try again.';
}

class ValidationFailure extends Failure {
  const ValidationFailure({
    super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => message ?? 'Invalid input. Please check your data.';
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage => message ?? 'The requested resource was not found.';
}

class TimeoutFailure extends Failure {
  const TimeoutFailure({
    super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage =>
      message ?? 'Request timed out. The AI is taking longer than expected.';
}

class CacheFailure extends Failure {
  const CacheFailure({
    super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage =>
      message ?? 'Local storage error. Please restart the app.';
}

class SecurityFailure extends Failure {
  const SecurityFailure({
    super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage =>
      message ?? 'Security verification required. Please authenticate.';
}

class ProviderFailure extends Failure {
  const ProviderFailure({
    super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });

  @override
  String get userMessage =>
      message ?? 'The AI provider returned an error. Try another model.';
}

class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}
