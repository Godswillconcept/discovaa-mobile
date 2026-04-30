import 'package:flutter/material.dart';

class AppConstants {
  // App Information
  static const String appName = 'Discovaa';
  static const String appVersion = '1.0.0';
  static const bool isDebugMode = true; // Set to false in production
  static const String platform =
      'Flutter'; // Could be dynamic based on platform

  // API Configuration
  static const String apiBaseUrl =
      'https://p01--discovaa-app--492q2z77g54x.code.run';
  static const int apiTimeout =
      60000; // 60 seconds - increased for slow endpoints
  static const int apiConnectTimeout = 20000; // 20 seconds

  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userProfileKey = 'user_profile';
  static const String themeKey = 'theme_mode';
  static const String localeKey = 'locale';
  static const String onboardingCompletedKey = 'onboarding_completed';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Image Upload
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> supportedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  ];

  // Validation
  static const int minPasswordLength = 8;
  static const int maxUsernameLength = 30;
  static const int maxBioLength = 500;

  // Rate Limiting
  static const int maxLoginAttempts = 5;
  static const Duration loginLockoutDuration = Duration(minutes: 15);

  // Cache Duration
  static const Duration defaultCacheDuration = Duration(hours: 1);
  static const Duration userProfileCacheDuration = Duration(minutes: 30);

  // UI Constants
  static const double defaultBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;
  static const double defaultPadding = 16.0;
  static const double largePadding = 24.0;

  // Typography
  static const String fontFamily = 'Inter'; // Google Fonts Inter font

  // Animation Durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration fastAnimationDuration = Duration(milliseconds: 150);
  static const Duration slowAnimationDuration = Duration(milliseconds: 500);
}

class AppColors {
  static const Color background = Color(0xFF000000);
  static const Color primary = Color(0xFF111111); // Professional Shade of Black
  static const Color success = Color(0xFF10B981); // Emerald Success
  static const Color primaryRed = Color(
    0xFFE2211D,
  ); // The red from the logo swoosh
  static const Color textWhite = Color(0xFFFFFFFF);

  // Additional colors for booking and UI elements
  static const Color warning = Color(0xFFF59E0B); // Amber/Warning
  static const Color lightBlueBackground = Color(
    0xFFF8FBFF,
  ); // Light blue background
  static const Color lightOrangeBackground = Color(
    0xFFFFF7ED,
  ); // Light orange background
}

class AppAssets {
  static const String logo = 'assets/images/logos/logo.png';

  /// Number of service placeholder images available (service_1.png … service_25.png)
  static const int _servicePlaceholderCount = 25;

  /// Returns a deterministic placeholder asset path for a service image.
  /// Uses [seed] (e.g. service id) so the same service always gets the same image.
  static String servicePlaceholder(String seed) {
    final index =
        (seed.codeUnits.fold(0, (a, b) => a + b) % _servicePlaceholderCount) +
        1;
    return 'assets/images/placeholders/service_$index.png';
  }
}
