import 'package:dio/dio.dart';
import 'package:discovaa/core/errors/exceptions.dart';
import 'package:discovaa/core/network/api_models.dart';

Map<String, dynamic> asMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  // Handle Map<dynamic, dynamic> from Hive/Dio by converting keys to String
  if (data is Map) {
    return Map<String, dynamic>.from(data);
  }
  throw ParseException(
    message: 'Invalid API payload: expected an object',
    code: 'INVALID_API_PAYLOAD',
    details: data,
  );
}

ApiEnvelope<T> decodeEnvelope<T>(
  Response<dynamic> response,
  T Function(dynamic rawData) decoder,
) {
  return ApiEnvelope<T>.fromJson(asMap(response.data), decoder);
}

ApiListEnvelope<T> decodeListEnvelope<T>(
  Response<dynamic> response,
  T Function(Map<String, dynamic> item) decoder,
) {
  return ApiListEnvelope<T>.fromJson(asMap(response.data), decoder);
}

String? maybeUuidCategoryId(String category) {
  final trimmed = category.trim();
  if (trimmed.isEmpty) return null;
  final uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );
  return uuid.hasMatch(trimmed) ? trimmed : null;
}
