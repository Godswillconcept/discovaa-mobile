import 'package:discovaa/app/dependency_injection/service_locator.dart';
import 'package:discovaa/features/profile/domain/entities/user_profile.dart';
import 'package:discovaa/features/profile/domain/entities/availability.dart';
import 'package:discovaa/features/profile/domain/entities/location.dart'
    as location;
import 'package:discovaa/features/profile/domain/entities/business_registration.dart';
import 'package:discovaa/features/profile/domain/entities/payout_account.dart';
import 'package:discovaa/features/profile/domain/entities/certification.dart';
import 'package:discovaa/features/profile/domain/repositories/profile_repository.dart';
import 'package:discovaa/features/profile/presentation/providers/profile_connectivity_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Profile operation state for tracking individual operations
enum ProfileOperationState { idle, loading, success, error }

/// State class that holds profile data and operation states
class ProfileState {
  final UserProfile? profile;
  final bool isLoading;
  final String? errorMessage;
  final ProfileOperationState updateState;
  final ProfileOperationState imageUploadState;
  final bool hasPendingChanges;
  final bool isFromCache; // Whether profile was loaded from cache
  final DateTime? cacheTimestamp; // When the cached data was last updated

  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.errorMessage,
    this.updateState = ProfileOperationState.idle,
    this.imageUploadState = ProfileOperationState.idle,
    this.hasPendingChanges = false,
    this.isFromCache = false,
    this.cacheTimestamp,
  });

  ProfileState copyWith({
    UserProfile? profile,
    bool? isLoading,
    String? errorMessage,
    ProfileOperationState? updateState,
    ProfileOperationState? imageUploadState,
    bool? hasPendingChanges,
    bool? isFromCache,
    DateTime? cacheTimestamp,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      updateState: updateState ?? this.updateState,
      imageUploadState: imageUploadState ?? this.imageUploadState,
      hasPendingChanges: hasPendingChanges ?? this.hasPendingChanges,
      isFromCache: isFromCache ?? this.isFromCache,
      cacheTimestamp: cacheTimestamp ?? this.cacheTimestamp,
    );
  }
}

/// Main provider for user profile with comprehensive state management
final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, ProfileState>((ref) {
      return UserProfileNotifier(ref, ref.watch(profileRepositoryProvider));
    });

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return sl<ProfileRepository>();
});

/// Async version for compatibility with existing code
final userProfileAsyncProvider = Provider<AsyncValue<UserProfile>>((ref) {
  final state = ref.watch(userProfileProvider);
  if (state.isLoading) return const AsyncValue.loading();
  if (state.errorMessage != null) {
    return AsyncValue.error(state.errorMessage!, StackTrace.current);
  }
  if (state.profile != null) return AsyncValue.data(state.profile!);
  return const AsyncValue.loading();
});

class UserProfileNotifier extends StateNotifier<ProfileState> {
  final Ref _ref;
  final ProfileRepository _repository;

  UserProfileNotifier(this._ref, this._repository)
    : super(const ProfileState(isLoading: true)) {
    _fetchProfile();
  }

  /// Fetch profile from remote API or cache
  Future<void> _fetchProfile() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final profile = await _repository.fetchProfile();
      final isFromCache = _repository.lastProfileFromCache;

