import '../core/refresh_token_result.dart';
import '../entities/login_request.dart';
import '../entities/my_user.dart';

/// Repository interface for auth operations (login, refresh, etc.).
abstract class AuthRepository {
  /// Signs in with email/password via [payload].
  /// Returns [MyUser] (with token) on success; throws [ApiException] on failure.
  Future<MyUser> signInWithEmailAndPassword(LoginRequest payload);

  /// Refreshes the access token using [refreshToken].
  /// Returns new [RefreshTokenResult] (accessToken, refreshToken) on success; throws [ApiException] on failure.
  Future<RefreshTokenResult> refreshToken(String refreshToken);

  /// Fetches current user details (GET /auth/me) using [accessToken].
  /// Returns [MyUser] on success; throws [ApiException] on failure.
  Future<MyUser> getMe(String accessToken);
}
