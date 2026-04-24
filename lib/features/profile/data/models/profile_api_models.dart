import 'package:dio/dio.dart';
import 'package:discovaa/features/profile/domain/entities/availability.dart';
import 'package:discovaa/features/profile/domain/entities/business_registration.dart';
import 'package:discovaa/features/profile/domain/entities/certification.dart';
import 'package:discovaa/features/profile/domain/entities/identity_verification.dart';
import 'package:discovaa/features/profile/domain/entities/location.dart';
import 'package:discovaa/features/profile/domain/entities/payout_account.dart';
import 'package:discovaa/features/profile/domain/entities/profile_enums.dart';
import 'package:discovaa/features/profile/domain/entities/provider_payout.dart';
import 'package:discovaa/features/profile/domain/entities/user_profile.dart';

class UserMeDto {
  final String id;
  final String email;
  final String? displayName;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? countryIso2;
  final String? gender;
  final String? language;
  final String? profilePhoto;
  final String? idNumber;
  final String? idDocumentFront;
  final String? idDocumentBack;
  final String? verificationStatus;
  final DateTime? verifiedAt;
  final String? providerId;
  final String? providerType;
  final String? role;

  const UserMeDto({
    required this.id,
    required this.email,
    this.displayName,
    this.firstName,
    this.lastName,
    this.phone,
    this.countryIso2,
    this.gender,
    this.language,
    this.profilePhoto,
    this.idNumber,
    this.idDocumentFront,
    this.idDocumentBack,
    this.verificationStatus,
    this.verifiedAt,
    this.providerId,
    this.providerType,
    this.role,
  });

  factory UserMeDto.fromJson(Map<String, dynamic> json) {
    return UserMeDto(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      displayName: json['display_name']?.toString(),
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      phone: json['phone']?.toString(),
      countryIso2: json['country_iso2']?.toString(),
      gender: json['gender']?.toString(),
      language: json['language']?.toString(),
      profilePhoto: json['profile_photo']?.toString(),
      idNumber: json['id_number']?.toString(),
      idDocumentFront: json['id_document_front']?.toString(),
      idDocumentBack: json['id_document_back']?.toString(),
      verificationStatus: json['verification_status']?.toString(),
      verifiedAt: _parseDateTime(json['verified_at']),
      providerId: _extractId(json['provider'] ?? json['provider_id']),
      providerType: json['provider_type']?.toString(),
      role: json['role']?.toString(),
    );
  }
}

class ProviderDto {
  final String id;
  final String? providerType;
  final String? displayName;
  final String? bio;
  final String? phone;
  final String? email;
  final String? profilePhoto;
  final bool isVerified;
  final List<ProviderLocationDto> locations;
  final List<ProviderCertificationDto> certifications;
  final List<ProviderAvailabilityRuleDto> availabilityRules;

  const ProviderDto({
    required this.id,
    this.providerType,
    this.displayName,
    this.bio,
    this.phone,
    this.email,
    this.profilePhoto,
    this.isVerified = false,
    this.locations = const [],
    this.certifications = const [],
    this.availabilityRules = const [],
  });

  factory ProviderDto.fromJson(Map<String, dynamic> json) {
    return ProviderDto(
      id: json['id']?.toString() ?? '',
      providerType: json['provider_type']?.toString(),
      displayName: json['display_name']?.toString(),
      bio: json['bio']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      profilePhoto: json['profile_photo']?.toString(),
      isVerified: json['is_verified'] == true,
      locations: _mapList(
        json['locations'],
        (item) => ProviderLocationDto.fromJson(item),
      ),
      certifications: _mapList(
        json['certifications'],
        (item) => ProviderCertificationDto.fromJson(item),
      ),
      availabilityRules: _mapList(
        json['availability_rules'],
        (item) => ProviderAvailabilityRuleDto.fromJson(item),
      ),
    );
  }
}

class ProviderProfileWriteDto {
  final String? providerType;
  final String? displayName;
  final String? bio;
  final String? phone;
  final String? email;
  final String? countryIso2;
  final String? registrationNumber;

