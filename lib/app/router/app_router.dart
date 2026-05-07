import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:discovaa/app/router/route_names.dart';
import 'package:discovaa/features/authentication/presentation/pages/complete_profile_page.dart';
import 'package:discovaa/features/authentication/presentation/pages/forgot_password_page.dart';
import 'package:discovaa/features/authentication/presentation/pages/identification_page.dart';
import 'package:discovaa/features/authentication/presentation/pages/login_page.dart';
import 'package:discovaa/features/authentication/presentation/pages/onboarding_page.dart';
import 'package:discovaa/features/authentication/presentation/pages/otp_page.dart';
import 'package:discovaa/features/authentication/presentation/pages/register_page.dart';
import 'package:discovaa/features/authentication/presentation/pages/reset_password_page.dart';
import 'package:discovaa/features/authentication/presentation/pages/signup_selection_page.dart';
import 'package:discovaa/features/authentication/presentation/providers/auth_provider.dart';
import 'package:discovaa/features/bookings/presentation/pages/bookings_page.dart';
import 'package:discovaa/features/contact_us/presentation/pages/contact_us_page.dart';
import 'package:discovaa/features/home/presentation/pages/dashboard_page.dart';
import 'package:discovaa/features/home/presentation/pages/home_page.dart';
import 'package:discovaa/features/messaging/presentation/pages/chat_page.dart';
import 'package:discovaa/features/messaging/presentation/pages/messages_list_page.dart';
import 'package:discovaa/features/messaging/domain/entities/conversation.dart';
import 'package:discovaa/features/notifications/presentation/pages/notifications_page.dart';
import 'package:discovaa/features/profile/presentation/pages/artisan_profile_page.dart';
import 'package:discovaa/features/profile/presentation/pages/favorites_page.dart';
import 'package:discovaa/features/profile/presentation/pages/user_profile_page.dart';
import 'package:discovaa/features/services/presentation/pages/services_page.dart';
import 'package:discovaa/features/splash/presentation/pages/splash_page.dart';
import 'package:discovaa/shared/presentation/pages/main_navigation_page.dart';

/// List of public routes that don't require authentication
const List<String> _publicRoutes = [
  RouteNames.splash,
  RouteNames.onboarding,
  RouteNames.login,
  RouteNames.signin,
  RouteNames.signupSelection,
  RouteNames.register,
  RouteNames.otp,
  RouteNames.forgotPassword,
  RouteNames.resetPassword,
  RouteNames.contactUs,
];

/// List of auth routes (login, register, etc.)
const List<String> _authRoutes = [
  RouteNames.login,
  RouteNames.signin,
  RouteNames.register,
  RouteNames.otp,
  RouteNames.forgotPassword,
  RouteNames.resetPassword,
];

/// Check if a route is public
bool _isPublicRoute(String location) {
  for (final route in _publicRoutes) {
    if (location == route || location.startsWith('$route/')) {
      return true;
    }
  }
  return false;
}

/// Check if a route is an auth route
bool _isAuthRoute(String location) {
  for (final route in _authRoutes) {
    if (location == route || location.startsWith('$route/')) {
      return true;
    }
  }
  return false;
}

class AppRouter {
  static const String initial = RouteNames.splash;

  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    refreshListenable: authRefreshNotifier,
    redirect: (context, state) {
      final location = state.uri.path;

      // Get the auth state from Riverpod
      final container = ProviderScope.containerOf(context);
      final authState = container.read(authProvider);

      // Wait for auth initialization
      if (authState.isLoading || authState.isRefreshing) {
        return RouteNames.splash;
      }

      final value = authState.value;
      if (value == null) {
        // Still loading or error, stay on splash
        return RouteNames.splash;
      }

      final isAuthenticated = value.isAuthenticated;
      final needsProfile = value.needsProfile;
      final needsVerification = value.needsVerification;

      // Check profile completion FIRST - before any other checks
      // Users with requiresProfile status must be redirected to /complete-profile
      // BUT allow OTP route for email verification (prerequisite to profile completion)
      if (needsProfile &&
          location != RouteNames.completeProfile &&
          location != RouteNames.otp) {
        return RouteNames.completeProfile;
      }

      // Check identity verification SECOND - before any other checks
      // ALL users with requiresVerification status must be redirected to /identification
      if (needsVerification && location != RouteNames.identification) {
        return RouteNames.identification;
      }

      // Allow access to public routes
      if (_isPublicRoute(location)) {
        // If already authenticated (or needs profile/verification handled above), redirect to home
        if (isAuthenticated) {
          return RouteNames.home;
        }
        return null;
      }

      // Check if user is authenticated (also consider profile/verification states as "authenticated enough")
      if (!isAuthenticated && !needsProfile && !needsVerification) {
        return RouteNames.onboarding;
      }

      // Prevent authenticated users from accessing auth routes
      if ((isAuthenticated || needsProfile || needsVerification) &&
          _isAuthRoute(location)) {
        return RouteNames.home;
      }

      return null;
    },
    routes: [
      // Splash/Onboarding
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),

