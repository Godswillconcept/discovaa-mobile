import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/device_token_model.dart';

/// Abstract remote data source for device token operations
abstract class DeviceTokenRemoteDataSource {
  /// Register a device token for push notifications
  ///
  /// [token] - The FCM or APNS device token
  /// [platform] - The device platform (android, ios, web)
  Future<void> registerDeviceToken({
    required String token,
    required DevicePlatform platform,
  });

  /// Detect the current device platform
  DevicePlatform detectPlatform();
}

/// Implementation using OpenAPI endpoints
class DeviceTokenRemoteDataSourceImpl implements DeviceTokenRemoteDataSource {
  final DioClient _dioClient;

  DeviceTokenRemoteDataSourceImpl({required DioClient dioClient})
    : _dioClient = dioClient;

  @override
  DevicePlatform detectPlatform() {
    if (kIsWeb) {
      return DevicePlatform.web;
    }
    if (Platform.isAndroid) {
      return DevicePlatform.android;
    }
    if (Platform.isIOS) {
      return DevicePlatform.ios;
    }
    return DevicePlatform.unknown;
  }

  @override
  Future<void> registerDeviceToken({
    required String token,
    required DevicePlatform platform,
  }) async {
    try {
      final request = DeviceTokenRequest(
        token: token,
        platform: platform.apiValue,
      );

      final response = await _dioClient.post(
        ApiEndpoints.deviceTokensRegister,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        debugPrint('[DeviceTokenRemoteDataSource] Device token registered successfully');
        return;
      }

      // Handle error response
      throw ServerException(
        message: 'Failed to register device token',
        code: 'DEVICE_TOKEN_REGISTRATION_FAILED',
      );
    } on DioException catch (e) {
      // Log but don't throw - device registration is best-effort
      debugPrint('[DeviceTokenRemoteDataSource] DioException during registration: ${e.message}');
      // Don't rethrow - allow login to succeed even if device registration fails
    } on NetworkException {
      // Log but don't throw
      debugPrint('[DeviceTokenRemoteDataSource] NetworkException during registration');
    } on ServerException {
      // Log but don't throw
      debugPrint('[DeviceTokenRemoteDataSource] ServerException during registration');
    } catch (e) {
      // Log but don't throw
      debugPrint('[DeviceTokenRemoteDataSource] Unexpected error during registration: $e');
    }
  }
}

/// Provider function for creating device token data source instance
DeviceTokenRemoteDataSource createDeviceTokenRemoteDataSource(DioClient dioClient) {
  return DeviceTokenRemoteDataSourceImpl(dioClient: dioClient);
}
