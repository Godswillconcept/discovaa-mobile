import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:discovaa/features/bookings/data/models/booking_model.dart';
import 'package:discovaa/features/payments/domain/entities/refund_entity.dart';
import 'package:discovaa/features/payments/presentation/providers/refund_provider.dart';
import 'package:discovaa/app/router/route_names.dart';
import 'package:discovaa/core/constants/app_constants.dart';

/// Widget that displays refund section in booking detail page
class RefundSection extends ConsumerWidget {
  final BookingModel booking;
  const RefundSection({required this.booking, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refundState = ref.watch(refundProvider);
    final refunds = refundState.refunds
        .where((r) => r.paymentId == booking.paymentId)
        .toList();

    return _CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.money_off_outlined,
                size: 18,
                color: Colors.red.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                'Refund',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (refunds.isEmpty)
            Text(
              'No refund requests yet.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: refunds.map((refund) {
                return RefundStatusCard(refund: refund);
              }).toList(),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                context.push(
                  RouteNames.refundRequest,
                  extra: {
                    'paymentId': booking.paymentId,
                    'capturedAmount':
                        double.tryParse(booking.paymentAmount ?? '0') ?? 0.0,
                    'paymentStatus': booking.paymentStatus,
                  },
                );
              },
              icon: Icon(
                Icons.money_off_outlined,
                size: 16,
                color: Colors.red.shade600,
              ),
              label: Text(
                'Request Refund',
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red.shade200),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget that displays a single refund status card
class RefundStatusCard extends StatelessWidget {
  final RefundRequest refund;
  const RefundStatusCard({required this.refund, super.key});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(refund.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withAlpha(10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withAlpha(30)),
      ),
      child: Row(
        children: [
          Icon(_getStatusIcon(refund.status), size: 16, color: statusColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Refund: NGN ${refund.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  refund.reason,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getStatusText(refund.status),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _getStatusColor(RefundStatus status) {
  switch (status) {
    case RefundStatus.pending:
      return Colors.orange;
    case RefundStatus.approved:
      return Colors.green;
    case RefundStatus.rejected:
      return Colors.red;
  }
}

IconData _getStatusIcon(RefundStatus status) {
  switch (status) {
    case RefundStatus.pending:
      return Icons.pending_outlined;
    case RefundStatus.approved:
      return Icons.check_circle_outline;
    case RefundStatus.rejected:
      return Icons.cancel_outlined;
  }
}

String _getStatusText(RefundStatus status) {
  switch (status) {
    case RefundStatus.pending:
      return 'Pending';
    case RefundStatus.approved:
      return 'Approved';
    case RefundStatus.rejected:
      return 'Rejected';
  }
}

/// Helper widget for card container (matching the existing _CardContainer in booking_detail_page)
class _CardContainer extends StatelessWidget {
  final Widget child;
  const _CardContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