      state = state.copyWith(
        profile: profile,
        isLoading: false,
        hasPendingChanges: false,
        isFromCache: isFromCache,
        cacheTimestamp: isFromCache ? DateTime.now() : null,
      );
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load profile. Please try again.',
        isFromCache: false,
      );
    }
  }

  /// Refresh profile data
  Future<void> refresh() async {
    await _fetchProfile();
  }

  /// Update profile with optimistic updates and error handling
  Future<bool> updateProfile(UserProfile updatedProfile) async {
    state = state.copyWith(
      profile: updatedProfile,
      updateState: ProfileOperationState.loading,
      hasPendingChanges: false,
      errorMessage: null,
    );

    try {
      // Success
      state = state.copyWith(
        updateState: ProfileOperationState.success,
        hasPendingChanges: false,
        errorMessage: null,
      );

      // Reset to idle after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          state = state.copyWith(updateState: ProfileOperationState.idle);
        }
      });

      return true;
    } catch (e) {
      state = state.copyWith(
        updateState: ProfileOperationState.error,
        errorMessage: 'Failed to update profile. Please try again.',
      );
      return false;
    }
  }

  /// Update specific profile fields
  Future<bool> updateFields({
    String? displayName,
    String? firstName,
    String? lastName,
    String? phone,
    String? country,
    String? gender,
    String? bio,
  }) async {
    if (state.profile == null) return false;
    try {
      final updatedProfile = await _repository.updateFields(
        state.profile!,
        displayName: displayName,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        country: country,
        gender: gender,
        bio: bio,
      );
      return await updateProfile(updatedProfile);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update profile.');
      return false;
    }
  }

  /// Update identity verification
  Future<bool> updateIdentityVerification({
    required String idNumber,
    String? idFrontImageUrl,
    String? idBackImageUrl,
  }) async {
    if (state.profile == null) return false;
    try {
      final updatedProfile = await _repository.updateIdentityVerification(
        state.profile!,
        idNumber: idNumber,
        idFrontImagePath: idFrontImageUrl,
        idBackImagePath: idBackImageUrl,
      );
      return await updateProfile(updatedProfile);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to update identity verification.',
      );
      return false;
    }
  }

  /// Update availability
  Future<bool> updateAvailability(Availability availability) async {
    if (state.profile == null) return false;
    try {
      final updatedProfile = await _repository.updateAvailability(availability);
      return await updateProfile(updatedProfile);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update availability.');
      return false;
    }
  }

  /// Update password - requires current password for verification
  Future<bool> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    // Check connectivity
    final connectivityNotifier = _ref.read(
      profileConnectivityProvider.notifier,
    );
    final isConnected = await connectivityNotifier.checkConnection();

    if (!isConnected) {
      state = state.copyWith(
        errorMessage: 'No connection. Please try again when online.',
      );
      return false;
    }

    if (state.profile == null) return false;

    state = state.copyWith(
      updateState: ProfileOperationState.loading,
      errorMessage: null,
    );

    try {
      // Call actual API to change password
      await _repository.changePassword(currentPassword, newPassword);

      final updatedProfile = state.profile!.copyWith(
        passwordLastChanged: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(
        profile: updatedProfile,
        updateState: ProfileOperationState.success,
        errorMessage: null,
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          state = state.copyWith(updateState: ProfileOperationState.idle);
        }
      });

      return true;
    } catch (e) {
      state = state.copyWith(
        updateState: ProfileOperationState.error,
        errorMessage:
            'Failed to update password. Please check your current password.',
      );
      return false;
    }
  }

  /// Delete account
  Future<bool> deleteAccount() async {
    // Check connectivity
    final connectivityNotifier = _ref.read(
      profileConnectivityProvider.notifier,
    );
    final isConnected = await connectivityNotifier.checkConnection();

    if (!isConnected) {
      state = state.copyWith(
        errorMessage: 'No connection. Cannot delete account while offline.',
      );
      return false;
    }

    try {
      await _repository.deleteAccount();
      state = const ProfileState();
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to delete account. Please try again.',
      );
      return false;
    }
  }

  /// Add or update a location
  Future<bool> saveLocation(location.ServiceLocation serviceLocation) async {
    if (state.profile == null) return false;
    try {
      final updatedProfile = await _repository.saveLocation(serviceLocation);
      return await updateProfile(updatedProfile);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to save location.');
      return false;
    }
  }

  /// Delete a location
  Future<bool> deleteLocation(String locationId) async {
    if (state.profile == null) return false;
    try {
      final updatedProfile = await _repository.deleteLocation(locationId);
      return await updateProfile(updatedProfile);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete location.');
      return false;
    }
  }

  /// Add or update a certification
  Future<bool> saveCertification(Certification certification) async {
    if (state.profile == null) return false;
    try {
      final updatedProfile = await _repository.saveCertification(certification);
      return await updateProfile(updatedProfile);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to save certification.');
      return false;
    }
  }

  /// Delete a certification
  Future<bool> deleteCertification(String certificationId) async {
    if (state.profile == null) return false;
    try {
      final updatedProfile = await _repository.deleteCertification(
        certificationId,
      );
      return await updateProfile(updatedProfile);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete certification.');
      return false;
    }
  }

  /// Update business registration
  Future<bool> updateBusinessRegistration(
    BusinessRegistration registration,
  ) async {
    if (state.profile == null) return false;
    try {
      final updatedProfile = await _repository.updateBusinessRegistration(
        registration,
      );
      return await updateProfile(updatedProfile);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to update business registration.',
      );
      return false;
    }
  }

  /// Update payout account
  Future<bool> updatePayoutAccount(PayoutAccount payoutAccount) async {
    if (state.profile == null) return false;
    try {
      final updatedProfile = await _repository.updatePayoutAccount(
        payoutAccount,
      );
      return await updateProfile(updatedProfile);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update payout account.');
      return false;
    }
  }

  /// Start payout onboarding and return the onboarding URL if available.
  Future<String?> startPayoutOnboarding({String? currency}) async {
    final profile = state.profile;
    if (profile == null) return null;
    try {
      final onboardingUrl = await _repository.startPayoutOnboarding(
        currency: currency ?? profile.payoutAccount?.currency ?? 'NGN',
        country: profile.countryCode ?? profile.country,
        email: profile.email,
      );
      await _fetchProfile();
      return onboardingUrl;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to start payout onboarding.',
      );
      return null;
    }
  }

  /// Resume onboarding for restricted accounts.
  Future<String?> resumePayoutOnboarding() async {
    try {
      final onboardingUrl = await _repository.resumePayoutOnboarding();
      await _fetchProfile();
      return onboardingUrl;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to resume payout onboarding.',
      );
      return null;
    }
  }

  /// Generate an update link for the payout account.
  Future<String?> createPayoutUpdateLink() async {
    try {
      return await _repository.createPayoutUpdateLink();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to create payout update link.',
      );
      return null;
    }
  }

  /// Request a payout transfer.
  Future<bool> requestPayout() async {
    try {
      await _repository.requestPayout();
      await _fetchProfile();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to request payout.');
      return false;
    }
  }

  /// Refresh profile from server
  Future<void> refreshProfile() async {
    await _fetchProfile();
  }

  /// Deactivate account (temporarily disable)
  Future<bool> deactivateAccount() async {
    // Check connectivity
    final connectivityNotifier = _ref.read(
      profileConnectivityProvider.notifier,
    );
    final isConnected = await connectivityNotifier.checkConnection();

    if (!isConnected) {
      state = state.copyWith(
        errorMessage: 'No connection. Cannot deactivate account while offline.',
      );
      return false;
    }

    if (state.profile == null) return false;

    try {
      final updatedProfile = await _repository.deactivateAccount(
        state.profile!,
      );

      state = state.copyWith(profile: updatedProfile);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to deactivate account. Please try again.',
      );
      return false;
    }
  }

  /// Request email change - sends verification to new email
  Future<bool> requestEmailChange(String newEmail) async {
    // Check connectivity
    final connectivityNotifier = _ref.read(
      profileConnectivityProvider.notifier,
    );
    final isConnected = await connectivityNotifier.checkConnection();

    if (!isConnected) {
      state = state.copyWith(
        errorMessage:
            'No connection. Cannot request email change while offline.',
      );
      return false;
    }

    state = state.copyWith(
      updateState: ProfileOperationState.loading,
      errorMessage: null,
    );

    try {
      await _repository.requestEmailChange(newEmail);

      state = state.copyWith(
        updateState: ProfileOperationState.success,
        errorMessage: null,
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          state = state.copyWith(updateState: ProfileOperationState.idle);
        }
      });

      return true;
    } catch (e) {
      state = state.copyWith(
        updateState: ProfileOperationState.error,
        errorMessage: 'Failed to request email change. Please try again.',
      );
      return false;
    }
  }

  /// Logout from all devices
  Future<bool> logoutAllDevices() async {
    // Check connectivity
    final connectivityNotifier = _ref.read(
      profileConnectivityProvider.notifier,
    );
    final isConnected = await connectivityNotifier.checkConnection();

    if (!isConnected) {
      state = state.copyWith(
        errorMessage:
            'No connection. Cannot logout from all devices while offline.',
      );
      return false;
    }

    try {
      await _repository.logoutAllDevices();
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to logout from all devices. Please try again.',
      );
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Upload account profile photo
  Future<String?> uploadAccountProfilePhoto(String filePath) async {
    if (state.profile == null) return null;
    state = state.copyWith(imageUploadState: ProfileOperationState.loading);
    try {
      final photoUrl = await _repository.uploadAccountProfilePhoto(filePath);
      final updatedProfile = state.profile!.copyWith(
        profileImage: photoUrl,
        updatedAt: DateTime.now(),
      );
      state = state.copyWith(
        profile: updatedProfile,
        imageUploadState: ProfileOperationState.success,
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          state = state.copyWith(imageUploadState: ProfileOperationState.idle);
        }
      });
      return photoUrl;
    } catch (e) {
      state = state.copyWith(
        imageUploadState: ProfileOperationState.error,
        errorMessage: 'Failed to upload profile photo.',
      );
      return null;
    }
  }

  /// Upload provider business photo
  Future<String?> uploadProviderPhoto(String filePath) async {
    if (state.profile == null) return null;
    state = state.copyWith(imageUploadState: ProfileOperationState.loading);
    try {
      final photoUrl = await _repository.uploadProviderPhoto(filePath);
      final updatedProfile = state.profile!.copyWith(
        profileImage: photoUrl,
        updatedAt: DateTime.now(),
      );
      state = state.copyWith(
        profile: updatedProfile,
        imageUploadState: ProfileOperationState.success,
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          state = state.copyWith(imageUploadState: ProfileOperationState.idle);
        }
      });
      return photoUrl;
    } catch (e) {
      state = state.copyWith(
        imageUploadState: ProfileOperationState.error,
        errorMessage: 'Failed to upload provider photo.',
      );
      return null;
    }
  }
}
