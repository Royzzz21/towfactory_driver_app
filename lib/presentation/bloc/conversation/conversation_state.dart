import 'package:equatable/equatable.dart';

import '../../../domain/entities/chat.dart';

abstract class ConversationState extends Equatable {
  const ConversationState();

  @override
  List<Object?> get props => [];
}

class ConversationInitial extends ConversationState {
  const ConversationInitial();
}

class ConversationLoading extends ConversationState {
  const ConversationLoading();
}

class ConversationLoaded extends ConversationState {
  const ConversationLoaded(this.conversations);

  final List<Chat> conversations;

  @override
  List<Object?> get props => [conversations];
}

class ConversationError extends ConversationState {
  const ConversationError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
