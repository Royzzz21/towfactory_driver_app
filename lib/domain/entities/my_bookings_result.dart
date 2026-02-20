import 'booking.dart';

/// Result of GET /bookings/my (paginated list + metadata).
/// Supports response shape: { activeBookingId?, data: [...], meta: { total, page, limit, totalPages } }.
class MyBookingsResult {
  const MyBookingsResult(this.raw);

  /// Raw response map.
  final Map<String, dynamic> raw;

  /// List of booking items (from [raw]['data'] or []).
  List<dynamic> get dataRaw => raw['data'] is List<dynamic> ? raw['data'] as List<dynamic> : <dynamic>[];

  /// Parsed list of [Booking].
  List<Booking> get data {
    final list = dataRaw;
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => Booking.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Active booking id if provided by API.
  String? get activeBookingId => raw['activeBookingId'] as String? ?? raw['active_booking_id'] as String?;

  /// Meta object (total, page, limit, totalPages).
  Map<String, dynamic> get meta => raw['meta'] is Map<String, dynamic> ? raw['meta'] as Map<String, dynamic> : <String, dynamic>{};

  /// Total count from [meta].
  int get total {
    final m = meta;
    if (m['total'] is int) return m['total'] as int;
    if (m['total'] is num) return (m['total'] as num).toInt();
    return 0;
  }

  /// Current page (1-based) from [meta].
  int get page {
    final m = meta;
    if (m['page'] is int) return m['page'] as int;
    if (m['page'] is num) return (m['page'] as num).toInt();
    return 1;
  }

  /// Page size from [meta].
  int get limit {
    final m = meta;
    if (m['limit'] is int) return m['limit'] as int;
    if (m['limit'] is num) return (m['limit'] as num).toInt();
    return 10;
  }

  /// Total pages from [meta].
  int get totalPages {
    final m = meta;
    if (m['totalPages'] is int) return m['totalPages'] as int;
    if (m['total_pages'] is int) return m['total_pages'] as int;
    if (m['totalPages'] is num) return (m['totalPages'] as num).toInt();
    if (m['total_pages'] is num) return (m['total_pages'] as num).toInt();
    return 1;
  }
}
