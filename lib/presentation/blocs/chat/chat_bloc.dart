// Chat Bloc - handles message sending, streaming, multi-model switching
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/message_entity.dart';
import '../../../domain/entities/model_config_entity.dart';
import '../../../domain/usecases/chat/send_message_usecase.dart';
import '../../../domain/usecases/chat/stream_message_usecase.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({
    required SendMessageUseCase sendMessageUseCase,
    required StreamMessageUseCase streamMessageUseCase,
  })  : _sendMessageUseCase = sendMessageUseCase,
        _streamMessageUseCase = streamMessageUseCase,
        super(const ChatState.initial()) {
    on<UserMessageSent>(_onUserMessageSent);
    on<StreamingCancelled>(_onStreamingCancelled);
    on<MessagesCleared>(_onMessagesCleared);
    on<ModelChanged>(_onModelChanged);
    on<SystemPromptChanged>(_onSystemPromptChanged);
    on<MessageDeleted>(_onMessageDeleted);
    on<MessageEdited>(_onMessageEdited);
    on<MessageRegenerated>(_onMessageRegenerated);
    on<MultiModelCompare>(_onMultiModelCompare);
  }

  final SendMessageUseCase _sendMessageUseCase;
  final StreamMessageUseCase _streamMessageUseCase;
  final _uuid = const Uuid();

  StreamSubscription<dynamic>? _streamSubscription;
  bool _isCancelled = false;

  Future<void> _onUserMessageSent(
    UserMessageSent event,
    Emitter<ChatState> emit,
  ) async {
    final userMessage = MessageEntity(
      id: _uuid.v4(),
      role: MessageRole.user,
      content: event.content,
      createdAt: DateTime.now(),
      attachments: event.attachments,
      status: MessageStatus.complete,
    );

    final messages = [...state.messages, userMessage];
    emit(
      state.copyWith(
        messages: messages,
        status: ChatStatus.sending,
        error: null,
      ),
    );

    final config = event.config ?? state.activeModel;
    final systemPrompt = event.systemPrompt ?? state.systemPrompt;

    if (config.supportsStreaming) {
      await _streamResponse(messages, config, systemPrompt, emit);
    } else {
      await _nonStreamingResponse(messages, config, systemPrompt, emit);
    }
  }

  Future<void> _streamResponse(
    List<MessageEntity> messages,
    ModelConfigEntity config,
    String? systemPrompt,
    Emitter<ChatState> emit,
  ) async {
    _isCancelled = false;
    final assistantId = _uuid.v4();

    emit(state.copyWith(status: ChatStatus.streaming));

    // Cancel any previously-active stream before starting a new one, so a
    // rapid second message doesn't leak the first subscription.
    await _streamSubscription?.cancel();
    _streamSubscription = _streamMessageUseCase(
      messages: messages,
      config: config,
      systemPrompt: systemPrompt,
      conversationId: state.conversationId,
    ).listen(
      (result) {
        if (_isCancelled) return;
        result.fold(
          (failure) => add(StreamingCancelled(failure)),
          (message) {
            if (message.status == MessageStatus.complete) {
              // Final message — replace the streaming sentinel (same id)
              // instead of appending, so the assistant turn isn't duplicated.
              final updatedMessages = List<MessageEntity>.from(state.messages);
              final idx =
                  updatedMessages.indexWhere((m) => m.id == assistantId);
              if (idx >= 0) {
                updatedMessages[idx] = message;
              } else {
                updatedMessages.add(message);
              }
              emit(
                state.copyWith(
                  messages: updatedMessages,
                  status: ChatStatus.ready,
                ),
              );
            } else {
              // Streaming chunk — upsert the in-progress assistant message.
              final streamingMessage = message.copyWith(
                id: assistantId,
                status: MessageStatus.streaming,
              );
              final hasStreamingMessage =
                  state.messages.any((m) => m.id == assistantId);
              final updatedMessages = List<MessageEntity>.from(state.messages);
              if (hasStreamingMessage) {
                final idx =
                    updatedMessages.indexWhere((m) => m.id == assistantId);
                updatedMessages[idx] = streamingMessage;
              } else {
                updatedMessages.add(streamingMessage);
              }
              emit(state.copyWith(messages: updatedMessages));
            }
          },
        );
      },
      onDone: () {
        if (!_isCancelled && state.status == ChatStatus.streaming) {
          emit(state.copyWith(status: ChatStatus.ready));
        }
      },
      onError: (e) {
        emit(
          state.copyWith(
            status: ChatStatus.error,
            error: e.toString(),
          ),
        );
      },
    );

    await _streamSubscription?.asFuture<void>();
  }

  Future<void> _nonStreamingResponse(
    List<MessageEntity> messages,
    ModelConfigEntity config,
    String? systemPrompt,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(status: ChatStatus.sending));

    final result = await _sendMessageUseCase(
      messages: messages,
      config: config,
      systemPrompt: systemPrompt,
      conversationId: state.conversationId,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ChatStatus.error,
          error: failure.userMessage,
        ),
      ),
      (message) {
        final updatedMessages = [...state.messages, message];
        emit(
          state.copyWith(
            messages: updatedMessages,
            status: ChatStatus.ready,
          ),
        );
      },
    );
  }

  void _onStreamingCancelled(
    StreamingCancelled event,
    Emitter<ChatState> emit,
  ) {
    _isCancelled = true;
    _streamSubscription?.cancel();
    _streamSubscription = null;
    emit(
      state.copyWith(
        status: ChatStatus.ready,
        error: event.failure?.userMessage,
      ),
    );
  }

  void _onMessagesCleared(MessagesCleared event, Emitter<ChatState> emit) {
    emit(
      const ChatState.initial().copyWith(
        activeModel: state.activeModel,
        systemPrompt: state.systemPrompt,
      ),
    );
  }

  void _onModelChanged(ModelChanged event, Emitter<ChatState> emit) {
    emit(state.copyWith(activeModel: event.config));
  }

  void _onSystemPromptChanged(
    SystemPromptChanged event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(systemPrompt: event.prompt));
  }

  void _onMessageDeleted(MessageDeleted event, Emitter<ChatState> emit) {
    final updated =
        state.messages.where((m) => m.id != event.messageId).toList();
    emit(state.copyWith(messages: updated));
  }

  void _onMessageEdited(MessageEdited event, Emitter<ChatState> emit) {
    final updated = state.messages.map((m) {
      if (m.id == event.messageId) {
        return m.copyWith(content: event.newContent);
      }
      return m;
    }).toList();
    emit(state.copyWith(messages: updated));
  }

  Future<void> _onMessageRegenerated(
    MessageRegenerated event,
    Emitter<ChatState> emit,
  ) async {
    final idx = state.messages.indexWhere((m) => m.id == event.messageId);
    if (idx == -1) return;
    final target = state.messages[idx];
    if (target.role != MessageRole.assistant) return;

    // Remove the target message and re-trigger generation
    final messagesBefore = state.messages.sublist(0, idx);
    emit(state.copyWith(messages: messagesBefore, status: ChatStatus.sending));

    if (target.modelConfig?.supportsStreaming == true) {
      await _streamResponse(
        messagesBefore,
        target.modelConfig!,
        state.systemPrompt,
        emit,
      );
    } else if (target.modelConfig != null) {
      await _nonStreamingResponse(
        messagesBefore,
        target.modelConfig!,
        state.systemPrompt,
        emit,
      );
    }
  }

  Future<void> _onMultiModelCompare(
    MultiModelCompare event,
    Emitter<ChatState> emit,
  ) async {
    final userMessage = MessageEntity(
      id: _uuid.v4(),
      role: MessageRole.user,
      content: event.content,
      createdAt: DateTime.now(),
      status: MessageStatus.complete,
    );
    final messages = [...state.messages, userMessage];
    emit(
      state.copyWith(
        messages: messages,
        status: ChatStatus.comparing,
      ),
    );

    // Send in parallel to each configured model
    final futures = event.configs.map((config) {
      return _sendMessageUseCase(
        messages: messages,
        config: config,
        systemPrompt: state.systemPrompt,
      ).then((result) => MapEntry(config, result));
    });

    final results = await Future.wait(futures);
    final responses = <MessageEntity>[];
    for (final entry in results) {
      entry.value.fold(
        (failure) => responses.add(
          MessageEntity(
            id: _uuid.v4(),
            role: MessageRole.assistant,
            content: 'Error: ${failure.userMessage}',
            createdAt: DateTime.now(),
            modelConfig: entry.key,
            status: MessageStatus.error,
            error: failure.userMessage,
          ),
        ),
        (message) => responses.add(message),
      );
    }

    final updated = [...state.messages, ...responses];
    emit(state.copyWith(messages: updated, status: ChatStatus.ready));
  }

  @override
  Future<void> close() {
    _streamSubscription?.cancel();
    return super.close();
  }
}
