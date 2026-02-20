import 'package:equatable/equatable.dart';

import '../../../domain/entities/message.dart';

abstract class ConversationMessagesEvent extends Equatable {
  const ConversationMessagesEvent();

  @override
  List<Object?> get props => [];
}

/// Load messages for the conversation (GET /chats?bookingId=...).
class LoadConversationMessages extends ConversationMessagesEvent {
  const LoadConversationMessages();
}

/// Refresh messages (reload page 1).
class RefreshConversationMessages extends ConversationMessagesEvent {
  const RefreshConversationMessages();
}

/// Load next page of messages (append when scrolling up).
class LoadMoreConversationMessages extends ConversationMessagesEvent {
  const LoadMoreConversationMessages();
}

/// Send a new message (POST /chats).
class SendConversationMessage extends ConversationMessagesEvent {
  const SendConversationMessage(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

/// Join the conversation room via WebSocket (after messages loaded).
class JoinConversationRoom extends ConversationMessagesEvent {
  const JoinConversationRoom();
}

/// Leave the conversation room (e.g. when leaving the screen).
class LeaveConversationRoom extends ConversationMessagesEvent {
  const LeaveConversationRoom();
}

/// New message received from WebSocket (internal).
class ConversationNewMessageFromSocket extends ConversationMessagesEvent {
  const ConversationNewMessageFromSocket(this.message);

  final Message message;

  @override
  List<Object?> get props => [message];
}

/// Message read update from WebSocket (internal).
class ConversationMessageReadFromSocket extends ConversationMessagesEvent {
  const ConversationMessageReadFromSocket(this.messageId);

  final String? messageId;

  @override
  List<Object?> get props => [messageId];
}

/// Other user typing status from WebSocket (internal).
class ConversationUserTypingFromSocket extends ConversationMessagesEvent {
  const ConversationUserTypingFromSocket(this.senderName, this.isTyping);

  final String senderName;
  final bool isTyping;

  @override
  List<Object?> get props => [senderName, isTyping];
}

/// Mark a message as read via WebSocket.
class MarkMessageAsRead extends ConversationMessagesEvent {
  const MarkMessageAsRead(this.messageId);

  final String messageId;

  @override
  List<Object?> get props => [messageId];
}

/// Set local typing status (sent via WebSocket).
class SetTyping extends ConversationMessagesEvent {
  const SetTyping(this.isTyping);

  final bool isTyping;

  @override
  List<Object?> get props => [isTyping];
}

/// Clear the snackbar message after showing (keeps list visible).
class ClearSnackbarMessage extends ConversationMessagesEvent {
  const ClearSnackbarMessage();
}

/// User came online in the booking (from WebSocket).
class ConversationUserOnlineFromSocket extends ConversationMessagesEvent {
  const ConversationUserOnlineFromSocket(this.userName, this.userType, this.bookingId);

  final String userName;
  final String userType;
  final String bookingId;

  @override
  List<Object?> get props => [userName, userType, bookingId];
}

/// User went offline in the booking (from WebSocket).
class ConversationUserOfflineFromSocket extends ConversationMessagesEvent {
  const ConversationUserOfflineFromSocket(this.userName, this.userType, this.bookingId);

  final String userName;
  final String userType;
  final String bookingId;

  @override
  List<Object?> get props => [userName, userType, bookingId];
}
