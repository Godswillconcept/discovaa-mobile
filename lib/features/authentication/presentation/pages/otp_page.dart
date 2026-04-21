import 'package:discovaa/features/authentication/presentation/widgets/auth_header.dart';
import 'package:discovaa/features/authentication/presentation/widgets/otp_input_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:discovaa/core/utils/form_validation.dart';
import 'package:discovaa/core/widgets/app_alert_message.dart';
import 'package:discovaa/core/widgets/app_snackbar.dart';
import 'package:discovaa/features/authentication/presentation/providers/auth_provider.dart';
import 'package:discovaa/features/authentication/presentation/widgets/verification_success_modal.dart';
import '../providers/signup_provider.dart';

class OtpPage extends ConsumerStatefulWidget {
  const OtpPage({super.key});

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  // ignore: prefer_final_fields
  bool _isLoading = false;
  DateTime? _lastResendTime;

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(signupProvider.notifier);
      notifier.updateOtpState(OtpState.neutral);
      notifier.goToOtp();
    });
  }

  void _onOtpChanged(String value) {
    // Validate OTP as user types
    final validation = FormValidationRules.validateOtp(value);

    if (value.length == 6) {
      // OTP is complete, validate it
      if (validation == null) {
        // Valid OTP - set success state
        ref.read(signupProvider.notifier).updateOtpState(OtpState.success);

        Future.delayed(const Duration(milliseconds: 500), () {
          _verifyOtp();
        });
      } else {
        // Invalid OTP - set error state
        ref.read(signupProvider.notifier).updateOtpState(OtpState.error);
      }
    } else {
      // Reset to neutral state when OTP is incomplete
      ref.read(signupProvider.notifier).updateOtpState(OtpState.neutral);
    }
  }

  Future<void> _verifyOtp() async {
    final state = ref.read(signupProvider);
    if (state.otpState != OtpState.success) return;

    // Determine navigation target based on source
    final Map<String, dynamic>? data =
        GoRouterState.of(context).extra as Map<String, dynamic>?;
    final String type = data?['type'] ?? 'register';
    final bool isForgot = type == 'forgot_password';
    final bool isLoginVerify =
        type == 'login_verify'; // came from unverified login
    final String email = data?['email'] ?? '';

    setState(() => _isLoading = true);

    try {
      // Call auth repository to verify OTP
      final success = await ref
          .read(authProvider.notifier)
          .verifyOtp(email: email, otpCode: _pinController.text);

      if (mounted) {
        if (success) {
          // Call config endpoint (best-effort)
          await ref.read(authProvider.notifier).fetchConfig();

          // Register device token (best-effort)
          // TODO: Integrate with Firebase Messaging to get actual FCM token
          // const String? fcmToken = null;
          // if (fcmToken != null && fcmToken.isNotEmpty) {
          //   await ref.read(authProvider.notifier).registerDeviceToken(token: fcmToken);
          // }

          // Show verification success modal
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const VerificationSuccessModal(),
            );

            // Auto-navigate after delay to allow modal to show
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) {
                Navigator.of(context).pop(); // Close modal
                // Navigate based on source
                if (isForgot) {
                  context.push('/reset-password', extra: {'email': email});
                } else if (isLoginVerify) {
                  // User verified from login — go straight to home
                  context.go('/home');
                } else {
                  ref.read(signupProvider.notifier).goToProfile();
                  context.push('/complete-profile');
                }
              }
            });
          }
        } else {
          final error = ref.read(authProvider).errorMessage;
          ref.read(signupProvider.notifier).updateOtpState(OtpState.error);
          _showErrorSnackBar(error ?? 'Verification failed. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        ref.read(signupProvider.notifier).updateOtpState(OtpState.error);
        _showErrorSnackBar('Verification failed. Please try again.');
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
    final Map<String, dynamic>? data =
        GoRouterState.of(context).extra as Map<String, dynamic>?;
    final String email = data?['email'] ?? '';

    setState(() => _lastResendTime = DateTime.now());

    // Reset OTP state and clear input
    _pinController.clear();
    ref.read(signupProvider.notifier).updateOtpState(OtpState.neutral);

    // Call auth repository to resend OTP
    final success = await ref.read(authProvider.notifier).resendOtp(email);

    if (!mounted) return;

    if (success) {
      AppSnackbar.showOtpSuccess(
        context,
        message: 'OTP resent successfully',
        onDismiss: () {},
      );
    } else {
      final error = ref.read(authProvider).errorMessage;
      _showErrorSnackBar(error ?? 'Failed to resend code. Please try again.');
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
    final Map<String, dynamic>? data =
        GoRouterState.of(context).extra as Map<String, dynamic>?;
    final String type = data?['type'] ?? 'register';
    final bool isForgot = type == 'forgot_password';
    final String email = data?['email'] ?? '';
    final String phone = data?['phone'] ?? '';
    final state = ref.watch(signupProvider);
    final otpState = state.otpState;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ref.read(signupProvider.notifier).goToRegistration();
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
                    ref.read(signupProvider.notifier).goToRegistration();
                    context.pop();
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text.rich(
                        TextSpan(
                          text: isForgot
                              ? "Please Enter the 6 digit verification code sent to "
                              : "We’ve sent a 6-digit confirmation code to",
                          style: const TextStyle(fontSize: 14),
                          children: [
                            TextSpan(
                              text: isForgot ? phone : " $email",
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
                      Divider(color: Colors.grey.shade300, thickness: 1),
                      const SizedBox(height: 40),

                      // OTP Input
                      OtpInputField(
                        controller: _pinController,
                        focusNode: _pinFocusNode,
                        otpState: otpState,
                        onChanged: _onOtpChanged,
                        onCompleted: (pin) => _verifyOtp(),
                      ),

                      const SizedBox(height: 20),

                      // OTP State Message
                      if (otpState == OtpState.error)
                        AppAlertMessage(
                          type: AlertType.error,
                          message:
                              'Invalid verification code. Please check your email and enter the 6-character code (letters and numbers).',
                          onDismiss: () {
                            ref
                                .read(signupProvider.notifier)
                                .updateOtpState(OtpState.neutral);
                          },
                        ),

                      if (otpState == OtpState.success)
                        AppAlertMessage(
                          type: AlertType.success,
                          message: 'OTP verified successfully!',
                          onDismiss: () {
                            ref
                                .read(signupProvider.notifier)
                                .updateOtpState(OtpState.neutral);
                          },
                        ),

                      const SizedBox(height: 40),

                      // Verify Button
                      ElevatedButton(
                        onPressed: (otpState == OtpState.success && !_isLoading)
                            ? _verifyOtp
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              (otpState == OtpState.success && !_isLoading)
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
                            : Text(
                                otpState == OtpState.error
                                    ? "Re-enter Code"
                                    : "Verify",
                                style: const TextStyle(
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
