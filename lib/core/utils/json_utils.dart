import 'dart:convert';

import '../../domain/core/api_exception.dart';

/// Safe decoding of API response bodies. Throws [ApiException] when the
/// response is HTML or invalid JSON instead of [FormatException].
abstract final class JsonUtils {
  /// Decodes [body] as JSON. Throws [ApiException] if body is HTML or invalid JSON.
  static dynamic decodeResponse(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      throw ApiException('Empty response from server');
    }
    if (trimmed.toLowerCase().startsWith('<')) {
      throw ApiException(
        'Server returned an HTML page instead of JSON. '
        'Check that the API URL is correct and the server is running.',
      );
    }
    try {
      return json.decode(body);
    } on FormatException catch (e) {
      throw ApiException('Invalid response format: ${e.message}');
    }
  }
}
