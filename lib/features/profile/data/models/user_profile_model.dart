import 'package:discovaa/features/profile/domain/entities/user_profile.dart';

/// Data model for UserProfile that extends the domain entity
/// Uses parent's fromJson/toJson methods for serialization
class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    required super.email,
    super.displayName,
    super.firstName,
    super.lastName,
    super.profileImage,
    super.accountType,
    super.verificationStatus,
    super.phone,
    super.country,
    super.countryCode,
    super.timezone,
    super.gender,
    super.pronouns,
    super.languagesSpoken,
    super.bio,
    super.servicesOffered,
    super.hourlyRate,
    super.priceRange,
    super.summary,
    super.emailVerified,
    super.passwordLastChanged,
    super.identityVerification,
    super.businessRegistration,
    super.certifications,
    super.locations,
    super.availability,
    super.payoutAccount,
    super.createdAt,
    super.updatedAt,
  });

  /// Factory constructor from JSON - delegates to parent
  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel.fromEntity(UserProfile.fromJson(json));
  }

  /// Convert from domain entity to model
  factory UserProfileModel.fromEntity(UserProfile entity) {
    return UserProfileModel(
      id: entity.id,
      email: entity.email,
      displayName: entity.displayName,
      firstName: entity.firstName,
      lastName: entity.lastName,
      profileImage: entity.profileImage,
      accountType: entity.accountType,
      verificationStatus: entity.verificationStatus,
      phone: entity.phone,
      country: entity.country,
      countryCode: entity.countryCode,
      timezone: entity.timezone,
      gender: entity.gender,
      pronouns: entity.pronouns,
      languagesSpoken: entity.languagesSpoken,
      bio: entity.bio,
      servicesOffered: entity.servicesOffered,
      hourlyRate: entity.hourlyRate,
      priceRange: entity.priceRange,
      summary: entity.summary,
      emailVerified: entity.emailVerified,
      passwordLastChanged: entity.passwordLastChanged,
      identityVerification: entity.identityVerification,
      businessRegistration: entity.businessRegistration,
      certifications: entity.certifications,
      locations: entity.locations,
      availability: entity.availability,
      payoutAccount: entity.payoutAccount,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Convert to JSON - delegates to parent
  @override
  Map<String, dynamic> toJson() => super.toJson();

  /// Convert to domain entity
  UserProfile toEntity() => this;
}
