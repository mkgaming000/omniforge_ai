// Local Storage Service - Hive-based persistence layer
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/ai_providers.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/agent_entity.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/folder_entity.dart';
import '../../domain/entities/image_entity.dart';
import '../../domain/entities/knowledge_base_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/entities/model_config_entity.dart';
import '../../domain/entities/music_entity.dart';
import '../../domain/entities/orchestrator/orchestrator_entities.dart';
import '../../domain/entities/usage_entity.dart';
import '../../domain/entities/video_entity.dart';
import '../../domain/entities/workspace_entity.dart';

class LocalStorageService {
  LocalStorageService._(this._box);

  final Box<dynamic> _box;

  static Future<LocalStorageService> getInstance() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MessageRoleAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ConversationEntityAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(MessageEntityAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(MessageAttachmentAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(AttachmentTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(ToolCallAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(ToolCallStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(ModelConfigEntityAdapter());
    }
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(MessageStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(ImageEntityAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(ImageGenerationRequestAdapter());
    }
    if (!Hive.isAdapterRegistered(20)) {
      Hive.registerAdapter(UsageEntityAdapter());
    }
    if (!Hive.isAdapterRegistered(21)) {
      Hive.registerAdapter(UsageOperationAdapter());
    }
    if (!Hive.isAdapterRegistered(22)) {
      Hive.registerAdapter(UsageStatsAdapter());
    }
    if (!Hive.isAdapterRegistered(23)) {
      Hive.registerAdapter(ProviderStatsAdapter());
    }
    if (!Hive.isAdapterRegistered(24)) {
      Hive.registerAdapter(DailyStatsAdapter());
    }
    if (!Hive.isAdapterRegistered(100)) {
      Hive.registerAdapter(_AIProviderAdapter());
    }

    // Video entities (typeId 30-32)
    if (!Hive.isAdapterRegistered(30)) {
      Hive.registerAdapter(VideoEntityAdapter());
    }
    if (!Hive.isAdapterRegistered(31)) {
      Hive.registerAdapter(VideoGenerationRequestAdapter());
    }
    if (!Hive.isAdapterRegistered(32)) {
      Hive.registerAdapter(VideoStatusAdapter());
    }

    // Music entities (typeId 40-42)
    if (!Hive.isAdapterRegistered(40)) {
      Hive.registerAdapter(MusicEntityAdapter());
    }
    if (!Hive.isAdapterRegistered(41)) {
      Hive.registerAdapter(MusicStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(42)) {
      Hive.registerAdapter(MusicGenerationRequestAdapter());
    }

    // Agent entities (typeId 70-72)
    if (!Hive.isAdapterRegistered(70)) {
      Hive.registerAdapter(AgentEntityAdapter());
    }
    if (!Hive.isAdapterRegistered(71)) {
      Hive.registerAdapter(AgentMemoryEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(72)) {
      Hive.registerAdapter(AgentRoleAdapter());
    }

    // Knowledge base entity (typeId 80)
    if (!Hive.isAdapterRegistered(80)) {
      Hive.registerAdapter(KnowledgeBaseEntityAdapter());
    }

    // Workspace entities (typeId 120-121) — 100 is used by _AIProviderAdapter.
    if (!Hive.isAdapterRegistered(120)) {
      Hive.registerAdapter(WorkspaceEntityAdapter());
    }
    if (!Hive.isAdapterRegistered(101)) {
      Hive.registerAdapter(WorkspaceTypeAdapter());
    }

    // Folder entity (typeId 110)
    if (!Hive.isAdapterRegistered(110)) {
      Hive.registerAdapter(FolderEntityAdapter());
    }

    // Orchestrator entities (typeId 200, 210-213)
    if (!Hive.isAdapterRegistered(200)) {
      Hive.registerAdapter(OrchestratorAgentAdapter());
    }
    if (!Hive.isAdapterRegistered(210)) {
      Hive.registerAdapter(SharedMemoryEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(211)) {
      Hive.registerAdapter(MemoryEntryKindAdapter());
    }
    if (!Hive.isAdapterRegistered(212)) {
      Hive.registerAdapter(AgentExecutionStateAdapter());
    }
    if (!Hive.isAdapterRegistered(213)) {
      Hive.registerAdapter(AgentRunStatusAdapter());
    }

    final box = await Hive.openBox<dynamic>(AppConstants.hiveBoxName);
    return LocalStorageService._(box);
  }

  Future<void> write<T>(String key, T value) => _box.put(key, value);

  T? read<T>(String key) => _box.get(key) as T?;

  Future<void> delete(String key) => _box.delete(key);

  List<T> readWhere<T>(bool Function(String key, dynamic value) predicate) {
    return _box.keys
        .whereType<String>()
        .where((key) => predicate(key, _box.get(key)))
        .map<T>((key) => _box.get(key) as T)
        .toList();
  }

  Future<void> clear() => _box.clear();

  Box<dynamic> get box => _box;
}

class _AIProviderAdapter extends TypeAdapter<AIProvider> {
  @override
  final typeId = 100;

  @override
  AIProvider read(BinaryReader reader) {
    final name = reader.readString();
    return AIProvider.values.firstWhere(
      (p) => p.name == name,
      orElse: () => AIProvider.openai,
    );
  }

  @override
  void write(BinaryWriter writer, AIProvider obj) {
    writer.writeString(obj.name);
  }
}
