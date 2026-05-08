import 'package:discovaa/features/payments/domain/entities/payment_entity.dart';

/// Abstract repository for payment operations
abstract class PaymentRepository {
  /// Authorize (hold) funds for a booking
  /// Returns the authorized Payment with status AUTHORIZED or REQUIRES_ACTION
  Future<Payment> authorizePayment(String bookingId, String paymentMethod);

  /// Capture (release) the held funds after service delivery
  /// Returns the captured Payment with status CAPTURED
  Future<Payment> capturePayment(String paymentId);

  /// Get a single payment by ID
  Future<Payment> getPayment(String paymentId);

  /// Get all payments, optionally filtered by status
  Future<List<Payment>> getPayments({String? status});

  /// Cancel an authorized payment (release hold without capture)
  Future<Payment> cancelPayment(String paymentId);
}
