// API Key Bloc
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/ai_providers.dart';
import '../../../core/utils/logger.dart';
import '../../../data/services/ai/ai_provider_factory.dart';
import '../../../domain/usecases/api_key/save_api_key_usecase.dart';
import '../../../domain/usecases/api_key/get_api_key_usecase.dart';
import '../../../domain/usecases/api_key/delete_api_key_usecase.dart';
import 'api_key_event.dart';
import 'api_key_state.dart';

class ApiKeyBloc extends Bloc<ApiKeyEvent, ApiKeyState> {
  ApiKeyBloc({
    required SaveApiKeyUseCase saveApiKeyUseCase,
    required GetApiKeyUseCase getApiKeyUseCase,
    required DeleteApiKeyUseCase deleteApiKeyUseCase,
    required AIProviderFactory providerFactory,
  })  : _saveUseCase = saveApiKeyUseCase,
        _getUseCase = getApiKeyUseCase,
        _deleteUseCase = deleteApiKeyUseCase,
        _providerFactory = providerFactory,
        super(const ApiKeyState.initial()) {
    on<LoadApiKeys>(_onLoad);
    on<SaveApiKey>(_onSave);
    on<DeleteApiKey>(_onDelete);
    on<TestApiKey>(_onTest);
  }

  final SaveApiKeyUseCase _saveUseCase;
  final GetApiKeyUseCase _getUseCase;
  final DeleteApiKeyUseCase _deleteUseCase;
  // Needed to invalidate the provider service cache after a key is saved or
  // deleted — without this the factory keeps returning the old cached service
  // instance that was created with no key, and the user gets
  // "API key not set" errors even after successfully saving a key.
  final AIProviderFactory _providerFactory;

  Future<void> _onLoad(
    LoadApiKeys event,
    Emitter<ApiKeyState> emit,
  ) async {
    emit(state.copyWith(status: ApiKeyStatus.loading));
    final Map<AIProvider, bool> configured = {};
    for (final provider in AIProvider.values) {
      final result = await _getUseCase(provider);
      configured[provider] =
          result.fold((_) => false, (key) => key != null && key.isNotEmpty);
    }
    emit(
      state.copyWith(
        status: ApiKeyStatus.ready,
        configured: configured,
      ),
    );
  }

  Future<void> _onSave(
    SaveApiKey event,
    Emitter<ApiKeyState> emit,
  ) async {
    emit(state.copyWith(status: ApiKeyStatus.saving));
    final result = await _saveUseCase(event.provider, event.apiKey);
    result.fold(
      (f) => emit(
        state.copyWith(
          status: ApiKeyStatus.error,
          error: f.userMessage,
        ),
      ),
      (_) {
        // Invalidate the cached service so the factory re-creates it with
        // the newly saved key on the next chat/image/video request.
        _providerFactory.refreshKey(event.provider);

        final updated = Map<AIProvider, bool>.from(state.configured);
        updated[event.provider] = true;
        emit(
          state.copyWith(
            status: ApiKeyStatus.ready,
            configured: updated,
            error: null,
          ),
        );
      },
    );
  }

  Future<void> _onDelete(
    DeleteApiKey event,
    Emitter<ApiKeyState> emit,
  ) async {
    final result = await _deleteUseCase(event.provider);
    result.fold(
      (f) => emit(
        state.copyWith(
          status: ApiKeyStatus.error,
          error: f.userMessage,
        ),
      ),
      (_) {
        // Invalidate cache so the factory won't serve the deleted key.
        _providerFactory.refreshKey(event.provider);

        final updated = Map<AIProvider, bool>.from(state.configured);
        updated[event.provider] = false;
        emit(state.copyWith(configured: updated));
      },
    );
  }

  Future<void> _onTest(
    TestApiKey event,
    Emitter<ApiKeyState> emit,
  ) async {
    emit(state.copyWith(status: ApiKeyStatus.testing));
    AppLogger.d('API key test not available without provider factory');
    emit(state.copyWith(status: ApiKeyStatus.ready));
  }
}
