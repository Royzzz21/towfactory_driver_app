/// Result of a successful token refresh (new access + refresh tokens).
/// Supports API response formats:
/// - Top-level: { "message": "...", "accessToken": "...", "refreshToken": "..." }
/// - Wrapped: { "data": { "accessToken": "...", "refreshToken": "..." } }
class RefreshTokenResult {
  const RefreshTokenResult({
    required this.accessToken,
    this.refreshToken,
  });

  final String accessToken;
  final String? refreshToken;

  factory RefreshTokenResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return RefreshTokenResult(
      accessToken: data['accessToken'] as String? ?? data['token'] as String? ?? '',
      refreshToken: data['refreshToken'] as String?,
    );
  }
}
