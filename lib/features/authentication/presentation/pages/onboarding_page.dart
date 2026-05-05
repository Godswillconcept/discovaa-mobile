import 'package:discovaa/app/router/route_names.dart';
import 'package:discovaa/core/constants/app_constants.dart';
import 'package:discovaa/core/widgets/custom_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../../core/utils/clippers.dart';
import '../providers/onboarding_provider.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  late PageController _pageController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoAdvanceTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoAdvanceTimer() {
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      final currentIndex = ref.read(onboardingPageIndexProvider);
      final nextIndex = (currentIndex + 1) % 3;

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    _startAutoAdvanceTimer();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(onboardingPageIndexProvider);
    final size = MediaQuery.of(context).size;

    // Assets for the three screens
    final List<String> images = [
      'assets/images/illustrations/photographer.png',
      'assets/images/illustrations/mechanic.png',
      'assets/images/illustrations/construction.png',
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // 1. Curved Black Header
            HeaderClipper(
              child: Container(
                padding: const EdgeInsets.only(bottom: 20),
                alignment: Alignment.bottomCenter,
                child: Image.asset(AppAssets.logo, width: 160),
              ),
            ),

            // 2. Sliding Image Section
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  ref.read(onboardingPageIndexProvider.notifier).state = index;
                  _resetTimer();
                },
                itemCount: 3,
                itemBuilder: (context, index) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),

                      child: Image.asset(
                        images[index],
                        height: size.height * 0.3,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),

            // 3. Indicator and Text Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Custom Dash Indicator
                  Row(
                    children: List.generate(
                      3,
                      (index) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        height: 3,
                        width: 30,
                        decoration: BoxDecoration(
                          color: currentIndex == index
                              ? Colors.black
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Headline with stylized "Artisans"
                  const Text(
                    "The best way\nto connect with",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Stack(
                    children: [
                      const Text(
                        "Artisans.",
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        left: 0,
                        child: SizedBox(
                          height: 8,
                          width: 140,
                          child: Image.asset(
                            'assets/images/logos/red_swoosh.png',
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 4. Buttons Footer
            Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  AppPrimaryButton(
                    onPressed: () => context.push(RouteNames.signupSelection),
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 15),
                  AppOutlinedButton(
                    onPressed: () => context.push(
                      RouteNames.login,
                      extra: {'fromOnboarding': true},
                    ),
                    child: RichText(
                      text: TextSpan(
                        text: "Already have an account? ",
                        style: const TextStyle(color: Colors.black),
                        children: [
                          TextSpan(
                            text: "Sign in",
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20), // Bottom safe area spacer
          ],
        ),
      ),
    );
  }
}
