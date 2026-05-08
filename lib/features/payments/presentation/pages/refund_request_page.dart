import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:discovaa/features/payments/presentation/providers/refund_provider.dart';
import 'package:discovaa/core/widgets/app_snackbar.dart';

/// Predefined refund reasons
const List<String> _predefinedReasons = [
  'Service not delivered',
  'Service not as described',
  'Provider cancelled',
  'Customer changed mind',
  'Quality issues',
  'Pricing dispute',
  'Other',
];

/// Page for requesting a refund
class RefundRequestPage extends ConsumerStatefulWidget {
  final String paymentId;
  final double capturedAmount;
  final String? paymentStatus;

  const RefundRequestPage({
    super.key,
    required this.paymentId,
    required this.capturedAmount,
    this.paymentStatus,
  });

  @override
  ConsumerState<RefundRequestPage> createState() => _RefundRequestPageState();
}

class _RefundRequestPageState extends ConsumerState<RefundRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _customReasonController = TextEditingController();

  String? _selectedReason;
  bool _isCustomReason = false;
  bool _isSubmitting = false;

  double get _maxRefundAmount {
    return widget.capturedAmount;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _customReasonController.dispose();
    super.dispose();
  }

  Future<void> _submitRefund() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      AppSnackbar.showError(context, message: 'Please enter a valid amount');
      return;
    }

    if (amount > _maxRefundAmount) {
      AppSnackbar.showError(
        context,
        message:
            'Refund amount cannot exceed captured amount of ${_maxRefundAmount.toStringAsFixed(2)}',
      );
      return;
    }

    final reason = _isCustomReason
        ? _customReasonController.text.trim()
        : _selectedReason;

    if (reason == null || reason.isEmpty) {
      AppSnackbar.showError(
        context,
        message: 'Please select or enter a reason',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref
          .read(refundProvider.notifier)
          .submitRefund(
            paymentId: widget.paymentId,
            amount: amount,
            reason: reason,
            capturedAmount: widget.capturedAmount,
          );

      if (!mounted) return;

      AppSnackbar.showSuccess(
        context,
        message: 'Refund request submitted successfully',
      );

      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        message: 'Failed to submit refund: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final refundState = ref.watch(refundProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Refund'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Information',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(label: 'Payment ID', value: widget.paymentId),
                    const SizedBox(height: 8),
                    _InfoRow(
                      label: 'Captured Amount',
                      value: 'NGN ${widget.capturedAmount.toStringAsFixed(2)}',
                      valueColor: Colors.green,
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      label: 'Status',
                      value: widget.paymentStatus ?? 'CAPTURED',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Refund Amount',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                hintText: 'Enter amount to refund',
                prefixText: 'NGN ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                helperText:
                    'Maximum: NGN ${_maxRefundAmount.toStringAsFixed(2)}',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter refund amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                if (amount > _maxRefundAmount) {
                  return 'Amount cannot exceed captured amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Reason for Refund',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _isCustomReason ? null : _selectedReason,
              decoration: InputDecoration(
                hintText: 'Select a reason',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: _predefinedReasons.map((reason) {
                return DropdownMenuItem(value: reason, child: Text(reason));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedReason = value;
                  _isCustomReason = false;
                  _customReasonController.clear();
                });
              },
              validator: (value) {
                if (!_isCustomReason && (value == null || value.isEmpty)) {
                  return 'Please select a reason';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: _isCustomReason,
                  onChanged: (value) {
                    setState(() {
                      _isCustomReason = value ?? false;
                      if (_isCustomReason) {
                        _selectedReason = null;
                      }
                    });
                  },
                ),
                const Text('Enter custom reason'),
              ],
            ),
            if (_isCustomReason) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _customReasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter your reason for refund',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (_isCustomReason &&
                      (value == null || value.trim().isEmpty)) {
                    return 'Please enter a reason';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 32),
            if (refundState.error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        refundState.error!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitRefund,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Submit Refund Request',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Refund requests are reviewed by our team. '
                      'You will be notified once your request is approved or rejected.',
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
