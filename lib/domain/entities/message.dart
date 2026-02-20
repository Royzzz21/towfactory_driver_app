/// A single message from GET /bookings/:id/messages (or similar).
class Message {
  const Message({
    required this.id,
    this.bookingId,
    this.senderId,
    this.senderName,
    this.senderType,
    required this.message,
    this.type,
    this.isRead,
    this.createdAt,
  });

  final String id;
  final String? bookingId;
  final String? senderId;
  final String? senderName;
  final String? senderType;
  final String message;
  final String? type;
  final bool? isRead;
  final String? createdAt;

  /// True if sent by driver or admin (show on right). False if customer/guest/user (show on left).
  bool get isFromMe {
    final t = senderType?.toLowerCase();
    if (t == null || t.isEmpty) return false;
    return t == 'driver' || t == 'admin' || t == 'system';
  }

  Message copyWith({
    String? id,
    String? bookingId,
    String? senderId,
    String? senderName,
    String? senderType,
    String? message,
    String? type,
    bool? isRead,
    String? createdAt,
  }) {
    return Message(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderType: senderType ?? this.senderType,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static Message fromJson(Map<String, dynamic> json) {
    final body = _messageBody(json);
    return Message(
      id: _stringFromJson(json['id']) ?? '',
      bookingId: _stringFromJson(json['bookingId']) ?? _stringFromJson(json['booking_id']),
      senderId: _stringFromJson(json['senderId']) ?? _stringFromJson(json['sender_id']),
      senderName: json['senderName'] as String? ?? json['sender_name'] as String?,
      senderType: json['senderType'] as String? ?? json['sender_type'] as String?,
      message: body,
      type: json['type'] as String?,
      isRead: json['isRead'] as bool? ?? json['is_read'] as bool?,
      createdAt: json['createdAt'] as String? ?? json['created_at'] as String?,
    );
  }

  static String _messageBody(Map<String, dynamic> json) {
    final msg = json['message'];
    if (msg is String) return msg;
    if (msg is Map<String, dynamic>) {
      final fromMap = (msg['text'] as String?) ?? (msg['content'] as String?) ?? (msg['body'] as String?) ?? (msg['message'] as String?);
      if (fromMap != null) return fromMap;
    }
    final text = (json['text'] as String?) ?? (json['content'] as String?) ?? (json['body'] as String?);
    return text ?? '';
  }

  static String? _stringFromJson(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is num) return value.toString();
    return null;
  }
}
