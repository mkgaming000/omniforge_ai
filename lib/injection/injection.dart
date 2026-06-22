// Dependency Injection container - GetIt-based service locator
import 'package:get_it/get_it.dart';

import '../core/network/network_info.dart';
import '../core/security/biometric_service.dart';
import '../core/security/encryption_service.dart';
import '../data/repositories/api_key_repository.dart';
import '../data/repositories/chat_repository.dart';
import '../data/repositories/conversation_repository.dart';
import '../data/repositories/image_repository.dart';
import '../data/repositories/usage_repository.dart';
import '../data/services/local_storage_service.dart';
import '../data/services/ai/ai_provider_factory.dart';
import '../data/services/ai/openai_service.dart';
import '../data/services/ai/anthropic_service.dart';
import '../data/services/ai/gemini_service.dart';
import '../data/services/ai/deepseek_service.dart';
import '../data/services/ai/mistral_service.dart';
import '../data/services/ai/grok_service.dart';
import '../data/services/ai/openrouter_service.dart';
import '../data/services/ai/ollama_service.dart';
import '../data/services/ai/qwen_service.dart';
import '../data/services/ai/zhipu_service.dart';
import '../data/services/ai/huggingface_service.dart';
import '../data/services/ai/image/openai_image_service.dart';
import '../data/services/ai/image/stability_image_service.dart';
import '../data/services/ai/image/flux_image_service.dart';
import '../data/services/ai/image/ideogram_image_service.dart';
import '../data/services/ai/image/recraft_image_service.dart';
import '../data/services/ai/image/leonardo_image_service.dart';
import '../data/services/ai/video/runway_service.dart';
import '../data/services/ai/video/pika_service.dart';
import '../data/services/ai/video/luma_service.dart';
import '../data/services/ai/video/kling_service.dart';
import '../data/services/ai/music/suno_service.dart';
import '../data/services/ai/music/udio_service.dart';
import '../data/services/ai/audio/elevenlabs_service.dart';
import '../data/services/ai/audio/assemblyai_service.dart';
import '../data/services/code_execution/code_execution_service.dart';
import '../data/services/agent/agent_runtime.dart';
import '../data/services/mcp/mcp_client.dart';
import '../data/services/ocr/ocr_service.dart';
import '../data/services/document/document_conversion_service.dart';
import '../data/services/web_search/tavily_search_service.dart';
import '../data/services/web_search/deep_research_service.dart';
import '../data/services/ai/embedding/openai_embedding_service.dart';
import '../data/services/vector_store/vector_store.dart';
import '../data/services/rag/rag_service.dart';
import '../data/services/orchestrator/orchestrator_pipeline.dart';
import '../data/repositories/agent_repository.dart';
import '../data/repositories/video_repository.dart';
import '../data/repositories/music_repository.dart';
import '../domain/usecases/chat/send_message_usecase.dart';
import '../domain/usecases/chat/stream_message_usecase.dart';
import '../domain/usecases/image/generate_image_usecase.dart';
import '../domain/usecases/conversation/create_conversation_usecase.dart';
import '../domain/usecases/conversation/get_conversations_usecase.dart';
import '../domain/usecases/conversation/delete_conversation_usecase.dart';
import '../domain/usecases/api_key/save_api_key_usecase.dart';
import '../domain/usecases/api_key/get_api_key_usecase.dart';
import '../domain/usecases/api_key/delete_api_key_usecase.dart';
import '../domain/usecases/usage/track_usage_usecase.dart';
import '../domain/usecases/usage/get_usage_stats_usecase.dart';
import '../presentation/blocs/app/app_bloc.dart';
import '../presentation/blocs/connectivity/connectivity_bloc.dart';
import '../presentation/blocs/chat/chat_bloc.dart';
import '../presentation/blocs/conversation/conversation_bloc.dart';
import '../presentation/blocs/api_key/api_key_bloc.dart';
import '../presentation/blocs/image/image_bloc.dart';
import '../presentation/blocs/usage/usage_bloc.dart';
import '../presentation/blocs/agent/agent_bloc.dart';
import '../presentation/blocs/video/video_bloc.dart';
import '../presentation/blocs/music/music_bloc.dart';
import '../presentation/blocs/mcp/mcp_bloc.dart';
import '../presentation/blocs/orchestrator/orchestrator_bloc.dart';
import '../core/theme/theme_cubit.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // Core services
  final encryptionService = await EncryptionService.create();
  getIt.registerSingleton<EncryptionService>(encryptionService);
  getIt.registerSingleton<BiometricService>(BiometricService.create());
  getIt.registerSingleton<NetworkInfo>(NetworkInfo.create());

  // Local storage
  final localStorage = await LocalStorageService.getInstance();
  getIt.registerSingleton<LocalStorageService>(localStorage);

  // AI provider services (chat)
  getIt.registerFactory<OpenAIService>(() => OpenAIService());
  getIt.registerFactory<AnthropicService>(() => AnthropicService());
  getIt.registerFactory<GeminiService>(() => GeminiService());
  getIt.registerFactory<DeepSeekService>(() => DeepSeekService());
  getIt.registerFactory<MistralService>(() => MistralService());
  getIt.registerFactory<GrokService>(() => GrokService());
  getIt.registerFactory<OpenRouterService>(() => OpenRouterService());
  getIt.registerFactory<OllamaService>(() => OllamaService());
  getIt.registerFactory<QwenService>(() => QwenService());
  getIt.registerFactory<ZhipuService>(() => ZhipuService());
  getIt.registerFactory<HuggingFaceService>(() => HuggingFaceService());

  // AI provider services (image)
  getIt.registerFactory<OpenAIImageService>(() => OpenAIImageService());
  getIt.registerFactory<StabilityImageService>(() => StabilityImageService());
  getIt.registerFactory<FluxImageService>(() => FluxImageService());
  getIt.registerFactory<IdeogramImageService>(() => IdeogramImageService());
  getIt.registerFactory<RecraftImageService>(() => RecraftImageService());
  getIt.registerFactory<LeonardoImageService>(() => LeonardoImageService());

  // AI provider services (video)
  getIt.registerFactory<RunwayService>(() => RunwayService());
  getIt.registerFactory<PikaService>(() => PikaService());
  getIt.registerFactory<LumaService>(() => LumaService());
  getIt.registerFactory<KlingService>(() => KlingService());

  // AI provider services (music + audio)
  getIt.registerFactory<SunoService>(() => SunoService());
  getIt.registerFactory<UdioService>(() => UdioService());
  getIt.registerFactory<ElevenLabsService>(() => ElevenLabsService());
  getIt.registerFactory<AssemblyAIService>(() => AssemblyAIService());

  // Provider factory
  getIt.registerSingleton<AIProviderFactory>(
    AIProviderFactory(
      encryptionService: encryptionService,
      openAI: getIt<OpenAIService>(),
      anthropic: getIt<AnthropicService>(),
      gemini: getIt<GeminiService>(),
      deepseek: getIt<DeepSeekService>(),
      mistral: getIt<MistralService>(),
      grok: getIt<GrokService>(),
      openRouter: getIt<OpenRouterService>(),
      ollama: getIt<OllamaService>(),
      qwen: getIt<QwenService>(),
      zhipu: getIt<ZhipuService>(),
      huggingFace: getIt<HuggingFaceService>(),
    ),
  );

  // Repositories
  getIt.registerFactory<ApiKeyRepository>(
    () => ApiKeyRepository(encryptionService: encryptionService),
  );
  getIt.registerFactory<ConversationRepository>(
    () => ConversationRepository(localStorage: localStorage),
  );
  getIt.registerFactory<ChatRepository>(
    () => ChatRepository(
      providerFactory: getIt<AIProviderFactory>(),
      usageRepository: getIt<UsageRepository>(),
    ),
  );
  getIt.registerFactory<ImageRepository>(
    () => ImageRepository(
      localStorage: localStorage,
      encryptionService: encryptionService,
      openai: getIt<OpenAIImageService>(),
      stability: getIt<StabilityImageService>(),
      flux: getIt<FluxImageService>(),
      ideogram: getIt<IdeogramImageService>(),
      recraft: getIt<RecraftImageService>(),
      leonardo: getIt<LeonardoImageService>(),
    ),
  );
  getIt.registerFactory<UsageRepository>(
    () => UsageRepository(localStorage: localStorage),
  );
  getIt.registerFactory<AgentRepository>(
    () => AgentRepository(localStorage: localStorage),
  );
  getIt.registerFactory<VideoRepository>(
    () => VideoRepository(localStorage: localStorage),
  );
  getIt.registerFactory<MusicRepository>(
    () => MusicRepository(localStorage: localStorage),
  );

  // TavilySearchService has a synchronous constructor; register it eagerly.
  getIt.registerSingleton<TavilySearchService>(TavilySearchService());

  // DeepResearchService depends on TavilySearchService + AIProviderFactory
  // (both already registered above).
  getIt.registerSingleton<DeepResearchService>(
    DeepResearchService(
      searchService: getIt<TavilySearchService>(),
      providerFactory: getIt<AIProviderFactory>(),
    ),
  );

  // Async-initialized services (require Hive boxes opened lazily).
  getIt.registerSingletonAsync<McpClient>(() => McpClient.create());
  getIt.registerSingletonAsync<VectorStore>(() => VectorStore.create());

  // Embedding service — synchronous constructor, API key injected lazily
  // when the embedding service is first used.
  getIt.registerSingleton<OpenAIEmbeddingService>(OpenAIEmbeddingService());

  // RAG service — depends on VectorStore (async) + OpenAIEmbeddingService.
  getIt.registerSingletonAsync<RagService>(() async {
    final vectorStore = await getIt.getAsync<VectorStore>();
    return RagService(
      embeddingService: getIt<OpenAIEmbeddingService>(),
      vectorStore: vectorStore,
    );
  });

  // Master Orchestrator pipeline — registered as async singleton because
  // RagService itself is async-registered (depends on VectorStore).
  getIt.registerSingletonAsync<OrchestratorPipeline>(() async {
    final ragService = await getIt.getAsync<RagService>();
    return OrchestratorPipeline(
      factory: getIt<AIProviderFactory>(),
      ragService: ragService,
    );
  });

  // Code execution service (Piston — free, public, no auth required).
  getIt.registerSingleton<CodeExecutionService>(PistonExecutionService());

  // OCR service (ML Kit — on-device, no API key required).
  getIt.registerSingleton<OcrService>(MlKitOcrService());

  // Document conversion — inject the AIProviderFactory so the service can
  // call the LLM for summarize/extract operations.
  getIt.registerSingleton<DocumentConversionService>(
    DocumentConversionService(factory: getIt<AIProviderFactory>()),
  );

  // Agent runtime depends on AIProviderFactory + McpClient + RagService.
  // All three are registered above; getIt resolves them synchronously
  // after `await getIt.allReady()` completes.
  getIt.registerFactory<AgentRuntime>(
    () => AgentRuntime(
      providerFactory: getIt<AIProviderFactory>(),
      mcpClient: getIt<McpClient>(),
      ragService: getIt<RagService>(),
    ),
  );

  // Use cases
  _registerUseCases();

  // BLoCs / Cubits
  getIt.registerFactory<ThemeCubit>(() => ThemeCubit());
  getIt.registerFactory<AppBloc>(() => AppBloc());
  getIt.registerFactory<ConnectivityBloc>(
    () => ConnectivityBloc(networkInfo: getIt<NetworkInfo>()),
  );
  getIt.registerFactory<ChatBloc>(
    () => ChatBloc(
      sendMessageUseCase: getIt<SendMessageUseCase>(),
      streamMessageUseCase: getIt<StreamMessageUseCase>(),
    ),
  );
  getIt.registerFactory<ConversationBloc>(
    () => ConversationBloc(
      createConversationUseCase: getIt<CreateConversationUseCase>(),
      getConversationsUseCase: getIt<GetConversationsUseCase>(),
      deleteConversationUseCase: getIt<DeleteConversationUseCase>(),
    ),
  );
  getIt.registerFactory<ApiKeyBloc>(
    () => ApiKeyBloc(
      saveApiKeyUseCase: getIt<SaveApiKeyUseCase>(),
      getApiKeyUseCase: getIt<GetApiKeyUseCase>(),
      deleteApiKeyUseCase: getIt<DeleteApiKeyUseCase>(),
    ),
  );
  getIt.registerFactory<ImageBloc>(
    () => ImageBloc(generateImageUseCase: getIt<GenerateImageUseCase>()),
  );
  getIt.registerFactory<UsageBloc>(
    () => UsageBloc(
      trackUsageUseCase: getIt<TrackUsageUseCase>(),
      getUsageStatsUseCase: getIt<GetUsageStatsUseCase>(),
    ),
  );
  getIt.registerFactory<AgentBloc>(
    () => AgentBloc(
      repository: getIt<AgentRepository>(),
      runtime: getIt<AgentRuntime>(),
    ),
  );
  getIt.registerFactory<VideoBloc>(
    () => VideoBloc(repository: getIt<VideoRepository>()),
  );
  getIt.registerFactory<MusicBloc>(
    () => MusicBloc(repository: getIt<MusicRepository>()),
  );
  getIt.registerFactory<McpBloc>(
    () => McpBloc(client: getIt<McpClient>()),
  );
  getIt.registerFactory<OrchestratorBloc>(
    () => OrchestratorBloc(pipeline: getIt<OrchestratorPipeline>()),
  );

  // Wait for all async-registered singletons (McpClient, VectorStore,
  // RagService) to be ready before returning. Without this, lazy factories
  // that depend on async singletons would throw `StateError: Object not
  // ready` at runtime.
  await getIt.allReady();
}

