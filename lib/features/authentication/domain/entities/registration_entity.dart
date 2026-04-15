/// Entity representing user registration data
class RegistrationEntity {
  final String email;
  final String password;
  final String? otpCode;
  final String role;
  final DateTime? createdAt;

  const RegistrationEntity({
    required this.email,
    required this.password,
    this.otpCode,
    required this.role,
    this.createdAt,
  });

  RegistrationEntity copyWith({
    String? email,
    String? password,
    String? otpCode,
    String? role,
    DateTime? createdAt,
  }) {
    return RegistrationEntity(
      email: email ?? this.email,
      password: password ?? this.password,
      otpCode: otpCode ?? this.otpCode,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'role': role,
    };
  }

  @override
  String toString() {
    return 'RegistrationEntity(email: $email, role: $role)';
  }
}
