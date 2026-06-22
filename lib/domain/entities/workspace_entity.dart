// Workspace entity - represents a coding project / file collection
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'workspace_entity.g.dart';

@HiveType(typeId: 120)
class WorkspaceEntity extends Equatable {
  const WorkspaceEntity({
    required this.id,
    required this.name,
    required this.path,
    required this.createdAt,
    this.description,
    this.type = WorkspaceType.general,
    this.language,
    this.framework,
    this.gitUrl,
    this.cloudSyncEnabled = false,
    this.cloudProvider,
    this.metadata = const {},
    this.lastOpenedAt,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String path;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final String? description;

  @HiveField(5)
  final WorkspaceType type;

  @HiveField(6)
  final String? language;

  @HiveField(7)
  final String? framework;

  @HiveField(8)
  final String? gitUrl;

  @HiveField(9)
  final bool cloudSyncEnabled;

  @HiveField(10)
  final String? cloudProvider;

  @HiveField(11)
  final Map<String, dynamic> metadata;

  @HiveField(12)
  final DateTime? lastOpenedAt;

  WorkspaceEntity copyWith({
    String? id,
    String? name,
    String? path,
    DateTime? createdAt,
    String? description,
    WorkspaceType? type,
    String? language,
    String? framework,
    String? gitUrl,
    bool? cloudSyncEnabled,
    String? cloudProvider,
    Map<String, dynamic>? metadata,
    DateTime? lastOpenedAt,
  }) {
    return WorkspaceEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      type: type ?? this.type,
      language: language ?? this.language,
      framework: framework ?? this.framework,
      gitUrl: gitUrl ?? this.gitUrl,
      cloudSyncEnabled: cloudSyncEnabled ?? this.cloudSyncEnabled,
      cloudProvider: cloudProvider ?? this.cloudProvider,
      metadata: metadata ?? this.metadata,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        path,
        createdAt,
        description,
        type,
        language,
        framework,
        gitUrl,
        cloudSyncEnabled,
        cloudProvider,
        metadata,
        lastOpenedAt,
      ];
}

@HiveType(typeId: 101)
enum WorkspaceType {
  @HiveField(0)
  flutter,
  @HiveField(1)
  react,
  @HiveField(2)
  vue,
  @HiveField(3)
  angular,
  @HiveField(4)
  svelte,
  @HiveField(5)
  node,
  @HiveField(6)
  python,
  @HiveField(7)
  rust,
  @HiveField(8)
  go,
  @HiveField(9)
  java,
  @HiveField(10)
  cpp,
  @HiveField(11)
  web,
  @HiveField(12)
  game,
  @HiveField(13)
  general,
}
