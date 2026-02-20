import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/message.dart';
import '../../../domain/repositories/chat_repository.dart';
import '../../../services/chat_websocket_service.dart';
import 'conversation_messages_event.dart';
import 'conversation_messages_state.dart';

class ConversationMessagesBloc
    extends Bloc<ConversationMessagesEvent, ConversationMessagesState> {
  ConversationMessagesBloc(
    this._repository,
    this._wsService,
    this.bookingId,
    this.bookingNumber,
  ) : super(const ConversationMessagesInitial()) {
    on<LoadConversationMessages>(_onLoadMessages);
    on<RefreshConversationMessages>(_onRefreshMessages);
    on<LoadMoreConversationMessages>(_onLoadMoreMessages);
    on<SendConversationMessage>(_onSendMessage);
    on<JoinConversationRoom>(_onJoinRoom);
    on<LeaveConversationRoom>(_onLeaveRoom);
    on<ConversationNewMessageFromSocket>(_onNewMessageFromSocket);
    on<ConversationMessageReadFromSocket>(_onMessageReadFromSocket);
    on<ConversationUserTypingFromSocket>(_onUserTypingFromSocket);
    on<ConversationUserOnlineFromSocket>(_onUserOnlineFromSocket);
    on<ConversationUserOfflineFromSocket>(_onUserOfflineFromSocket);
    on<MarkMessageAsRead>(_onMarkAsRead);
    on<SetTyping>(_onSetTyping);
    on<ClearSnackbarMessage>(_onClearSnackbarMessage);
  }

  final ChatRepository _repository;
  final ChatWebSocketService _wsService;
  final String bookingId;
  /// Booking number used for GET /chats/booking/number/:number.
  final String bookingNumber;

  String get _messagesBookingRef => bookingNumber.isNotEmpty ? bookingNumber : bookingId;

  static const int _pageSize = 20;

  StreamSubscription<ChatWsIncomingEvent>? _wsSubscription;

  @override
  Future<void> close() {
    _leaveRoomSync();
    return super.close();
  }

  void _leaveRoomSync() {
    _wsSubscription?.cancel();
    _wsSubscription = null;
    if (bookingId.isNotEmpty) {
      _wsService.leaveBooking(bookingId);
    }
  }

  Future<void> _onLoadMessages(
    LoadConversationMessages event,
    Emitter<ConversationMessagesState> emit,
  ) async {
    if (_messagesBookingRef.isEmpty) {
      emit(const ConversationMessagesLoaded([]));
      return;
    }
    emit(const ConversationMessagesLoading());
    try {
      final result = await _repository.getMessages(
        _messagesBookingRef,
        page: 1,
        limit: _pageSize,
      );
      final hasMore = result.page < result.totalPages;
      emit(ConversationMessagesLoaded(
        _deduplicateById(result.data),
        page: 1,
        hasMore: hasMore,
      ));
    } catch (e) {
      final msg = _shortError(e.toString());
      emit(ConversationMessagesError(msg));
      return;
    }
    add(const JoinConversationRoom());
  }

  Future<void> _onRefreshMessages(
    RefreshConversationMessages event,
    Emitter<ConversationMessagesState> emit,
  ) async {
    if (_messagesBookingRef.isEmpty) return;
    await _fetch(emit, page: 1);
  }

  Future<void> _onLoadMoreMessages(
    LoadMoreConversationMessages event,
    Emitter<ConversationMessagesState> emit,
  ) async {
    final current = state;
    if (current is! ConversationMessagesLoaded ||
        !current.hasMore ||
        current.isLoadingMore) return;
    emit(current.copyWith(isLoadingMore: true));
    try {
      final nextPage = current.page + 1;
      final result = await _repository.getMessages(
        _messagesBookingRef,
        page: nextPage,
        limit: _pageSize,
      );
      final hasMore = result.page < result.totalPages;
      emit(current.copyWith(
        messages: _deduplicateById([...current.messages, ...result.data]),
        page: nextPage,
        hasMore: hasMore,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(current.copyWith(
        isLoadingMore: false,
        snackbarMessage: 'Couldn\'t load more messages.',
      ));
    }
  }

  Future<void> _fetch(Emitter<ConversationMessagesState> emit, {required int page}) async {
    try {
      final result = await _repository.getMessages(
        _messagesBookingRef,
        page: page,
        limit: _pageSize,
      );
      final hasMore = result.page < result.totalPages;
      emit(ConversationMessagesLoaded(
        _deduplicateById(result.data),
        page: page,
        hasMore: hasMore,
      ));
    } catch (e) {
      final msg = _shortError(e.toString());
      emit(ConversationMessagesError(msg));
    }
  }

  void _onClearSnackbarMessage(
    ClearSnackbarMessage event,
    Emitter<ConversationMessagesState> emit,
  ) {
    final current = state;
    if (current is ConversationMessagesLoaded && current.snackbarMessage != null) {
      emit(current.copyWith(snackbarMessage: ''));
    }
  }

  static String _shortError(String s) {
    final t = s
        .replaceFirst(RegExp(r'^ApiException:\s*'), '')
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .trim();
    if (t.length > 120) return '${t.substring(0, 117)}...';
    return t;
  }

  /// Keeps first occurrence per message id to avoid duplicate bubbles.
  static List<Message> _deduplicateById(List<Message> list) {
    final seen = <String>{};
    return list.where((m) => seen.add(m.id)).toList();
  }

  Future<void> _onJoinRoom(
    JoinConversationRoom event,
    Emitter<ConversationMessagesState> emit,
  ) async {
    if (bookingId.isEmpty) return;
    _wsSubscription?.cancel();

    // Fetch initial online status from the API
    try {
      final isOnline = await _repository.isCustomerOnline(bookingId);
      final current = state;
      if (current is ConversationMessagesLoaded) {
        emit(current.copyWith(isOtherOnline: isOnline));
      }
    } catch (_) {
      // Non-critical; WebSocket events will update status
    }

    try {
      await _wsService.connect();
      await _wsService.joinBooking(bookingId);
      _wsSubscription = _wsService.eventStream.listen((e) {
        switch (e) {
          case ChatWsNewMessage(:final message):
            add(ConversationNewMessageFromSocket(message));
            break;
          case ChatWsMessageRead(:final messageId):
            add(ConversationMessageReadFromSocket(messageId));
            break;
          case ChatWsUserTyping(:final senderName, :final isTyping):
            add(ConversationUserTypingFromSocket(senderName, isTyping));
            break;
          case ChatWsUserOnline(:final userName, :final userType, :final bookingId):
            add(ConversationUserOnlineFromSocket(userName, userType, bookingId));
            break;
          case ChatWsUserOffline(:final userName, :final userType, :final bookingId):
            add(ConversationUserOfflineFromSocket(userName, userType, bookingId));
            break;
        }
      });
    } catch (_) {
      // WebSocket unavailable (e.g. server not running, wrong scheme); chat still works via HTTP
    }
  }

  void _onLeaveRoom(
    LeaveConversationRoom event,
    Emitter<ConversationMessagesState> emit,
  ) {
    _leaveRoomSync();
  }

  void _onNewMessageFromSocket(
    ConversationNewMessageFromSocket event,
    Emitter<ConversationMessagesState> emit,
  ) {
    final current = state;
    if (current is! ConversationMessagesLoaded) return;
    final msg = event.message;
    final exists = current.messages.any((m) => m.id == msg.id);
    if (exists) return;
    emit(current.copyWith(
      messages: _deduplicateById([...current.messages, msg]),
    ));
  }

  void _onMessageReadFromSocket(
    ConversationMessageReadFromSocket event,
    Emitter<ConversationMessagesState> emit,
  ) {
    final current = state;
    if (current is! ConversationMessagesLoaded) return;
    final id = event.messageId;
    if (id == null || id.isEmpty) return;
    final updated = current.messages
        .map((m) => m.id == id ? m.copyWith(isRead: true) : m)
        .toList();
    emit(current.copyWith(messages: updated));
  }

  void _onUserTypingFromSocket(
    ConversationUserTypingFromSocket event,
    Emitter<ConversationMessagesState> emit,
  ) {
    final current = state;
    if (current is! ConversationMessagesLoaded) return;
    emit(current.copyWith(
      isOtherTyping: event.isTyping,
      otherTypingName: event.isTyping ? event.senderName : null,
    ));
  }

  void _onUserOnlineFromSocket(
    ConversationUserOnlineFromSocket event,
    Emitter<ConversationMessagesState> emit,
  ) {
    final current = state;
    if (current is! ConversationMessagesLoaded) return;
    // Only care about customer coming online
    if (event.userType == 'customer' && event.bookingId == bookingId) {
      emit(current.copyWith(isOtherOnline: true));
    }
  }

  void _onUserOfflineFromSocket(
    ConversationUserOfflineFromSocket event,
    Emitter<ConversationMessagesState> emit,
  ) {
    final current = state;
    if (current is! ConversationMessagesLoaded) return;
    // Only care about customer going offline
    if (event.userType == 'customer' && event.bookingId == bookingId) {
      emit(current.copyWith(isOtherOnline: false));
    }
  }

  void _onMarkAsRead(
    MarkMessageAsRead event,
    Emitter<ConversationMessagesState> emit,
  ) {
    _wsService.markAsRead(event.messageId);
  }

  void _onSetTyping(
    SetTyping event,
    Emitter<ConversationMessagesState> emit,
  ) {
    if (bookingId.isEmpty) return;
    _wsService.sendTyping(bookingId, 'Driver', event.isTyping);
  }

  Future<void> _onSendMessage(
    SendConversationMessage event,
    Emitter<ConversationMessagesState> emit,
  ) async {
    final text = event.text.trim();
    if (text.isEmpty) return;
    if (bookingId.isEmpty) return;

    final current = state;

    // Optimistic: show message immediately with a temp id
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = Message(
      id: tempId,
      bookingId: bookingId,
      senderType: 'driver',
      message: text,
      type: 'text',
      isRead: false,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );

    if (current is ConversationMessagesLoaded) {
      emit(current.copyWith(
        messages: _deduplicateById([...current.messages, optimistic]),
      ));
    }

    // Send via HTTP in background
    try {
      final sent = await _repository.sendMessage(bookingId, text, type: 'text');
      final latest = state;
      if (sent != null && latest is ConversationMessagesLoaded) {
        // Replace temp message with real one from server
        final updated = latest.messages
            .map((m) => m.id == tempId ? sent : m)
            .toList();
        emit(latest.copyWith(messages: _deduplicateById(updated)));
      }
    } catch (e) {
      // Remove optimistic message on failure
      final latest = state;
      if (latest is ConversationMessagesLoaded) {
        final updated = latest.messages.where((m) => m.id != tempId).toList();
        emit(latest.copyWith(
          messages: updated,
          snackbarMessage: 'Failed to send message. Try again.',
        ));
      }
    }
  }
}
