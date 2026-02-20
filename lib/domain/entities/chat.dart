import 'booking.dart';

/// A single chat/conversation from GET /chats/my.
class Chat {
  const Chat({
    required this.id,
    this.bookingId,
    this.bookingNumber,
    this.status,
    this.customerName,
    this.customerPhone,
    this.pickupAddress,
    this.dropoffAddress,
    this.chatLink,
    this.lastMessage,
    this.lastMessageAt,
    this.isOnline,
  });

  final String id;
  final String? bookingId;
  final String? bookingNumber;
  /// Booking status (e.g. pending, confirmed, ongoing, completed). Used to allow/block sending messages.
  final String? status;
  final String? customerName;
  final String? customerPhone;
  final String? pickupAddress;
  final String? dropoffAddress;
  final String? chatLink;
  final String? lastMessage;
  final String? lastMessageAt;
  /// Whether the other party (customer) is online. From API when available.
  final bool? isOnline;

  /// True when the booking is in an active state (driver can send messages).
  bool get isBookingActive {
    final s = status?.toLowerCase().trim();
    if (s == null || s.isEmpty) return false;
    switch (s) {
      case 'confirmed':
      case 'arrived_pickup':
      case 'ongoing':
      case 'active':
      case 'in_progress':
      case 'in progress':
      case 'arrived_dropoff':
        return true;
      default:
        return false;
    }
  }

  /// Builds a [Chat] from a [Booking] so the conversation screen can be opened from booking details.
  static Chat fromBooking(Booking booking) {
    return Chat(
      id: booking.id,
      bookingId: booking.id,
      bookingNumber: booking.bookingNumber,
      status: booking.status,
      customerName: booking.customerName,
      customerPhone: booking.customerPhone,
      pickupAddress: booking.pickupAddress,
      dropoffAddress: booking.dropoffAddress,
      chatLink: booking.chatLink,
      lastMessage: booking.lastMessage,
      lastMessageAt: booking.lastMessageAt,
    );
  }

  static Chat fromJson(Map<String, dynamic> json) {
    return Chat(
      id: _stringFromJson(json['id']) ?? _stringFromJson(json['_id']) ?? '',
      bookingId: _stringFromJson(json['bookingId']) ?? _stringFromJson(json['booking_id']),
      bookingNumber: _stringFromJson(json['bookingNumber']) ?? _stringFromJson(json['booking_number']),
      status: json['status'] as String?,
      customerName: _stringOrFromMap(json['customerName'], json['customer_name'], ['name', 'customerName']),
      customerPhone: _stringOrFromMap(json['customerPhone'], json['customer_phone'], ['phone', 'customerPhone']),
      pickupAddress: _stringOrFromMap(json['pickupAddress'], json['pickup_address'], ['address']),
      dropoffAddress: _stringOrFromMap(json['dropoffAddress'], json['dropoff_address'], ['address']),
      chatLink: _stringFromJson(json['chatLink']) ?? _stringFromJson(json['chat_link']),
      lastMessage: _stringOrFromMap(json['lastMessage'], json['last_message'], ['text', 'content', 'body']),
      lastMessageAt: _stringFromJson(json['lastMessageAt']) ?? _stringFromJson(json['last_message_at']),
      isOnline: json['isOnline'] as bool? ?? json['is_online'] as bool?,
    );
  }

  static String? _stringFromJson(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is num) return value.toString();
    return null;
  }

  /// Handles API returning either a string or a Map (e.g. pickup: { address: "..." }).
  static String? _stringOrFromMap(dynamic a, dynamic b, List<String> keys) {
    final s = _stringFromJson(a);
    if (s != null && s.isNotEmpty) return s;
    final s2 = _stringFromJson(b);
    if (s2 != null && s2.isNotEmpty) return s2;
    final map = (a is Map<String, dynamic> ? a : null) ?? (b is Map<String, dynamic> ? b : null);
    if (map == null) return null;
    for (final k in keys) {
      final v = map[k];
      final str = _stringFromJson(v);
      if (str != null && str.isNotEmpty) return str;
    }
    return null;
  }
}
