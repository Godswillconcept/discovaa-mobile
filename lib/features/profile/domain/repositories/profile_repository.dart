import 'package:discovaa/features/profile/domain/entities/availability.dart';
import 'package:discovaa/features/profile/domain/entities/business_registration.dart';
import 'package:discovaa/features/profile/domain/entities/certification.dart';
import 'package:discovaa/features/profile/domain/entities/location.dart';
import 'package:discovaa/features/profile/domain/entities/payout_account.dart';
import 'package:discovaa/features/profile/domain/entities/user_profile.dart';
import 'package:discovaa/features/profile/domain/entities/provider_payout.dart';

abstract class ProfileRepository {
  /// Whether the last profile fetch was from local cache
  bool get lastProfileFromCache;

  Future<UserProfile> fetchProfile();

  Future<UserProfile> updateFields(
    UserProfile current, {
    String? displayName,
    String? firstName,
    String? lastName,
    String? phone,
    String? country,
    String? gender,
    String? bio,
  });

  Future<UserProfile> updateIdentityVerification(
    UserProfile current, {
    required String idNumber,
    String? idFrontImagePath,
    String? idBackImagePath,
  });

  Future<UserProfile> updateAvailability(Availability availability);
  Future<UserProfile> saveLocation(ServiceLocation serviceLocation);
  Future<UserProfile> deleteLocation(String locationId);
  Future<UserProfile> saveCertification(Certification certification);
  Future<UserProfile> deleteCertification(String certificationId);
  Future<UserProfile> updateBusinessRegistration(
    BusinessRegistration registration,
  );
  Future<UserProfile> updatePayoutAccount(PayoutAccount payoutAccount);
  Future<String?> startPayoutOnboarding({
    required String currency,
    String? country,
    String? email,
  });
  Future<String?> resumePayoutOnboarding();
  Future<String?> createPayoutUpdateLink();
  Future<List<ProviderPayout>> fetchPayouts({int? page, int? pageSize});
  Future<void> requestPayout();
  Future<void> deleteAccount();
  Future<UserProfile> deactivateAccount(UserProfile current);
  Future<String> uploadAccountProfilePhoto(String filePath);
  Future<String> uploadProviderPhoto(String filePath);

  /// Clear local profile cache
  Future<void> clearCache();

  // ============================================================================
  // SECURITY & AUTHENTICATION METHODS
  // ============================================================================

  /// Change user password
  /// [currentPassword] - The current password for verification
  /// [newPassword] - The new password to set
  /// Throws [ServerException] if current password is incorrect
  Future<void> changePassword(String currentPassword, String newPassword);

  /// Request email change - sends verification email to new address
  /// [newEmail] - The new email address to change to
  /// Throws [ServerException] if email is already in use or invalid
  Future<void> requestEmailChange(String newEmail);

  /// Logout from all devices/sessions
  /// Invalidates all active sessions except current
  Future<void> logoutAllDevices();
}
