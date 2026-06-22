// Unit tests for ChatBloc
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:omniforge_ai/core/errors/failures.dart';
import 'package:omniforge_ai/core/constants/ai_providers.dart';
import 'package:omniforge_ai/domain/entities/message_entity.dart';
import 'package:omniforge_ai/domain/entities/model_config_entity.dart';
import 'package:omniforge_ai/domain/usecases/chat/send_message_usecase.dart';
import 'package:omniforge_ai/domain/usecases/chat/stream_message_usecase.dart';
import 'package:omniforge_ai/presentation/blocs/chat/chat_bloc.dart';
import 'package:omniforge_ai/presentation/blocs/chat/chat_event.dart';
import 'package:omniforge_ai/presentation/blocs/chat/chat_state.dart';

/// Manual mock for [SendMessageUseCase].
///
/// The naive `extends Mock implements SendMessageUseCase {}` pattern does not
/// work with strict-casts + non-nullable named parameters: `anyNamed(...)`
/// returns `Null`, which the analyzer rejects for `required List<MessageEntity>
/// messages` / `required ModelConfigEntity config`, and the Dart VM enforces
/// the same type check at runtime before dispatching to `noSuchMethod`.
///
/// The fix is to override `call` with widened (nullable) parameter types —
/// legal because Dart allows contravariant parameter widening in overrides —
/// and delegate to `super.noSuchMethod` so the standard Mockito `when`/`verify`
/// machinery still works.
class MockSendMessageUseCase extends Mock implements SendMessageUseCase {
  @override
  Future<Either<Failure, MessageEntity>> call({
    required List<MessageEntity>? messages,
    required ModelConfigEntity? config,
    String? systemPrompt,
    String? conversationId,
  }) =>
      super.noSuchMethod(
        Invocation.method(
          #call,
          null,
          <Symbol, Object?>{
            #messages: messages,
            #config: config,
            #systemPrompt: systemPrompt,
            #conversationId: conversationId,
          },
        ),
        returnValue: Future<Either<Failure, MessageEntity>>.value(
          const Left<Failure, MessageEntity>(
            UnknownFailure(message: 'MockSendMessageUseCase: no stub'),
          ),
        ),
      ) as Future<Either<Failure, MessageEntity>>;
}

class MockStreamMessageUseCase extends Mock implements StreamMessageUseCase {
  @override
  Stream<Either<Failure, MessageEntity>> call({
    required List<MessageEntity>? messages,
    required ModelConfigEntity? config,
    String? systemPrompt,
    String? conversationId,
  }) =>
      super.noSuchMethod(
        Invocation.method(
          #call,
          null,
          <Symbol, Object?>{
            #messages: messages,
            #config: config,
            #systemPrompt: systemPrompt,
            #conversationId: conversationId,
          },
        ),
        returnValue: const Stream<Either<Failure, MessageEntity>>.empty(),
      ) as Stream<Either<Failure, MessageEntity>>;
}

void main() {
  late ChatBloc bloc;
  late MockSendMessageUseCase mockSend;
  late MockStreamMessageUseCase mockStream;

  const testConfig = ModelConfigEntity(
    provider: AIProvider.openai,
    modelId: 'gpt-4o',
    supportsStreaming: false,
  );

  setUp(() {
    mockSend = MockSendMessageUseCase();
    mockStream = MockStreamMessageUseCase();
    bloc = ChatBloc(
      sendMessageUseCase: mockSend,
      streamMessageUseCase: mockStream,
    );
  });

  tearDown(() => bloc.close());

  test('initial state is correct', () {
    expect(bloc.state.status, equals(ChatStatus.initial));
    expect(bloc.state.messages, isEmpty);
  });

  blocTest<ChatBloc, ChatState>(
    'emits [sending, ready] with user + assistant messages on successful send',
    build: () {
      when(
        mockSend.call(
          messages: anyNamed('messages'),
          config: anyNamed('config'),
          systemPrompt: anyNamed('systemPrompt'),
          conversationId: anyNamed('conversationId'),
        ),
      ).thenAnswer(
        (_) async => Right(
          MessageEntity(
            id: 'assistant-1',
            role: MessageRole.assistant,
            content: 'Hello!',
            createdAt: DateTime.now(),
            modelConfig: testConfig,
          ),
        ),
      );
      return bloc;
    },
    act: (b) => b.add(
      const UserMessageSent(
        content: 'Hi',
        config: testConfig,
      ),
    ),
    wait: const Duration(milliseconds: 100),
    expect: () => [
      isA<ChatState>().having((s) => s.status, 'status', ChatStatus.sending),
      isA<ChatState>()
          .having((s) => s.status, 'status', ChatStatus.ready)
          .having((s) => s.messages.length, 'messages', 2),
    ],
  );

  blocTest<ChatBloc, ChatState>(
    'emits error state when send fails',
    build: () {
      when(
        mockSend.call(
          messages: anyNamed('messages'),
          config: anyNamed('config'),
          systemPrompt: anyNamed('systemPrompt'),
          conversationId: anyNamed('conversationId'),
        ),
      ).thenAnswer(
        (_) async => const Left(
          NetworkFailure(
            message: 'No internet',
          ),
        ),
      );
      return bloc;
    },
    act: (b) => b.add(
      const UserMessageSent(
        content: 'Hi',
        config: testConfig,
      ),
    ),
    wait: const Duration(milliseconds: 100),
    expect: () => [
      isA<ChatState>().having((s) => s.status, 'status', ChatStatus.sending),
      isA<ChatState>()
          .having((s) => s.status, 'status', ChatStatus.error)
          .having((s) => s.error, 'error', 'No internet'),
    ],
  );
}
