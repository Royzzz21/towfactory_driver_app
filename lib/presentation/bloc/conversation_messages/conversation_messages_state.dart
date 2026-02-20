import 'package:equatable/equatable.dart';

import '../../../domain/entities/message.dart';

abstract class ConversationMessagesState extends Equatable {
  const ConversationMessagesState();

  @override
  List<Object?> get props => [];
}

class ConversationMessagesInitial extends ConversationMessagesState {
  const ConversationMessagesInitial();
}

class ConversationMessagesLoading extends ConversationMessagesState {
  const ConversationMessagesLoading();
}

class ConversationMessagesLoaded extends ConversationMessagesState {
  const ConversationMessagesLoaded(
    this.messages, {
    this.page = 1,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.isOtherTyping = false,
    this.otherTypingName,
    this.isOtherOnline = false,
    this.snackbarMessage,
  });

  final List<Message> messages;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isOtherTyping;
  final String? otherTypingName;
  final bool isOtherOnline;
  /// Short message to show in a SnackBar (e.g. send/load-more failure). Cleared after showing.
  final String? snackbarMessage;

  @override
  List<Object?> get props => [messages, page, hasMore, isLoadingMore, isOtherTyping, otherTypingName, isOtherOnline, snackbarMessage];

  ConversationMessagesLoaded copyWith({
    List<Message>? messages,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isOtherTyping,
    String? otherTypingName,
    bool? isOtherOnline,
    String? snackbarMessage,
  }) {
    return ConversationMessagesLoaded(
      messages ?? this.messages,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isOtherTyping: isOtherTyping ?? this.isOtherTyping,
      otherTypingName: otherTypingName ?? this.otherTypingName,
      isOtherOnline: isOtherOnline ?? this.isOtherOnline,
      snackbarMessage: snackbarMessage ?? this.snackbarMessage,
    );
  }
}

class ConversationMessagesError extends ConversationMessagesState {
  const ConversationMessagesError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
