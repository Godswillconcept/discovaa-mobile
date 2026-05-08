import 'package:discovaa/features/bookings/data/models/booking_model.dart';
import 'package:flutter/material.dart';

/// Widget to display payment status information in booking detail page
class PaymentStatusCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback? onRefresh;

  const PaymentStatusCard({super.key, required this.booking, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final status = booking.paymentStatus ?? 'Unknown';
    final isAuthorized = status == 'AUTHORIZED';
    final isCaptured = status == 'CAPTURED';
    final isRequiresAction = status == 'REQUIRES_ACTION';
    final isFailed = status == 'FAILED';
    final isCancelled = status == 'CANCELLED';
    final isRefunded = status == 'REFUNDED';

    Color statusColor;
    IconData statusIcon;
    String statusMessage;

    if (isAuthorized) {
      statusColor = Colors.blue;
      statusIcon = Icons.lock_clock_outlined;
      statusMessage = 'Funds are held (authorized) for this booking.';
    } else if (isCaptured) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_outlined;
      statusMessage = 'Payment has been captured successfully.';
    } else if (isRequiresAction) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning_amber_outlined;
      statusMessage = 'Action required to complete payment.';
    } else if (isFailed || isCancelled) {
      statusColor = Colors.red;
      statusIcon = Icons.error_outlined;
      statusMessage = 'Payment failed or was cancelled.';
    } else if (isRefunded) {
      statusColor = Colors.purple;
      statusIcon = Icons.money_off_outlined;
      statusMessage = 'Payment has been refunded.';
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.info_outlined;
      statusMessage = 'Payment status: ${_formatStatus(status)}';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Payment ${_formatStatus(status)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (onRefresh != null)
                IconButton(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh, size: 18),
                  color: Colors.grey.shade600,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            statusMessage,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          if (booking.paymentAmount != null) ...[
            const SizedBox(height: 8),
            Text(
              'Amount: ${booking.paymentAmount}',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (isRequiresAction && booking.paymentAuthorizationUrl != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // This would typically open a WebView for 3D Secure
                  // The existing _PaymentActionSection already handles this
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Complete Payment',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatStatus(String status) {
    if (status.isEmpty) return 'Unknown';
    return status
        .toLowerCase()
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1)}'
              : '',
        )
        .join(' ');
  }
}
