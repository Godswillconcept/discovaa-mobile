import 'package:discovaa/features/payments/domain/entities/refund_entity.dart';

/// Abstract repository for refund operations
abstract class RefundRepository {
  /// Create a new refund request
  /// Returns the created RefundRequest
  /// Throws exception if amount > captured amount
  Future<RefundRequest> createRefund({
    required String paymentId,
    required double amount,
    required String reason,
  });

  /// Get all refund requests, optionally filtered by status
  Future<List<RefundRequest>> getRefunds({String? status});

  /// Get a single refund request by ID
  Future<RefundRequest> getRefund(String refundId);

  /// Cancel a refund request (if still pending)
  /// Returns the updated RefundRequest
  Future<RefundRequest> cancelRefund(String refundId);
}
