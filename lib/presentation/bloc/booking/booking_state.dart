import 'package:equatable/equatable.dart';

import '../../../domain/entities/booking.dart';
import '../../../domain/entities/my_bookings_result.dart';

/// Booking bloc states.
abstract class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object?> get props => [];
}

class BookingInitial extends BookingState {
  const BookingInitial();
}

class BookingLoading extends BookingState {
  const BookingLoading({this.isLoadMore = false});

  final bool isLoadMore;

  @override
  List<Object?> get props => [isLoadMore];
}

class BookingLoaded extends BookingState {
  const BookingLoaded({
    required this.result,
    required this.bookings,
    this.isFetchingMore = false,
  });

  /// Latest API result (meta, etc.).
  final MyBookingsResult result;

  /// Accumulated list of bookings (all pages so far).
  final List<Booking> bookings;

  /// True while a load-more fetch is in progress (existing list stays visible).
  final bool isFetchingMore;

  int get page => result.page;
  int get totalPages => result.totalPages;
  bool get hasMore => page < totalPages;

  /// Active booking id from API (e.g. current in-progress booking).
  String? get activeBookingId => result.activeBookingId;

  @override
  List<Object?> get props => [result, bookings, isFetchingMore];
}

class BookingError extends BookingState {
  const BookingError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Emitted while accept API call is in progress.
class AcceptBookingLoading extends BookingState {
  const AcceptBookingLoading();
}

/// Emitted after accept API success; UI can show [message] then list refreshes.
class AcceptBookingSuccess extends BookingState {
  const AcceptBookingSuccess(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Emitted after arrived API success; UI can show [message] then list refreshes.
class ArrivedBookingSuccess extends BookingState {
  const ArrivedBookingSuccess(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Emitted after start API success; UI can show [message] then list refreshes.
class StartBookingSuccess extends BookingState {
  const StartBookingSuccess(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Emitted after complete API success; UI can show [message] then list refreshes.
class CompleteBookingSuccess extends BookingState {
  const CompleteBookingSuccess(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Emitted after cancel API success; UI can show [message] then list refreshes.
class CancelBookingSuccess extends BookingState {
  const CancelBookingSuccess(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
