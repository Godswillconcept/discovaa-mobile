import 'package:discovaa/features/profile/domain/entities/profile_enums.dart';

class ProviderPayout {
  final String id;
  final String? provider;
  final String? ownerProvider;
  final String currency;
  final double amount;
  final ProviderPayoutStatus status;
  final String? externalReference;
  final String? failureReason;
  final DateTime? requestedAt;
  final DateTime? processedAt;
  final DateTime? paidAt;
  final DateTime? failedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProviderPayout({
    required this.id,
    required this.currency,
    required this.amount,
    required this.status,
    this.provider,
    this.ownerProvider,
    this.externalReference,
    this.failureReason,
    this.requestedAt,
    this.processedAt,
    this.paidAt,
    this.failedAt,
    this.createdAt,
    this.updatedAt,
  });
}
