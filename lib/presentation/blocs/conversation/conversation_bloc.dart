// Conversation Bloc
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/conversation/create_conversation_usecase.dart';
import '../../../domain/usecases/conversation/get_conversations_usecase.dart';
import '../../../domain/usecases/conversation/delete_conversation_usecase.dart';
import 'conversation_event.dart';
import 'conversation_state.dart';

class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  ConversationBloc({
    required CreateConversationUseCase createConversationUseCase,
    required GetConversationsUseCase getConversationsUseCase,
    required DeleteConversationUseCase deleteConversationUseCase,
  })  : _createUseCase = createConversationUseCase,
        _getUseCase = getConversationsUseCase,
        _deleteUseCase = deleteConversationUseCase,
        super(const ConversationState.initial()) {
    on<LoadConversations>(_onLoad);
    on<CreateConversation>(_onCreate);
    on<DeleteConversation>(_onDelete);
    on<SelectConversation>(_onSelect);
    on<SearchConversations>(_onSearch);
  }

  final CreateConversationUseCase _createUseCase;
  final GetConversationsUseCase _getUseCase;
  final DeleteConversationUseCase _deleteUseCase;

  Future<void> _onLoad(
    LoadConversations event,
    Emitter<ConversationState> emit,
  ) async {
    emit(state.copyWith(status: ConversationStatus.loading));
    final result = await _getUseCase(
      folderId: event.folderId,
      includeArchived: event.includeArchived,
    );
    result.fold(
      (f) => emit(
        state.copyWith(
          status: ConversationStatus.error,
          error: f.userMessage,
        ),
      ),
      (conversations) => emit(
        state.copyWith(
          status: ConversationStatus.ready,
          conversations: conversations,
        ),
      ),
    );
  }

  Future<void> _onCreate(
    CreateConversation event,
    Emitter<ConversationState> emit,
  ) async {
    final result = await _createUseCase(
      title: event.title,
      systemPrompt: event.systemPrompt,
      folderId: event.folderId,
    );
    result.fold(
      (f) => emit(
        state.copyWith(
          status: ConversationStatus.error,
          error: f.userMessage,
        ),
      ),
      (conversation) {
        final updated = [conversation, ...state.conversations];
        emit(
          state.copyWith(
            status: ConversationStatus.ready,
            conversations: updated,
            selectedId: conversation.id,
          ),
        );
      },
    );
  }

  Future<void> _onDelete(
    DeleteConversation event,
    Emitter<ConversationState> emit,
  ) async {
    final result = await _deleteUseCase(event.id);
    result.fold(
      (f) => emit(
        state.copyWith(
          status: ConversationStatus.error,
          error: f.userMessage,
        ),
      ),
      (_) {
        final updated =
            state.conversations.where((c) => c.id != event.id).toList();
        emit(
          state.copyWith(
            conversations: updated,
            selectedId: state.selectedId == event.id ? null : state.selectedId,
          ),
        );
      },
    );
  }

  void _onSelect(
    SelectConversation event,
    Emitter<ConversationState> emit,
  ) {
    emit(state.copyWith(selectedId: event.id));
  }

  Future<void> _onSearch(
    SearchConversations event,
    Emitter<ConversationState> emit,
  ) async {
    emit(state.copyWith(status: ConversationStatus.loading));
    final result = await _getUseCase();
    result.fold(
      (f) => emit(
        state.copyWith(
          status: ConversationStatus.error,
          error: f.userMessage,
        ),
      ),
      (all) {
        final q = event.query.toLowerCase();
        final filtered = all
            .where(
              (c) =>
                  c.title.toLowerCase().contains(q) ||
                  c.messages.any((m) => m.content.toLowerCase().contains(q)),
            )
            .toList();
        emit(
          state.copyWith(
            status: ConversationStatus.ready,
            conversations: filtered,
          ),
        );
      },
    );
  }
}
