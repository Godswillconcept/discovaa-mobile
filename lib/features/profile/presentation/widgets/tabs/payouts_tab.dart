import 'package:discovaa/features/profile/domain/entities/payout_account.dart';
import 'package:discovaa/features/profile/domain/entities/provider_payout.dart';
import 'package:discovaa/features/profile/domain/entities/profile_enums.dart';
import 'package:discovaa/features/profile/presentation/providers/user_profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

final providerPayoutsProvider =
    FutureProvider.autoDispose<List<ProviderPayout>>((ref) async {
      final repository = ref.read(profileRepositoryProvider);
      return repository.fetchPayouts(pageSize: 10);
    });

/// Payouts Tab - Stripe Connect integration for providers
class PayoutsTab extends ConsumerWidget {
  const PayoutsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(userProfileProvider);
    final profile = profileState.profile;

    if (profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final account = profile.payoutAccount;

    if (account == null) {
      // Detect country to determine gateway
      final countryCode =
          profile.countryCode?.toUpperCase() ??
          profile.country?.toUpperCase() ??
          '';
      final isNigeria =
          countryCode == 'NG' || profile.country?.toLowerCase() == 'nigeria';

      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payout Account',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Connect your bank account to receive earnings',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const _StatusPill(status: PayoutStatus.notConnected),
              ],
            ),
            const SizedBox(height: 16),
            const _PayoutSummarySection(account: null),
            const SizedBox(height: 20),
            if (isNigeria)
              _PaystackOnboardingCard(
                country: profile.countryCode ?? profile.country,
                email: profile.email,
                onRefresh: () =>
                    ref.read(userProfileProvider.notifier).refreshProfile(),
              )
            else
              _StartOnboardingCard(
                initialCurrency: 'USD',
                country: profile.countryCode ?? profile.country,
                email: profile.email,
                onStart: (currency) async {
                  final notifier = ref.read(userProfileProvider.notifier);
                  final onboardingUrl = await notifier.startPayoutOnboarding(
                    currency: currency,
                  );
                  if (!context.mounted) return;
                  if (onboardingUrl == null || onboardingUrl.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Unable to start onboarding right now.'),
                      ),
                    );
                    return;
                  }
                  final uri = Uri.tryParse(onboardingUrl);
                  if (uri != null) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                onRefresh: () =>
                    ref.read(userProfileProvider.notifier).refreshProfile(),
                onResume: null,
              ),
          ],
        ),
      );
    }

    final payoutsAsync = ref.watch(providerPayoutsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payout Account',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Connect your bank account to receive earnings',
                      style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              _StatusPill(status: account.status),
            ],
          ),
          const SizedBox(height: 16),
          _PayoutSummarySection(account: account),
          const SizedBox(height: 20),
          // Account Overview Card
          _PayoutAccountCard(account: account),
          if (!account.chargesEnabled) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _resumeStripeOnboarding(context, ref),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Finish Stripe Verification'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF111827),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openAccountUpdate(context, ref),
                icon: const Icon(Icons.manage_accounts, size: 18),
                label: const Text('Update Stripe Account'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF111827),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Balance Section
          _BalanceSection(
            account: account,
            onWithdraw: () => _showWithdrawDialog(context, ref, account),
          ),
          const SizedBox(height: 24),

          // Payout Schedule
          _PayoutScheduleSection(account: account),
          const SizedBox(height: 24),

          // Transaction History
          payoutsAsync.when(
            data: (payouts) =>
                _TransactionHistorySection(account: account, payouts: payouts),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => _TransactionHistorySection(
              account: account,
              payouts: const [],
              errorMessage: 'Unable to load payout history.',
            ),
          ),
          const SizedBox(height: 24),

          // Withdrawal Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showWithdrawDialog(context, ref, account),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111827),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Withdraw'),
            ),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog(
    BuildContext context,
    WidgetRef ref,
    PayoutAccount account,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw Funds'),
        content: Text(
          'Withdraw ${account.formattedAvailableBalance} to your connected bank account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final notifier = ref.read(userProfileProvider.notifier);
              final success = await notifier.requestPayout();

              if (!context.mounted) return;

              Navigator.pop(context);
              ref.invalidate(providerPayoutsProvider);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Payout requested successfully.'
                        : 'Unable to request payout.',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF111827),
            ),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }

  Future<void> _resumeStripeOnboarding(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final notifier = ref.read(userProfileProvider.notifier);
    final onboardingUrl = await notifier.resumePayoutOnboarding();

    if (!context.mounted) return;

    if (onboardingUrl == null || onboardingUrl.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to resume setup.')));
      return;
    }

    final uri = Uri.tryParse(onboardingUrl);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openAccountUpdate(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(userProfileProvider.notifier);
    final updateUrl = await notifier.createPayoutUpdateLink();

    if (!context.mounted) return;

    if (updateUrl == null || updateUrl.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to open update.')));
      return;
    }

    final uri = Uri.tryParse(updateUrl);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Payout Account Overview Card
class _PayoutAccountCard extends StatelessWidget {
  final PayoutAccount account;

  const _PayoutAccountCard({required this.account});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF1F2937), const Color(0xFF111827)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF111827).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.account_balance,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      account.status == PayoutStatus.active ||
                              account.status == PayoutStatus.connected
                          ? 'Active'
                          : 'Pending',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  account.gateway == PayoutGateway.paystack ? 'P' : 'S',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            account.connectedAccountId != null
                ? '${account.gateway?.displayName ?? 'Stripe'} Account Connected'
                : 'Connect ${account.gateway?.displayName ?? 'Stripe'}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            account.status == PayoutStatus.active ||
                    account.status == PayoutStatus.connected
                ? 'Ready to receive payouts'
                : 'Complete verification to receive payouts',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          if (account.gateway == PayoutGateway.paystack &&
              account.bankName != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.business, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    account.bankName!,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
          if (account.chargesEnabled) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'Charges Enabled',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Status pill and summary/onboarding helpers
class _StatusPill extends StatelessWidget {
  final PayoutStatus? status;

  const _StatusPill({this.status});

  @override
  Widget build(BuildContext context) {
    final String label = switch (status) {
      PayoutStatus.notConnected => 'Not Connected',
      PayoutStatus.pending => 'Pending',
      PayoutStatus.connected => 'Connected',
      PayoutStatus.active => 'Active',
      PayoutStatus.disabled => 'Disabled',
      null => 'Not Connected',
    };

    final Color color = status == PayoutStatus.active
        ? const Color(0xFF10B981)
        : status == PayoutStatus.connected
        ? const Color(0xFF3B82F6)
        : status == PayoutStatus.pending
        ? const Color(0xFFF59E0B)
        : status == PayoutStatus.disabled
        ? const Color(0xFFEF4444)
        : const Color(0xFF9CA3AF);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status == PayoutStatus.active
                ? Icons.check_circle
                : status == PayoutStatus.pending
                ? Icons.schedule
                : Icons.info_outline,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;

  const _InfoCard({required this.title, required this.value, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
          ],
        ],
      ),
    );
  }
}

