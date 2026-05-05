/// Entity representing a user in the system
class UserEntity {
  final String id;
  final String email;
  final String displayName;
  final String? phone;
  final String? address;
  final String? country;
  final String? photoUrl;
  final String role;
  final bool isEmailVerified;
  final bool isIdentityVerified;
  final bool isProfileComplete;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.displayName,
    this.phone,
    this.address,
    this.country,
    this.photoUrl,
    required this.role,
    this.isEmailVerified = false,
    this.isIdentityVerified = false,
    this.isProfileComplete = false,
    this.createdAt,
    this.updatedAt,
  });

  /// True if the user is any kind of service provider
  String get normalizedRole => role.trim().toUpperCase();

  bool get isProvider =>
      normalizedRole == 'INDIVIDUAL' || normalizedRole == 'BUSINESS';

  /// True if the user is specifically an individual service provider
  bool get isIndividualProvider => normalizedRole == 'INDIVIDUAL';

  /// True if the user is specifically a business service provider
  bool get isBusinessProvider => normalizedRole == 'BUSINESS';

  /// True if the user is a standard user
  bool get isOrdinaryUser => normalizedRole == 'USER';

  UserEntity copyWith({
    String? id,
    String? email,
    String? displayName,
    String? phone,
    String? address,
    String? country,
    String? photoUrl,
    String? role,
    bool? isEmailVerified,
    bool? isIdentityVerified,
    bool? isProfileComplete,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      country: country ?? this.country,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isIdentityVerified: isIdentityVerified ?? this.isIdentityVerified,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserEntity(id: $id, email: $email, displayName: $displayName, role: $role)';
  }
}
