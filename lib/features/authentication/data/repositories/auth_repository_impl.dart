import 'dart:io';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/registration_entity.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/device_token_remote_datasource.dart';
import '../models/registration_model.dart';

/// Implementation of AuthRepository
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final DeviceTokenRemoteDataSource _deviceTokenDataSource;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required DeviceTokenRemoteDataSource deviceTokenDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _deviceTokenDataSource = deviceTokenDataSource;

  @override
  Future<Result<UserEntity>> register(RegistrationEntity registration) async {
    try {
      final registrationModel = RegistrationModel.fromEntity(registration);
      final userModel = await _remoteDataSource.register(registrationModel);
      return Result.success(userModel.toEntity());
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Result.error(ServerFailure(message: e.message, code: e.code));
    } on ValidationException catch (e) {
      return Result.error(
        ValidationFailure(
          message: e.message,
          code: e.code,
          fieldErrors: e.fieldErrors,
        ),
      );
    } on ConflictException catch (e) {
      return Result.error(ConflictFailure(message: e.message, code: e.code));
    } catch (e) {
      return Result.error(
        UnknownFailure(
          message: 'Unexpected error during registration',
          code: 'UNKNOWN_REGISTRATION_ERROR',
        ),
      );
    }
  }

  @override
  Future<Result<bool>> verifyOtp({
    required String email,
    required String otpCode,
  }) async {
    try {
      final result = await _remoteDataSource.verifyEmail(
        email: email,
        code: otpCode,
      );
      return Result.success(result);
    } on ConflictException catch (_) {
      // 409 could mean email already verified - treat as success
      // The user can proceed since email is verified
      return Result.success(true);
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Result.error(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      return Result.error(
        UnknownFailure(
          message: 'Unexpected error during email verification',
          code: 'UNKNOWN_EMAIL_VERIFICATION_ERROR',
        ),
      );
    }
  }

  /// Note: completeProfile is not needed in OpenAPI - signup includes profile
  /// This method now just fetches the current user
  @override
  Future<Result<UserEntity>> completeProfile(ProfileEntity profile) async {
    try {
      final userModel = await _remoteDataSource.getCurrentUser();
      if (userModel != null) {
        return Result.success(userModel.toEntity());
      }
      return Result.error(
        UnknownFailure(
          message: 'Failed to get current user',
          code: 'GET_USER_FAILED',
        ),
      );
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Result.error(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      return Result.error(
        UnknownFailure(
          message: 'Unexpected error during profile completion',
          code: 'UNKNOWN_PROFILE_ERROR',
        ),
      );
    }
  }

  @override
  Future<Result<UserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final userModel = await _remoteDataSource.login(
        email: email,
        password: password,
      );
      return Result.success(userModel.toEntity());
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(message: e.message, code: e.code));
    } on AuthenticationException catch (e) {
      return Result.error(
        AuthenticationFailure(message: e.message, code: e.code),
      );
    } on ServerException catch (e) {
      return Result.error(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      return Result.error(
        UnknownFailure(
          message: 'Unexpected error during login',
          code: 'UNKNOWN_LOGIN_ERROR',
        ),
      );
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _remoteDataSource.logout();
      return Result.success(null);
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(message: e.message, code: e.code));
    } catch (e) {
      return Result.error(
        UnknownFailure(
          message: 'Unexpected error during logout',
          code: 'UNKNOWN_LOGOUT_ERROR',
        ),
      );
    }
  }

  @override
  Future<Result<UserEntity?>> getCurrentUser() async {
    try {
      final userModel = await _remoteDataSource.getCurrentUser();
      return Result.success(userModel?.toEntity());
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(message: e.message, code: e.code));
    } catch (e) {
      return Result.error(
        UnknownFailure(
          message: 'Unexpected error getting current user',
          code: 'UNKNOWN_GET_USER_ERROR',
        ),
      );
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final result = await getCurrentUser();
    return result.isSuccess && result.data != null;
  }

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    try {
      await _remoteDataSource.sendPasswordResetEmail(email);
      return Result.success(null);
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(message: e.message, code: e.code));
    } on NotFoundException catch (e) {
      return Result.error(NotFoundFailure(message: e.message, code: e.code));
    } catch (e) {
      return Result.error(
        UnknownFailure(
          message: 'Unexpected error sending reset email',
          code: 'UNKNOWN_RESET_EMAIL_ERROR',
        ),
      );
    }
  }

  @override
  Future<Result<void>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _remoteDataSource.resetPassword(
        key: token,
        newPassword: newPassword,
      );
      return Result.success(null);
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(message: e.message, code: e.code));
    } on ValidationException catch (e) {
      return Result.error(ValidationFailure(message: e.message, code: e.code));
    } catch (e) {
      return Result.error(
        UnknownFailure(
          message: 'Unexpected error resetting password',
          code: 'UNKNOWN_PASSWORD_RESET_ERROR',
        ),
      );
    }
  }

  @override
  Future<Result<void>> resendOtp(String email) async {
    try {
      await _remoteDataSource.resendEmailVerification(email);
      return Result.success(null);
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(message: e.message, code: e.code));
    } on RateLimitException catch (e) {
      return Result.error(
        RateLimitFailure(
          message: e.message,
          code: e.code,
          retryAfter: e.retryAfter,
        ),
      );
    } catch (e) {
      return Result.error(
        UnknownFailure(
          message: 'Unexpected error resending verification email',
          code: 'UNKNOWN_RESEND_VERIFICATION_ERROR',
        ),
      );
    }
  }

  @override
  Future<Result<void>> registerDeviceToken({required String token}) async {
    try {
      final platform = _deviceTokenDataSource.detectPlatform();
      await _deviceTokenDataSource.registerDeviceToken(
        token: token,
        platform: platform,
      );
      return Result.success(null);
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Result.error(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      return Result.error(
        UnknownFailure(
          message: 'Unexpected error registering device token',
          code: 'UNKNOWN_DEVICE_TOKEN_ERROR',
        ),
      );
    }
  }

  @override
  Future<Result<UserEntity>> updateProfile({
    required String firstName,
    required String lastName,
    required String displayName,
    required String phone,
    required String? countryIso2,
    String? businessName,
    String? businessDescription,
  }) async {
    try {
      // Call the remote data source to update profile
      final userModel = await _remoteDataSource.updateProfile(
        firstName: firstName,
        lastName: lastName,
        displayName: displayName,
        phone: phone,
        countryIso2: countryIso2,
        businessName: businessName,
        businessDescription: businessDescription,
      );
      return Result.success(userModel.toEntity());
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Result.error(ServerFailure(message: e.message, code: e.code));
    } on ValidationException catch (e) {
      return Result.error(ValidationFailure(message: e.message, code: e.code));
    } catch (e) {
      return Result.error(
        UnknownFailure(
          message: 'Unexpected error updating profile',
          code: 'UNKNOWN_PROFILE_UPDATE_ERROR',
        ),
      );
    }
  }

  @override
  Future<Result<UserEntity?>> fetchFullProfile() async {
    try {
      final userModel = await _remoteDataSource.fetchFullProfile();
      if (userModel != null) {
        return Result.success(userModel.toEntity());
      }
      return Result.success(null);
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Result.error(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      return Result.error(
        UnknownFailure(
          message: 'Unexpected error fetching full profile',
          code: 'UNKNOWN_FETCH_PROFILE_ERROR',
        ),
      );
    }
  }

  @override
  Future<Result<Map<String, dynamic>?>> fetchConfig() async {
    try {
      final config = await _remoteDataSource.fetchConfig();
      return Result.success(config);
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Result.error(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      return Result.error(
        UnknownFailure(
          message: 'Unexpected error fetching config',
          code: 'UNKNOWN_CONFIG_ERROR',
        ),
      );
    }
  }

  @override
  Future<Result<UserEntity>> uploadIdDocumentFront({
    required String idNumber,
    required File documentFront,
  }) async {
    try {
      final userModel = await _remoteDataSource.uploadIdDocumentFront(
        idNumber: idNumber,
        documentFront: documentFront,
      );
      return Result.success(userModel.toEntity());
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Result.error(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      return Result.error(
        UnknownFailure(
          message: 'Unexpected error uploading ID document front',
          code: 'UNKNOWN_ID_FRONT_ERROR',
        ),
      );
    }
  }

  @override
  Future<Result<UserEntity>> uploadIdDocumentBack({
    required String idNumber,
    required File documentBack,
  }) async {
    try {
      final userModel = await _remoteDataSource.uploadIdDocumentBack(
        idNumber: idNumber,
        documentBack: documentBack,
      );
      return Result.success(userModel.toEntity());
    } on NetworkException catch (e) {
      return Result.error(NetworkFailure(message: e.message, code: e.code));
    } on ServerException catch (e) {
      return Result.error(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      return Result.error(
        UnknownFailure(
          message: 'Unexpected error uploading ID document back',
          code: 'UNKNOWN_ID_BACK_ERROR',
        ),
      );
    }
  }
}
