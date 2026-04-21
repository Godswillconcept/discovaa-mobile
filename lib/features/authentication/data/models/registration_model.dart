import '../../domain/entities/registration_entity.dart';

/// Data model for user registration data
class RegistrationModel {
  final String email;
  final String password;
  final String? otpCode;
  final String accountType;
  final String? providerType;
  final DateTime? createdAt;

  const RegistrationModel({
    required this.email,
    required this.password,
    this.otpCode,
    required this.accountType,
    this.providerType,
    this.createdAt,
  });

  /// Create from JSON map
  factory RegistrationModel.fromJson(Map<String, dynamic> json) {
    return RegistrationModel(
      email: json['email'] as String,
      password: json['password'] as String,
      otpCode: json['otpCode'] as String?,
      accountType:
          json['account_type'] as String? ?? json['role'] as String? ?? 'user',
      providerType: json['provider_type'] as String?,
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
      'account_type': accountType,
      if (providerType != null) 'provider_type': providerType,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// Convert to domain entity
  RegistrationEntity toEntity() {
    return RegistrationEntity(
      email: email,
      password: password,
      otpCode: otpCode,
      accountType: accountType,
      providerType: providerType,
      createdAt: createdAt,
    );
  }

  /// Create from domain entity
  factory RegistrationModel.fromEntity(RegistrationEntity entity) {
    return RegistrationModel(
      email: entity.email,
      password: entity.password,
      otpCode: entity.otpCode,
      accountType: entity.accountType,
      providerType: entity.providerType,
      createdAt: entity.createdAt,
    );
  }

  /// Legacy compatibility: get role from account_type and provider_type
  String get role {
    if (accountType == 'service_provider') {
      return providerType == 'business' ? 'business' : 'individual';
    }
    return 'user';
  }

  RegistrationModel copyWith({
    String? email,
    String? password,
    String? otpCode,
    String? accountType,
    String? providerType,
    DateTime? createdAt,
  }) {
    return RegistrationModel(
      email: email ?? this.email,
      password: password ?? this.password,
      otpCode: otpCode ?? this.otpCode,
      accountType: accountType ?? this.accountType,
      providerType: providerType ?? this.providerType,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
