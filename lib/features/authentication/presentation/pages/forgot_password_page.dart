import 'package:discovaa/features/authentication/presentation/widgets/auth_field_label.dart';
import 'package:discovaa/features/authentication/presentation/widgets/auth_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/utils/form_validation.dart';
import '../../../../core/widgets/custom_buttons.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final success = await ref
          .read(authProvider.notifier)
          .sendPasswordResetEmail(_emailController.text);

      if (mounted) {
        if (success) {
          // Navigate to OTP page for verification
          context.push(
            RouteNames.otp,
            extra: {'type': 'forgot_password', 'email': _emailController.text},
          );
        } else {
          final error = ref.read(authProvider).errorMessage;
          _showErrorSnackBar(
            error ?? 'Failed to send reset email. Please try again.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to send reset email. Please try again.');
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          AuthHeader(
            title: "Forgot Your Password?",
            onBack: () => context.pop(),
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
                      "Please enter your registered email address & we will send an OTP verification code.",
                      style: TextStyle(color: Colors.grey, height: 1.5),
                    ),
                    const Divider(height: 40),
                    const AuthFieldLabel(label: "Email address"),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'your@email.com',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email is required';
                        }
                        return FormValidationRules.validateEmail(value);
                      },
                    ),
                    const SizedBox(height: 40),
                    AppPrimaryButton(
                      onPressed: _isLoading ? null : _sendResetEmail,
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
    );
  }
}
