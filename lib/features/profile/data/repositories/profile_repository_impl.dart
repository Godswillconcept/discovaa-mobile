import 'package:dio/dio.dart';
import 'package:discovaa/core/constants/api_endpoints.dart';
import 'package:discovaa/core/errors/exceptions.dart';
import 'package:discovaa/core/network/api_helpers.dart';
import 'package:discovaa/core/network/dio_client.dart';
import 'package:discovaa/core/network/network_info.dart';
import 'package:discovaa/core/storage/hive_service.dart';
import 'package:discovaa/features/profile/data/models/profile_api_models.dart';
import 'package:discovaa/features/profile/domain/entities/availability.dart';
import 'package:discovaa/features/profile/domain/entities/business_registration.dart';
import 'package:discovaa/features/profile/domain/entities/certification.dart';
import 'package:discovaa/features/profile/domain/entities/location.dart';
import 'package:discovaa/features/profile/domain/entities/payout_account.dart';
import 'package:discovaa/features/profile/domain/entities/provider_payout.dart';
import 'package:discovaa/features/profile/domain/entities/user_profile.dart';
import 'package:discovaa/features/profile/domain/repositories/profile_repository.dart';
import 'package:discovaa/core/storage/secure_token_storage.dart';
import 'package:flutter/material.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final DioClient _dioClient;
  final HiveService _hiveService;
  final NetworkInfo _networkInfo;
  final SecureTokenStorage _tokenStorage;
  bool _lastProfileFromCache = false;

  // Cache configuration
  static const String _profileCacheKey = 'profile.cache.me';
  static const String _profileCacheTimestampKey = 'profile.cache.me.timestamp';

  ProfileRepositoryImpl({
    required DioClient dioClient,
    required HiveService hiveService,
    required NetworkInfo networkInfo,
    required SecureTokenStorage tokenStorage,
  }) : _dioClient = dioClient,
       _hiveService = hiveService,
       _networkInfo = networkInfo,
       _tokenStorage = tokenStorage;

  @override
  bool get lastProfileFromCache => _lastProfileFromCache;

  @override
  Future<UserProfile> fetchProfile() async {
    // Check if online
    final isOnline = await _networkInfo.isConnected;

    if (isOnline) {
      try {
        // Try to fetch from network
        final profile = await _fetchFromNetwork();
        // Cache successful response
        await _cacheProfile(profile);
        _lastProfileFromCache = false;
        return profile;
      } catch (e) {
        // Network failed - try cache fallback
        final cached = _readCachedProfile();
        if (cached != null) {
          debugPrint('Network failed, using cached profile');
          _lastProfileFromCache = true;
          return cached;
        }
        // No cache available, rethrow error
        rethrow;
      }
    } else {
      // OFFLINE - use cache
      final cached = _readCachedProfile();
      if (cached != null) {
        _lastProfileFromCache = true;
        return cached;
      }

      // No cache and offline
      throw NetworkException(
        message: 'No internet connection and no cached profile available.',
        code: 'NO_CACHE',
      );
    }
  }

  /// Fetch profile from network API
  Future<UserProfile> _fetchFromNetwork() async {
    final meResponse = await _dioClient.get(ApiEndpoints.accountsMe);
    final me = decodeEnvelope(
      meResponse,
      (raw) => UserMeDto.fromJson(asMap(raw)),
    ).data;

    ProviderDto? provider;
    ProviderPayoutAccountStatusDto? payoutStatus;
    AccountBalanceDto? balance;

    if ((me.providerId ?? '').isNotEmpty) {
      try {
        final providerResponse = await _dioClient.get(
          ApiEndpoints.providersMeProfile,
        );
        provider = decodeEnvelope(
          providerResponse,
          (raw) => ProviderDto.fromJson(asMap(raw)),
        ).data;
      } catch (_) {}

      try {
        final payoutResponse = await _dioClient.get(ApiEndpoints.payoutAccount);
        payoutStatus = decodeEnvelope(
          payoutResponse,
          (raw) => ProviderPayoutAccountStatusDto.fromJson(asMap(raw)),
        ).data;
      } catch (_) {}

      try {
        final balanceResponse = await _dioClient.get(
          ApiEndpoints.payoutAccountBalance,
        );
        balance = decodeEnvelope(
          balanceResponse,
          (raw) => AccountBalanceDto.fromJson(asMap(raw)),
        ).data;
      } on ValidationException catch (e) {
        if (e.message.contains('No Stripe payout account found')) {
          debugPrint(
            '[ProfileRepository][payouts] No payout balance available because payout account is not configured yet.',
          );
        } else {
          debugPrint(
            '[ProfileRepository][payouts] Unexpected payout balance validation error: ${e.message}',
          );
        }
      } catch (e) {
        debugPrint(
          '[ProfileRepository][payouts] Failed to fetch payout balance: $e',
        );
      }
    }

    return mapProfileAggregate(
      user: me,
      provider: provider,
      balance: balance,
      payoutAccount: payoutStatus?.payoutAccount,
    );
  }

  /// Cache profile to local storage
  Future<void> _cacheProfile(UserProfile profile) async {
    await _hiveService.setMap(_profileCacheKey, profile.toJson());
    await _hiveService.setString(
      _profileCacheTimestampKey,
      DateTime.now().toIso8601String(),
    );
  }

  /// Deep convert `Map<dynamic, dynamic>` to `Map<String, dynamic>` recursively
  dynamic _deepConvertMap(dynamic value) {
    if (value is Map) {
      final converted = <String, dynamic>{};
      for (final key in value.keys) {
        final stringKey = key.toString();
        converted[stringKey] = _deepConvertMap(value[key]);
      }
      return converted;
    } else if (value is List) {
      return value.map((item) => _deepConvertMap(item)).toList();
    }
    return value;
  }

  /// Read cached profile from local storage
  UserProfile? _readCachedProfile() {
    final cached = _hiveService.getMap(_profileCacheKey);
    if (cached == null) return null;

    try {
      // Deep convert to handle nested Map<dynamic, dynamic> structures
      final converted = _deepConvertMap(cached);
      return UserProfile.fromJson(converted);
    } catch (e) {
      debugPrint('Error parsing cached profile: $e');
      return null;
    }
  }

  @override
  Future<void> clearCache() async {
    await _hiveService.remove(_profileCacheKey);
    await _hiveService.remove(_profileCacheTimestampKey);
  }

  @override
  Future<UserProfile> updateFields(
    UserProfile current, {
    String? displayName,
    String? firstName,
    String? lastName,
    String? phone,
    String? country,
    String? gender,
    String? bio,
  }) async {
    if (current.isProvider) {
      await _dioClient.patch(
        ApiEndpoints.providersMeProfile,
        data: ProviderProfileWriteDto(
          displayName: displayName,
          phone: phone,
          countryIso2: country,
          bio: bio,
        ).toJson(),
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      return fetchProfile();
    }

    await _dioClient.patch(
      ApiEndpoints.accountsMe,
      data: {
        'display_name': ?displayName,
        'first_name': ?firstName,
        'last_name': ?lastName,
        'phone': ?phone,
        'country_iso2': ?country,
        'gender': ?gender,
        'bio': ?bio,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    return fetchProfile();
  }

  @override
  Future<UserProfile> updateIdentityVerification(
    UserProfile current, {
    required String idNumber,
    String? idFrontImagePath,
    String? idBackImagePath,
  }) async {
    await _dioClient.patch(
      ApiEndpoints.accountsMe,
      data: buildIdentityVerificationFormData(
        idNumber: idNumber,
        idFrontImagePath: idFrontImagePath,
        idBackImagePath: idBackImagePath,
      ),
      options: Options(contentType: 'multipart/form-data'),
    );
    return fetchProfile();
  }

  @override
  Future<UserProfile> updateAvailability(Availability availability) async {
    // Fetch current user to get provider ID
    final meResponse = await _dioClient.get(ApiEndpoints.accountsMe);
    final me = decodeEnvelope(
      meResponse,
      (raw) => UserMeDto.fromJson(asMap(raw)),
    ).data;

    final providerId = me.providerId;
    if (providerId == null || providerId.isEmpty) {
      throw Exception('User does not have a provider profile');
    }

    for (final day in availability.days) {
      await _dioClient.post(
        ApiEndpoints.providerAvailabilityRules,
        data: ProviderAvailabilityRuleDto(
          id: '',
          provider: providerId,
          weekday: day.day.index,
          startTime: day.startTime,
          endTime: day.endTime,
          isClosed: !day.isAvailable,
          timezone: availability.timezone,
        ).toWriteJson(),
      );
    }
    return fetchProfile();
  }

  @override
  Future<UserProfile> saveLocation(ServiceLocation serviceLocation) async {
    final dto = ProviderLocationDto(
      id: serviceLocation.id,
      name: serviceLocation.name,
      address: serviceLocation.address,
      lat: serviceLocation.latitude,
      lng: serviceLocation.longitude,
    );
    if (_looksLikeUuid(serviceLocation.id)) {
      await _dioClient.patch(
        '${ApiEndpoints.providerLocations}${serviceLocation.id}/',
        data: dto.toWriteJson(),
      );
    } else {
      await _dioClient.post(
        ApiEndpoints.providerLocations,
        data: dto.toWriteJson(),
      );
    }
    return fetchProfile();
  }

  @override
  Future<UserProfile> deleteLocation(String locationId) async {
    if (_looksLikeUuid(locationId)) {
      await _dioClient.delete('${ApiEndpoints.providerLocations}$locationId/');
    }
    return fetchProfile();
  }

  @override
  Future<UserProfile> saveCertification(
    Certification certification, {
    String? documentPath,
  }) async {
    final dto = ProviderCertificationDto(
      id: certification.id,
      title: certification.name,
      issuer: certification.issuingOrganization,
      issuedDate: certification.issueDate,
      expiresDate: certification.expiryDate,
      document: certification.documentUrl,
    );

    dynamic requestData;
    Options? options;

    if (documentPath != null && documentPath.isNotEmpty) {
      final map = dto.toWriteJson();
      map['document'] = await MultipartFile.fromFile(documentPath);
      requestData = FormData.fromMap(map);
      options = Options(contentType: 'multipart/form-data');
    } else {
      requestData = dto.toWriteJson();
    }

    if (_looksLikeUuid(certification.id)) {
      await _dioClient.patch(
        '${ApiEndpoints.providerCertifications}${certification.id}/',
        data: requestData,
        options: options,
      );
    } else {
      await _dioClient.post(
        ApiEndpoints.providerCertifications,
        data: requestData,
        options: options,
      );
    }
    return fetchProfile();
  }

  @override
  Future<UserProfile> deleteCertification(String certificationId) async {
    if (_looksLikeUuid(certificationId)) {
      await _dioClient.delete(
        '${ApiEndpoints.providerCertifications}$certificationId/',
      );
    }
    return fetchProfile();
  }

  @override
  Future<UserProfile> updateBusinessRegistration(
    BusinessRegistration registration, {
    String? documentPath,
  }) async {
    dynamic requestData;
    Options? options;

    final writeDto = ProviderProfileWriteDto(
      displayName: registration.businessName,
      registrationNumber: registration.registrationNumber,
    ).toJson();

    if (documentPath != null && documentPath.isNotEmpty) {
      writeDto['registration_document'] = await MultipartFile.fromFile(
        documentPath,
      );
      requestData = FormData.fromMap(writeDto);
      options = Options(contentType: 'multipart/form-data');
    } else {
      requestData = writeDto;
      options = Options(contentType: Headers.formUrlEncodedContentType);
    }

    await _dioClient.patch(
      ApiEndpoints.providersMeProfile,
      data: requestData,
      options: options,
    );
    return fetchProfile();
  }

  @override
  Future<UserProfile> updatePayoutAccount(PayoutAccount payoutAccount) async {
    await _dioClient.post(
      ApiEndpoints.payoutAccountSetup,
      data: {
        'currency': payoutAccount.currency ?? 'NGN',
        if (payoutAccount.country != null) 'country': payoutAccount.country,
        if (payoutAccount.email != null) 'email': payoutAccount.email,
      },
    );
    return fetchProfile();
  }

  @override
  Future<String?> startPayoutOnboarding({
    required String currency,
    String? country,
    String? email,
    String? accountNumber,
    String? bankCode,
    String? accountName,
  }) async {
    final data = <String, dynamic>{
      'currency': currency,
      'country': ?country,
      'email': ?email,
      'account_number': ?accountNumber,
      'bank_code': ?bankCode,
      'account_name': ?accountName,
    };
    final response = await _dioClient.post(
      ApiEndpoints.payoutAccountSetup,
      data: data,
    );
    final payload = decodeEnvelope(
      response,
      (raw) => ProviderPayoutAccountSetupResponseDto.fromJson(asMap(raw)),
    ).data;
    return payload.onboardingUrl;
  }

  @override
  Future<String?> resumePayoutOnboarding() async {
    final response = await _dioClient.post(
      ApiEndpoints.payoutAccountResumeOnboarding,
    );
    final payload = decodeEnvelope(
      response,
      (raw) => OnboardingResumeResponseDto.fromJson(asMap(raw)),
    ).data;
    return payload.onboardingUrl;
  }

  @override
  Future<String?> createPayoutUpdateLink() async {
    final response = await _dioClient.post(ApiEndpoints.payoutAccountUpdate);
    final payload = decodeEnvelope(
      response,
      (raw) => AccountUpdateResponseDto.fromJson(asMap(raw)),
    ).data;
    return payload.updateUrl;
  }

  @override
  Future<List<ProviderPayout>> fetchPayouts({int? page, int? pageSize}) async {
    final response = await _dioClient.get(
      ApiEndpoints.payouts,
      queryParameters: {'page': ?page, 'page_size': ?pageSize},
    );
    final payload = decodeListEnvelope(
      response,
      (raw) => ProviderPayoutDto.fromJson(raw),
    );
    return payload.data.map(mapProviderPayout).toList();
  }

  @override
  Future<void> requestPayout() async {
    await _dioClient.post(ApiEndpoints.payouts);
  }

  @override
  Future<void> deleteAccount() async {
    await _dioClient.delete(ApiEndpoints.settings);
    await clearCache(); // Clear local cache when account deleted
  }

  @override
  Future<List<dynamic>> fetchPaystackBanks() async {
    final response = await _dioClient.get(ApiEndpoints.paystackBanks);
    final payload = decodeEnvelope(response, (raw) => raw as List);
    return payload.data;
  }

  @override
  Future<String?> resolvePaystackAccount({
    required String accountNumber,
    required String bankCode,
  }) async {
    final response = await _dioClient.get(
      ApiEndpoints.paystackResolveAccount,
      queryParameters: {'account_number': accountNumber, 'bank_code': bankCode},
    );
    final payload = decodeEnvelope(
      response,
      (raw) => PaystackResolveAccountResponseDto.fromJson(asMap(raw)),
    );
    return payload.data.accountName;
  }

  @override
  Future<UserProfile> deactivateAccount(UserProfile current) async {
    return current.copyWith(isDeactivated: true, updatedAt: DateTime.now());
  }

  @override
  Future<String> uploadAccountProfilePhoto(String filePath) async {
    final formData = FormData.fromMap({
      'profile_photo': await MultipartFile.fromFile(filePath),
    });
    final response = await _dioClient.patch(
      ApiEndpoints.accountsMeProfilePhoto,
      data: formData,
    );
    final envelope = decodeEnvelope(
      response,
      (raw) => UserMeDto.fromJson(asMap(raw)),
    );
    return envelope.data.profilePhoto ?? '';
  }

  @override
  Future<String> uploadProviderPhoto(String filePath) async {
    final formData = FormData.fromMap({
      'profile_photo': await MultipartFile.fromFile(filePath),
    });
    final response = await _dioClient.patch(
      ApiEndpoints.providersMeProviderPhoto,
      data: formData,
    );
    final envelope = decodeEnvelope(
      response,
      (raw) => ProviderDto.fromJson(asMap(raw)),
    );
    return envelope.data.profilePhoto ?? '';
  }

  // ============================================================================
  // SECURITY & AUTHENTICATION IMPLEMENTATIONS
  // ============================================================================

  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    await _dioClient.post(
      ApiEndpoints.authPasswordChange,
      data: {'current_password': currentPassword, 'password': newPassword},
    );
  }

  @override
  Future<void> requestEmailChange(String newEmail) async {
    // Use the AllAuth email management endpoint
    // POST /api/identity/app/v1/account/email to add a new email
    await _dioClient.post(
      '/api/identity/app/v1/account/email',
      data: {'email': newEmail},
    );
  }

  @override
  Future<void> logoutAllDevices() async {
    // Delete all sessions - in AllAuth this typically means revoking all tokens
    try {
      await _dioClient.delete(
        ApiEndpoints.authLogout,
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          extra: {'no-retry': true},
        ),
      );
    } catch (e) {
      // Ignore API errors during logout - we still want to clear local data securely
      debugPrint('[ProfileRepository] Logout API call failed: $e');
    }

    // Clear local cache as well since all sessions are terminated
    await clearCache();
    // CRITICAL: Clear all authentication data locally so the user is signed out on this device too
    await _tokenStorage.clearAllAuthData();
  }
}

bool _looksLikeUuid(String value) {
  return RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  ).hasMatch(value);
}
