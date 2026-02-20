import '../entities/my_user.dart';

/// Login API response shape (user + token + optional refreshToken).
class LoginResponse {
  const LoginResponse({required this.user, this.token, this.refreshToken});

  final MyUser user;
  final String? token;
  final String? refreshToken;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final token = json['token'] as String? ?? json['accessToken'] as String?;
    final refreshToken = json['refreshToken'] as String?;
    final userMap = json['user'] as Map<String, dynamic>? ?? json;
    final userJson = Map<String, dynamic>.from(userMap);
    if (token != null) userJson['token'] = token;
    if (token != null) userJson['accessToken'] = token;
    if (refreshToken != null) userJson['refreshToken'] = refreshToken;
    final user = MyUser.fromJson(userJson);
    return LoginResponse(
      user: user,
      token: token ?? user.token,
      refreshToken: refreshToken ?? user.refreshToken,
    );
  }
}
