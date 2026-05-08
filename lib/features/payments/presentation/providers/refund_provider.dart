import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:discovaa/features/payments/domain/entities/refund_entity.dart';
import 'package:discovaa/features/payments/domain/repositories/refund_repository.dart';
import 'package:discovaa/app/dependency_injection/service_locator.dart';

/// State for refund operations
class RefundState {
  final bool isLoading;
  final String? error;
  final RefundRequest? createdRefund;
  final List<RefundRequest> refunds;
  final Map<String, double> paymentCapturedAmounts;

  const RefundState({
    this.isLoading = false,
    this.error,
    this.createdRefund,
    this.refunds = const [],
    this.paymentCapturedAmounts = const {},
  });

  RefundState copyWith({
    bool? isLoading,
    String? error,
    RefundRequest? createdRefund,
    List<RefundRequest>? refunds,
    Map<String, double>? paymentCapturedAmounts,
  }) {
    return RefundState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      createdRefund: createdRefund ?? this.createdRefund,
      refunds: refunds ?? this.refunds,
      paymentCapturedAmounts:
          paymentCapturedAmounts ?? this.paymentCapturedAmounts,
    );
  }
}

/// Notifier for managing refund state
class RefundNotifier extends StateNotifier<RefundState> {
  final RefundRepository _repository;

  RefundNotifier(this._repository) : super(const RefundState());

  /// Submit a new refund request
  /// Validates that refund amount ≤ captured amount
  Future<void> submitRefund({
    required String paymentId,
    required double amount,
    required String reason,
    required double capturedAmount,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Validate refund amount
      if (amount <= 0) {
        throw Exception('Refund amount must be greater than zero');
      }

      if (amount > capturedAmount) {
        throw Exception(
          'Refund amount cannot exceed captured amount of $capturedAmount',
        );
      }

      final refund = await _repository.createRefund(
        paymentId: paymentId,
        amount: amount,
        reason: reason,
      );

      state = state.copyWith(isLoading: false, createdRefund: refund);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Fetch all refunds, optionally filtered by status
  Future<List<RefundRequest>> getRefunds({String? status}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final refunds = await _repository.getRefunds(status: status);
      state = state.copyWith(isLoading: false, refunds: refunds);
      return refunds;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Fetch a single refund by ID
  Future<RefundRequest> getRefund(String refundId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final refund = await _repository.getRefund(refundId);
      state = state.copyWith(isLoading: false, createdRefund: refund);
      return refund;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Cancel a refund request
  Future<RefundRequest> cancelRefund(String refundId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final refund = await _repository.cancelRefund(refundId);
      state = state.copyWith(isLoading: false, createdRefund: refund);
      return refund;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Get refunds for a specific payment
  List<RefundRequest> getRefundsForPayment(String paymentId) {
    return state.refunds
        .where((refund) => refund.paymentId == paymentId)
        .toList();
  }

  /// Check if a payment has any pending refunds
  bool hasPendingRefund(String paymentId) {
    return state.refunds.any(
      (refund) =>
          refund.paymentId == paymentId &&
          refund.status == RefundStatus.pending,
    );
  }

  /// Get total refunded amount for a payment
  double getTotalRefundedAmount(String paymentId) {
    return state.refunds
        .where(
          (refund) =>
              refund.paymentId == paymentId &&
              refund.status == RefundStatus.approved,
        )
        .fold(0.0, (sum, refund) => sum + refund.amount);
  }

  /// Clear any error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Reset the created refund state
  void resetCreatedRefund() {
    state = state.copyWith(createdRefund: null);
  }
}

/// Provider for RefundNotifier
/// Uses service locator to get the RefundRepository
final refundProvider = StateNotifierProvider<RefundNotifier, RefundState>((
  ref,
) {
  final repository = sl<RefundRepository>();
  return RefundNotifier(repository);
});
