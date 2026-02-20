import 'package:equatable/equatable.dart';

import '../../../domain/entities/chat.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  const ChatLoading();
}

class ChatLoaded extends ChatState {
  const ChatLoaded(this.conversations);

  final List<Chat> conversations;

  @override
  List<Object?> get props => [conversations];
}

class ChatError extends ChatState {
  const ChatError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
