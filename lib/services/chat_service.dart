import 'dart:convert';

import '../core/constants/app_constraints.dart';
import '../core/utils/json_utils.dart';
import '../domain/core/api_exception.dart';
import 'api_service.dart';

/// Service for chat-related API calls (uses [ApiService] for auth + refresh).
class ChatService {
  ChatService(this._apiService);

  final ApiService _apiService;

  /// GET [AppConstraints.chatsMy]. Returns response body as [Map]. Throws [ApiException] on non-2xx.
  Future<Map<String, dynamic>> getMyChats() async {
    final body = await _apiService.get(AppConstraints.chatsMy);
    final decoded = JsonUtils.decodeResponse(body);
    if (decoded is! Map<String, dynamic>) {
      return <String, dynamic>{'data': decoded};
    }
    return decoded;
  }

  /// GET /chats/booking/number/[bookingNumber] with query [page], [limit].
  /// Returns response body as [Map] (e.g. data list + meta). Throws [ApiException] on non-2xx.
  Future<Map<String, dynamic>> getMessages(
    String bookingNumber, {
    int page = 1,
    int limit = 50,
  }) async {
    final path = AppConstraints.chatsBookingByNumber(bookingNumber);
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    final body = await _apiService.get(path, queryParameters: queryParams);
    final decoded = JsonUtils.decodeResponse(body);
    if (decoded is! Map<String, dynamic>) {
      return <String, dynamic>{'data': decoded};
    }
    return decoded;
  }

  /// POST [AppConstraints.chats] with body { bookingId, message, type }.
  /// Returns response body as [Map]. Throws [ApiException] on non-2xx.
  Future<Map<String, dynamic>> sendMessage(
    String bookingId,
    String message, {
    String type = 'text',
  }) async {
    final body = json.encode(<String, dynamic>{
      'bookingId': bookingId,
      'message': message,
      'type': type,
    });
    final responseBody = await _apiService.post(AppConstraints.chats, body: body);
    final decoded = JsonUtils.decodeResponse(responseBody);
    if (decoded is! Map<String, dynamic>) {
      return <String, dynamic>{};
    }
    return decoded;
  }

  /// GET /chats/booking/:bookingId/online.
  /// Returns { bookingId, isOnline }. Throws [ApiException] on non-2xx.
  Future<bool> isCustomerOnline(String bookingId) async {
    final path = AppConstraints.chatsBookingOnline(bookingId);
    final body = await _apiService.get(path);
    final decoded = JsonUtils.decodeResponse(body);
    if (decoded is Map<String, dynamic>) {
      return decoded['isOnline'] as bool? ?? false;
    }
    return false;
  }
}
