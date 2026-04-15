import 'profile_enums.dart';
import 'identity_verification.dart';
import 'business_registration.dart';
import 'certification.dart';
import 'location.dart';
import 'availability.dart';
import 'payout_account.dart';

/// Comprehensive user profile entity with all profile-related data
class UserProfile {
  // Core Info
  final String id;
  final String email;
  final String? displayName;
  final String? firstName;
  final String? lastName;
  final String? profileImage;

  // Account Type
  final AccountType accountType;
  final VerificationStatus verificationStatus;

  // Contact Info
  final String? phone;
  final String? country;
  final String? countryCode;
  final String? timezone;

  // Personal Details
  final String? gender;
  final String? pronouns;
  final String? languagesSpoken;
  final String? bio;

  // Provider-specific fields
  final String? servicesOffered;
  final String? hourlyRate;
  final String? priceRange;
  final String? summary;

  // Security
  final bool emailVerified;
  final DateTime? passwordLastChanged;
  final bool isDeactivated;

  // Related Entities
  final IdentityVerification? identityVerification;
  final BusinessRegistration? businessRegistration;
  final List<Certification> certifications;
  final List<ServiceLocation> locations;
  final Availability? availability;
  final PayoutAccount? payoutAccount;

  // Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.id,
    required this.email,
    this.displayName,
    this.firstName,
    this.lastName,
    this.profileImage,
    this.accountType = AccountType.user,
    this.verificationStatus = VerificationStatus.unverified,
    this.phone,
    this.country,
    this.countryCode,
    this.timezone,
    this.gender,
    this.pronouns,
    this.languagesSpoken,
    this.bio,
    this.servicesOffered,
    this.hourlyRate,
    this.priceRange,
    this.summary,
    this.emailVerified = false,
    this.passwordLastChanged,
    this.isDeactivated = false,
    this.identityVerification,
    this.businessRegistration,
    this.certifications = const [],
    this.locations = const [],
    this.availability,
    this.payoutAccount,
    this.createdAt,
    this.updatedAt,
  });

  // Computed properties
  String get fullName {
    if (firstName != null &&
        firstName!.isNotEmpty &&
        lastName != null &&
        lastName!.isNotEmpty) {
      return '$firstName $lastName';
    }
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!;
    }
    if (email.isNotEmpty) {
      return email.split('@').first;
    }
    return 'User';
  }

  String get initials {
    if (firstName != null &&
        firstName!.isNotEmpty &&
        lastName != null &&
        lastName!.isNotEmpty) {
      return '${firstName![0]}${lastName![0]}'.toUpperCase();
    }
    if (displayName != null && displayName!.isNotEmpty) {
      final parts = displayName!.trim().split(RegExp(r'\s+'));
      if (parts.length > 1 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      if (parts.isNotEmpty && parts[0].isNotEmpty) {
        return parts[0][0].toUpperCase();
      }
    }
    if (email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    return '?';
  }

  bool get isProvider => accountType.isProvider;

  bool get isBusiness => accountType == AccountType.business;

  String get formattedPhone {
    if (phone == null || phone!.isEmpty) return 'Not set';
    return phone!;
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? firstName,
    String? lastName,
    String? profileImage,
    AccountType? accountType,
    VerificationStatus? verificationStatus,
    String? phone,
    String? country,
    String? countryCode,
    String? timezone,
    String? gender,
    String? pronouns,
    String? languagesSpoken,
    String? bio,
    String? servicesOffered,
    String? hourlyRate,
    String? priceRange,
    String? summary,
    bool? emailVerified,
    DateTime? passwordLastChanged,
    bool? isDeactivated,
    IdentityVerification? identityVerification,
    BusinessRegistration? businessRegistration,
    List<Certification>? certifications,
    List<ServiceLocation>? locations,
    Availability? availability,
    PayoutAccount? payoutAccount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profileImage: profileImage ?? this.profileImage,
      accountType: accountType ?? this.accountType,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      phone: phone ?? this.phone,
      country: country ?? this.country,
      countryCode: countryCode ?? this.countryCode,
      timezone: timezone ?? this.timezone,
      gender: gender ?? this.gender,
      pronouns: pronouns ?? this.pronouns,
      languagesSpoken: languagesSpoken ?? this.languagesSpoken,
      bio: bio ?? this.bio,
      servicesOffered: servicesOffered ?? this.servicesOffered,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      priceRange: priceRange ?? this.priceRange,
      summary: summary ?? this.summary,
      emailVerified: emailVerified ?? this.emailVerified,
      passwordLastChanged: passwordLastChanged ?? this.passwordLastChanged,
      isDeactivated: isDeactivated ?? this.isDeactivated,
      identityVerification: identityVerification ?? this.identityVerification,
      businessRegistration: businessRegistration ?? this.businessRegistration,
      certifications: certifications ?? this.certifications,
      locations: locations ?? this.locations,
      availability: availability ?? this.availability,
      payoutAccount: payoutAccount ?? this.payoutAccount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'firstName': firstName,
      'lastName': lastName,
      'profileImage': profileImage,
      'accountType': accountType.name,
      'verificationStatus': verificationStatus.name,
      'phone': phone,
      'country': country,
      'countryCode': countryCode,
      'timezone': timezone,
      'gender': gender,
      'pronouns': pronouns,
      'languagesSpoken': languagesSpoken,
      'bio': bio,
      'servicesOffered': servicesOffered,
      'hourlyRate': hourlyRate,
      'priceRange': priceRange,
      'summary': summary,
      'emailVerified': emailVerified,
      'passwordLastChanged': passwordLastChanged?.toIso8601String(),
      'isDeactivated': isDeactivated,
      'identityVerification': identityVerification?.toJson(),
      'businessRegistration': businessRegistration?.toJson(),
      'certifications': certifications.map((c) => c.toJson()).toList(),
      'locations': locations.map((l) => l.toJson()).toList(),
      'availability': availability?.toJson(),
      'payoutAccount': payoutAccount?.toJson(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      profileImage: json['profileImage'],
      accountType: AccountType.values.firstWhere(
        (e) => e.name == json['accountType'],
        orElse: () => AccountType.user,
      ),
      verificationStatus: VerificationStatus.values.firstWhere(
        (e) => e.name == json['verificationStatus'],
        orElse: () => VerificationStatus.unverified,
      ),
      phone: json['phone'],
      country: json['country'],
      countryCode: json['countryCode'],
      timezone: json['timezone'],
      gender: json['gender'],
      pronouns: json['pronouns'],
      languagesSpoken: json['languagesSpoken'],
      bio: json['bio'],
      servicesOffered: json['servicesOffered'],
      hourlyRate: json['hourlyRate'],
      priceRange: json['priceRange'],
      summary: json['summary'],
      emailVerified: json['emailVerified'] ?? false,
      passwordLastChanged: json['passwordLastChanged'] != null
          ? DateTime.parse(json['passwordLastChanged'])
          : null,
      isDeactivated: json['isDeactivated'] ?? false,
      identityVerification: json['identityVerification'] != null
          ? IdentityVerification.fromJson(json['identityVerification'])
          : null,
      businessRegistration: json['businessRegistration'] != null
          ? BusinessRegistration.fromJson(json['businessRegistration'])
          : null,
      certifications:
          (json['certifications'] as List?)
              ?.map((c) => Certification.fromJson(c))
              .toList() ??
          [],
      locations:
          (json['locations'] as List?)
              ?.map((l) => ServiceLocation.fromJson(l))
              .toList() ??
          [],
      availability: json['availability'] != null
          ? Availability.fromJson(json['availability'])
          : null,
      payoutAccount: json['payoutAccount'] != null
          ? PayoutAccount.fromJson(json['payoutAccount'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }
}
