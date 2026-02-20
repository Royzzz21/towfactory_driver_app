import 'package:equatable/equatable.dart';

abstract class ConversationEvent extends Equatable {
  const ConversationEvent();

  @override
  List<Object?> get props => [];
}

/// Load "my" conversations from GET /chats/my.
class LoadConversations extends ConversationEvent {
  const LoadConversations();
}

/// Refresh conversations (reload list).
class RefreshConversations extends ConversationEvent {
  const RefreshConversations();
}
