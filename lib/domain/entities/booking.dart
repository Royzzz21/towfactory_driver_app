/// A single booking from GET /bookings/my.
class Booking {
  const Booking({
    required this.id,
    this.bookingNumber,
    this.customerName,
    this.customerPhone,
    this.vehicleInfo,
    this.pickupAddress,
    this.dropoffAddress,
    this.type,
    this.status,
    this.scheduledAt,
    this.distance,
    this.estimatedCost,
    this.chatLink,
    this.lastMessage,
    this.lastMessageAt,
  });

  final String id;
  final String? bookingNumber;
  final String? customerName;
  final String? customerPhone;
  final String? vehicleInfo;
  final String? pickupAddress;
  final String? dropoffAddress;
  final String? type;
  final String? status;
  final String? scheduledAt;
  final String? distance;
  final String? estimatedCost;
  final String? chatLink;
  /// Last message preview for chat list (e.g. from conversations API or booking payload).
  final String? lastMessage;
  /// ISO date-time of last message, for "2m ago" style display.
  final String? lastMessageAt;

  static Booking fromJson(Map<String, dynamic> json) {
    final pickup = json['pickup'] is Map<String, dynamic> ? json['pickup'] as Map<String, dynamic> : null;
    final dropoff = json['dropoff'] is Map<String, dynamic> ? json['dropoff'] as Map<String, dynamic> : null;
    return Booking(
      id: _stringFromJson(json['id']) ?? _stringFromJson(json['_id']) ?? '',
      bookingNumber: json['bookingNumber'] as String? ?? json['booking_number'] as String?,
      customerName: json['customerName'] as String? ?? json['customer_name'] as String?,
      customerPhone: json['customerPhone'] as String? ?? json['customer_phone'] as String?,
      vehicleInfo: json['vehicleInfo'] as String? ?? json['vehicle_info'] as String?,
      pickupAddress: pickup?['address'] as String?,
      dropoffAddress: dropoff?['address'] as String?,
      type: json['type'] as String?,
      status: json['status'] as String?,
      scheduledAt: json['scheduledAt'] as String? ?? json['scheduled_at'] as String?,
      distance: json['distance']?.toString(),
      estimatedCost: json['estimatedCost']?.toString() ?? json['estimated_cost']?.toString(),
      chatLink: json['chatLink'] as String? ?? json['chat_link'] as String?,
      lastMessage: json['lastMessage'] as String? ?? json['last_message'] as String?,
      lastMessageAt: json['lastMessageAt'] as String? ?? json['last_message_at'] as String?,
    );
  }

  static String? _stringFromJson(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is num) return value.toString();
    return null;
  }
}
