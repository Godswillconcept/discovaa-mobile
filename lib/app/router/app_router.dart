import 'package:discovaa/features/notifications/presentation/pages/notifications_page.dart';
import 'package:discovaa/features/messaging/presentation/pages/chat_page.dart';
import 'package:discovaa/features/messaging/presentation/pages/messages_list_page.dart';
import 'package:discovaa/features/messaging/domain/entities/conversation.dart';
import 'package:discovaa/features/profile/presentation/pages/favorites_page.dart';
import 'package:discovaa/features/profile/presentation/pages/user_profile_page.dart';
import 'package:discovaa/features/profile/presentation/pages/artisan_profile_page.dart';
import 'package:discovaa/features/home/presentation/pages/home_page.dart';
import 'package:discovaa/features/home/presentation/pages/dashboard_page.dart';
import 'package:discovaa/features/bookings/presentation/pages/bookings_page.dart';
import 'package:discovaa/features/services/presentation/pages/services_page.dart';
import 'package:discovaa/features/authentication/presentation/pages/identification_page.dart';
import 'package:discovaa/shared/presentation/pages/main_navigation_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:discovaa/core/storage/secure_token_storage.dart';
import 'package:discovaa/core/storage/hive_service.dart';
import 'package:discovaa/features/authentication/presentation/pages/complete_profile_page.dart';
import 'package:discovaa/features/authentication/presentation/pages/forgot_password_page.dart';
import 'package:discovaa/features/authentication/presentation/pages/login_page.dart';
import 'package:discovaa/features/authentication/presentation/pages/onboarding_page.dart';
import 'package:discovaa/features/authentication/presentation/pages/otp_page.dart';
import 'package:discovaa/features/authentication/presentation/pages/register_page.dart';
import 'package:discovaa/features/authentication/presentation/pages/reset_password_page.dart';
import 'package:discovaa/features/authentication/presentation/pages/signup_selection_page.dart';
import 'package:discovaa/features/contact_us/presentation/pages/contact_us_page.dart';
import 'package:discovaa/features/splash/presentation/pages/splash_page.dart';
import 'package:discovaa/app/router/route_names.dart';

/// List of routes that don't require authentication.
/// Users can access these routes without being logged in.
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
  RouteNames.completeProfile,
  RouteNames.contactUs,
];

/// Check if a route is public (doesn't require authentication).
bool _isPublicRoute(String location) {
  for (final route in _publicRoutes) {
    if (location == route || location.startsWith('$route/')) {
      return true;
    }
  }
  return false;
}

/// Global instance of SecureTokenStorage for router auth checks.
/// This is initialized lazily when first accessed.
SecureTokenStorage? _tokenStorage;
SecureTokenStorage get _routerTokenStorage {
  return _tokenStorage ??= SecureTokenStorage(
    hiveService: HiveService.instance,
  );
}

class AppRouter {
  static const String initial = RouteNames.splash;

  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final location = state.uri.path;

      // Allow access to public routes
      if (_isPublicRoute(location)) {
        return null;
      }

      // Check if user is authenticated
      final isAuthenticated =
          _routerTokenStorage.isAuthenticated() &&
          _routerTokenStorage.hasValidTokens();

      // Redirect unauthenticated users to login
      if (!isAuthenticated) {
        return RouteNames.onboarding;
      }

      // User is authenticated, allow access
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
          final fromOnboarding = extra?['fromOnboarding'] as bool? ?? false;
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
          final fromOnboarding = extra?['fromOnboarding'] as bool? ?? false;
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

      // Dashboard is now inside ShellRoute

      // Verification/Identification
      GoRoute(
        path: RouteNames.identification,
        builder: (context, state) => const IdentificationPage(),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainNavigationPage(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.home,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.dashboard,
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.bookings,
                builder: (context, state) => const BookingsPage(),
              ),
            ],
          ),
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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.services,
                builder: (context, state) => const ServicesPage(),
              ),
            ],
          ),
        ],
      ),

      // Notifications
      GoRoute(
        path: RouteNames.notifications,
        builder: (context, state) => const NotificationsPage(),
      ),

      // Favorites
      GoRoute(
        path: RouteNames.favorites,
        builder: (context, state) => const FavoritesPage(),
      ),
      // User Profile
      GoRoute(
        path: RouteNames.userProfile,
        builder: (context, state) => const UserProfilePage(),
      ),
      // Artisan Profile
      GoRoute(
        path: RouteNames.artisanProfile,
        builder: (context, state) => const ArtisanProfilePage(),
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
