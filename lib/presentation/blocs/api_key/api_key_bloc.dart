// API Key Bloc
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/ai_providers.dart';
import '../../../core/utils/logger.dart';
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
  })  : _saveUseCase = saveApiKeyUseCase,
        _getUseCase = getApiKeyUseCase,
        _deleteUseCase = deleteApiKeyUseCase,
        super(const ApiKeyState.initial()) {
    on<LoadApiKeys>(_onLoad);
    on<SaveApiKey>(_onSave);
    on<DeleteApiKey>(_onDelete);
    on<TestApiKey>(_onTest);
  }

  final SaveApiKeyUseCase _saveUseCase;
  final GetApiKeyUseCase _getUseCase;
  final DeleteApiKeyUseCase _deleteUseCase;

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
    // Health check requires the provider factory, which is not injected here.
    AppLogger.d('API key test not available without provider factory');
    emit(state.copyWith(status: ApiKeyStatus.ready));
  }
}