class _PayoutSummarySection extends StatelessWidget {
  final PayoutAccount? account;

  const _PayoutSummarySection({required this.account});

  String _fmt(String symbol, double? v) =>
      v == null ? '—' : '$symbol${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final currency = account?.currency ?? 'USD';
    final symbol =
        account?.currencySymbol ??
        (() {
          switch (currency.toUpperCase()) {
            case 'USD':
              return '\$';
            case 'EUR':
              return '€';
            case 'GBP':
              return '£';
            case 'NGN':
              return '₦';
            default:
              return currency;
          }
        }());

    final statusText = account?.status.displayName ?? 'Not Connected';
    final available = account?.availableBalance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoCard(
          title: 'Provider',
          value: 'STRIPE',
          subtitle: 'Secure payouts via Stripe Connect',
        ),
        _InfoCard(
          title: 'Status',
          value: statusText,
          subtitle: account == null || account!.chargesEnabled
              ? null
              : 'Complete onboarding to enable payouts',
        ),
        _InfoCard(
          title: 'Available Balance',
          value: available == null || available == 0
              ? 'No pending payout'
              : _fmt(symbol, available),
        ),
        _InfoCard(
          title: 'Total Balance',
          value: _fmt(symbol, account?.totalBalance),
        ),
        _InfoCard(
          title: 'Total Income',
          value: _fmt(symbol, account?.totalIncome),
        ),
        _InfoCard(
          title: 'Total Payout',
          value: _fmt(symbol, account?.totalPayout),
        ),
        _InfoCard(
          title: 'Instant Available',
          value: account == null
              ? '—'
              : (account!.instantPayoutAvailable ? 'Yes' : 'No'),
        ),
      ],
    );
  }
}

