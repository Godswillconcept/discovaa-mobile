import 'package:discovaa/features/profile/domain/entities/profile_enums.dart';
import 'package:flutter/material.dart';

/// Reusable status badge widget for verification and account states
class StatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;
  final double fontSize;
  final EdgeInsets padding;

  const StatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  });

  /// Factory constructor for verification status badges
  factory StatusBadge.verification(VerificationStatus status) {
    Color bgColor;
    Color textColor;
    IconData? icon;

    switch (status) {
      case VerificationStatus.verified:
        bgColor = const Color(0xFF10B981).withValues(alpha: 0.1);
        textColor = const Color(0xFF10B981);
        icon = Icons.check_circle;
        break;
      case VerificationStatus.pending:
        bgColor = const Color(0xFFF59E0B).withValues(alpha: 0.1);
        textColor = const Color(0xFFF59E0B);
        icon = Icons.pending;
        break;
      case VerificationStatus.rejected:
        bgColor = const Color(0xFFEF4444).withValues(alpha: 0.1);
        textColor = const Color(0xFFEF4444);
        icon = Icons.error;
        break;
      case VerificationStatus.unverified:
        bgColor = const Color(0xFF6B7280).withValues(alpha: 0.1);
        textColor = const Color(0xFF6B7280);
        icon = null;
        break;
    }

    return StatusBadge(
      label: status.displayName,
      backgroundColor: bgColor,
      textColor: textColor,
      icon: icon,
    );
  }

  /// Factory constructor for account type badges
  factory StatusBadge.accountType(AccountType type) {
    Color bgColor;
    Color textColor;

    switch (type) {
      case AccountType.user:
        bgColor = const Color(0xFF3B82F6).withValues(alpha: 0.1);
        textColor = const Color(0xFF3B82F6);
        break;
      case AccountType.provider:
        bgColor = const Color(0xFF8B5CF6).withValues(alpha: 0.1);
        textColor = const Color(0xFF8B5CF6);
        break;
      case AccountType.business:
        bgColor = const Color(0xFF111111);
        textColor = Colors.white;
        break;
    }

    return StatusBadge(
      label: type.displayName,
      backgroundColor: bgColor,
      textColor: textColor,
    );
  }

  /// Factory constructor for generic success/error/info badges
  factory StatusBadge.success(String label) => StatusBadge(
        label: label,
        backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1),
        textColor: const Color(0xFF10B981),
        icon: Icons.check_circle,
      );

  factory StatusBadge.error(String label) => StatusBadge(
        label: label,
        backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.1),
        textColor: const Color(0xFFEF4444),
        icon: Icons.error,
      );

  factory StatusBadge.info(String label) => StatusBadge(
        label: label,
        backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.1),
        textColor: const Color(0xFF3B82F6),
        icon: Icons.info,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
