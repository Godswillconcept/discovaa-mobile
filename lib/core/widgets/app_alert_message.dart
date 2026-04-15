import 'package:flutter/material.dart';

enum AlertType { error, success, info, warning }

class AppAlertMessage extends StatelessWidget {
  final AlertType type;
  final String message;
  final IconData? icon;
  final VoidCallback? onDismiss;
  final bool showDismissButton;

  const AppAlertMessage({
    super.key,
    required this.type,
    required this.message,
    this.icon,
    this.onDismiss,
    this.showDismissButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();
    final displayIcon = icon ?? _getDefaultIcon();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(displayIcon, color: colors.icon, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.text, fontSize: 14),
            ),
          ),
          if (showDismissButton && onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close, color: colors.icon, size: 16),
            ),
        ],
      ),
    );
  }

  ({Color background, Color border, Color icon, Color text}) _getColors() {
    switch (type) {
      case AlertType.error:
        return (
          background: Colors.red.withValues(alpha: 0.1),
          border: Colors.red.withValues(alpha: 0.3),
          icon: Colors.red,
          text: Colors.red,
        );
      case AlertType.success:
        return (
          background: Colors.green.withValues(alpha: 0.1),
          border: Colors.green.withValues(alpha: 0.3),
          icon: Colors.green,
          text: Colors.green,
        );
      case AlertType.warning:
        return (
          background: Colors.orange.withValues(alpha: 0.1),
          border: Colors.orange.withValues(alpha: 0.3),
          icon: Colors.orange,
          text: Colors.orange,
        );
      case AlertType.info:
        return (
          background: Colors.blue.withValues(alpha: 0.1),
          border: Colors.blue.withValues(alpha: 0.3),
          icon: Colors.blue,
          text: Colors.blue,
        );
    }
  }

  IconData _getDefaultIcon() {
    switch (type) {
      case AlertType.error:
        return Icons.error_outline;
      case AlertType.success:
        return Icons.check_circle_outline;
      case AlertType.warning:
        return Icons.warning;
      case AlertType.info:
        return Icons.info_outline;
    }
  }
}
