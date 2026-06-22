import 'package:equatable/equatable.dart';

import '../../../core/constants/ai_providers.dart';

abstract class ApiKeyEvent extends Equatable {
  const ApiKeyEvent();
}

class LoadApiKeys extends ApiKeyEvent {
  const LoadApiKeys();
  @override
  List<Object?> get props => [];
}

class SaveApiKey extends ApiKeyEvent {
  const SaveApiKey(this.provider, this.apiKey);
  final AIProvider provider;
  final String apiKey;
  @override
  List<Object?> get props => [provider, apiKey];
}

class DeleteApiKey extends ApiKeyEvent {
  const DeleteApiKey(this.provider);
  final AIProvider provider;
  @override
  List<Object?> get props => [provider];
}

class TestApiKey extends ApiKeyEvent {
  const TestApiKey(this.provider);
  final AIProvider provider;
  @override
  List<Object?> get props => [provider];
}
