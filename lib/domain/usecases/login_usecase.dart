import '../entities/login_request.dart';
import '../entities/my_user.dart';
import '../repositories/auth_repository.dart';

/// Use case: sign in with email/password via [AuthRepository].
class LoginUsecase {
  LoginUsecase(this._authRepository);

  final AuthRepository _authRepository;

  Future<MyUser> call(LoginRequest payload) =>
      _authRepository.signInWithEmailAndPassword(payload);
}
