import 'package:discovaa/app/router/route_names.dart';
import 'package:discovaa/core/utils/form_validation.dart';
import 'package:discovaa/core/widgets/app_alert_message.dart';
import 'package:discovaa/core/widgets/custom_buttons.dart';
import 'package:discovaa/features/authentication/presentation/providers/auth_provider.dart';
import 'package:discovaa/features/authentication/presentation/widgets/auth_field_label.dart';
import 'package:discovaa/features/authentication/presentation/widgets/auth_header.dart';
import 'package:discovaa/features/authentication/presentation/widgets/reset_success_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Get email from route extras before any async operations
    final Map<String, dynamic>? extraData =
        GoRouterState.of(context).extra as Map<String, dynamic>?;
    final String code = extraData?['code'] ?? '';

    setState(() => _isLoading = true);

    try {
      // Call auth repository to reset password
      final success = await ref
          .read(authProvider.notifier)
          .resetPassword(
            token: code, // Using the code entered on OTP page
            newPassword: _newPasswordController.text,
          );

      if (mounted) {
        if (success) {
          _showSuccess(context);
        } else {
          final error = ref.read(authProvider).value?.errorMessage;
          _showErrorSnackBar(
            error ?? 'Failed to reset password. Please try again.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to reset password. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final errorMessage = authState.value?.errorMessage;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            AuthHeader(
              title: "Reset Password",
              onBack: () {
                // Check if we can pop to avoid "nothing to pop" error
                if (GoRouter.of(context).canPop()) {
                  context.pop();
                } else {
                  // Fallback: navigate to login page if nothing to pop
                  context.go(RouteNames.login);
                }
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Please enter your new password",
                        style: TextStyle(color: Colors.grey),
                      ),
                      const Divider(height: 30),

                      const AuthFieldLabel(label: "New Password"),
                      _buildPasswordField(
                        "Enter password",
                        _newPasswordController,
                        _isNewPasswordVisible,
                        (value) =>
                            setState(() => _isNewPasswordVisible = value),
                        (value) => FormValidationRules.validatePassword(value),
                      ),

                      const SizedBox(height: 20),
                      const AuthFieldLabel(label: "Confirm Password"),
                      _buildPasswordField(
                        "Confirm password",
                        _confirmPasswordController,
                        _isConfirmPasswordVisible,
                        (value) =>
                            setState(() => _isConfirmPasswordVisible = value),
                        (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),
                      const Text(
                        "*NOTE: Choose a password that is distinctive & you can easily remember",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),

                      if (errorMessage != null) ...[
                        const SizedBox(height: 16),
                        AppAlertMessage(
                          type: AlertType.error,
                          message: errorMessage,
                          onDismiss: () {
                            ref.read(authProvider.notifier).clearError();
                          },
                        ),
                      ],

                      const SizedBox(height: 40),
                      AppPrimaryButton(
                        onPressed: _isLoading ? null : _resetPassword,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text("Proceed"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccess(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ResetSuccessModal(),
    );
  }

  Widget _buildPasswordField(
    String hint,
    TextEditingController controller,
    bool isVisible,
    Function(bool) onToggle,
    String? Function(String?) validator,
  ) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      keyboardType: TextInputType.visiblePassword,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock_outline),
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        suffixIcon: IconButton(
          icon: Icon(isVisible ? Icons.visibility_off : Icons.visibility),
          onPressed: () => onToggle(!isVisible),
        ),
      ),
    );
  }
}
