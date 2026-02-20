import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/core/api_exception.dart';
import '../domain/core/refresh_token_result.dart';
import '../domain/entities/my_user.dart';
import '../domain/repositories/session_repository.dart';
import '../domain/storage/session_storage.dart';

/// Central API client that adds [Authorization: Bearer] and handles 401 by
/// refreshing the token and retrying once. If refresh fails, clears session
/// and calls [onRefreshFailed] (e.g. trigger logout).
class ApiService {
  ApiService({
    required this.baseUrl,
    required SessionRepository sessionRepository,
    required SessionStorage sessionStorage,
    required Future<RefreshTokenResult> Function(String refreshToken) refreshTokenCallback,
    required void Function() onRefreshFailed,
  })  : _sessionRepository = sessionRepository,
        _sessionStorage = sessionStorage,
        _refreshTokenCallback = refreshTokenCallback,
        _onRefreshFailed = onRefreshFailed;

  final String baseUrl;
  final SessionRepository _sessionRepository;
  final SessionStorage _sessionStorage;
  final Future<RefreshTokenResult> Function(String refreshToken) _refreshTokenCallback;
  final void Function() _onRefreshFailed;

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Map<String, String> _authHeaders(String accessToken) => {
        ..._jsonHeaders,
        'Authorization': 'Bearer $accessToken',
      };

  /// GET [path] with optional [queryParameters]. Uses current access token. On 401: refresh and retry once;
  /// if refresh fails, clear session, call [onRefreshFailed], and throw.
  Future<String> get(String path, {Map<String, String>? queryParameters}) async {
    final user = await _sessionRepository.getStoredUser();
    if (user == null || user.token.isEmpty) {
      _onRefreshFailed();
      throw ApiException('Not authenticated', 401);
    }
    var uri = Uri.parse('$baseUrl$path');
    if (queryParameters != null && queryParameters.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParameters);
    }
    final response = await http.get(uri, headers: _authHeaders(user.token));
    if (response.statusCode == 401) {
      return _on401Get(uri, user, response);
    }
    _throwIfNotSuccess(response, path);
    return response.body;
  }

  Future<String> _on401Get(Uri uri, MyUser user, http.Response response) async {
    final refreshToken = user.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      await _sessionStorage.clearSession();
      _onRefreshFailed();
      throw ApiException('Unauthorized', 401);
    }
    try {
      final result = await _refreshTokenCallback(refreshToken);
      final updatedUser = user.copyWith(
        token: result.accessToken,
        refreshToken: result.refreshToken ?? user.refreshToken,
      );
      await _sessionRepository.saveSession(updatedUser);
      final retryResponse = await http.get(uri, headers: _authHeaders(updatedUser.token));
      if (retryResponse.statusCode == 401) {
        await _sessionStorage.clearSession();
        _onRefreshFailed();
        throw ApiException('Unauthorized', 401);
      }
      _throwIfNotSuccess(retryResponse, uri.path);
      return retryResponse.body;
    } catch (e) {
      await _sessionStorage.clearSession();
      _onRefreshFailed();
      rethrow;
    }
  }

  /// POST [path] with [body] and current access token. Same 401/refresh/retry logic as [get].
  Future<String> post(String path, {String? body}) async {
    final user = await _sessionRepository.getStoredUser();
    if (user == null || user.token.isEmpty) {
      _onRefreshFailed();
      throw ApiException('Not authenticated', 401);
    }
    final uri = Uri.parse('$baseUrl$path');
    final response = await http.post(
      uri,
      headers: _authHeaders(user.token),
      body: body,
    );
    if (response.statusCode == 401) {
      return _on401Post(uri, user, path, body);
    }
    _throwIfNotSuccess(response, path);
    return response.body;
  }

  Future<String> _on401Post(Uri uri, MyUser user, String path, String? body) async {
    final refreshToken = user.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      await _sessionStorage.clearSession();
      _onRefreshFailed();
      throw ApiException('Unauthorized', 401);
    }
    try {
      final result = await _refreshTokenCallback(refreshToken);
      final updatedUser = user.copyWith(
        token: result.accessToken,
        refreshToken: result.refreshToken ?? user.refreshToken,
      );
      await _sessionRepository.saveSession(updatedUser);
      final retryResponse = await http.post(
        uri,
        headers: _authHeaders(updatedUser.token),
        body: body,
      );
      if (retryResponse.statusCode == 401) {
        await _sessionStorage.clearSession();
        _onRefreshFailed();
        throw ApiException('Unauthorized', 401);
      }
      _throwIfNotSuccess(retryResponse, path);
      return retryResponse.body;
    } catch (e) {
      await _sessionStorage.clearSession();
      _onRefreshFailed();
      rethrow;
    }
  }

  /// PATCH [path] with optional [body]. Same 401/refresh/retry logic as [get].
  Future<String> patch(String path, {String? body}) async {
    final user = await _sessionRepository.getStoredUser();
    if (user == null || user.token.isEmpty) {
      _onRefreshFailed();
      throw ApiException('Not authenticated', 401);
    }
    final uri = Uri.parse('$baseUrl$path');
    final response = await http.patch(
      uri,
      headers: _authHeaders(user.token),
      body: body,
    );
    if (response.statusCode == 401) {
      return _on401Patch(uri, user, path, body);
    }
    _throwIfNotSuccess(response, path);
    return response.body;
  }

  Future<String> _on401Patch(Uri uri, MyUser user, String path, String? body) async {
    final refreshToken = user.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      await _sessionStorage.clearSession();
      _onRefreshFailed();
      throw ApiException('Unauthorized', 401);
    }
    try {
      final result = await _refreshTokenCallback(refreshToken);
      final updatedUser = user.copyWith(
        token: result.accessToken,
        refreshToken: result.refreshToken ?? user.refreshToken,
      );
      await _sessionRepository.saveSession(updatedUser);
      final retryResponse = await http.patch(
        uri,
        headers: _authHeaders(updatedUser.token),
        body: body,
      );
      if (retryResponse.statusCode == 401) {
        await _sessionStorage.clearSession();
        _onRefreshFailed();
        throw ApiException('Unauthorized', 401);
      }
      _throwIfNotSuccess(retryResponse, path);
      return retryResponse.body;
    } catch (e) {
      await _sessionStorage.clearSession();
      _onRefreshFailed();
      rethrow;
    }
  }

  void _throwIfNotSuccess(http.Response response, String path) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final bodyMap = _tryDecode(response.body);
    final msg = bodyMap?['message'] as String? ??
        bodyMap?['msg'] as String? ??
        response.reasonPhrase ??
        'Request failed';
    throw ApiException(msg, response.statusCode, null);
  }

  static Map<String, dynamic>? _tryDecode(String raw) {
    try {
      return json.decode(raw) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }
}
