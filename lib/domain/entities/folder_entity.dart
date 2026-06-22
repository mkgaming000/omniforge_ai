// Conversation Folder entity - for organizing conversations
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'folder_entity.g.dart';

@HiveType(typeId: 110)
class FolderEntity extends Equatable {
  const FolderEntity({
    required this.id,
    required this.name,
    required this.createdAt,
    this.parentId,
    this.color,
    this.icon,
    this.metadata = const {},
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final String? parentId;

  @HiveField(4)
  final int? color;

  @HiveField(5)
  final String? icon;

  @HiveField(6)
  final Map<String, dynamic> metadata;

  FolderEntity copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    String? parentId,
    int? color,
    String? icon,
    Map<String, dynamic>? metadata,
  }) {
    return FolderEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      parentId: parentId ?? this.parentId,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, createdAt, parentId, color, icon, metadata];
}
