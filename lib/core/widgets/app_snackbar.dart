import 'package:flutter/material.dart';
import 'app_alert_message.dart';

class AppSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    AlertType type = AlertType.info,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onDismiss,
    bool floating = true, // New parameter for positioning
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: floating ? SnackBarBehavior.floating : SnackBarBehavior.fixed,
        content: AppAlertMessage(
          type: type,
          message: message,
          showDismissButton: onDismiss != null,
          onDismiss: onDismiss,
        ),
      ),
    );
  }

  static void showSuccess(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onDismiss,
    bool floating = true, // Success messages float by default
  }) {
    show(
      context,
      message: message,
      type: AlertType.success,
      duration: duration,
      onDismiss: onDismiss,
      floating: floating,
    );
  }

  static void showError(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 5),
    VoidCallback? onDismiss,
    bool floating = false, // Error messages fixed at bottom by default
  }) {
    show(
      context,
      message: message,
      type: AlertType.error,
      duration: duration,
      onDismiss: onDismiss,
      floating: floating,
    );
  }

  static void showWarning(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onDismiss,
    bool floating = false, // Warning messages fixed at bottom by default
  }) {
    show(
      context,
      message: message,
      type: AlertType.warning,
      duration: duration,
      onDismiss: onDismiss,
      floating: floating,
    );
  }

  static void showInfo(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onDismiss,
    bool floating = false, // Info messages fixed at bottom by default
  }) {
    show(
      context,
      message: message,
      type: AlertType.info,
      duration: duration,
      onDismiss: onDismiss,
      floating: floating,
    );
  }

  static void showOtpSuccess(
    BuildContext context, {
    required String message,
    VoidCallback? onDismiss,
  }) {
    // OTP success messages float to be more prominent
    show(
      context,
      message: message,
      type: AlertType.success,
      duration: const Duration(seconds: 4),
      onDismiss: onDismiss,
      floating: true, // Always float for OTP success
    );
  }

  static void showOtpInfo(
    BuildContext context, {
    required String message,
    VoidCallback? onDismiss,
  }) {
    // OTP info messages fixed at bottom (less intrusive)
    show(
      context,
      message: message,
      type: AlertType.info,
      duration: const Duration(seconds: 3),
      onDismiss: onDismiss,
      floating: false, // Fixed for OTP info
    );
  }

  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  static void clear(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }
}
