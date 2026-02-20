import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../domain/entities/message.dart';
import '../domain/repositories/session_repository.dart';

/// Incoming chat event from the Socket.IO server.
sealed class ChatWsIncomingEvent {
  const ChatWsIncomingEvent();
}

/// A new message was sent in the chat (payload: Chat object or message).
class ChatWsNewMessage extends ChatWsIncomingEvent {
  const ChatWsNewMessage(this.message);

  final Message message;
}

/// A message was marked as read (payload: Chat object).
class ChatWsMessageRead extends ChatWsIncomingEvent {
  const ChatWsMessageRead(this.messageId);

  final String? messageId;
}

/// Another user's typing status (payload: { senderName, isTyping }).
class ChatWsUserTyping extends ChatWsIncomingEvent {
  const ChatWsUserTyping(this.senderName, this.isTyping);

  final String senderName;
  final bool isTyping;
}

/// A user came online in the booking (payload: { userName, userType, bookingId }).
class ChatWsUserOnline extends ChatWsIncomingEvent {
  const ChatWsUserOnline(this.userName, this.userType, this.bookingId);

  final String userName;
  final String userType;
  final String bookingId;
}

/// A user went offline in the booking (payload: { userName, userType, bookingId }).
class ChatWsUserOffline extends ChatWsIncomingEvent {
  const ChatWsUserOffline(this.userName, this.userType, this.bookingId);

  final String userName;
  final String userType;
  final String bookingId;
}

/// Socket.IO-based chat service: connect to server's /chats namespace,
/// join/leave booking room, send typing/markAsRead, stream newMessage, messageRead, userTyping.
class ChatWebSocketService {
  ChatWebSocketService({
    required String socketUrl,
    required SessionRepository sessionRepository,
    String? socketPath,
  })  : _socketUrl = socketUrl,
        _socketPath = socketPath,
        _sessionRepository = sessionRepository;

  final String _socketUrl;
  final String? _socketPath;
  final SessionRepository _sessionRepository;

  io.Socket? _socket;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  final StreamController<ChatWsIncomingEvent> _eventController =
      StreamController<ChatWsIncomingEvent>.broadcast();

  /// Stream of incoming chat events.
  Stream<ChatWsIncomingEvent> get eventStream => _eventController.stream;

  bool get isConnected => _socket != null && _socket!.connected;

  /// Connect to Socket.IO (idempotent). Uses current access token in auth.
  /// Registers user as 'driver' on connect.
  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;
    try {
      final user = await _sessionRepository.getStoredUser();
      final token = user?.token ?? '';
      final userName = user?.name ?? 'Driver';
      _socket?.disconnect();
      _socket?.dispose();

      final optionBuilder = io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(_maxReconnectAttempts)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(10000)
          .setAuth(<String, dynamic>{'token': token});

      // Set custom Socket.IO path for reverse proxy (e.g. /api/socket.io/)
      if (_socketPath != null && _socketPath!.isNotEmpty) {
        optionBuilder.setPath(_socketPath!);
      }

      _socket = io.io(_socketUrl, optionBuilder.build());

      _socket!.onConnect((_) {
        _reconnectAttempts = 0;
        // Register as driver when connected
        _socket!.emit('registerUser', {
          'userId': user?.id,
          'userName': userName,
          'userType': 'driver',
        });
      });
      _socket!.onDisconnect((_) {
        _scheduleReconnect();
      });
      _socket!.onConnectError((data) {
        _eventController.addError(data ?? 'Connection error');
        _scheduleReconnect();
      });
      _socket!.on('newMessage', _onNewMessage);
      _socket!.on('messageRead', _onMessageRead);
      _socket!.on('userTyping', _onUserTyping);
      _socket!.on('userOnline', _onUserOnline);
      _socket!.on('userOffline', _onUserOffline);
    } catch (e) {
      disconnect();
      rethrow;
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) return;
    _reconnectTimer?.cancel();
    final delay = Duration(
      milliseconds: (1000 * (1 << _reconnectAttempts)).clamp(1000, 10000),
    );
    _reconnectAttempts++;
    _reconnectTimer = Timer(delay, () {
      if (_socket != null && !_socket!.connected) {
        _socket!.connect();
      }
    });
  }

  void _onNewMessage(dynamic data) {
    final msg = _parseMessage(_toMap(data));
    if (msg != null) _eventController.add(ChatWsNewMessage(msg));
  }

  void _onMessageRead(dynamic data) {
    final map = _toMap(data);
    final id = _string(map?['messageId']) ?? _string(map?['message_id']);
    _eventController.add(ChatWsMessageRead(id));
  }

  void _onUserTyping(dynamic data) {
    final map = _toMap(data);
    final name = _string(map?['senderName']) ?? _string(map?['sender_name']) ?? '';
    final isTyping = map?['isTyping'] as bool? ?? map?['is_typing'] as bool? ?? false;
    _eventController.add(ChatWsUserTyping(name, isTyping));
  }

  void _onUserOnline(dynamic data) {
    final map = _toMap(data);
    final userName = _string(map?['userName']) ?? _string(map?['user_name']) ?? '';
    final userType = _string(map?['userType']) ?? _string(map?['user_type']) ?? '';
    final bookingId = _string(map?['bookingId']) ?? _string(map?['booking_id']) ?? '';
    _eventController.add(ChatWsUserOnline(userName, userType, bookingId));
  }

  void _onUserOffline(dynamic data) {
    final map = _toMap(data);
    final userName = _string(map?['userName']) ?? _string(map?['user_name']) ?? '';
    final userType = _string(map?['userType']) ?? _string(map?['user_type']) ?? '';
    final bookingId = _string(map?['bookingId']) ?? _string(map?['booking_id']) ?? '';
    _eventController.add(ChatWsUserOffline(userName, userType, bookingId));
  }

  Map<String, dynamic>? _toMap(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  Message? _parseMessage(Map<String, dynamic>? json) {
    if (json == null) return null;
    try {
      // Server sends full Chat object directly, not nested
      return Message.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  static String? _string(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    if (v is num) return v.toString();
    return null;
  }

  /// Join a booking chat room with driver info.
  Future<void> joinBooking(String bookingId) async {
    final user = await _sessionRepository.getStoredUser();
    _socket?.emit('joinBooking', {
      'bookingId': bookingId,
      'userName': user?.name ?? 'Driver',
      'userType': 'driver',
    });
  }

  /// Leave a booking chat room.
  void leaveBooking(String bookingId) {
    _socket?.emit('leaveBooking', {'bookingId': bookingId});
  }

  /// Send typing status (driver).
  void sendTyping(String bookingId, String senderName, bool isTyping) {
    _socket?.emit('typing', {
      'bookingId': bookingId,
      'senderName': senderName,
      'isTyping': isTyping,
    });
  }

  /// Mark a message as read.
  void markAsRead(String messageId) {
    _socket?.emit('markAsRead', {'messageId': messageId});
  }

  /// Disconnect and release.
  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    _socket?.off('newMessage');
    _socket?.off('messageRead');
    _socket?.off('userTyping');
    _socket?.off('userOnline');
    _socket?.off('userOffline');
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  /// Close the broadcast stream.
  void close() {
    disconnect();
    _eventController.close();
  }
}