  const ProviderProfileWriteDto({
    this.providerType,
    this.displayName,
    this.bio,
    this.phone,
    this.email,
    this.countryIso2,
    this.registrationNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      if (providerType != null) 'provider_type': providerType,
      if (displayName != null) 'display_name': displayName,
      if (bio != null) 'bio': bio,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (countryIso2 != null) 'country_iso2': countryIso2,
      if (registrationNumber != null) 'registration_number': registrationNumber,
    };
  }
}

class ProviderLocationDto {
  final String id;
  final String name;
  final String? address;
  final String? phone;
  final double? lat;
  final double? lng;

  const ProviderLocationDto({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.lat,
    this.lng,
  });

  factory ProviderLocationDto.fromJson(Map<String, dynamic> json) {
    final point = json['point'] as Map<String, dynamic>?;
    final coordinates = point?['coordinates'] as List<dynamic>?;
    return ProviderLocationDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString(),
      phone: json['phone']?.toString(),
      lng: coordinates != null && coordinates.isNotEmpty
          ? _asDouble(coordinates.first)
          : null,
      lat: coordinates != null && coordinates.length > 1
          ? _asDouble(coordinates[1])
          : null,
    );
  }

  Map<String, dynamic> toWriteJson() {
    return {
      'name': name,
      if (address != null && address!.isNotEmpty) 'address': address,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      if (lat != null && lng != null)
        'point': {
          'type': 'Point',
          'coordinates': [lng, lat],
        },
    };
  }
}

class ProviderCertificationDto {
  final String id;
  final String title;
  final String? issuer;
  final DateTime? issuedDate;
  final DateTime? expiresDate;
  final String? document;

  const ProviderCertificationDto({
    required this.id,
    required this.title,
    this.issuer,
    this.issuedDate,
    this.expiresDate,
    this.document,
  });

  factory ProviderCertificationDto.fromJson(Map<String, dynamic> json) {
    return ProviderCertificationDto(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      issuer: json['issuer']?.toString(),
      issuedDate: _parseDateTime(json['issued_date']),
      expiresDate: _parseDateTime(json['expires_date']),
      document: json['document']?.toString(),
    );
  }

  Map<String, dynamic> toWriteJson() {
    return {
      'title': title,
      if (issuer != null && issuer!.isNotEmpty) 'issuer': issuer,
      if (issuedDate != null) 'issued_date': _dateOnly(issuedDate!),
      if (expiresDate != null) 'expires_date': _dateOnly(expiresDate!),
      if (document != null && document!.isNotEmpty) 'document': document,
    };
  }
}

class ProviderAvailabilityRuleDto {
  final String id;
  final String? provider;
  final int weekday;
  final String? startTime;
  final String? endTime;
  final bool isClosed;
  final String? timezone;

  const ProviderAvailabilityRuleDto({
    required this.id,
    this.provider,
    required this.weekday,
    this.startTime,
    this.endTime,
    this.isClosed = false,
    this.timezone,
  });

  factory ProviderAvailabilityRuleDto.fromJson(Map<String, dynamic> json) {
    return ProviderAvailabilityRuleDto(
      id: json['id']?.toString() ?? '',
      provider: json['provider']?.toString(),
      weekday: _asInt(json['weekday']),
      startTime: json['start_time']?.toString(),
      endTime: json['end_time']?.toString(),
      isClosed: json['is_closed'] == true,
      timezone: json['timezone']?.toString(),
    );
  }

  Map<String, dynamic> toWriteJson() {
    return {
      if (provider != null) 'provider': provider,
      'weekday': weekday,
      'start_time': startTime,
      'end_time': endTime,
      'is_closed': isClosed,
      if (timezone != null) 'timezone': timezone,
    };
  }
}

class ProviderPayoutAccountDto {
  final String id;
  final String? provider;
  final String? ownerProvider;
  final String? externalAccountId;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProviderPayoutAccountDto({
    required this.id,
    this.provider,
    this.ownerProvider,
    this.externalAccountId,
    this.isActive = false,
    this.createdAt,
    this.updatedAt,
  });

