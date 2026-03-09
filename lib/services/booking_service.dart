import 'dart:convert';

import '../core/constants/app_constraints.dart';
import '../core/utils/json_utils.dart';
import '../domain/core/api_exception.dart';
import 'api_service.dart';

/// Service for booking-related API calls (uses [ApiService] for auth + refresh).
class BookingService {
  BookingService(this._apiService);

  final ApiService _apiService;

  /// GET [AppConstraints.bookingsMy] with [page], [limit], optional [search] and [driverId].
  /// Returns the response body as a [Map]. Throws [ApiException] on non-2xx.
  Future<Map<String, dynamic>> getMyBookings({
    required int page,
    required int limit,
    String? search,
    String? driverId,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (driverId != null && driverId.trim().isNotEmpty) {
      queryParams['driverId'] = driverId.trim();
    }
    final body = await _apiService.get(
      AppConstraints.bookingsMy,
      queryParameters: queryParams,
    );
    final decoded = JsonUtils.decodeResponse(body);
    if (decoded is! Map<String, dynamic>) {
      return <String, dynamic>{'data': decoded};
    }
    return decoded;
  }

  /// PATCH /bookings/:id/accept. Returns { message, booking }. Throws [ApiException] on failure.
  Future<Map<String, dynamic>> acceptBooking(String bookingId) async {
    final path = AppConstraints.bookingAcceptPath(bookingId);
    final body = await _apiService.patch(path);
    final decoded = JsonUtils.decodeResponse(body);
    if (decoded is! Map<String, dynamic>) {
      return <String, dynamic>{'message': 'Booking accepted successfully'};
    }
    return decoded;
  }

  /// PATCH /bookings/:id/arrived. [location] e.g. "pickup" or "dropoff" sent in body. Throws [ApiException] on failure.
  Future<void> arrivedBooking(String bookingId, {String location = 'pickup'}) async {
    final path = AppConstraints.bookingArrivedPath(bookingId);
    final body = json.encode(<String, String>{'location': location});
    await _apiService.patch(path, body: body);
  }

  /// PATCH /bookings/:id/start. Throws [ApiException] on failure.
  Future<void> startBooking(String bookingId) async {
    final path = AppConstraints.bookingStartPath(bookingId);
    await _apiService.patch(path);
  }

  /// PATCH /bookings/:id/complete. Throws [ApiException] on failure.
  Future<void> completeBooking(String bookingId) async {
    final path = AppConstraints.bookingCompletePath(bookingId);
    await _apiService.patch(path);
  }

  /// PATCH /bookings/:id/cancel. Throws [ApiException] on failure.
  Future<void> cancelBooking(String bookingId) async {
    final path = AppConstraints.bookingCancelPath(bookingId);
    await _apiService.patch(path);
  }

  /// PATCH /bookings/:id/eta. Saves ETA text to DB. Throws [ApiException] on failure.
  Future<void> saveEta(String bookingId, {String? etaToPickup, String? etaToDropoff}) async {
    final path = AppConstraints.bookingEtaPath(bookingId);
    final body = json.encode(<String, String?>{
      if (etaToPickup != null) 'etaToPickup': etaToPickup,
      if (etaToDropoff != null) 'etaToDropoff': etaToDropoff,
    });
    await _apiService.patch(path, body: body);
  }
}
