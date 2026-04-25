import 'profile_enums.dart';

/// Represents a payout account configuration (Stripe Connect or Paystack)
class PayoutAccount {
  final String? stripeAccountId;
  final String? connectedAccountId;
  final PayoutStatus status;
  final String? currency;
  final String? country;
  final double? availableBalance;
  final double? currentBalance;
  final double? pendingBalance;
  final double? totalBalance;
  final double? totalIncome;
  final double? totalPayout;
  final bool instantPayoutAvailable;
  final DateTime? lastPayoutDate;
  final DateTime? nextPayoutDate;
  final String? email;
  final String? payoutSchedule;
  final bool chargesEnabled;
  final PayoutGateway? gateway;
  final String? bankCode;
  final String? bankName;

  const PayoutAccount({
    this.stripeAccountId,
    this.connectedAccountId,
    this.status = PayoutStatus.notConnected,
    this.currency,
    this.country,
    this.availableBalance,
    this.currentBalance,
    this.pendingBalance,
    this.totalBalance,
    this.totalIncome,
    this.totalPayout,
    this.instantPayoutAvailable = false,
    this.lastPayoutDate,
    this.nextPayoutDate,
    this.email,
    this.payoutSchedule,
    this.chargesEnabled = false,
    this.gateway,
    this.bankCode,
    this.bankName,
  });

  PayoutAccount copyWith({
    String? stripeAccountId,
    String? connectedAccountId,
    PayoutStatus? status,
    String? currency,
    String? country,
    double? availableBalance,
    double? currentBalance,
    double? pendingBalance,
    double? totalBalance,
    double? totalIncome,
    double? totalPayout,
    bool? instantPayoutAvailable,
    DateTime? lastPayoutDate,
    DateTime? nextPayoutDate,
    String? email,
    String? payoutSchedule,
    bool? chargesEnabled,
    PayoutGateway? gateway,
    String? bankCode,
    String? bankName,
  }) {
    return PayoutAccount(
      stripeAccountId: stripeAccountId ?? this.stripeAccountId,
      connectedAccountId: connectedAccountId ?? this.connectedAccountId,
      status: status ?? this.status,
      currency: currency ?? this.currency,
      country: country ?? this.country,
      availableBalance: availableBalance ?? this.availableBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      totalBalance: totalBalance ?? this.totalBalance,
      totalIncome: totalIncome ?? this.totalIncome,
      totalPayout: totalPayout ?? this.totalPayout,
      instantPayoutAvailable:
          instantPayoutAvailable ?? this.instantPayoutAvailable,
      lastPayoutDate: lastPayoutDate ?? this.lastPayoutDate,
      nextPayoutDate: nextPayoutDate ?? this.nextPayoutDate,
      email: email ?? this.email,
      payoutSchedule: payoutSchedule ?? this.payoutSchedule,
      chargesEnabled: chargesEnabled ?? this.chargesEnabled,
      gateway: gateway ?? this.gateway,
      bankCode: bankCode ?? this.bankCode,
      bankName: bankName ?? this.bankName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stripeAccountId': stripeAccountId,
      'connectedAccountId': connectedAccountId,
      'status': status.name,
      'currency': currency,
      'country': country,
      'availableBalance': availableBalance,
      'currentBalance': currentBalance,
      'pendingBalance': pendingBalance,
      'totalBalance': totalBalance,
      'totalIncome': totalIncome,
      'totalPayout': totalPayout,
      'instantPayoutAvailable': instantPayoutAvailable,
      'lastPayoutDate': lastPayoutDate?.toIso8601String(),
      'nextPayoutDate': nextPayoutDate?.toIso8601String(),
      'email': email,
      'payoutSchedule': payoutSchedule,
      'chargesEnabled': chargesEnabled,
      'gateway': gateway?.name,
      'bankCode': bankCode,
      'bankName': bankName,
    };
  }

  factory PayoutAccount.fromJson(Map<String, dynamic> json) {
    return PayoutAccount(
      stripeAccountId: json['stripeAccountId'],
      connectedAccountId: json['connectedAccountId'],
      status: PayoutStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PayoutStatus.notConnected,
      ),
      currency: json['currency'],
      country: json['country'],
      availableBalance: json['availableBalance']?.toDouble(),
      currentBalance: json['currentBalance']?.toDouble(),
      pendingBalance: json['pendingBalance']?.toDouble(),
      totalBalance: json['totalBalance']?.toDouble(),
      totalIncome: json['totalIncome']?.toDouble(),
      totalPayout: json['totalPayout']?.toDouble(),
      instantPayoutAvailable: json['instantPayoutAvailable'] ?? false,
      lastPayoutDate: json['lastPayoutDate'] != null
          ? DateTime.parse(json['lastPayoutDate'])
          : null,
      nextPayoutDate: json['nextPayoutDate'] != null
          ? DateTime.parse(json['nextPayoutDate'])
          : null,
      email: json['email'],
      payoutSchedule: json['payoutSchedule'],
      chargesEnabled: json['chargesEnabled'] ?? false,
      gateway: json['gateway'] != null
          ? PayoutGateway.values.firstWhere(
              (e) => e.name == json['gateway'],
              orElse: () => PayoutGateway.stripe,
            )
          : null,
      bankCode: json['bankCode'],
      bankName: json['bankName'],
    );
  }

  bool get isConnected =>
      status == PayoutStatus.connected || status == PayoutStatus.active;

  bool get canReceivePayouts =>
      isConnected && availableBalance != null && availableBalance! > 0;

  /// Check if account can withdraw (connected with positive balance)
  bool get canWithdraw =>
      isConnected &&
      ((availableBalance != null && availableBalance! > 0) ||
          (currentBalance != null && currentBalance! > 0));

  /// Currency symbol for display
  String get currencySymbol => _getCurrencySymbol(currency ?? 'USD');

  String get formattedAvailableBalance {
    if (availableBalance == null) return '--';
    final symbol = _getCurrencySymbol(currency ?? 'USD');
    return '$symbol${availableBalance!.toStringAsFixed(2)}';
  }

  String get formattedTotalIncome {
    if (totalIncome == null) return '--';
    final symbol = _getCurrencySymbol(currency ?? 'USD');
    return '$symbol${totalIncome!.toStringAsFixed(2)}';
  }

  String _getCurrencySymbol(String currency) {
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
  }
}
