import 'package:discovaa/app/router/route_names.dart';
import 'package:discovaa/features/authentication/presentation/providers/auth_provider.dart';
import 'package:discovaa/features/authentication/presentation/providers/registration_flow_provider.dart';
import 'package:discovaa/features/authentication/presentation/widgets/auth_header.dart';
import 'package:discovaa/features/authentication/presentation/widgets/otp_input_field.dart';
import 'package:discovaa/features/authentication/presentation/widgets/verification_success_modal.dart';
import 'package:discovaa/core/utils/form_validation.dart';
import 'package:discovaa/core/widgets/app_alert_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OtpPage extends ConsumerStatefulWidget {
  const OtpPage({super.key});

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  bool _isLoading = false;
  DateTime? _lastResendTime;
  String? _resendSuccessMessage;
  String? _resendErrorMessage;

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  /// Check if can resend OTP (30 second cooldown)
  bool get _canResend {
    if (_lastResendTime == null) return true;
    final elapsed = DateTime.now().difference(_lastResendTime!);
    return elapsed.inSeconds >= 30;
  }

  String get _resendCountdown {
    if (_lastResendTime == null) return '';
    final elapsed = DateTime.now().difference(_lastResendTime!);
    final remaining = 30 - elapsed.inSeconds;
    return remaining > 0 ? ' (${remaining}s)' : '';
  }

  void _onOtpChanged(String value, int length) {
    // Don't change state while loading to prevent false errors
    if (_isLoading) return;

    // Validate OTP as user types
    final validation = FormValidationRules.validateOtp(value, length: length);

    if (value.length == length) {
      // OTP is complete, validate it
      if (validation == null) {
        // Valid OTP - verify it
        _verifyOtp();
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_isLoading) return;

    // Determine navigation target based on source
    final data = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final String type = data?['type'] ?? 'register';
    final bool isForgot = type == 'forgot_password';
    final bool isLoginVerify = type == 'login_verify';
    final String email = data?['email'] ?? '';

    debugPrint(
      '[OtpPage] Verifying OTP - type: $type, isForgot: $isForgot, email: $email',
    );
    debugPrint('[OtpPage] OTP code entered: ${_pinController.text}');

    // For forgot password flow, DON'T verify OTP here
    // Just navigate to reset password page with the code
    if (isForgot) {
      debugPrint(
        '[OtpPage] Forgot password flow - skipping OTP verification, navigating directly to reset password',
      );
      if (mounted) {
        context.go(
          RouteNames.resetPassword,
          extra: {'email': email, 'code': _pinController.text},
        );
      }
      return;
    }

    // Validate email is not empty
    if (email.isEmpty) {
      setState(() {
        _resendErrorMessage = 'Email is required for verification';
      });
      // Auto-clear error after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _resendErrorMessage = null;
          });
        }
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Call auth repository to verify OTP (only for register/login_verify flows)
      final success = await ref
          .read(authProvider.notifier)
          .verifyOtp(email: email, otpCode: _pinController.text);

      if (mounted) {
        if (success) {
          // Show verification success modal
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const VerificationSuccessModal(),
          );

          // Auto-navigate after delay to allow modal to show
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              Navigator.of(context).pop(); // Close modal

              if (isLoginVerify) {
                // User verified from login — need to re-login to get fresh tokens
                context.go(RouteNames.login);
              } else {
                // Registration flow - clear registration flow state
                ref
                    .read(registrationFlowProvider.notifier)
                    .moveToProfileCompletion();

                // Navigate to complete profile
                context.go(RouteNames.completeProfile);
              }
            }
          });
        } else {
          // Get error message from API response
          final errorMessage = ref.read(authProvider).value?.errorMessage;
          debugPrint('[OtpPage] OTP verification failed: $errorMessage');
        }
      }
    } catch (e) {
      if (mounted) {
        debugPrint('[OtpPage] OTP verification error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    // Get email from route extras before any async operations
    final data = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final String type = data?['type'] ?? 'register';
    final bool isForgot = type == 'forgot_password';
    final String email = data?['email'] ?? '';

    setState(() => _lastResendTime = DateTime.now());

    // Reset OTP state and clear input
    _pinController.clear();

    // Call correct repository method based on flow
    final success = isForgot
        ? await ref.read(authProvider.notifier).sendPasswordResetEmail(email)
        : await ref.read(authProvider.notifier).resendOtp(email);

    if (!mounted) return;

    if (success) {
      // Show success message using AppAlertMessage
      setState(() {
        _resendSuccessMessage = 'OTP resent successfully to $email';
      });
      // Auto-clear success message after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _resendSuccessMessage = null;
          });
        }
      });
    } else {
      final error = ref.read(authProvider).value?.errorMessage;
      setState(() {
        _resendErrorMessage =
            error ?? 'Failed to resend code. Please try again.';
      });
      // Auto-clear error message after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _resendErrorMessage = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final String type = data?['type'] ?? 'register';
    final bool isForgot = type == 'forgot_password';
    final String email = data?['email'] ?? '';
    final int otpLength = isForgot ? 8 : 6;

    final authState = ref.watch(authProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ref.read(registrationFlowProvider.notifier).reset();
        context.pop();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                AuthHeader(
                  title: isForgot ? "Forgot Your Password?" : "Check your Mail",
                  subtitle: isForgot ? null : "Verification code",
                  step: isForgot ? null : "02/03",
                  onBack: () {
                    ref.read(registrationFlowProvider.notifier).reset();
                    // Check if we can pop to avoid "nothing to pop" error
                    if (GoRouter.of(context).canPop()) {
                      context.pop();
                    } else {
                      // Fallback: navigate to login page if nothing to pop
                      context.go(RouteNames.login);
                    }
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text.rich(
                        TextSpan(
                          text: isForgot
                              ? "Please Enter the $otpLength digit verification code sent to "
                              : "We've sent a $otpLength-digit confirmation code to ",
                          style: const TextStyle(fontSize: 14),
                          children: [
                            TextSpan(
                              text: " $email",
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const TextSpan(
                              text: ". Make sure you enter correct code.",
                            ),
                          ],
                        ),
                        textAlign: TextAlign.left,
                      ),
                      const Divider(color: Colors.grey, thickness: 1),
                      const SizedBox(height: 40),

                      // OTP Input
                      OtpInputField(
                        controller: _pinController,
                        focusNode: _pinFocusNode,
                        otpState: authState.hasError
                            ? OtpState.error
                            : OtpState.neutral,
                        length: otpLength,
                        onChanged: (val) => _onOtpChanged(val, otpLength),
                        onCompleted: (pin) => _verifyOtp(),
                      ),

                      const SizedBox(height: 20),

                      // OTP State Message - Show API error if available
                      if (authState.hasError ||
                          (authState.value?.errorMessage != null))
                        Builder(
                          builder: (context) {
                            final errorMessage =
                                authState.value?.errorMessage ??
                                'Invalid verification code. Please check and try again.';
                            return AppAlertMessage(
                              type: AlertType.error,
                              message: errorMessage,
                              onDismiss: () {
                                ref.read(authProvider.notifier).clearError();
                              },
                            );
                          },
                        ),

                      // Resend success/error messages
                      if (_resendSuccessMessage != null) ...[
                        const SizedBox(height: 12),
                        AppAlertMessage(
                          type: AlertType.success,
                          message: _resendSuccessMessage!,
                          onDismiss: () {
                            setState(() {
                              _resendSuccessMessage = null;
                            });
                          },
                        ),
                      ],

                      if (_resendErrorMessage != null) ...[
                        const SizedBox(height: 12),
                        AppAlertMessage(
                          type: AlertType.error,
                          message: _resendErrorMessage!,
                          onDismiss: () {
                            setState(() {
                              _resendErrorMessage = null;
                            });
                          },
                        ),
                      ],

                      const SizedBox(height: 40),

                      // Verify Button
                      ElevatedButton(
                        onPressed: !_isLoading ? _verifyOtp : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !_isLoading
                              ? Colors.black
                              : Colors.grey,
                          minimumSize: const Size(double.infinity, 55),
                        ),
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
                            : const Text(
                                "Verify",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                      const SizedBox(height: 20),
                      RichText(
                        text: TextSpan(
                          text: "Didn't receive code? ",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                          children: [
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: _canResend ? _resendOtp : null,
                                child: Text(
                                  _canResend
                                      ? "Resend code$_resendCountdown"
                                      : "Resend code$_resendCountdown",
                                  style: TextStyle(
                                    color: _canResend
                                        ? Colors.blue
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
