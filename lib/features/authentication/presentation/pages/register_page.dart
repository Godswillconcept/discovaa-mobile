import 'package:discovaa/app/router/route_names.dart';
import 'package:discovaa/features/authentication/presentation/providers/auth_provider.dart';
import 'package:discovaa/features/authentication/presentation/providers/registration_flow_provider.dart';
import 'package:discovaa/features/authentication/presentation/widgets/auth_field_label.dart';
import 'package:discovaa/features/authentication/presentation/widgets/auth_header.dart';
import 'package:discovaa/features/authentication/presentation/widgets/social_auth_section.dart';
import 'package:discovaa/core/utils/form_validation.dart';
import 'package:discovaa/core/widgets/custom_buttons.dart';
import 'package:discovaa/core/widgets/app_alert_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/gestures.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
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
      // Get selected role from registration flow provider
      final registrationState = ref.read(registrationFlowProvider);

      // Call auth repository via provider
      final success = await ref
          .read(authProvider.notifier)
          .register(
            email: _emailController.text,
            password: _passwordController.text,
            role: registrationState.selectedRole ?? UserRole.user,
          );

      if (mounted) {
        if (success) {
          // Store email in registration flow provider (not password - security fix)
          ref
              .read(registrationFlowProvider.notifier)
              .setEmail(_emailController.text);

          // Navigate to OTP page
          context.push(
            RouteNames.otp,
            extra: {'type': 'register', 'email': _emailController.text},
          );
        } else {
          final authState = ref.read(authProvider);
          final errorMessage =
              authState.value?.errorMessage ??
              'Registration failed. Please try again.';
          _showErrorSnackBar(errorMessage);
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
            SizedBox(width: 12.w),
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
        // Parse the role string and update registration flow provider
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
          ref.read(registrationFlowProvider.notifier).setRole(role);
        }
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final registrationState = ref.watch(registrationFlowProvider);
    final authState = ref.watch(authProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ref.read(registrationFlowProvider.notifier).reset();
        // Check if we can pop to avoid "nothing to pop" error
        if (GoRouter.of(context).canPop()) {
          context.pop();
        } else {
          context.go(RouteNames.signupSelection);
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          body: Column(
            children: [
              AuthHeader(
                title: registrationState.selectedRole == UserRole.user
                    ? "Register User Account!"
                    : registrationState.selectedRole ==
                          UserRole.individualProvider
                    ? "Individual Service Provider"
                    : "Business Service Provider",
                subtitle: "Personal Info.",
                step: "01/03",
                onBack: () {
                  ref.read(registrationFlowProvider.notifier).reset();
                  // Check if we can pop to avoid "nothing to pop" error
                  if (GoRouter.of(context).canPop()) {
                    context.pop();
                  } else {
                    context.go(RouteNames.signupSelection);
                  }
                },
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24.w),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8.h),
                        Text(
                          "For the purpose of industry regulation, your details are required.",
                          style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                        ),
                        Divider(height: 40.h),
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
                        SizedBox(height: 20.h),
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
                        SizedBox(height: 20.h),
                        const AuthFieldLabel(label: "Confirm password"),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_isConfirmPasswordVisible,
                          keyboardType: TextInputType.visiblePassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: "Confirm password",
                            suffixIcon: TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                foregroundColor: Colors.black,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isConfirmPasswordVisible =
                                      !_isConfirmPasswordVisible;
                                });
                              },
                              child: Text(
                                _isConfirmPasswordVisible ? "Hide" : "Show",
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),
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
                              child: RichText(
                                text: TextSpan(
                                  text: "By signing up, you agree to ",
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: "Discovaa's ",
                                      style: TextStyle(color: Colors.black),
                                    ),
                                    const TextSpan(text: "Terms and "),
                                    TextSpan(
                                      text: "Privacy Policy.",
                                      style: const TextStyle(
                                        color: Colors.blue,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          // TODO: Implement privacy policy link
                                          debugPrint('Privacy Policy tapped');
                                        },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 30.h),
                        // Show error message if registration failed
                        if (authState.hasError ||
                            (authState.value?.errorMessage != null))
                          Builder(
                            builder: (context) {
                              final errorMessage =
                                  authState.value?.errorMessage ??
                                  authState.error.toString();
                              return AppAlertMessage(
                                type: AlertType.error,
                                message: errorMessage,
                                onDismiss: () {
                                  ref.read(authProvider.notifier).clearError();
                                },
                              );
                            },
                          ),
                        SizedBox(height: 12.h),
                        AppPrimaryButton(
                          onPressed: _canSubmit() ? _performRegistration : null,
                          child: _isLoading
                              ? SizedBox(
                                  height: 20.h,
                                  width: 20.w,
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
