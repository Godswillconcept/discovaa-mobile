import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../features/authentication/presentation/providers/auth_initializer_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Animation for the Logo scaling (Image 2 to Image 3)
  late Animation<double> _logoScale;

  // Animation for the Tagline opacity (Image 4)
  late Animation<double> _taglineOpacity;

  @override
  void initState() {
    super.initState();

    // Total duration of the splash sequence
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // 1. Logo Scale: Starts small (Image 2) and grows to full size (Image 3)
    // Timing: 0% to 60% of total duration
    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    // 2. Tagline Fade: Stays invisible until logo is grown, then fades in (Image 4)
    // Timing: 70% to 100% of total duration
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.linear),
      ),
    );

    // Start the animation sequence
    _controller.forward().then((_) async {
      // Hold on the final state (Image 4) for 1.5 seconds
      await Future.delayed(const Duration(milliseconds: 1500));

      if (!mounted) return;

      // Wait for auth initialization to complete
      await _waitForAuthInitialization();

      if (!mounted) return;

      // Navigate based on auth status
      _navigateBasedOnAuthStatus();
    });
  }

  /// Wait for auth initialization to complete.
  ///
  /// This ensures we have the authentication status before navigating.
  Future<void> _waitForAuthInitialization() async {
    // Wait for up to 5 seconds for auth to initialize
    const maxWaitDuration = Duration(seconds: 5);
    const checkInterval = Duration(milliseconds: 100);
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < maxWaitDuration) {
      final isInitialized = ref.read(isAuthInitializedProvider);
      if (isInitialized) {
        break;
      }
      await Future.delayed(checkInterval);
    }
    stopwatch.stop();
  }

  /// Navigate based on the current authentication status.
  ///
  /// - If authenticated: Go to home
  /// - If unauthenticated: Go to onboarding
  void _navigateBasedOnAuthStatus() {
    final authState = ref.read(authInitializerProvider);

    switch (authState.status) {
      case AuthStatus.authenticated:
        // User is logged in, navigate to home
        context.go(RouteNames.home);
        break;
      case AuthStatus.unauthenticated:
      case AuthStatus.unknown:
        // User is not logged in, navigate to onboarding
        context.go(RouteNames.onboarding);
        break;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width for responsive scaling
    final screenWidth = MediaQuery.of(context).size.width;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.background,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Responsive Logo with Scaling Animation
              AnimatedBuilder(
                animation: _logoScale,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoScale.value,
                    child: Image.asset(
                      AppAssets.logo,
                      width:
                          screenWidth *
                          0.5, // Adjust width based on screen size
                      fit: BoxFit.contain,
                    ),
                  );
                },
              ),

              // Tagline - Only appears on the last stage (Image 4)
              FadeTransition(
                opacity: _taglineOpacity,
                child: const Text(
                  'All expertise on one platform',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
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
