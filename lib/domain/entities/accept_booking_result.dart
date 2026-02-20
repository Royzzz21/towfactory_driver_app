import 'booking.dart';

/// Response from PATCH /bookings/:id/accept.
/// Sample: { "message": "Booking accepted successfully", "booking": { "id", "bookingNumber", "status", "chatLink" } }
class AcceptBookingResult {
  const AcceptBookingResult({
    required this.message,
    this.booking,
  });

  final String message;
  final Booking? booking;

  factory AcceptBookingResult.fromJson(Map<String, dynamic> json) {
    final bookingRaw = json['booking'];
    Booking? booking;
    if (bookingRaw is Map<String, dynamic>) {
      booking = Booking.fromJson(Map<String, dynamic>.from(bookingRaw));
    }
    final message = json['message'] as String? ?? 'Booking accepted successfully';
    return AcceptBookingResult(message: message, booking: booking);
  }
}
