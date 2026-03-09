import '../entities/accept_booking_result.dart';
import '../entities/my_bookings_result.dart';

/// Repository interface for booking operations.
abstract class BookingRepository {
  /// Fetches "my" bookings with pagination and optional filters.
  /// Throws [ApiException] on failure.
  Future<MyBookingsResult> getMyBookings({
    required int page,
    required int limit,
    String? search,
    String? driverId,
  });

  /// Accepts a pending booking. Returns API response (message + booking). Throws [ApiException] on failure.
  Future<AcceptBookingResult> acceptBooking(String bookingId);

  /// Marks driver arrived at [location] (e.g. "pickup", "dropoff"). Throws [ApiException] on failure.
  Future<void> arrivedBooking(String bookingId, {String location = 'pickup'});

  /// Starts a booking (confirmed/arrived_pickup → ongoing). Throws [ApiException] on failure.
  Future<void> startBooking(String bookingId);

  /// Completes a booking (ongoing/arrived_dropoff → completed). Throws [ApiException] on failure.
  Future<void> completeBooking(String bookingId);

  /// Cancels a booking. Throws [ApiException] on failure.
  Future<void> cancelBooking(String bookingId);

  /// Saves ETA text to the database. Only one of the parameters needs to be provided.
  Future<void> saveEta(String bookingId, {String? etaToPickup, String? etaToDropoff});
}
