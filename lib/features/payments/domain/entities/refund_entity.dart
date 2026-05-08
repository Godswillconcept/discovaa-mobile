import 'package:equatable/equatable.dart';

/// Refund status enum matching the API's RefundStatus enum
enum RefundStatus {
  pending,
  approved,
  rejected;

  String get displayName {
    switch (this) {
      case RefundStatus.pending:
        return 'Pending';
      case RefundStatus.approved:
        return 'Approved';
      case RefundStatus.rejected:
        return 'Rejected';
    }
  }

  String get apiValue {
    switch (this) {
      case RefundStatus.pending:
        return 'PENDING';
      case RefundStatus.approved:
        return 'APPROVED';
      case RefundStatus.rejected:
        return 'REJECTED';
    }
  }

  static RefundStatus fromApiValue(String value) {
    switch (value.toUpperCase()) {
      case 'PENDING':
        return RefundStatus.pending;
      case 'APPROVED':
        return RefundStatus.approved;
      case 'REJECTED':
        return RefundStatus.rejected;
      default:
        return RefundStatus.pending;
    }
  }
}

/// Refund initiator enum matching the API's RefundInitiator enum
enum RefundInitiator {
  customer,
  provider;

  String get displayName {
    switch (this) {
      case RefundInitiator.customer:
        return 'Customer';
      case RefundInitiator.provider:
        return 'Provider';
    }
  }

  String get apiValue {
    switch (this) {
      case RefundInitiator.customer:
        return 'CUSTOMER';
      case RefundInitiator.provider:
        return 'PROVIDER';
    }
  }

  static RefundInitiator fromApiValue(String value) {
    switch (value.toUpperCase()) {
      case 'CUSTOMER':
        return RefundInitiator.customer;
      case 'PROVIDER':
        return RefundInitiator.provider;
      default:
        return RefundInitiator.customer;
    }
  }
}

/// Core refund request entity representing a refund request
class RefundRequest extends Equatable {
  final String id;
  final String paymentId;
  final double amount;
  final String reason;
  final RefundStatus status;
  final RefundInitiator initiator;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const RefundRequest({
    required this.id,
    required this.paymentId,
    required this.amount,
    required this.reason,
    required this.status,
    required this.initiator,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    paymentId,
    amount,
    reason,
    status,
    initiator,
    createdAt,
    updatedAt,
  ];

  RefundRequest copyWith({
    String? id,
    String? paymentId,
    double? amount,
    String? reason,
    RefundStatus? status,
    RefundInitiator? initiator,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RefundRequest(
      id: id ?? this.id,
      paymentId: paymentId ?? this.paymentId,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      initiator: initiator ?? this.initiator,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
