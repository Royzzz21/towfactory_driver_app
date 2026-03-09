/// App-wide API paths and constraints.
abstract final class AppConstraints {
  /// Login endpoint for mobile (POST body: email, password; driver/customer only).
  static const String login = '/auth/login/mobile';

  /// Refresh token endpoint (POST body: refreshToken).
  static const String refresh = '/auth/refresh';

  /// Current user details (GET; requires Authorization: Bearer token).
  static const String me = '/auth/me';

  /// My bookings (GET; query: page, limit, search?, driverId?; requires Bearer token).
  static const String bookingsMy = '/bookings/my';

  /// Accept a pending booking (POST or PATCH; requires Bearer token).
  /// Use with [bookingAcceptPath(id)] for path with id.
  static String bookingAcceptPath(String bookingId) => '/bookings/$bookingId/accept';

  /// Mark driver arrived (PATCH; requires Bearer token).
  static String bookingArrivedPath(String bookingId) => '/bookings/$bookingId/arrived';

  /// Start a booking (PATCH; requires Bearer token).
  static String bookingStartPath(String bookingId) => '/bookings/$bookingId/start';

  /// Complete a booking (PATCH; requires Bearer token).
  static String bookingCompletePath(String bookingId) => '/bookings/$bookingId/complete';

  /// Cancel a booking (PATCH; requires Bearer token).
  static String bookingCancelPath(String bookingId) => '/bookings/$bookingId/cancel';

  /// Save ETA for a booking (PATCH; requires Bearer token).
  static String bookingEtaPath(String bookingId) => '/bookings/$bookingId/eta';

  /// My chats/conversations (GET; requires Bearer token).
  static const String chatsMy = '/chats/my';

  /// Chats/messages for a booking (GET; query: page, limit, bookingId; requires Bearer token).
  static const String chats = '/chats';

  /// Messages for a booking by number (GET /chats/booking/number/:number; query: page, limit).
  static String chatsBookingByNumber(String bookingNumber) => '/chats/booking/number/$bookingNumber';

  /// Check if customer is online for a booking (GET /chats/booking/:id/online).
  static String chatsBookingOnline(String bookingId) => '/chats/booking/$bookingId/online';
}
