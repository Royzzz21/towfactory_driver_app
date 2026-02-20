import 'package:equatable/equatable.dart';

/// Logged-in user from login /auth/me API (id, name, email, token, phone, userType, etc.).
class MyUser extends Equatable {
  const MyUser({
    required this.id,
    required this.name,
    required this.email,
    required this.token,
    this.refreshToken,
    this.phone,
    this.userType,
    this.isActive = true,
    this.lastLogin,
    this.createdAt,
    this.updatedAt,
    this.qrcode,
    this.mpinEnrolled = false,
  });

  final String id;
  final String name;
  final String email;
  final String token;
  /// Optional refresh token for renewing access.
  final String? refreshToken;
  final String? phone;
  final String? userType;
  final bool isActive;
  /// ISO 8601 string from API (e.g. "2024-01-15T10:30:00.000Z").
  final String? lastLogin;
  final String? createdAt;
  final String? updatedAt;
  final String? qrcode;
  final bool mpinEnrolled;

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        token,
        refreshToken,
        phone,
        userType,
        isActive,
        lastLogin,
        createdAt,
        updatedAt,
        qrcode,
        mpinEnrolled,
      ];

  static MyUser fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? json['_id'] as String? ?? '';
    final email = json['email'] as String? ?? '';
    final firstName = json['firstName'] as String? ?? json['first_name'] as String? ?? '';
    final lastName = json['lastName'] as String? ?? json['last_name'] as String? ?? '';
    final name = '$firstName $lastName'.trim();
    final token = json['token'] as String? ?? json['accessToken'] as String? ?? '';
    final refreshToken = json['refreshToken'] as String?;
    final phone = json['phone'] as String? ?? json['phoneNumber'] as String?;
    final userType = json['userType'] as String? ?? json['user_type'] as String?;
    final isActive = json['isActive'] as bool? ?? json['is_active'] as bool? ?? true;
    final lastLogin = json['lastLogin'] as String? ?? json['last_login'] as String?;
    final createdAt = json['createdAt'] as String? ?? json['created_at'] as String?;
    final updatedAt = json['updatedAt'] as String? ?? json['updated_at'] as String?;
    final qrcode = json['qrcode'] as String?;
    final mpinEnrolled = json['mpinEnrolled'] as bool? ?? json['mpin_enrolled'] as bool? ?? false;

    return MyUser(
      id: id,
      name: name.isEmpty ? email : name,
      email: email,
      token: token,
      refreshToken: refreshToken,
      phone: phone,
      userType: userType,
      isActive: isActive,
      lastLogin: lastLogin,
      createdAt: createdAt,
      updatedAt: updatedAt,
      qrcode: qrcode,
      mpinEnrolled: mpinEnrolled,
    );
  }

  /// Returns a copy with the given fields replaced (used e.g. after token refresh).
  MyUser copyWith({
    String? id,
    String? name,
    String? email,
    String? token,
    String? refreshToken,
    String? phone,
    String? userType,
    bool? isActive,
    String? lastLogin,
    String? createdAt,
    String? updatedAt,
    String? qrcode,
    bool? mpinEnrolled,
  }) {
    return MyUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
      phone: phone ?? this.phone,
      userType: userType ?? this.userType,
      isActive: isActive ?? this.isActive,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      qrcode: qrcode ?? this.qrcode,
      mpinEnrolled: mpinEnrolled ?? this.mpinEnrolled,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'token': token,
        if (refreshToken != null) 'refreshToken': refreshToken,
        if (phone != null) 'phone': phone,
        if (userType != null) 'userType': userType,
        'isActive': isActive,
        if (lastLogin != null) 'lastLogin': lastLogin,
        if (createdAt != null) 'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
        if (qrcode != null) 'qrcode': qrcode,
        'mpinEnrolled': mpinEnrolled,
      };
}
