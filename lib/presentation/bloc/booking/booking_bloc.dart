import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/core/api_exception.dart';
import '../../../domain/entities/my_bookings_result.dart';
import '../../../domain/repositories/booking_repository.dart';
import 'booking_event.dart';
import 'booking_state.dart';

/// Bloc for "my" bookings list: load, refresh, load more.
class BookingBloc extends Bloc<BookingEvent, BookingState> {
  BookingBloc(this._repository) : super(const BookingInitial()) {
    on<LoadBookings>(_onLoadBookings);
    on<LoadMoreBookings>(_onLoadMoreBookings);
    on<RefreshBookings>(_onRefreshBookings);
    on<AcceptBooking>(_onAcceptBooking);
    on<ArrivedBooking>(_onArrivedBooking);
    on<StartBooking>(_onStartBooking);
    on<CompleteBooking>(_onCompleteBooking);
    on<CancelBooking>(_onCancelBooking);
  }

  final BookingRepository _repository;

  Future<void> _onLoadBookings(
    LoadBookings event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading(isLoadMore: false));
    try {
      final result = await _repository.getMyBookings(
        page: event.page,
        limit: event.limit,
        search: event.search,
        driverId: event.driverId,
      );
      emit(BookingLoaded(result: result, bookings: result.data));
    } catch (e) {
      emit(BookingError(ApiException.cleanMessage(e)));
    }
  }

  Future<void> _onLoadMoreBookings(
    LoadMoreBookings event,
    Emitter<BookingState> emit,
  ) async {
    final current = state;
    if (current is! BookingLoaded || !current.hasMore || current.isFetchingMore) return;
    // Keep existing bookings visible, just show a footer loader
    emit(BookingLoaded(
      result: current.result,
      bookings: current.bookings,
      isFetchingMore: true,
    ));
    try {
      final nextPage = current.page + 1;
      final result = await _repository.getMyBookings(
        page: nextPage,
        limit: current.result.limit,
        search: null,
        driverId: event.driverId,
      );
      final merged = [...current.bookings, ...result.data];
      final mergedRaw = {
        ...current.result.raw,
        'data': [...current.result.dataRaw, ...result.dataRaw],
        'meta': result.raw['meta'],
      };
      emit(BookingLoaded(
        result: MyBookingsResult(mergedRaw),
        bookings: merged,
      ));
    } catch (e) {
      emit(BookingError(ApiException.cleanMessage(e)));
      emit(current);
    }
  }

  Future<void> _onRefreshBookings(
    RefreshBookings event,
    Emitter<BookingState> emit,
  ) async {
    add(LoadBookings(driverId: event.driverId));
  }

  Future<void> _onAcceptBooking(
    AcceptBooking event,
    Emitter<BookingState> emit,
  ) async {
    try {
      final result = await _repository.acceptBooking(event.bookingId);
      emit(AcceptBookingSuccess(result.message));
      add(LoadBookings(driverId: event.driverId));
    } catch (e) {
      emit(BookingError(ApiException.cleanMessage(e)));
    }
  }

  Future<void> _onArrivedBooking(
    ArrivedBooking event,
    Emitter<BookingState> emit,
  ) async {
    try {
      await _repository.arrivedBooking(event.bookingId, location: event.location);
      final message = event.location == 'pickup'
          ? 'Arrived at pickup location'
          : event.location == 'dropoff'
              ? 'Arrived at drop-off location'
              : 'Arrived marked successfully';
      emit(ArrivedBookingSuccess(message));
      add(LoadBookings(driverId: event.driverId));
    } catch (e) {
      emit(BookingError(ApiException.cleanMessage(e)));
    }
  }

  Future<void> _onStartBooking(
    StartBooking event,
    Emitter<BookingState> emit,
  ) async {
    try {
      await _repository.startBooking(event.bookingId);
      emit(const StartBookingSuccess('Booking started'));
      add(LoadBookings(driverId: event.driverId));
    } catch (e) {
      emit(BookingError(ApiException.cleanMessage(e)));
    }
  }

  Future<void> _onCompleteBooking(
    CompleteBooking event,
    Emitter<BookingState> emit,
  ) async {
    try {
      await _repository.completeBooking(event.bookingId);
      emit(const CompleteBookingSuccess('Booking completed'));
      add(LoadBookings(driverId: event.driverId));
    } catch (e) {
      emit(BookingError(ApiException.cleanMessage(e)));
    }
  }

  Future<void> _onCancelBooking(
    CancelBooking event,
    Emitter<BookingState> emit,
  ) async {
    try {
      await _repository.cancelBooking(event.bookingId);
      emit(const CancelBookingSuccess('Booking cancelled'));
      add(LoadBookings(driverId: event.driverId));
    } catch (e) {
      emit(BookingError(ApiException.cleanMessage(e)));
    }
  }
}
