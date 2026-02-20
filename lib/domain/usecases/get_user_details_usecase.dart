import '../entities/my_user.dart';
import '../repositories/auth_repository.dart';

/// Use case: fetch current user details (GET /auth/me) via [AuthRepository].
class GetUserDetailsUsecase {
  GetUserDetailsUsecase(this._authRepository);

  final AuthRepository _authRepository;

  Future<MyUser> call(String accessToken) => _authRepository.getMe(accessToken);
}
