import 'package:equatable/equatable.dart';

import '../../../core/constants/ai_providers.dart';

enum ApiKeyStatus { initial, loading, ready, saving, testing, error }

class ApiKeyState extends Equatable {
  const ApiKeyState({
    this.status = ApiKeyStatus.initial,
    this.configured = const {},
    this.error,
  });

  const ApiKeyState.initial() : this();

  final ApiKeyStatus status;
  final Map<AIProvider, bool> configured;
  final String? error;

  ApiKeyState copyWith({
    ApiKeyStatus? status,
    Map<AIProvider, bool>? configured,
    String? error,
  }) {
    return ApiKeyState(
      status: status ?? this.status,
      configured: configured ?? this.configured,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, configured, error];
}
