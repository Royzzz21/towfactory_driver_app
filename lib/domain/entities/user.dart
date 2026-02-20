import 'package:equatable/equatable.dart';

/// User details from login API response.
class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.userType,
    this.isActive = true,
    this.lastLogin,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final String userType;
  final bool isActive;
  final String? lastLogin;
  final String? createdAt;
  final String? updatedAt;

  String get fullName => '$firstName $lastName'.trim();

  @override
  List<Object?> get props => [id, email, firstName, lastName, phone, userType, isActive, lastLogin, createdAt, updatedAt];

  /// From API response map (e.g. response['user']).
  static User? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final id = json['id'] as String? ?? json['_id'] as String?;
    if (id == null || id.isEmpty) return null;
    return User(
      id: id,
      email: json['email'] as String? ?? '',
      firstName: json['firstName'] as String? ?? json['first_name'] as String? ?? '',
      lastName: json['lastName'] as String? ?? json['last_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      userType: json['userType'] as String? ?? json['user_type'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      lastLogin: json['lastLogin'] as String? ?? json['last_login'] as String?,
      createdAt: json['createdAt'] as String? ?? json['created_at'] as String?,
      updatedAt: json['updatedAt'] as String? ?? json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'userType': userType,
        'isActive': isActive,
        if (lastLogin != null) 'lastLogin': lastLogin,
        if (createdAt != null) 'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };
}
