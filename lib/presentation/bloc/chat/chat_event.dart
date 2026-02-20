import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

/// Load "my" chats from GET /chats/my.
class LoadChats extends ChatEvent {
  const LoadChats();
}

/// Refresh chats (reload list).
class RefreshChats extends ChatEvent {
  const RefreshChats();
}
