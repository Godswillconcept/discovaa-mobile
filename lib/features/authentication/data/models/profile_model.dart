import '../../domain/entities/profile_entity.dart';

/// Data model for user profile data
class ProfileModel {
  final String displayName;
  final String? phone;
  final String? address;
  final String? country;
  final String? businessName;
  final String? businessDescription;
  final DateTime? updatedAt;

  const ProfileModel({
    required this.displayName,
    this.phone,
    this.address,
    this.country,
    this.businessName,
    this.businessDescription,
    this.updatedAt,
  });

  /// Create from JSON map
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      displayName: json['displayName'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      country: json['country'] as String?,
      businessName: json['businessName'] as String?,
      businessDescription: json['businessDescription'] as String?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'phone': phone,
      'address': address,
      'country': country,
      'businessName': businessName,
      'businessDescription': businessDescription,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Convert to domain entity
  ProfileEntity toEntity() {
    return ProfileEntity(
      displayName: displayName,
      phone: phone,
      address: address,
      country: country,
      businessName: businessName,
      businessDescription: businessDescription,
      updatedAt: updatedAt,
    );
  }

  /// Create from domain entity
  factory ProfileModel.fromEntity(ProfileEntity entity) {
    return ProfileModel(
      displayName: entity.displayName,
      phone: entity.phone,
      address: entity.address,
      country: entity.country,
      businessName: entity.businessName,
      businessDescription: entity.businessDescription,
      updatedAt: entity.updatedAt,
    );
  }

  ProfileModel copyWith({
    String? displayName,
    String? phone,
    String? address,
    String? country,
    String? businessName,
    String? businessDescription,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      country: country ?? this.country,
      businessName: businessName ?? this.businessName,
      businessDescription: businessDescription ?? this.businessDescription,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
