/// Entity representing user registration data
class RegistrationEntity {
  final String email;
  final String password;
  final String? otpCode;
  final String accountType;
  final String? providerType;
  final DateTime? createdAt;

  const RegistrationEntity({
    required this.email,
    required this.password,
    this.otpCode,
    required this.accountType,
    this.providerType,
    this.createdAt,
  });

  RegistrationEntity copyWith({
    String? email,
    String? password,
    String? otpCode,
    String? accountType,
    String? providerType,
    DateTime? createdAt,
  }) {
    return RegistrationEntity(
      email: email ?? this.email,
      password: password ?? this.password,
      otpCode: otpCode ?? this.otpCode,
      accountType: accountType ?? this.accountType,
      providerType: providerType ?? this.providerType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'account_type': accountType,
      if (providerType != null) 'provider_type': providerType,
    };
  }

  /// Legacy compatibility: get role from account_type and provider_type
  String get role {
    if (accountType == 'service_provider') {
      return providerType == 'business' ? 'business' : 'individual';
    }
    return 'user';
  }

  @override
  String toString() {
    return 'RegistrationEntity(email: $email, accountType: $accountType, providerType: $providerType)';
  }
}
