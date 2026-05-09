import 'package:discovaa/app/router/route_names.dart';
import 'package:discovaa/core/constants/app_constants.dart';
import 'package:discovaa/core/utils/form_validation.dart';
import 'package:discovaa/core/widgets/app_alert_message.dart';
import 'package:discovaa/features/authentication/presentation/providers/auth_provider.dart';
import 'package:discovaa/features/authentication/presentation/providers/identity_verification_reminder_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:developer';
import '../../../../core/utils/clippers.dart';
import '../../../../core/widgets/custom_buttons.dart';

class LoginPage extends ConsumerStatefulWidget {
  final bool fromOnboarding; // Flag to determine which layout to show
  final bool fromRegistration; // Flag to show identification screen after login

  const LoginPage({
    super.key,
    this.fromOnboarding = false,
    this.fromRegistration = false,
  });

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  late PageController _pageController;
  int _currentImageIndex = 0;
  Timer? _timer;
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final List<String> _blobImages = [
    'assets/images/illustrations/photographer.png',
    'assets/images/illustrations/mechanic.png',
    'assets/images/illustrations/construction.png',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.fromOnboarding) {
      _pageController = PageController();
      // Auto-animate the blob images every 3 seconds
      _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
        if (_currentImageIndex < 2) {
          _currentImageIndex++;
        } else {
          _currentImageIndex = 0;
        }
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            _currentImageIndex,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null; // Clear reference to prevent memory leaks
    if (widget.fromOnboarding) _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Perform login with validation and loading state
  Future<void> _performLogin() async {
    // Validate form
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Call auth repository via provider
      await ref
          .read(authProvider.notifier)
          .login(
            email: _emailController.text,
            password: _passwordController.text,
          );

      if (mounted) {
        final authState = ref.read(authProvider);

        authState.when(
          data: (state) {
            log(state.toString());
            // Mutually exclusive status checks — order matters:
            // requiresProfile and requiresVerification are NOT isAuthenticated.
            if (state.needsProfile) {
              // Check if user has pending email verification (empty ID indicates pending state)
              final isPendingEmailVerification =
                  state.user?.id.isEmpty ?? false;
              if (isPendingEmailVerification) {
                // Navigate to OTP for email verification first
                if (mounted) {
                  context.push(
                    RouteNames.otp,
                    extra: {
                      'email': _emailController.text,
                      'type': 'login_verify',
                    },
                  );
                }
              } else {
                // Navigate to complete profile
                if (mounted) {
                  context.go(
                    RouteNames.completeProfile,
                    extra: {'fromLogin': true},
                  );
                }
              }
              return;
            }

            if (state.needsVerification) {
              if (mounted) {
                context.go(RouteNames.identification);
              }
              return;
            }

            if (state.isAuthenticated) {
              // Register device token after successful login
              _registerDeviceToken();

              // Check identity verification status after login
              // This will trigger the reminder banner if verification is pending
              ref
                  .read(identityVerificationReminderProvider.notifier)
                  .checkVerificationStatus();

              if (mounted) {
                if (widget.fromRegistration) {
                  context.go(RouteNames.identification);
                } else {
                  context.go(RouteNames.home);
                }
              }
              return;
            }

            if (state.errorMessage != null) {
              if (state.errorMessage == 'VERIFICATION_PENDING') {
                // Redirect to OTP page for unverified account
                if (mounted) {
                  context.go(
                    RouteNames.otp,
                    extra: {
                      'email': _emailController.text,
                      'type':
                          'login_verify', // Distinct from 'register' — navigates to home after success
                    },
                  );
                }
              } else {
                _showErrorSnackBar(
                  state.errorMessage ?? 'Login failed. Please try again.',
                );
              }
            }
          },
          loading: () {
            // Still loading, do nothing
          },
          error: (error, _) {
            _showErrorSnackBar('Login failed. Please try again.');
          },
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Login failed. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Register device token for push notifications
  /// This is a best-effort operation - failures don't block login
  Future<void> _registerDeviceToken() async {
    try {
      // Get FCM token - for now use a placeholder
      // In production, this should come from FirebaseMessaging.instance.getToken()
      const String? fcmToken = null; // Note: Integrate with Firebase Messaging

      if (fcmToken == null || fcmToken.isEmpty) {
        // No FCM token available, skip registration
        return;
      }

      // Register device token via provider
      await ref
          .read(authProvider.notifier)
          .registerDeviceToken(token: fcmToken);
    } catch (e) {
      // Device registration is best-effort, don't block login
      debugPrint('[_LoginPageState] Device token registration failed: $e');
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.background,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // 1. Dynamic Header
            HeaderClipper(
              child: SizedBox(
                width: double.infinity,
                child: SafeArea(
                  child: Column(
                    children: [
                      // Indicators only shown if coming from Onboarding
                      if (widget.fromOnboarding)
                        Padding(
                          padding: const EdgeInsets.only(top: 10, left: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: List.generate(
                              3,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                height: 3,
                                width: 30,
                                decoration: BoxDecoration(
                                  color: _currentImageIndex == index
                                      ? Colors.white
                                      : Colors.white38,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ),
                      const Spacer(),
                      GestureDetector(
                        onLongPress: () {
                          // DEV: Show role info from auth state
                          final user = authState.value?.user;
                          if (user != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Logged in as: ${user.email} (${user.role})',
                                ),
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        child: const Text(
                          "Welcome",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Text(
                        "Login to continue",
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  // 2. Conditional Mid-Section (Carousel vs Illustration)
                  children: [
                    if (widget.fromOnboarding)
                      SizedBox(
                        height: 220,
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) =>
                              setState(() => _currentImageIndex = index),
                          itemCount: _blobImages.length,
                          itemBuilder: (context, index) => Center(
                            child: Image.asset(
                              _blobImages[index],
                              height: 200,
                              width: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Image.asset(
                          'assets/images/illustrations/login_illustration.png',
                          height: 180,
                        ),
                      ),

                    // 3. Login Form (Shared)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel("Email"),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              validator: (value) =>
                                  FormValidationRules.validateEmail(value),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.email_outlined),
                                hintText: "Your email",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildLabel("Password"),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              keyboardType: TextInputType.visiblePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              validator: (value) =>
                                  FormValidationRules.validatePassword(value),
                              onFieldSubmitted: (_) => _performLogin(),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                                hintText: "Your password",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: CheckboxListTile(
                                    value: _rememberMe,
                                    activeColor: Colors.black,
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text("Remember Me"),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    onChanged: (v) {
                                      setState(() {
                                        _rememberMe = v ?? false;
                                      });
                                    },
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    context.push(RouteNames.forgotPassword);
                                  },
                                  child: const Text(
                                    "Forgot password?",
                                    style: TextStyle(color: Colors.blue),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Show error message if login failed
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
                                      ref
                                          .read(authProvider.notifier)
                                          .clearError();
                                    },
                                  );
                                },
                              ),
                            const SizedBox(height: 12),
                            AppPrimaryButton(
                              onPressed: _isLoading ? null : _performLogin,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text("Login"),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 15),
                              child: Center(child: Text("or continue with")),
                            ),
                            AppOutlinedButton(
                              onPressed: () {},
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                    'assets/images/logos/google.svg',
                                    width: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    "Google",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: GestureDetector(
                                onTap: () {
                                  // Navigate to signup selection
                                  context.go(RouteNames.signupSelection);
                                },
                                child: RichText(
                                  text: const TextSpan(
                                    text: "Don't have an account? ",
                                    style: TextStyle(color: Colors.black),
                                    children: [
                                      TextSpan(
                                        text: "Sign Up",
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
    ),
  );
}
