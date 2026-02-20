import 'package:equatable/equatable.dart';

/// Booking bloc events.
abstract class BookingEvent extends Equatable {
  const BookingEvent();

  @override
  List<Object?> get props => [];
}

/// Load bookings (initial or refresh). [page] 1 = first page; omit for refresh (page 1).
class LoadBookings extends BookingEvent {
  const LoadBookings({
    required this.driverId,
    this.page = 1,
    this.limit = 10,
    this.search,
  });

  final String driverId;
  final int page;
  final int limit;
  final String? search;

  @override
  List<Object?> get props => [driverId, page, limit, search];
}

/// Load next page (append to current list). Requires current state to be [BookingLoaded].
class LoadMoreBookings extends BookingEvent {
  const LoadMoreBookings({required this.driverId});

  final String driverId;

  @override
  List<Object?> get props => [driverId];
}

/// Refresh bookings (reload page 1).
class RefreshBookings extends BookingEvent {
  const RefreshBookings({required this.driverId});

  final String driverId;

  @override
  List<Object?> get props => [driverId];
}

/// Accept a pending booking. Refreshes the list after success.
class AcceptBooking extends BookingEvent {
  const AcceptBooking({
    required this.bookingId,
    required this.driverId,
  });

  final String bookingId;
  final String driverId;

  @override
  List<Object?> get props => [bookingId, driverId];
}

/// Mark driver arrived at [location] (e.g. "pickup", "dropoff"). Refreshes the list after success.
class ArrivedBooking extends BookingEvent {
  const ArrivedBooking({
    required this.bookingId,
    required this.driverId,
    this.location = 'pickup',
  });

  final String bookingId;
  final String driverId;
  final String location;

  @override
  List<Object?> get props => [bookingId, driverId, location];
}

/// Start a booking. Refreshes the list after success.
class StartBooking extends BookingEvent {
  const StartBooking({
    required this.bookingId,
    required this.driverId,
  });

  final String bookingId;
  final String driverId;

  @override
  List<Object?> get props => [bookingId, driverId];
}

/// Complete a booking. Refreshes the list after success.
class CompleteBooking extends BookingEvent {
  const CompleteBooking({
    required this.bookingId,
    required this.driverId,
  });

  final String bookingId;
  final String driverId;

  @override
  List<Object?> get props => [bookingId, driverId];
}

/// Cancel a booking. Refreshes the list after success.
class CancelBooking extends BookingEvent {
  const CancelBooking({
    required this.bookingId,
    required this.driverId,
  });

  final String bookingId;
  final String driverId;

  @override
  List<Object?> get props => [bookingId, driverId];
}
