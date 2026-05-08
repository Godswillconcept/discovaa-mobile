import 'package:dio/dio.dart';
import 'package:discovaa/core/network/dio_client.dart';
import 'package:discovaa/features/payments/domain/entities/payment_entity.dart';
import 'package:discovaa/features/payments/domain/repositories/payment_repository.dart';

/// Implementation of PaymentRepository that communicates with the API
class PaymentRepositoryImpl implements PaymentRepository {
  final DioClient _dioClient;

  PaymentRepositoryImpl(this._dioClient);

  @override
  Future<Payment> authorizePayment(
    String bookingId,
    String paymentMethod,
  ) async {
    try {
      final response = await _dioClient.post(
        '/api/payments/authorize/',
        data: {'booking': bookingId, 'payment_method': paymentMethod},
      );

      return _parsePaymentResponse(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e, 'authorize payment');
    } catch (e) {
      throw Exception('Failed to authorize payment: $e');
    }
  }

  @override
  Future<Payment> capturePayment(String paymentId) async {
    try {
      final response = await _dioClient.post(
        '/api/payments/$paymentId/capture/',
      );

      return _parsePaymentResponse(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e, 'capture payment');
    } catch (e) {
      throw Exception('Failed to capture payment: $e');
    }
  }

  @override
  Future<Payment> getPayment(String paymentId) async {
    try {
      final response = await _dioClient.get('/api/payments/$paymentId/');

      return _parsePaymentResponse(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e, 'get payment');
    } catch (e) {
      throw Exception('Failed to get payment: $e');
    }
  }

  @override
  Future<List<Payment>> getPayments({String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) {
        queryParams['status'] = status;
      }

      final response = await _dioClient.get(
        '/api/payments/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final List<dynamic> paymentsJson = response.data is List
          ? response.data
          : (response.data['results'] ?? response.data['data'] ?? []);

      return paymentsJson
          .map((json) => _parsePaymentResponse(json))
          .toList(growable: false);
    } on DioException catch (e) {
      throw _handleDioError(e, 'get payments');
    } catch (e) {
      throw Exception('Failed to get payments: $e');
    }
  }

  @override
  Future<Payment> cancelPayment(String paymentId) async {
    try {
      final response = await _dioClient.post(
        '/api/payments/$paymentId/cancel/',
      );

      return _parsePaymentResponse(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e, 'cancel payment');
    } catch (e) {
      throw Exception('Failed to cancel payment: $e');
    }
  }

  /// Parse API response into Payment entity
  Payment _parsePaymentResponse(dynamic data) {
    final Map<String, dynamic> json = data is Map<String, dynamic>
        ? data
        : Map<String, dynamic>.from(data);

    return Payment(
      id: json['id']?.toString() ?? '',
      bookingId: json['booking']?.toString() ?? '',
      status: _parsePaymentStatus(json['status']?.toString() ?? 'FAILED'),
      amount: _parseAmount(json['amount']),
      capturedAmount: json['captured_amount'] != null
          ? _parseAmount(json['captured_amount'])
          : null,
      failureReason: json['failure_reason'] as String?,
      authorizationUrl: json['authorization_url'] as String?,
      providerReference: json['provider_reference'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  /// Parse payment status string to enum
  PaymentStatus _parsePaymentStatus(String status) {
    switch (status.toUpperCase()) {
      case 'REQUIRES_ACTION':
        return PaymentStatus.requiresAction;
      case 'AUTHORIZED':
        return PaymentStatus.authorized;
      case 'CAPTURED':
        return PaymentStatus.captured;
      case 'PARTIALLY_REFUNDED':
        return PaymentStatus.partiallyRefunded;
      case 'REFUNDED':
        return PaymentStatus.refunded;
      case 'CANCELLED':
        return PaymentStatus.cancelled;
      case 'FAILED':
      default:
        return PaymentStatus.failed;
    }
  }

  /// Parse amount from various formats (string, int, double)
  double _parseAmount(dynamic amount) {
    if (amount == null) return 0.0;
    if (amount is double) return amount;
    if (amount is int) return amount.toDouble();
    if (amount is String) return double.tryParse(amount) ?? 0.0;
    return 0.0;
  }

  /// Handle Dio errors and convert to meaningful exceptions
  Exception _handleDioError(DioException e, String operation) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;
      final message = data is Map ? data['detail'] ?? data['message'] : null;
      return Exception('Failed to $operation: $message (status: $statusCode)');
    }
    return Exception('Failed to $operation: ${e.message}');
  }
}
