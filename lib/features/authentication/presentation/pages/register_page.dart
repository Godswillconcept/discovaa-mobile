import 'package:discovaa/features/authentication/presentation/widgets/auth_field_label.dart';
import 'package:discovaa/features/authentication/presentation/widgets/auth_header.dart';
import 'package:discovaa/features/authentication/presentation/widgets/social_auth_section.dart';
import 'package:flutter/gestures.dart';
import 'package:discovaa/core/utils/form_validation.dart';
import 'package:discovaa/core/widgets/custom_buttons.dart';
import 'package:discovaa/features/authentication/presentation/providers/auth_provider.dart';
import 'package:discovaa/features/authentication/presentation/providers/signup_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _agreeToTerms = false;
  bool _isLoading = false;

  bool _isFormValid() {
    return _formKey.currentState?.validate() ?? false;
  }

  bool _canSubmit() {
    return _agreeToTerms && _isFormValid() && !_isLoading;
  }

  Future<void> _performRegistration() async {
    if (!_canSubmit()) return;

    setState(() => _isLoading = true);

    try {
      // Get selected role from signup provider
      final signupState = ref.read(signupProvider);

      // Call auth repository via provider
      final success = await ref
          .read(authProvider.notifier)
          .register(
            email: _emailController.text,
            password: _passwordController.text,
            role: signupState.selectedRole,
          );

      if (mounted) {
        if (success) {
          final notifier = ref.read(signupProvider.notifier);
          notifier.updateRegistrationInfo(
            email: _emailController.text,
            password: _passwordController.text,
          );
          notifier.updateOtpState(OtpState.neutral);
          context.push(
            '/otp',
            extra: {'type': 'register', 'email': _emailController.text},
          );
        } else {
          final error = ref.read(authProvider).errorMessage;
          _showErrorSnackBar(error ?? 'Registration failed. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Registration failed. Please try again.');
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Read role from navigation extra if provided
      final routerState = GoRouterState.of(context);
      final roleString = routerState.extra as String?;

      if (roleString != null) {
        // Parse the role string and update signup provider
        // Handle both uppercase (API spec) and lowercase (legacy) values
        UserRole? role;
        switch (roleString.toUpperCase()) {
          case 'USER':
            role = UserRole.user;
            break;
          case 'INDIVIDUAL':
          case 'PROVIDER':
            role = UserRole.individualProvider;
            break;
          case 'BUSINESS':
            role = UserRole.businessProvider;
            break;
        }

        if (role != null) {
          ref.read(signupProvider.notifier).selectRole(role);
        }
      }

      ref.read(signupProvider.notifier).goToRegistration();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signupProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ref.read(signupProvider.notifier).goBackFromRegistration();
        context.pop();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          body: Column(
            children: [
              AuthHeader(
                title: state.selectedRole == UserRole.user
                    ? "Register User Account!"
                    : state.selectedRole == UserRole.individualProvider
                    ? "Individual Service Provider"
                    : "Business Service Provider",
                subtitle: "Personal Info.",
                step: "01/03",
                onBack: () {
                  ref.read(signupProvider.notifier).goBackFromRegistration();
                  context.pop();
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
                        const SizedBox(height: 8),
                        const Text(
                          "For the purpose of industry regulation, your details are required.",
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        const Divider(height: 40),
                        const AuthFieldLabel(label: "Email address"),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) =>
                              FormValidationRules.validateEmail(value),
                          decoration: const InputDecoration(
                            hintText: "Enter email address",
                          ),
                        ),
                        const SizedBox(height: 20),
                        const AuthFieldLabel(label: "Create password"),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          keyboardType: TextInputType.visiblePassword,
                          validator: (value) =>
                              FormValidationRules.validatePassword(value),
                          decoration: InputDecoration(
                            hintText: "Enter password",
                            suffixIcon: TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                foregroundColor: Colors.black,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                              child: Text(_isPasswordVisible ? "Hide" : "Show"),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Checkbox(
                              value: _agreeToTerms,
                              onChanged: (v) {
                                setState(() {
                                  _agreeToTerms = v ?? false;
                                });
                              },
                              activeColor: Colors.black,
                            ),
                            Expanded(
                              child: state.selectedRole == UserRole.user
                                  ? RichText(
                                      text: TextSpan(
                                        text:
                                            "By signing up, you are creating a ",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                        children: [
                                          const TextSpan(
                                            text: "Discovaa ",
                                            style: TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                          const TextSpan(
                                            text: "account and agree to ",
                                          ),
                                          const TextSpan(
                                            text: "Discovaa’s ",
                                            style: TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                          const TextSpan(text: "Terms and "),
                                          TextSpan(
                                            text: "Privacy Policy.",
                                            style: const TextStyle(
                                              color: Colors.blue,
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                // Handle link
                                              },
                                          ),
                                        ],
                                      ),
                                    )
                                  : const Text(
                                      "I agree to terms & conditions",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        AppPrimaryButton(
                          onPressed: _canSubmit() ? _performRegistration : null,
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
                              : const Text("Register Account"),
                        ),
                        SocialAuthSection(
                          onGooglePressed: () {
                            // Handle Google Registration
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