      // Authentication
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final fromOnboarding = extra?['fromOnboarding'] as bool? ?? true;
          final fromRegistration = extra?['fromRegistration'] as bool? ?? false;
          return LoginPage(
            fromOnboarding: fromOnboarding,
            fromRegistration: fromRegistration,
          );
        },
      ),
      GoRoute(
        path: RouteNames.signin,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final fromOnboarding = extra?['fromOnboarding'] as bool? ?? true;
          final fromRegistration = extra?['fromRegistration'] as bool? ?? false;
          return LoginPage(
            fromOnboarding: fromOnboarding,
            fromRegistration: fromRegistration,
          );
        },
      ),
      GoRoute(
        path: RouteNames.signupSelection,
        builder: (context, state) => const SignupSelectionPage(),
      ),
      GoRoute(
        path: RouteNames.otp,
        builder: (context, state) => const OtpPage(),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: RouteNames.completeProfile,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final fromLogin = extra?['fromLogin'] as bool? ?? false;
          return CompleteProfilePage(fromLogin: fromLogin);
        },
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: RouteNames.resetPassword,
        builder: (context, state) => const ResetPasswordPage(),
      ),

      // Contact Us
      GoRoute(
        path: RouteNames.contactUs,
        builder: (context, state) => const ContactUsPage(),
      ),

      // Verification/Identification
      GoRoute(
        path: RouteNames.identification,
        builder: (context, state) => const IdentificationPage(),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainNavigationPage(navigationShell: navigationShell),
        branches: _buildShellBranches(),
      ),
    ],
    errorBuilder: (context, state) => ErrorPage(error: state.error),
  );
}

class ErrorPage extends StatelessWidget {
  final Exception? error;

  const ErrorPage({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('An error occurred'),
            if (error != null) Text(error.toString()),
          ],
        ),
      ),
    );
  }
}

/// Build shell branches - all branches always created
/// Feature flags control whether actual pages or Coming Soon pages are shown
List<StatefulShellBranch> _buildShellBranches() {
  final branches = <StatefulShellBranch>[];

  // Home branch (always available)
  branches.add(
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: RouteNames.home,
          builder: (context, state) => const HomePage(),
          routes: [
            GoRoute(
              path: 'favorites',
              builder: (context, state) => const FavoritesPage(),
            ),
            GoRoute(
              path: 'user-profile',
              builder: (context, state) => const UserProfilePage(),
            ),
            GoRoute(
              path: 'artisan-profile/:id',
              builder: (context, state) {
                final artisanId = state.pathParameters['id'];
                if (artisanId == null) {
                  return const Scaffold(
                    body: Center(child: Text('No artisan selected')),
                  );
                }
                return ArtisanProfilePage(artisanId: artisanId);
              },
            ),
            GoRoute(
              path: 'notifications',
              builder: (context, state) => const NotificationsPage(),
            ),
          ],
        ),
      ],
    ),
  );

  // Dashboard branch
  branches.add(
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: RouteNames.dashboard,
          builder: (context, state) => const DashboardPage(),
        ),
      ],
    ),
  );

  // Bookings branch (always available)
  branches.add(
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: RouteNames.bookings,
          builder: (context, state) => const BookingsPage(),
        ),
      ],
    ),
  );

  // Messages branch
  branches.add(
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: RouteNames.messages,
          builder: (context, state) => const MessagesListPage(),
          routes: [
            GoRoute(
              path: 'chat',
              builder: (context, state) {
                final conversation = state.extra as Conversation;
                return ChatPage(conversation: conversation);
              },
            ),
          ],
        ),
      ],
    ),
  );

  // Services branch (always available for providers)
  branches.add(
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: RouteNames.services,
          builder: (context, state) => const ServicesPage(),
        ),
      ],
    ),
  );

  return branches;
}
