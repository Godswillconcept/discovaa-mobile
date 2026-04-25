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
    this.isProfileComplete = false,
    this.createdAt,
    this.updatedAt,
  });

  /// True if the user is any kind of service provider
  bool get isProvider => role == 'INDIVIDUAL' || role == 'BUSINESS';

  /// True if the user is specifically an individual service provider
  bool get isIndividualProvider => role == 'INDIVIDUAL';

  /// True if the user is specifically a business service provider
  bool get isBusinessProvider => role == 'BUSINESS';

  /// True if the user is a standard user
  bool get isOrdinaryUser => role == 'USER';

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
