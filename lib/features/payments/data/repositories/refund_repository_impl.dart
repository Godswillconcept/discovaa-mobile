import 'package:dio/dio.dart';
import 'package:discovaa/core/network/dio_client.dart';
import 'package:discovaa/features/payments/domain/entities/refund_entity.dart';
import 'package:discovaa/features/payments/domain/repositories/refund_repository.dart';

/// Implementation of RefundRepository that communicates with the API
class RefundRepositoryImpl implements RefundRepository {
  final DioClient _dioClient;

  RefundRepositoryImpl(this._dioClient);

  @override
  Future<RefundRequest> createRefund({
    required String paymentId,
    required double amount,
    required String reason,
  }) async {
    try {
      final response = await _dioClient.post(
        '/api/payments/refunds/',
        data: {'payment': paymentId, 'amount': amount, 'reason': reason},
      );

      return _parseRefundResponse(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e, 'create refund');
    } catch (e) {
      throw Exception('Failed to create refund: $e');
    }
  }

  @override
  Future<List<RefundRequest>> getRefunds({String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) {
        queryParams['status'] = status;
      }

      final response = await _dioClient.get(
        '/api/payments/refunds/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final List<dynamic> refundsJson = response.data is List
          ? response.data
          : (response.data['results'] ?? response.data['data'] ?? []);

      return refundsJson
          .map((json) => _parseRefundResponse(json))
          .toList(growable: false);
    } on DioException catch (e) {
      throw _handleDioError(e, 'get refunds');
    } catch (e) {
      throw Exception('Failed to get refunds: $e');
    }
  }

  @override
  Future<RefundRequest> getRefund(String refundId) async {
    try {
      final response = await _dioClient.get('/api/payments/refunds/$refundId/');

      return _parseRefundResponse(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e, 'get refund');
    } catch (e) {
      throw Exception('Failed to get refund: $e');
    }
  }

  @override
  Future<RefundRequest> cancelRefund(String refundId) async {
    try {
      final response = await _dioClient.patch(
        '/api/payments/refunds/$refundId/',
        data: {'status': 'REJECTED'},
      );

      return _parseRefundResponse(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e, 'cancel refund');
    } catch (e) {
      throw Exception('Failed to cancel refund: $e');
    }
  }

  /// Parse API response into RefundRequest entity
  RefundRequest _parseRefundResponse(dynamic data) {
    final Map<String, dynamic> json = data is Map<String, dynamic>
        ? data
        : Map<String, dynamic>.from(data);

    return RefundRequest(
      id: json['id']?.toString() ?? '',
      paymentId: json['payment']?.toString() ?? '',
      amount: _parseAmount(json['amount']),
      reason: json['reason']?.toString() ?? '',
      status: RefundStatus.fromApiValue(
        json['status']?.toString() ?? 'PENDING',
      ),
      initiator: RefundInitiator.fromApiValue(
        json['initiator']?.toString() ?? 'CUSTOMER',
      ),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
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

      if (statusCode == 400) {
        final message = data is Map ? data['detail'] ?? data['message'] : null;
        if (message != null) {
          return Exception('Failed to $operation: $message');
        }
      }

      if (statusCode == 404) {
        return Exception('Resource not found while trying to $operation');
      }

      if (statusCode == 403) {
        return Exception('Not authorized to $operation');
      }

      return Exception(
        'Failed to $operation: $statusCode - ${e.response!.statusMessage}',
      );
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception('Connection timeout while trying to $operation');
    }

    if (e.type == DioExceptionType.connectionError) {
      return Exception('No internet connection while trying to $operation');
    }

    return Exception('Failed to $operation: ${e.message}');
  }
}
