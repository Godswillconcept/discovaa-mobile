import 'package:discovaa/core/constants/app_constants.dart';
import 'package:discovaa/features/bookings/data/models/booking_model.dart';
import 'package:discovaa/features/services/data/models/service_model.dart';
import 'package:flutter/material.dart';

class BookingItemDto {
  final String id;
  final String serviceId;
  final int quantity;
  final String? unitPriceAmount;
  final String? currency;
  final String? durationMinutes;
  final ServiceNestedDto? service;

  const BookingItemDto({
    required this.id,
    required this.serviceId,
    required this.quantity,
    this.unitPriceAmount,
    this.currency,
    this.durationMinutes,
    this.service,
  });

  factory BookingItemDto.fromJson(Map<String, dynamic> json) {
    return BookingItemDto(
      id: json['id']?.toString() ?? '',
      serviceId: json['service'] is String
          ? json['service'] as String
          : json['service'] is Map
          ? (json['service'] as Map)['id']?.toString() ?? ''
          : '',
      quantity: json['quantity'] as int? ?? 1,
      unitPriceAmount: json['unit_price_amount']?.toString(),
      currency: json['currency']?.toString(),
      durationMinutes: json['duration_minutes']?.toString(),
      service: json['service'] is Map<String, dynamic>
          ? ServiceNestedDto.fromJson(json['service'] as Map<String, dynamic>)
          : null,
    );
  }
}

// DTO for nested service data from expand parameter
class ServiceNestedDto {
  final String id;
  final String provider;
  final String category;
  final String title;
  final String description;
  final String pricingModel;
  final String priceType;
  final String? priceAmount;
  final String? priceMinAmount;
  final String? priceMaxAmount;
  final String currency;
  final String? durationMinutes;
  final bool isActive;
  final List<String> media;

  const ServiceNestedDto({
    required this.id,
    required this.provider,
    required this.category,
    required this.title,
    required this.description,
    required this.pricingModel,
    required this.priceType,
    this.priceAmount,
    this.priceMinAmount,
    this.priceMaxAmount,
    required this.currency,
    this.durationMinutes,
    this.isActive = true,
    this.media = const [],
  });

