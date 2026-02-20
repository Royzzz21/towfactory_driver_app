/// Thrown when an API call fails (e.g. 401, 4xx, 5xx).
class ApiException implements Exception {
  ApiException(this.message, [this.statusCode, this.errors]);

  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  @override
  String toString() => 'ApiException: $message';

  /// Extracts a clean error message from any exception, removing class prefixes.
  static String cleanMessage(Object error) {
    final s = error.toString();
    // Remove common exception prefixes
    return s
        .replaceFirst(RegExp(r'^ApiException:\s*'), '')
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .trim();
  }
}