class _StartOnboardingCard extends ConsumerStatefulWidget {
  final String? initialCurrency;
  final String? country;
  final String? email;
  final Future<void> Function(String currency) onStart;
  final VoidCallback onRefresh;
  final VoidCallback? onResume;

  const _StartOnboardingCard({
    required this.initialCurrency,
    required this.country,
    required this.email,
    required this.onStart,
    required this.onRefresh,
    this.onResume,
  });

  @override
  ConsumerState<_StartOnboardingCard> createState() =>
      _StartOnboardingCardState();
}

class _StartOnboardingCardState extends ConsumerState<_StartOnboardingCard> {
  late String _currency;

  @override
  void initState() {
    super.initState();
    _currency = widget.initialCurrency ?? 'USD';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Start Onboarding',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              Row(
                children: [
                  if (widget.onResume != null) ...[
                    OutlinedButton(
                      onPressed: widget.onResume,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      child: const Text('Finish Verification'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  OutlinedButton(
                    onPressed: widget.onRefresh,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            initialValue: _currency,
            decoration: const InputDecoration(
              labelText: 'Currency',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'USD', child: Text('USD')),
              DropdownMenuItem(value: 'NGN', child: Text('NGN')),
              DropdownMenuItem(value: 'GBP', child: Text('GBP')),
              DropdownMenuItem(value: 'EUR', child: Text('EUR')),
            ],
            onChanged: (v) => setState(() => _currency = v ?? 'USD'),
          ),

          const SizedBox(height: 12),

          TextFormField(
            enabled: false,
            initialValue: widget.country ?? '',
            decoration: const InputDecoration(
              labelText: 'Country',
              hintText: 'Please select',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          TextFormField(
            enabled: false,
            initialValue: widget.email ?? '',
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),
          const Text(
            'You will be redirected to Stripe to complete identity verification',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await widget.onStart(_currency);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Start Onboarding'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Balance Display Section
class _BalanceSection extends StatelessWidget {
  final PayoutAccount account;
  final VoidCallback onWithdraw;

  const _BalanceSection({required this.account, required this.onWithdraw});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: account.currencySymbol,
      decimalDigits: 2,
    );

    // Safe balance values
    final currentBalance = account.currentBalance ?? 0;
    final pendingBalance = account.pendingBalance ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Balance',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(currentBalance / 100),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          if (pendingBalance > 0) ...[
            const SizedBox(height: 8),
            Text(
              '${currencyFormat.format(pendingBalance / 100)} pending',
              style: const TextStyle(fontSize: 14, color: Color(0xFFF59E0B)),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: account.canWithdraw ? onWithdraw : null,
              icon: const Icon(Icons.account_balance_wallet, size: 18),
              label: const Text('Withdraw to Bank'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111827),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: const Color(0xFFE5E7EB),
                disabledForegroundColor: const Color(0xFF9CA3AF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Payout Schedule Section
class _PayoutScheduleSection extends StatelessWidget {
  final PayoutAccount account;

  const _PayoutScheduleSection({required this.account});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payout Schedule',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          _buildScheduleRow(
            icon: Icons.calendar_today,
            title: 'Frequency',
            value: _formatSchedule(account.payoutSchedule),
          ),
          if (account.nextPayoutDate != null) ...[
            const SizedBox(height: 12),
            _buildScheduleRow(
              icon: Icons.event,
              title: 'Next Payout',
              value: DateFormat('MMM d, yyyy').format(account.nextPayoutDate!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScheduleRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF6B7280)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatSchedule(String? schedule) {
    switch (schedule) {
      case 'daily':
        return 'Daily (Manual)';
      case 'weekly':
        return 'Weekly (Every Monday)';
      case 'monthly':
        return 'Monthly (1st of month)';
      default:
        return 'Manual';
    }
  }
}

/// Transaction History Section
class _TransactionHistorySection extends StatelessWidget {
  final PayoutAccount account;
  final List<ProviderPayout> payouts;
  final String? errorMessage;

  const _TransactionHistorySection({
    required this.account,
    required this.payouts,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: account.currencySymbol,
      decimalDigits: 2,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              TextButton(
                onPressed: () {
                  // NOTE: Full transaction history screen to be implemented
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (errorMessage != null) ...[
            Text(
              errorMessage!,
              style: const TextStyle(fontSize: 14, color: Color(0xFFEF4444)),
            ),
          ] else if (payouts.isEmpty)
            _buildEmptyTransactions()
          else
            ...payouts.map(
              (payout) => _buildTransactionRow(payout, currencyFormat),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'No transactions yet',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(
    ProviderPayout payout,
    NumberFormat currencyFormat,
  ) {
    final isPaid = payout.status == ProviderPayoutStatus.paid;
    final isFailed =
        payout.status == ProviderPayoutStatus.failed ||
        payout.status == ProviderPayoutStatus.cancelled;
    final accentColor = isPaid
        ? const Color(0xFF10B981)
        : isFailed
        ? const Color(0xFFEF4444)
        : const Color(0xFFF59E0B);
    final icon = isPaid
        ? Icons.arrow_downward
        : isFailed
        ? Icons.arrow_upward
        : Icons.schedule;
    final amount = payout.amount;
    final date =
        payout.paidAt ??
        payout.processedAt ??
        payout.requestedAt ??
        payout.createdAt ??
        DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payout • ${payout.status.displayName}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMM d, yyyy • h:mm a').format(date),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '-${currencyFormat.format(amount)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Paystack Onboarding Card for Nigerian users
class _PaystackOnboardingCard extends ConsumerStatefulWidget {
  final String? country;
  final String? email;
  final VoidCallback onRefresh;

  const _PaystackOnboardingCard({
    required this.country,
    required this.email,
    required this.onRefresh,
  });

  @override
  ConsumerState<_PaystackOnboardingCard> createState() =>
      _PaystackOnboardingCardState();
}

class _PaystackOnboardingCardState
    extends ConsumerState<_PaystackOnboardingCard> {
  final _accountNumberController = TextEditingController();
  String? _selectedBankCode;
  String? _resolvedAccountName;
  List<dynamic> _banks = [];
  bool _isLoadingBanks = false;
  bool _isResolvingAccount = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchBanks();
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    super.dispose();
  }

  Future<void> _fetchBanks() async {
    setState(() => _isLoadingBanks = true);
    final banks = await ref
        .read(userProfileProvider.notifier)
        .fetchPaystackBanks();
    setState(() {
      _banks = banks;
      _isLoadingBanks = false;
    });
  }

  Future<void> _resolveAccountName() async {
    final accountNumber = _accountNumberController.text.trim();
    if (accountNumber.length != 10 || _selectedBankCode == null) return;

    setState(() => _isResolvingAccount = true);
    final accountName = await ref
        .read(userProfileProvider.notifier)
        .resolvePaystackAccount(
          accountNumber: accountNumber,
          bankCode: _selectedBankCode!,
        );
    setState(() {
      _resolvedAccountName = accountName;
      _isResolvingAccount = false;
    });
  }

  Future<void> _submitPaystackSetup() async {
    final accountNumber = _accountNumberController.text.trim();
    if (accountNumber.length != 10 ||
        _selectedBankCode == null ||
        _resolvedAccountName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await ref
        .read(userProfileProvider.notifier)
        .startPayoutOnboarding(
          currency: 'NGN',
          accountNumber: accountNumber,
          bankCode: _selectedBankCode,
          accountName: _resolvedAccountName,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paystack account connected successfully!'),
        ),
      );
      widget.onRefresh();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to connect Paystack account')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Connect Payout Account',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              OutlinedButton(
                onPressed: widget.onRefresh,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                child: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Enter your Nigerian bank details to receive payouts via Paystack.',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),

          // Country (read-only)
          TextFormField(
            enabled: false,
            initialValue: widget.country ?? 'Nigeria',
            decoration: const InputDecoration(
              labelText: 'Country',
              prefixIcon: Icon(Icons.flag, size: 20),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // Currency (read-only)
          TextFormField(
            enabled: false,
            initialValue: 'NGN',
            decoration: InputDecoration(
              labelText: 'Currency',
              prefixIcon: Icon(Icons.attach_money, size: 20),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // Gateway (read-only)
          TextFormField(
            enabled: false,
            initialValue: 'Paystack',
            decoration: InputDecoration(
              labelText: 'Gateway',
              prefixIcon: Icon(Icons.account_balance, size: 20),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // Account Email (read-only)
          TextFormField(
            enabled: false,
            initialValue: widget.email,
            decoration: const InputDecoration(
              labelText: 'Account Email',
              prefixIcon: Icon(Icons.email, size: 20),
              border: OutlineInputBorder(),
              helperText: 'Resolved from your profile. Not editable here.',
            ),
          ),
          const SizedBox(height: 12),

          // Account Number
          TextFormField(
            controller: _accountNumberController,
            keyboardType: TextInputType.number,
            maxLength: 10,
            decoration: const InputDecoration(
              labelText: 'Account Number',
              prefixIcon: Icon(Icons.account_balance_wallet, size: 20),
              border: OutlineInputBorder(),
              counterText: '',
            ),
            onChanged: (_) => _resolveAccountName(),
          ),
          const SizedBox(height: 12),

          // Bank Selection
          _isLoadingBanks
              ? const Center(child: CircularProgressIndicator())
              : DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Bank',
                    prefixIcon: Icon(Icons.business, size: 20),
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('Select a bank'),
                  items: _banks.map((bank) {
                    return DropdownMenuItem<String>(
                      value: bank['code']?.toString(),
                      child: Text(bank['name']?.toString() ?? ''),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBankCode = value;
                    });
                    _resolveAccountName();
                  },
                ),
          const SizedBox(height: 12),

          // Account Name (auto-filled)
          TextFormField(
            enabled: false,
            initialValue: _resolvedAccountName,
            decoration: InputDecoration(
              labelText: 'Account Name',
              prefixIcon: const Icon(Icons.person, size: 20),
              border: const OutlineInputBorder(),
              helperText: _isResolvingAccount
                  ? 'Resolving account name...'
                  : 'Auto-filled after account number + bank are entered',
              suffixIcon: _isResolvingAccount
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitPaystackSetup,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111827),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                disabledBackgroundColor: const Color(0xFFE5E7EB),
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
                  : const Text('Connect Paystack Account'),
            ),
          ),
        ],
      ),
    );
  }
}

// (Removed legacy full-screen onboarding view in favor of summary + onboarding card)