  factory ServiceNestedDto.fromJson(Map<String, dynamic> json) {
    return ServiceNestedDto(
      id: json['id']?.toString() ?? '',
      provider: json['provider']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      pricingModel: json['pricing_model']?.toString() ?? 'FIXED',
      priceType: json['price_type']?.toString() ?? 'FIXED',
      priceAmount: json['price_amount']?.toString(),
      priceMinAmount: json['price_min_amount']?.toString(),
      priceMaxAmount: json['price_max_amount']?.toString(),
      currency: json['currency']?.toString() ?? 'NGN',
      durationMinutes: json['duration_minutes']?.toString(),
      isActive: json['is_active'] as bool? ?? true,
      media: (json['media'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
    );
  }
}

class BookingDto {
  final String id;
  final String userId;
  final String providerId;
  final String status;
  final String serviceType;
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;
  final String? addressText;
  final dynamic locationPoint;
  final String? currency;
  final String? totalAmount;
  final String? notes;
  final List<BookingItemDto> items;
  final DateTime createdAt;
  final DateTime? updatedAt;
  // Nested objects from expand parameter
  final UserNestedDto? user;
  final ProviderNestedDto? provider;
  final PaymentDto? payment;

  const BookingDto({
    required this.id,
    required this.userId,
    required this.providerId,
    required this.status,
    required this.serviceType,
    this.scheduledStart,
    this.scheduledEnd,
    this.addressText,
    this.locationPoint,
    this.currency,
    this.totalAmount,
    this.notes,
    required this.items,
    required this.createdAt,
    this.updatedAt,
    this.user,
    this.provider,
    this.payment,
  });

  factory BookingDto.fromJson(Map<String, dynamic> json) {
    return BookingDto(
      id: json['id']?.toString() ?? '',
      userId: json['user'] is String
          ? json['user'] as String
          : json['user'] is Map
          ? (json['user'] as Map)['id']?.toString() ?? ''
          : '',
      providerId: json['provider'] is String
          ? json['provider'] as String
          : json['provider'] is Map
          ? (json['provider'] as Map)['id']?.toString() ?? ''
          : '',
      status: json['status']?.toString() ?? 'REQUESTED',
      serviceType: json['service_type']?.toString() ?? 'ONSITE',
      scheduledStart:
          DateTime.tryParse(json['scheduled_start']?.toString() ?? '') ??
          DateTime.now(),
      scheduledEnd: DateTime.tryParse(json['scheduled_end']?.toString() ?? ''),
      addressText: json['address_text']?.toString(),
      locationPoint: json['location_point'],
      currency: json['currency']?.toString(),
      totalAmount: json['total_amount']?.toString(),
      notes: json['notes']?.toString(),
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(BookingItemDto.fromJson)
          .toList(growable: false),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
      user: json['user'] is Map<String, dynamic>
          ? UserNestedDto.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      provider: json['provider'] is Map<String, dynamic>
          ? ProviderNestedDto.fromJson(json['provider'] as Map<String, dynamic>)
          : null,
      payment: json['payment'] is Map<String, dynamic>
          ? PaymentDto.fromJson(json['payment'] as Map<String, dynamic>)
          : null,
    );
  }
}

class BookingWriteDto {
  final String providerId;
  final DateTime scheduledStart;
  final DateTime? scheduledEnd;
  final String serviceType;
  final String? currency;
  final String? notes;
  final String? addressText;
  final double? latitude;
  final double? longitude;
  final List<Map<String, dynamic>> items;

  const BookingWriteDto({
    required this.providerId,
    required this.scheduledStart,
    this.scheduledEnd,
    this.serviceType = 'ONSITE',
    this.currency,
    this.notes,
    this.addressText,
    this.latitude,
    this.longitude,
    this.items = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'provider': providerId,
      'scheduled_start': scheduledStart.toIso8601String(),
      if (scheduledEnd != null)
        'scheduled_end': scheduledEnd!.toIso8601String(),
      'service_type': serviceType,
      if (currency != null) 'currency': currency,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (addressText != null && addressText!.isNotEmpty)
        'address_text': addressText,
      if (latitude != null && longitude != null)
        'location_point': {
          'type': 'Point',
          'coordinates': [longitude, latitude], // GeoJSON uses [lng, lat] order
        },
      if (items.isNotEmpty) 'items': items,
    };
  }
}

// DTO for review data from /api/reviews/ endpoint
class ReviewDto {
  final String id;
  final String bookingId;
  final String authorDisplayName;
  final String? authorProfilePhoto;
  final double? rating;
  final String? comment;
  final bool isPublic;
  final DateTime createdAt;

  const ReviewDto({
    required this.id,
    required this.bookingId,
    required this.authorDisplayName,
    this.authorProfilePhoto,
    this.rating,
    this.comment,
    this.isPublic = true,
    required this.createdAt,
  });

  factory ReviewDto.fromJson(Map<String, dynamic> json) {
    final authorUser = json['author_user'] as Map<String, dynamic>?;
    return ReviewDto(
      id: json['id']?.toString() ?? '',
      bookingId: json['booking']?.toString() ?? '',
      authorDisplayName: authorUser?['display_name']?.toString() ?? '',
      authorProfilePhoto: authorUser?['profile_photo']?.toString(),
      rating: (json['rating'] as num?)?.toDouble(),
      comment: json['comment']?.toString(),
      isPublic: json['is_public'] as bool? ?? true,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

// DTO for user profile data from /api/accounts/me/ endpoint
class UserProfileDto {
  final String id;
  final String displayName;
  final String? profilePhoto;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;

  const UserProfileDto({
    required this.id,
    required this.displayName,
    this.profilePhoto,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
  });

  factory UserProfileDto.fromJson(Map<String, dynamic> json) {
    return UserProfileDto(
      id: json['id']?.toString() ?? '',
      displayName:
          json['display_name']?.toString() ??
          json['username']?.toString() ??
          '',
      profilePhoto: json['profile_photo']?.toString(),
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
    );
  }

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return displayName;
  }
}

// DTO for provider profile data from /api/providers/me/profile/ endpoint
class ProviderProfileDto {
  final String id;
  final String displayName;
  final String? profilePhoto;
  final String? businessName;
  final String? description;
  final double? avgRating;
  final int? reviewCount;

  const ProviderProfileDto({
    required this.id,
    required this.displayName,
    this.profilePhoto,
    this.businessName,
    this.description,
    this.avgRating,
    this.reviewCount,
  });

  factory ProviderProfileDto.fromJson(Map<String, dynamic> json) {
    return ProviderProfileDto(
      id: json['id']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      profilePhoto: json['profile_photo']?.toString(),
      businessName: json['business_name']?.toString(),
      description: json['description']?.toString(),
      avgRating: (json['avg_rating'] as num?)?.toDouble(),
      reviewCount: json['review_count'] as int?,
    );
  }

  String get displayBusinessName {
    return businessName?.isNotEmpty == true ? businessName! : displayName;
  }
}

// DTO for nested user data from expand parameter
class UserNestedDto {
  final String id;
  final String displayName;
  final String? profilePhoto;
  final bool isDeleted;

  const UserNestedDto({
    required this.id,
    required this.displayName,
    this.profilePhoto,
    this.isDeleted = false,
  });

  factory UserNestedDto.fromJson(Map<String, dynamic> json) {
    return UserNestedDto(
      id: json['id']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      profilePhoto: json['profile_photo']?.toString(),
      isDeleted: json['is_deleted'] as bool? ?? false,
    );
  }
}

// DTO for provider media data (expanded from API)
class ProviderMediaDto {
  final String id;
  final String service;
  final String url;
  final String caption;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProviderMediaDto({
    required this.id,
    required this.service,
    required this.url,
    this.caption = '',
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProviderMediaDto.fromJson(Map<String, dynamic> json) {
    return ProviderMediaDto(
      id: json['id']?.toString() ?? '',
      service: json['service']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      caption: json['caption']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

// DTO for nested provider data from expand parameter
class ProviderNestedDto {
  final String id;
  final String? user;
  final String providerType;
  final String displayName;
  final String? bio;
  final String? photo;
  final String? phone;
  final String? email;
  final List<dynamic> languages;
  final bool isVerified;
  final bool acceptMessages;
  final bool autoPayoutEnabled;
  final String? profilePhoto;
  final Map<String, dynamic>? country;
  final String? countryIso2;
  final List<LocationDto> locations;
  final List<ProviderMediaDto> media;
  final List<CertificationDto> certifications;
  final List<AvailabilityRuleDto> availabilityRules;
  final double? avgRating;
  final int reviewCount;
  final int hiresCount;
  final String? individualProfile;
  final String? businessProfile;

  const ProviderNestedDto({
    required this.id,
    this.user,
    required this.providerType,
    required this.displayName,
    this.bio,
    this.photo,
    this.phone,
    this.email,
    this.languages = const [],
    this.isVerified = false,
    this.acceptMessages = true,
    this.autoPayoutEnabled = true,
    this.profilePhoto,
    this.country,
    this.countryIso2,
    this.locations = const [],
    this.media = const [],
    this.certifications = const [],
    this.availabilityRules = const [],
    this.avgRating,
    this.reviewCount = 0,
    this.hiresCount = 0,
    this.individualProfile,
    this.businessProfile,
  });

  factory ProviderNestedDto.fromJson(Map<String, dynamic> json) {
    return ProviderNestedDto(
      id: json['id']?.toString() ?? '',
      user: json['user']?.toString(),
      providerType: json['provider_type']?.toString() ?? 'INDIVIDUAL',
      displayName: json['display_name']?.toString() ?? '',
      bio: json['bio']?.toString(),
      photo: json['photo']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      languages: json['languages'] as List<dynamic>? ?? [],
      isVerified: json['is_verified'] as bool? ?? false,
      acceptMessages: json['accept_messages'] as bool? ?? true,
      autoPayoutEnabled: json['auto_payout_enabled'] as bool? ?? true,
      profilePhoto: json['profile_photo']?.toString(),
      country: json['country'] as Map<String, dynamic>?,
      countryIso2: json['country_iso2']?.toString(),
      locations: (json['locations'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(LocationDto.fromJson)
          .toList(growable: false),
      media: (json['media'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ProviderMediaDto.fromJson)
          .toList(growable: false),
      certifications: (json['certifications'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CertificationDto.fromJson)
          .toList(growable: false),
      availabilityRules: (json['availability_rules'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(AvailabilityRuleDto.fromJson)
          .toList(growable: false),
      avgRating: (json['avg_rating'] as num?)?.toDouble(),
      reviewCount: json['review_count'] as int? ?? 0,
      hiresCount: json['hires_count'] as int? ?? 0,
      individualProfile: json['individual_profile']?.toString(),
      businessProfile: json['business_profile']?.toString(),
    );
  }
}

// DTO for location data
class LocationDto {
  final String id;
  final String provider;
  final String name;
  final String address;
  final dynamic point;
  final String phone;

  const LocationDto({
    required this.id,
    required this.provider,
    required this.name,
    required this.address,
    this.point,
    this.phone = '',
  });

  factory LocationDto.fromJson(Map<String, dynamic> json) {
    return LocationDto(
      id: json['id']?.toString() ?? '',
      provider: json['provider']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      point: json['point'],
      phone: json['phone']?.toString() ?? '',
    );
  }
}

// DTO for certification data
class CertificationDto {
  final String id;
  final String provider;
  final String title;
  final String issuer;
  final String issuedDate;
  final String? expiresDate;
  final String credentialId;
  final String credentialUrl;
  final String? document;

  const CertificationDto({
    required this.id,
    required this.provider,
    required this.title,
    required this.issuer,
    required this.issuedDate,
    this.expiresDate,
    this.credentialId = '',
    this.credentialUrl = '',
    this.document,
  });

  factory CertificationDto.fromJson(Map<String, dynamic> json) {
    return CertificationDto(
      id: json['id']?.toString() ?? '',
      provider: json['provider']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      issuer: json['issuer']?.toString() ?? '',
      issuedDate: json['issued_date']?.toString() ?? '',
      expiresDate: json['expires_date']?.toString(),
      credentialId: json['credential_id']?.toString() ?? '',
      credentialUrl: json['credential_url']?.toString() ?? '',
      document: json['document']?.toString(),
    );
  }
}

// DTO for availability rule data
class AvailabilityRuleDto {
  final String id;
  final String provider;
  final int weekday;
  final String startTime;
  final String endTime;
  final bool isClosed;
  final String timezone;

  const AvailabilityRuleDto({
    required this.id,
    required this.provider,
    required this.weekday,
    required this.startTime,
    required this.endTime,
    this.isClosed = false,
    this.timezone = '',
  });

  factory AvailabilityRuleDto.fromJson(Map<String, dynamic> json) {
    return AvailabilityRuleDto(
      id: json['id']?.toString() ?? '',
      provider: json['provider']?.toString() ?? '',
      weekday: json['weekday'] as int? ?? 0,
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      isClosed: json['is_closed'] as bool? ?? false,
      timezone: json['timezone']?.toString() ?? '',
    );
  }
}

// DTO for payment data from expand parameter
class PaymentDto {
  final String id;
  final String provider;
  final String providerReference;
  final String clientSecret;
  final String? authorizationUrl;
  final String booking;
  final String currency;
  final String amount;
  final String commissionAmount;
  final String providerPayoutAmount;
  final String status;
  final DateTime? authorizedAt;
  final DateTime? capturedAt;
  final DateTime? refundedAt;

  const PaymentDto({
    required this.id,
    required this.provider,
    required this.providerReference,
    this.clientSecret = '',
    this.authorizationUrl,
    required this.booking,
    required this.currency,
    required this.amount,
    required this.commissionAmount,
    required this.providerPayoutAmount,
    required this.status,
    this.authorizedAt,
    this.capturedAt,
    this.refundedAt,
  });

  factory PaymentDto.fromJson(Map<String, dynamic> json) {
    return PaymentDto(
      id: json['id']?.toString() ?? '',
      provider: json['provider']?.toString() ?? '',
      providerReference: json['provider_reference']?.toString() ?? '',
      clientSecret: json['client_secret']?.toString() ?? '',
      authorizationUrl: json['authorization_url']?.toString(),
      booking: json['booking']?.toString() ?? '',
      currency: json['currency']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '',
      commissionAmount: json['commission_amount']?.toString() ?? '',
      providerPayoutAmount: json['provider_payout_amount']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      authorizedAt: DateTime.tryParse(json['authorized_at']?.toString() ?? ''),
      capturedAt: DateTime.tryParse(json['captured_at']?.toString() ?? ''),
      refundedAt: DateTime.tryParse(json['refunded_at']?.toString() ?? ''),
    );
  }
}

// Role detection utilities
/// User roles from the API
enum UserRole {
  user,
  individual,
  business,
  admin,
  unknown;

  static UserRole fromString(String role) {
    switch (role.toUpperCase()) {
      case 'USER':
        return UserRole.user;
      case 'INDIVIDUAL':
        return UserRole.individual;
      case 'BUSINESS':
        return UserRole.business;
      case 'ADMIN':
        return UserRole.admin;
      default:
        return UserRole.unknown;
    }
  }

  /// Returns true if the role is a provider (INDIVIDUAL or BUSINESS)
  bool get isProvider =>
      this == UserRole.individual || this == UserRole.business;

  /// Returns true if the role is a regular user (not a provider)
  bool get isClient => this == UserRole.user;
}

/// Helper function to check if a user role string indicates a provider
bool isProviderRole(String? role) {
  if (role == null || role.isEmpty) return false;
  final userRole = UserRole.fromString(role);
  return userRole.isProvider;
}

/// Helper function to check if a user role string indicates a client
bool isClientRole(String? role) {
  if (role == null || role.isEmpty) return false;
  final userRole = UserRole.fromString(role);
  return userRole.isClient;
}

BookingModel mapBookingDto(
  BookingDto dto,
  Map<String, ServiceModel> serviceMap, {
  UserProfileDto? userProfile,
  ProviderProfileDto? providerProfile,
  ReviewDto? review,
}) {
  // Use nested service data if available, otherwise fetch from serviceMap
  final nestedService = dto.items.isNotEmpty ? dto.items.first.service : null;
  final bookedService = nestedService != null
      ? null // Will create snapshot from nested data
      : (dto.items.isNotEmpty ? serviceMap[dto.items.first.serviceId] : null);

  // Parse price type from nested service data
  PriceType? parsePriceType(String? raw) {
    if (raw == null) return null;
    return PriceType.values.firstWhere(
      (e) => e.name.toUpperCase() == raw.toUpperCase(),
      orElse: () => PriceType.fixed,
    );
  }

  final snapshot = bookedService != null
      ? BookedServiceSnapshot.fromService(bookedService)
      : (nestedService != null
            ? BookedServiceSnapshot(
                serviceId: nestedService.id,
                title: nestedService.title,
                category: 'Service',
                imagePath: _extractServiceImagePath(
                  nestedService,
                  dto.provider,
                ),
                formattedPrice: _formatAmount(dto.totalAmount, dto.currency),
                pricingModel: PricingModel.fixed,
                priceType: parsePriceType(nestedService.priceType),
                durationMinutes: int.tryParse(
                  nestedService.durationMinutes ?? '',
                ),
              )
            : BookedServiceSnapshot(
                // Fallback when service data is not available
                // This happens when API doesn't return expanded service data
                // and service is not in the serviceMap cache
                serviceId: dto.items.isNotEmpty
                    ? dto.items.first.serviceId
                    : dto.id,
                title:
                    'Service #${dto.items.isNotEmpty ? dto.items.first.serviceId : dto.id}',
                category: 'Service',
                imagePath: AppAssets.servicePlaceholder(
                  dto.items.isNotEmpty ? dto.items.first.serviceId : dto.id,
                ),
                formattedPrice: _formatAmount(dto.totalAmount, dto.currency),
                pricingModel: PricingModel.fixed,
                durationMinutes:
                    dto.scheduledStart != null && dto.scheduledEnd != null
                    ? dto.scheduledEnd!
                          .difference(dto.scheduledStart!)
                          .inMinutes
                    : null,
              ));

  // Extract user info from nested user object
  final userDisplayName = dto.user?.displayName ?? 'Client';
  final userProfilePhoto = dto.user?.profilePhoto;

  // Extract provider info from nested provider object
  final providerData = dto.provider;
  final providerName = providerData?.displayName ?? 'Provider';
  final providerAvatarPath = providerData?.profilePhoto ?? providerData?.photo;
  final providerEmail = providerData?.email;
  final providerPhone = providerData?.phone;
  final providerBio = providerData?.bio;
  final providerCountry = providerData?.country?['name']?.toString();
  final providerAvgRating = providerData?.avgRating;
  final providerReviewCount = providerData?.reviewCount;
  final providerHiresCount = providerData?.hiresCount;

  // Extract payment info
  final paymentData = dto.payment;
  final paymentStatus = paymentData?.status;
  final paymentAmount = paymentData?.amount;
  final paymentAuthorizationUrl = paymentData?.authorizationUrl;
  final paymentProviderReference = paymentData?.providerReference;

  final rating = review?.rating?.toInt();
  final reviewText = review?.comment;

  return BookingModel(
    id: dto.id,
    service: snapshot,
    clientId: dto.userId, // NEW: Map userId from DTO to clientId in model
    clientName: userDisplayName,
    clientAvatarPath: userProfilePhoto,
    userDisplayName: userDisplayName,
    userProfilePhoto: userProfilePhoto,
    providerId: dto.providerId,
    providerName: providerName,
    providerAvatarPath: providerAvatarPath,
    providerEmail: providerEmail,
    providerPhone: providerPhone,
    providerBio: providerBio,
    providerCountry: providerCountry,
    providerAvgRating: providerAvgRating,
    providerReviewCount: providerReviewCount,
    providerHiresCount: providerHiresCount,
    scheduledDate: dto.scheduledStart ?? DateTime.now(),
    scheduledTime: TimeOfDay.fromDateTime(dto.scheduledStart ?? DateTime.now()),
    scheduledEnd: dto.scheduledEnd,
    status: bookingStatusFromString(dto.status),
    serviceType: dto.serviceType,
    addressText: dto.addressText,
    note: dto.notes,
    createdAt: dto.createdAt,
    updatedAt: dto.updatedAt,
    rating: rating,
    review: reviewText,
    paymentStatus: paymentStatus,
    paymentAmount: paymentAmount,
    paymentAuthorizationUrl: paymentAuthorizationUrl,
    paymentProviderReference: paymentProviderReference,
    concludedUnitPrice: dto.items.isNotEmpty
        ? dto.items.first.unitPriceAmount
        : null,
  );
}

String _formatAmount(String? amount, String? currency) {
  final parsed = double.tryParse(amount ?? '');
  if (parsed == null) return 'Price on request';
  return '${currency ?? 'NGN'} ${parsed.toStringAsFixed(0)}';
}

BookingStatus bookingStatusFromString(String raw) {
  switch (raw.toUpperCase()) {
    case 'CONFIRMED':
      return BookingStatus.confirmed;
    case 'ONGOING':
      return BookingStatus.ongoing;
    case 'COMPLETED':
      return BookingStatus.completed;
    case 'CANCELLED':
      return BookingStatus.cancelled;
    default:
      return BookingStatus.requested;
  }
}

/// Extracts a renderable image path from nested service data
/// The API returns media as UUID strings, not URLs, so we validate
/// and fall back to placeholder if no renderable path is found.
/// We also check the provider's media array since the API provides full media objects there.
String? _extractServiceImagePath(
  ServiceNestedDto service, [
  ProviderNestedDto? provider,
]) {
  // 1. Check provider's media array since API expands full media objects there
  if (provider != null) {
    for (final mediaItem in provider.media) {
      if (mediaItem.service == service.id) {
        if (_isRenderableImagePath(mediaItem.url)) {
          return mediaItem.url;
        }
      }
    }
  }

  // 2. Check if any media item inside service is directly a renderable URL
  for (final mediaItem in service.media) {
    if (_isRenderableImagePath(mediaItem)) {
      return mediaItem;
    }
  }

  // 3. No renderable URL found, use placeholder
  return AppAssets.servicePlaceholder(service.id);
}

/// Validates that a string is a renderable image path (URL or asset path)
/// Rejects UUIDs and other non-renderable strings
bool _isRenderableImagePath(String? value) {
  if (value == null || value.isEmpty) {
    return false;
  }
  return value.startsWith('http://') ||
      value.startsWith('https://') ||
      value.startsWith('assets/');
}
