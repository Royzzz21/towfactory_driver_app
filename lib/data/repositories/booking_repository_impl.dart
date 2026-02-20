import '../../domain/entities/accept_booking_result.dart';
import '../../domain/entities/my_bookings_result.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../services/booking_service.dart';

class BookingRepositoryImpl implements BookingRepository {
  BookingRepositoryImpl(this._bookingService);

  final BookingService _bookingService;

  @override
  Future<MyBookingsResult> getMyBookings({
    required int page,
    required int limit,
    String? search,
    String? driverId,
  }) async {
    final map = await _bookingService.getMyBookings(
      page: page,
      limit: limit,
      search: search,
      driverId: driverId,
    );
    return MyBookingsResult(map);
  }

  @override
  Future<AcceptBookingResult> acceptBooking(String bookingId) async {
    final map = await _bookingService.acceptBooking(bookingId);
    return AcceptBookingResult.fromJson(map);
  }

  @override
  Future<void> arrivedBooking(String bookingId, {String location = 'pickup'}) async {
    await _bookingService.arrivedBooking(bookingId, location: location);
  }

  @override
  Future<void> startBooking(String bookingId) async {
    await _bookingService.startBooking(bookingId);
  }

  @override
  Future<void> completeBooking(String bookingId) async {
    await _bookingService.completeBooking(bookingId);
  }

  @override
  Future<void> cancelBooking(String bookingId) async {
    await _bookingService.cancelBooking(bookingId);
  }
}
