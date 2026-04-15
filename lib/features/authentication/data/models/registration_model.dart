import '../../domain/entities/registration_entity.dart';

/// Data model for user registration data
class RegistrationModel {
  final String email;
  final String password;
  final String? otpCode;
  final String role;
  final DateTime? createdAt;

  const RegistrationModel({
    required this.email,
    required this.password,
    this.otpCode,
    required this.role,
    this.createdAt,
  });

  /// Create from JSON map
  factory RegistrationModel.fromJson(Map<String, dynamic> json) {
    return RegistrationModel(
      email: json['email'] as String,
      password: json['password'] as String,
      otpCode: json['otpCode'] as String?,
      role: json['role'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'otpCode': otpCode,
      'role': role,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// Convert to domain entity
  RegistrationEntity toEntity() {
    return RegistrationEntity(
      email: email,
      password: password,
      otpCode: otpCode,
      role: role,
      createdAt: createdAt,
    );
  }

  /// Create from domain entity
  factory RegistrationModel.fromEntity(RegistrationEntity entity) {
    return RegistrationModel(
      email: entity.email,
      password: entity.password,
      otpCode: entity.otpCode,
      role: entity.role,
      createdAt: entity.createdAt,
    );
  }

  RegistrationModel copyWith({
    String? email,
    String? password,
    String? otpCode,
    String? role,
    DateTime? createdAt,
  }) {
    return RegistrationModel(
      email: email ?? this.email,
      password: password ?? this.password,
      otpCode: otpCode ?? this.otpCode,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
