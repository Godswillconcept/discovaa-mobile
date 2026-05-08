import 'package:equatable/equatable.dart';

/// Payment status enum matching the API's PaymentStatus enum
enum PaymentStatus {
  requiresAction,
  authorized,
  captured,
  partiallyRefunded,
  refunded,
  cancelled,
  failed;

  String get displayName {
    switch (this) {
      case PaymentStatus.requiresAction:
        return 'Requires Action';
      case PaymentStatus.authorized:
        return 'Authorized (Funds Held)';
      case PaymentStatus.captured:
        return 'Captured';
      case PaymentStatus.partiallyRefunded:
        return 'Partially Refunded';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.cancelled:
        return 'Cancelled';
      case PaymentStatus.failed:
        return 'Failed';
    }
  }

  bool get isTerminal =>
      this == PaymentStatus.captured ||
      this == PaymentStatus.refunded ||
      this == PaymentStatus.cancelled ||
      this == PaymentStatus.failed;

  bool get isActive =>
      this == PaymentStatus.authorized || this == PaymentStatus.requiresAction;
}

/// Core payment entity representing a payment authorization/capture
class Payment extends Equatable {
  final String id;
  final String bookingId;
  final PaymentStatus status;
  final double amount;
  final double? capturedAmount;
  final String? failureReason;
  final String? authorizationUrl;
  final String? providerReference;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Payment({
    required this.id,
    required this.bookingId,
    required this.status,
    required this.amount,
    this.capturedAmount,
    this.failureReason,
    this.authorizationUrl,
    this.providerReference,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    bookingId,
    status,
    amount,
    capturedAmount,
    failureReason,
    authorizationUrl,
    providerReference,
    createdAt,
    updatedAt,
  ];

  Payment copyWith({
    String? id,
    String? bookingId,
    PaymentStatus? status,
    double? amount,
    double? capturedAmount,
    String? failureReason,
    String? authorizationUrl,
    String? providerReference,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Payment(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      capturedAmount: capturedAmount ?? this.capturedAmount,
      failureReason: failureReason ?? this.failureReason,
      authorizationUrl: authorizationUrl ?? this.authorizationUrl,
      providerReference: providerReference ?? this.providerReference,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
