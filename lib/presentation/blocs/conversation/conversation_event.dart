// Conversation Events
import 'package:equatable/equatable.dart';

abstract class ConversationEvent extends Equatable {
  const ConversationEvent();
}

class LoadConversations extends ConversationEvent {
  const LoadConversations({this.folderId, this.includeArchived = false});
  final String? folderId;
  final bool includeArchived;
  @override
  List<Object?> get props => [folderId, includeArchived];
}

class CreateConversation extends ConversationEvent {
  const CreateConversation({
    required this.title,
    this.systemPrompt,
    this.folderId,
  });
  final String title;
  final String? systemPrompt;
  final String? folderId;
  @override
  List<Object?> get props => [title, systemPrompt, folderId];
}

class DeleteConversation extends ConversationEvent {
  const DeleteConversation(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

class SelectConversation extends ConversationEvent {
  const SelectConversation(this.id);
  final String? id;
  @override
  List<Object?> get props => [id];
}

class SearchConversations extends ConversationEvent {
  const SearchConversations(this.query);
  final String query;
  @override
  List<Object?> get props => [query];
}
