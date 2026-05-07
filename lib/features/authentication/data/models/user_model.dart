import '../../domain/entities/user_entity.dart';

/// Data model for user data from API
class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? phone;
  final String? address;
  final String? country;
  final String? postalCode;
  final String? photoUrl;
  final String role;
  final bool isEmailVerified;
  final bool isIdentityVerified;
  final bool isProfileComplete;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.phone,
    this.address,
    this.country,
    this.postalCode,
    this.photoUrl,
    required this.role,
    this.isEmailVerified = false,
    this.isIdentityVerified = false,
    this.isProfileComplete = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Create from JSON map
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      country: json['country'] as String?,
      postalCode: json['postalCode'] as String?,
      photoUrl: json['photoUrl'] as String?,
      role: json['role'] as String,
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      isIdentityVerified: json['isIdentityVerified'] as bool? ?? false,
      isProfileComplete: json['isProfileComplete'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'phone': phone,
      'address': address,
      'country': country,
      'postalCode': postalCode,
      'photoUrl': photoUrl,
      'role': role,
      'isEmailVerified': isEmailVerified,
      'isIdentityVerified': isIdentityVerified,
      'isProfileComplete': isProfileComplete,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Convert to domain entity
  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      displayName: displayName,
      phone: phone,
      address: address,
      country: country,
      postalCode: postalCode,
      photoUrl: photoUrl,
      role: role,
      isEmailVerified: isEmailVerified,
      isIdentityVerified: isIdentityVerified,
      isProfileComplete: isProfileComplete,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create from domain entity
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      displayName: entity.displayName,
      phone: entity.phone,
      address: entity.address,
      country: entity.country,
      postalCode: entity.postalCode,
      photoUrl: entity.photoUrl,
      role: entity.role,
      isEmailVerified: entity.isEmailVerified,
      isIdentityVerified: entity.isIdentityVerified,
      isProfileComplete: entity.isProfileComplete,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? phone,
    String? address,
    String? country,
    String? postalCode,
    String? photoUrl,
    String? role,
    bool? isEmailVerified,
    bool? isIdentityVerified,
    bool? isProfileComplete,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isIdentityVerified: isIdentityVerified ?? this.isIdentityVerified,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
