import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../core/constants/app_constraints.dart';
import '../core/utils/json_utils.dart';
import '../domain/core/api_exception.dart';
import '../domain/core/base_response.dart';
import '../domain/core/login_response.dart';
import '../domain/core/refresh_token_result.dart';
import '../domain/entities/login_request.dart';
import '../domain/entities/my_user.dart';
import '../domain/repositories/session_repository.dart';
import 'api_service.dart';

/// Default base URL when [.env] API_BASE_URL is not set.
const String _defaultBaseUrl = 'http://192.168.68.79:3001';

/// Service for auth API calls (login, refresh, getMe).
/// Authenticated calls (getMe) go through [ApiService] for refresh-token handling.
class AuthService {
  AuthService({
    String? baseUrl,
    ApiService? apiService,
    SessionRepository? sessionRepository,
  })  : _baseUrl = baseUrl ?? dotenv.env['API_BASE_URL'] ?? _defaultBaseUrl,
        _apiService = apiService,
        _sessionRepository = sessionRepository;

  final String _baseUrl;
  final ApiService? _apiService;
  final SessionRepository? _sessionRepository;

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  /// POST to [AppConstraints.login] with [payload] (email, password, type).
  /// 200: Returns [BaseResponse]<[LoginResponse]> (user + token).
  /// 401: Throws [ApiException] with message and optional errors.
  Future<BaseResponse<LoginResponse>> loginWithEmail(LoginRequest payload) async {
    final uri = Uri.parse('$_baseUrl${AppConstraints.login}');
    final body = json.encode(payload.toJson());

    final response = await http.post(
      uri,
      headers: _headers,
      body: body,
    );

    if (kDebugMode) {
      print('[AuthService] ${response.request?.url}');
      print('[AuthService] statusCode: ${response.statusCode}');
      print('[AuthService] body: ${response.body}');
    }

    if (response.statusCode == 401) {
      final bodyMap = _tryDecode(response.body);
      final msg = bodyMap?['message'] as String? ?? bodyMap?['msg'] as String? ?? 'Unauthorized';
      final errors = bodyMap?['errors'] as Map<String, dynamic>?;
      throw ApiException(msg, 401, errors != null ? Map<String, dynamic>.from(errors) : null);
    }

    if (response.statusCode == 422) {
      final bodyMap = _tryDecode(response.body);
      final msg = bodyMap?['message'] as String? ??
          bodyMap?['msg'] as String? ??
          'Validation failed';
      final errorsRaw = bodyMap?['errors'];
      final errorsMap = _parse422Errors(errorsRaw);
      throw ApiException(msg, 422, errorsMap);
    }

    // Treat 200 OK and 201 Created as success (API may return either).
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(
        response.reasonPhrase ?? 'Login failed',
        response.statusCode,
      );
    }

    final data = JsonUtils.decodeResponse(response.body) as Map<String, dynamic>;
    final inner = data['data'] as Map<String, dynamic>? ?? data;
    final loginResponse = BaseResponse<LoginResponse>(
      data: LoginResponse.fromJson(Map<String, dynamic>.from(inner)),
      message: data['message'] as String?,
    );
    return loginResponse;
  }

  /// POST to [AppConstraints.refresh] with [refreshToken].
  /// Returns new [RefreshTokenResult] (accessToken, refreshToken) on success.
  /// 401 / 4xx: Throws [ApiException].
  Future<RefreshTokenResult> refreshToken(String refreshToken) async {
    final uri = Uri.parse('$_baseUrl${AppConstraints.refresh}');
    final body = json.encode(<String, String>{'refreshToken': refreshToken});

    final response = await http.post(
      uri,
      headers: _headers,
      body: body,
    );

    if (response.statusCode == 401) {
      final bodyMap = _tryDecode(response.body);
      final msg = bodyMap?['message'] as String? ?? bodyMap?['msg'] as String? ?? 'Unauthorized';
      throw ApiException(msg, 401, null);
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      final bodyMap = _tryDecode(response.body);
      final msg = bodyMap?['message'] as String? ?? bodyMap?['msg'] as String? ?? response.reasonPhrase ?? 'Refresh failed';
      throw ApiException(msg, response.statusCode, null);
    }

    final data = JsonUtils.decodeResponse(response.body) as Map<String, dynamic>;
    final inner = data['data'] as Map<String, dynamic>? ?? data;
    return RefreshTokenResult.fromJson(Map<String, dynamic>.from(inner));
  }

  /// GET [AppConstraints.me] via [ApiService] (adds Bearer, handles 401 refresh/retry).
  /// Returns [MyUser]; token is taken from session (current or after refresh).
  Future<MyUser> getMe(String accessToken) async {
    final api = _apiService;
    final repo = _sessionRepository;
    if (api != null && repo != null) {
      final body = await api.get(AppConstraints.me);
      final data = JsonUtils.decodeResponse(body) as Map<String, dynamic>;
      Map<String, dynamic> inner = data['data'] as Map<String, dynamic>? ?? data;
      if (inner['user'] is Map<String, dynamic>) {
        inner = inner['user'] as Map<String, dynamic>;
      }
      final userJson = Map<String, dynamic>.from(inner);
      final currentUser = await repo.getStoredUser();
      userJson['token'] = currentUser?.token ?? accessToken;
      return MyUser.fromJson(userJson);
    }
    // Fallback: direct http (no refresh handling)
    final uri = Uri.parse('$_baseUrl${AppConstraints.me}');
    final headers = <String, String>{
      ..._headers,
      'Accept': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 401) {
      final bodyMap = _tryDecode(response.body);
      final msg = bodyMap?['message'] as String? ?? bodyMap?['msg'] as String? ?? 'Unauthorized';
      throw ApiException(msg, 401, null);
    }
    if (response.statusCode != 200) {
      final bodyMap = _tryDecode(response.body);
      final msg = bodyMap?['message'] as String? ?? bodyMap?['msg'] as String? ?? response.reasonPhrase ?? 'Failed to load user';
      throw ApiException(msg, response.statusCode, null);
    }
    final data = JsonUtils.decodeResponse(response.body) as Map<String, dynamic>;
    Map<String, dynamic> inner = data['data'] as Map<String, dynamic>? ?? data;
    if (inner['user'] is Map<String, dynamic>) {
      inner = inner['user'] as Map<String, dynamic>;
    }
    final userJson = Map<String, dynamic>.from(inner);
    userJson['token'] = accessToken;
    return MyUser.fromJson(userJson);
  }

  static Map<String, dynamic>? _tryDecode(String body) {
    try {
      return json.decode(body) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// Converts 422 errors from API format to field → message map.
  /// Handles array format: [{"field":"email", "errors":["msg"]}, ...].
  static Map<String, dynamic>? _parse422Errors(dynamic errorsRaw) {
    if (errorsRaw is Map<String, dynamic>) {
      return Map<String, dynamic>.from(errorsRaw);
    }
    if (errorsRaw is! List<dynamic>) return null;
    final result = <String, dynamic>{};
    for (final item in errorsRaw) {
      if (item is! Map<String, dynamic>) continue;
      final field = item['field'] as String?;
      final errs = item['errors'];
      if (field == null) continue;
      if (errs is List<dynamic> && errs.isNotEmpty) {
        result[field] = errs.first.toString();
      } else if (errs is String) {
        result[field] = errs;
      }
    }
    return result.isEmpty ? null : result;
  }
}
