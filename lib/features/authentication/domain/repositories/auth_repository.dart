import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../entities/registration_entity.dart';
import '../entities/profile_entity.dart';

/// Result wrapper for repository operations
class Result<T> {
  final T? data;
  final Failure? failure;

  const Result._({this.data, this.failure});

  factory Result.success(T data) => Result._(data: data);
  factory Result.error(Failure failure) => Result._(failure: failure);

  bool get isSuccess => failure == null;
  bool get isError => failure != null;
}

/// Abstract repository for authentication operations
abstract class AuthRepository {
  /// Register a new user
  Future<Result<UserEntity>> register(RegistrationEntity registration);

  /// Verify OTP code
  Future<Result<bool>> verifyOtp({
    required String email,
    required String otpCode,
  });

  /// Complete user profile
  Future<Result<UserEntity>> completeProfile(ProfileEntity profile);

  /// Login with email and password
  Future<Result<UserEntity>> login({
    required String email,
    required String password,
  });

  /// Logout current user
  Future<Result<void>> logout();

  /// Get current authenticated user
  Future<Result<UserEntity?>> getCurrentUser();

  /// Check if user is authenticated
  Future<bool> isAuthenticated();

  /// Send password reset email
  Future<Result<void>> sendPasswordResetEmail(String email);

  /// Reset password with token
  Future<Result<void>> resetPassword({
    required String token,
    required String newPassword,
  });

  /// Resend OTP code
  Future<Result<void>> resendOtp(String email);

  /// Register device token for push notifications
  Future<Result<void>> registerDeviceToken({required String token});

  /// Update user profile (for resumed registration flow)
  Future<Result<UserEntity>> updateProfile({
    required String displayName,
    required String phone,
    required String address,
    required String? country,
    String? businessName,
    String? businessDescription,
  });
}