  factory ProviderPayoutAccountDto.fromJson(Map<String, dynamic> json) {
    return ProviderPayoutAccountDto(
      id: json['id']?.toString() ?? '',
      provider: json['provider']?.toString(),
      ownerProvider: json['owner_provider']?.toString(),
      externalAccountId: json['external_account_id']?.toString(),
      isActive: json['is_active'] == true,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }
}

class ProviderPayoutAccountStatusDto {
  final bool exists;
  final ProviderPayoutAccountDto? payoutAccount;

  const ProviderPayoutAccountStatusDto({
    required this.exists,
    this.payoutAccount,
  });

  factory ProviderPayoutAccountStatusDto.fromJson(Map<String, dynamic> json) {
    return ProviderPayoutAccountStatusDto(
      exists: json['exists'] == true,
      payoutAccount: json['payout_account'] is Map<String, dynamic>
          ? ProviderPayoutAccountDto.fromJson(
              json['payout_account'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class ProviderPayoutAccountSetupResponseDto {
  final String? provider;
  final String? currency;
  final ProviderPayoutAccountDto? payoutAccount;
  final String? onboardingUrl;

  const ProviderPayoutAccountSetupResponseDto({
    this.provider,
    this.currency,
    this.payoutAccount,
    this.onboardingUrl,
  });

  factory ProviderPayoutAccountSetupResponseDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return ProviderPayoutAccountSetupResponseDto(
      provider: json['provider']?.toString(),
      currency: json['currency']?.toString(),
      payoutAccount: json['payout_account'] is Map<String, dynamic>
          ? ProviderPayoutAccountDto.fromJson(
              json['payout_account'] as Map<String, dynamic>,
            )
          : null,
      onboardingUrl: json['onboarding_url']?.toString(),
    );
  }
}

class AccountUpdateResponseDto {
  final String? updateUrl;

  const AccountUpdateResponseDto({this.updateUrl});

  factory AccountUpdateResponseDto.fromJson(Map<String, dynamic> json) {
    return AccountUpdateResponseDto(updateUrl: json['update_url']?.toString());
  }
}

class OnboardingResumeResponseDto {
  final String? onboardingUrl;

  const OnboardingResumeResponseDto({this.onboardingUrl});

  factory OnboardingResumeResponseDto.fromJson(Map<String, dynamic> json) {
    return OnboardingResumeResponseDto(
      onboardingUrl: json['onboarding_url']?.toString(),
    );
  }
}

class AccountBalanceDto {
  final double available;
  final double pending;
  final bool instantAvailable;

  const AccountBalanceDto({
    required this.available,
    required this.pending,
    required this.instantAvailable,
  });

  factory AccountBalanceDto.fromJson(Map<String, dynamic> json) {
    return AccountBalanceDto(
      available: _sumCurrencyArray(json['available']),
      pending: _sumCurrencyArray(json['pending']),
      instantAvailable:
          (json['instant_available'] as List<dynamic>? ?? const []).isNotEmpty,
    );
  }
}

class ProviderPayoutDto {
  final String id;
  final String? provider;
  final String? ownerProvider;
  final String? currency;
  final String? amount;
  final String? status;
  final String? externalReference;
  final String? failureReason;
  final DateTime? requestedAt;
  final DateTime? processedAt;
  final DateTime? paidAt;
  final DateTime? failedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProviderPayoutDto({
    required this.id,
    this.provider,
    this.ownerProvider,
    this.currency,
    this.amount,
    this.status,
    this.externalReference,
    this.failureReason,
    this.requestedAt,
    this.processedAt,
    this.paidAt,
    this.failedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory ProviderPayoutDto.fromJson(Map<String, dynamic> json) {
    return ProviderPayoutDto(
      id: json['id']?.toString() ?? '',
      provider: json['provider']?.toString(),
      ownerProvider: json['owner_provider']?.toString(),
      currency: json['currency']?.toString(),
      amount: json['amount']?.toString(),
      status: json['status']?.toString(),
      externalReference: json['external_reference']?.toString(),
      failureReason: json['failure_reason']?.toString(),
      requestedAt: _parseDateTime(json['requested_at']),
      processedAt: _parseDateTime(json['processed_at']),
      paidAt: _parseDateTime(json['paid_at']),
      failedAt: _parseDateTime(json['failed_at']),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }
}

ProviderPayout mapProviderPayout(ProviderPayoutDto dto) {
  return ProviderPayout(
    id: dto.id,
    provider: dto.provider,
    ownerProvider: dto.ownerProvider,
    currency: dto.currency ?? 'NGN',
    amount: _asDouble(dto.amount),
    status: _providerPayoutStatus(dto.status),
    externalReference: dto.externalReference,
    failureReason: dto.failureReason,
    requestedAt: dto.requestedAt,
    processedAt: dto.processedAt,
    paidAt: dto.paidAt,
    failedAt: dto.failedAt,
    createdAt: dto.createdAt,
    updatedAt: dto.updatedAt,
  );
}

UserProfile mapProfileAggregate({
  required UserMeDto user,
  ProviderDto? provider,
  AccountBalanceDto? balance,
  ProviderPayoutAccountDto? payoutAccount,
}) {
  final accountType = switch ((provider?.providerType ??
          user.providerType ??
          user.role ??
          '')
      .toUpperCase()) {
    'INDIVIDUAL' => AccountType.provider,
    'BUSINESS' => AccountType.business,
    _ => AccountType.user,
  };

  final verificationStatus = _verificationStatus(
    provider?.isVerified == true ? 'VERIFIED' : user.verificationStatus,
  );

  return UserProfile(
    id: user.id,
    email: user.email,
    displayName: _smartDisplayName(
      user.displayName,
      provider?.displayName,
      user.email,
    ),
    firstName: user.firstName,
    lastName: user.lastName,
    profileImage: provider?.profilePhoto ?? user.profilePhoto,
    accountType: accountType,
    verificationStatus: verificationStatus,
    providerTypeRaw: provider?.providerType ?? user.providerType,
    providerId: user.providerId,
    phone: provider?.phone ?? user.phone,
    country: user.countryIso2,
    countryCode: user.countryIso2,
    timezone:
        _firstAvailabilityTimezone(provider?.availabilityRules) ??
        'Africa/Lagos',
    gender: user.gender,
    languagesSpoken: user.language,
    bio: provider?.bio,
    summary: provider?.bio,
    emailVerified: true,
    identityVerification: IdentityVerification(
      idNumber: user.idNumber,
      idFrontImageUrl: user.idDocumentFront,
      idBackImageUrl: user.idDocumentBack,
      status: verificationStatus,
      verifiedAt: user.verifiedAt,
    ),
    businessRegistration: accountType == AccountType.business
        ? BusinessRegistration(
            businessName: provider?.displayName ?? user.displayName ?? '',
            registrationNumber: '',
            businessType: 'Business',
            verificationStatus: verificationStatus,
            registrationDate: DateTime.now(),
          )
        : null,
    certifications:
        provider?.certifications.map((cert) {
          return Certification(
            id: cert.id,
            name: cert.title,
            issuingOrganization: cert.issuer,
            issueDate: cert.issuedDate,
            expiryDate: cert.expiresDate,
            documentUrl: cert.document,
            verificationStatus: verificationStatus,
          );
        }).toList() ??
        const [],
    locations:
        provider?.locations.map((location) {
          return ServiceLocation(
            id: location.id,
            name: location.name,
            address: location.address,
            country: user.countryIso2,
            latitude: location.lat,
            longitude: location.lng,
          );
        }).toList() ??
        const [],
    availability: Availability(
      days: _availabilityDays(provider?.availabilityRules ?? const []),
      timezone:
          _firstAvailabilityTimezone(provider?.availabilityRules) ??
          'Africa/Lagos',
    ),
    payoutAccount: payoutAccount == null
        ? null
        : PayoutAccount(
            connectedAccountId: payoutAccount.externalAccountId,
            status: payoutAccount.isActive
                ? PayoutStatus.active
                : PayoutStatus.pending,
            currency: 'NGN',
            currentBalance: balance?.available,
            availableBalance: balance?.available,
            pendingBalance: balance?.pending,
            instantPayoutAvailable: balance?.instantAvailable ?? false,
            email: user.email,
            chargesEnabled: payoutAccount.isActive,
          ),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

FormData buildIdentityVerificationFormData({
  required String idNumber,
  String? idFrontImagePath,
  String? idBackImagePath,
}) {
  final data = <String, dynamic>{'id_number': idNumber};
  if (idFrontImagePath != null && idFrontImagePath.isNotEmpty) {
    data['id_document_front'] = MultipartFile.fromFileSync(idFrontImagePath);
  }
  if (idBackImagePath != null && idBackImagePath.isNotEmpty) {
    data['id_document_back'] = MultipartFile.fromFileSync(idBackImagePath);
  }
  return FormData.fromMap(data);
}

List<DayAvailability> _availabilityDays(
  List<ProviderAvailabilityRuleDto> rules,
) {
  final mapped = <DayAvailability>[];
  for (final day in DayOfWeek.values) {
    final matches = rules.where((element) => element.weekday == day.index);
    final rule = matches.isEmpty ? null : matches.first;
    mapped.add(
      DayAvailability(
        day: day,
        isAvailable: rule != null && !rule.isClosed,
        startTime: rule?.startTime,
        endTime: rule?.endTime,
      ),
    );
  }
  return mapped;
}

String? _firstAvailabilityTimezone(List<ProviderAvailabilityRuleDto>? rules) {
  if (rules == null || rules.isEmpty) return null;
  return rules.first.timezone;
}

VerificationStatus _verificationStatus(String? raw) {
  switch ((raw ?? '').toUpperCase()) {
    case 'PENDING':
      return VerificationStatus.pending;
    case 'VERIFIED':
      return VerificationStatus.verified;
    case 'REJECTED':
      return VerificationStatus.rejected;
    default:
      return VerificationStatus.unverified;
  }
}

ProviderPayoutStatus _providerPayoutStatus(String? raw) {
  switch ((raw ?? '').toUpperCase()) {
    case 'REQUESTED':
      return ProviderPayoutStatus.requested;
    case 'PROCESSING':
      return ProviderPayoutStatus.processing;
    case 'PAID':
      return ProviderPayoutStatus.paid;
    case 'FAILED':
      return ProviderPayoutStatus.failed;
    case 'CANCELLED':
      return ProviderPayoutStatus.cancelled;
    default:
      return ProviderPayoutStatus.processing;
  }
}

DateTime? _parseDateTime(dynamic value) {
  final raw = value?.toString();
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

String? _extractId(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  if (value is Map<String, dynamic>) {
    final id = value['id']?.toString().trim();
    return id == null || id.isEmpty ? null : id;
  }

  final raw = value.toString().trim();
  if (raw.isEmpty || raw == 'null') return null;
  return raw;
}

String _dateOnly(DateTime value) => value.toIso8601String().split('T').first;

double _sumCurrencyArray(dynamic input) {
  if (input is! List) return 0;
  var total = 0.0;
  for (final item in input) {
    if (item is Map<String, dynamic>) {
      total += _asDouble(item['amount']);
    }
  }
  return total;
}

double _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

List<T> _mapList<T>(
  dynamic source,
  T Function(Map<String, dynamic> item) mapper,
) {
  if (source is! List) return const [];
  return source.whereType<Map<String, dynamic>>().map(mapper).toList();
}

/// Smart display name detection
/// Prefers user's display_name unless provider's display_name is a meaningful business name
/// (i.e., not just a username fallback matching the email username)
String? _smartDisplayName(
  String? userDisplayName,
  String? providerDisplayName,
  String email,
) {
  // If provider name is different from email username, use it (likely a business name)
  if (providerDisplayName != null &&
      providerDisplayName.isNotEmpty &&
      !providerDisplayName.contains(email.split('@').first)) {
    return providerDisplayName;
  }
  // Otherwise prefer user's display_name
  return userDisplayName;
}