void _registerUseCases() {
  // Chat
  getIt.registerFactory<SendMessageUseCase>(
    () => SendMessageUseCase(chatRepository: getIt<ChatRepository>()),
  );
  getIt.registerFactory<StreamMessageUseCase>(
    () => StreamMessageUseCase(chatRepository: getIt<ChatRepository>()),
  );

  // Image
  getIt.registerFactory<GenerateImageUseCase>(
    () => GenerateImageUseCase(repository: getIt<ImageRepository>()),
  );

  // Conversation
  getIt.registerFactory<CreateConversationUseCase>(
    () => CreateConversationUseCase(
      repository: getIt<ConversationRepository>(),
    ),
  );
  getIt.registerFactory<GetConversationsUseCase>(
    () => GetConversationsUseCase(repository: getIt<ConversationRepository>()),
  );
  getIt.registerFactory<DeleteConversationUseCase>(
    () => DeleteConversationUseCase(
      repository: getIt<ConversationRepository>(),
    ),
  );

  // API Keys
  getIt.registerFactory<SaveApiKeyUseCase>(
    () => SaveApiKeyUseCase(repository: getIt<ApiKeyRepository>()),
  );
  getIt.registerFactory<GetApiKeyUseCase>(
    () => GetApiKeyUseCase(repository: getIt<ApiKeyRepository>()),
  );
  getIt.registerFactory<DeleteApiKeyUseCase>(
    () => DeleteApiKeyUseCase(repository: getIt<ApiKeyRepository>()),
  );

  // Usage
  getIt.registerFactory<TrackUsageUseCase>(
    () => TrackUsageUseCase(repository: getIt<UsageRepository>()),
  );
  getIt.registerFactory<GetUsageStatsUseCase>(
    () => GetUsageStatsUseCase(repository: getIt<UsageRepository>()),
  );
}
