import '../../domain/core/refresh_token_result.dart';
import '../../domain/entities/login_request.dart';
import '../../domain/entities/my_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../services/auth_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._authService);

  final AuthService _authService;

  @override
  Future<MyUser> signInWithEmailAndPassword(LoginRequest payload) async {
    final response = await _authService.loginWithEmail(payload);
    final loginResponse = response.data;
    return loginResponse.user;
  }

  @override
  Future<RefreshTokenResult> refreshToken(String refreshToken) async {
    return _authService.refreshToken(refreshToken);
  }

  @override
  Future<MyUser> getMe(String accessToken) async {
    return _authService.getMe(accessToken);
  }
}
