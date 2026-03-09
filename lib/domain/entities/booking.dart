/// A single booking from GET /bookings/my.
class Booking {
  const Booking({
    required this.id,
    this.bookingNumber,
    this.customerName,
    this.customerPhone,
    this.vehicleInfo,
    this.pickupAddress,
    this.pickupLat,
    this.pickupLng,
    this.dropoffAddress,
    this.dropoffLat,
    this.dropoffLng,
    this.type,
    this.etaToPickup,
    this.etaToDropoff,
    this.status,
    this.scheduledAt,
    this.distance,
    this.estimatedCost,
    this.chatLink,
    this.lastMessage,
    this.lastMessageAt,
    this.confirmedAt,
    this.arrivedPickupAt,
    this.startedAt,
    this.arrivedDropoffAt,
    this.completedAt,
    this.isPriority = false,
    this.addOns = const [],
    this.notes,
  });

  final String id;
  final String? bookingNumber;
  final String? customerName;
  final String? customerPhone;
  final String? vehicleInfo;
  final String? notes;
  final String? pickupAddress;
  final double? pickupLat;
  final double? pickupLng;
  final String? dropoffAddress;
  final double? dropoffLat;
  final double? dropoffLng;
  final String? type;
  final String? etaToPickup;
  final String? etaToDropoff;
  final String? status;
  final String? scheduledAt;
  final String? distance;
  final String? estimatedCost;
  final String? chatLink;
  /// Last message preview for chat list (e.g. from conversations API or booking payload).
  final String? lastMessage;
  /// ISO date-time of last message, for "2m ago" style display.
  final String? lastMessageAt;
  final String? confirmedAt;
  final String? arrivedPickupAt;
  final String? startedAt;
  final String? arrivedDropoffAt;
  final String? completedAt;
  final bool isPriority;
  final List<Map<String, dynamic>> addOns;

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
      pickupLat: (pickup?['lat'] as num?)?.toDouble(),
      pickupLng: (pickup?['lng'] as num?)?.toDouble(),
      dropoffAddress: dropoff?['address'] as String?,
      dropoffLat: (dropoff?['lat'] as num?)?.toDouble(),
      dropoffLng: (dropoff?['lng'] as num?)?.toDouble(),
      type: json['type'] as String?,
      etaToPickup: json['etaToPickup'] as String? ?? json['eta_to_pickup'] as String?,
      etaToDropoff: json['etaToDropoff'] as String? ?? json['eta_to_dropoff'] as String?,
      status: json['status'] as String?,
      scheduledAt: json['scheduledAt'] as String? ?? json['scheduled_at'] as String?,
      distance: json['distance']?.toString(),
      estimatedCost: json['estimatedCost']?.toString() ?? json['estimated_cost']?.toString(),
      chatLink: json['chatLink'] as String? ?? json['chat_link'] as String?,
      lastMessage: json['lastMessage'] as String? ?? json['last_message'] as String?,
      lastMessageAt: json['lastMessageAt'] as String? ?? json['last_message_at'] as String?,
      confirmedAt: json['confirmedAt'] as String? ?? json['confirmed_at'] as String?,
      arrivedPickupAt: json['arrivedPickupAt'] as String? ?? json['arrived_pickup_at'] as String?,
      startedAt: json['startedAt'] as String? ?? json['started_at'] as String?,
      arrivedDropoffAt: json['arrivedDropoffAt'] as String? ?? json['arrived_dropoff_at'] as String?,
      completedAt: json['completedAt'] as String? ?? json['completed_at'] as String?,
      isPriority: json['isPriority'] as bool? ?? json['is_priority'] as bool? ?? false,
      addOns: (json['addOns'] as List<dynamic>? ?? json['add_ons'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList(),
      notes: json['notes'] as String?,
    );
  }

  static String? _stringFromJson(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is num) return value.toString();
    return null;
  }
}
