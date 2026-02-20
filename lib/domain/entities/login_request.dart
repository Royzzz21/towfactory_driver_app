import 'package:equatable/equatable.dart';

/// Payload for mobile login API (email + password only).
/// The /auth/login/mobile endpoint is driver-only; no userType needed.
class LoginRequest extends Equatable {
  const LoginRequest({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}
