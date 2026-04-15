import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors
  static const Color primaryColor = Color(0xFF111111); // Professional Shade of Black
  static const Color primaryVariant = Color(0xFF000000); // Deep Black variant
  static const Color secondaryColor = Color(0xFF10B981); // Emerald
  static const Color secondaryVariant = Color(0xFF059669);

  // Neutral Colors
  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;

  // Text Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Colors.white;

  // Status Colors
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color infoColor = Color(0xFF3B82F6);

  // Border Colors
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color dividerColor = Color(0xFFF3F4F6);

  // Shadow Colors
  static const Color shadowColor = Color(0x1A000000);
  static const Color shadowColorLight = Color(0x0D000000);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, primaryVariant],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondaryColor, secondaryVariant],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Typography
  static const String fontFamily = 'Inter';

  // Border Radius
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusXLarge = 16.0;
  static const double radiusXXLarge = 24.0;

  // Spacing
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  static const double spacingXXLarge = 48.0;

  // Elevations
  static const double elevationNone = 0.0;
  static const double elevationSmall = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationLarge = 8.0;
  static const double elevationXLarge = 16.0;
}

class AppTextStyles {
  // Headings
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppTheme.textPrimary,
    fontFamily: AppTheme.fontFamily,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppTheme.textPrimary,
    fontFamily: AppTheme.fontFamily,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppTheme.textPrimary,
    fontFamily: AppTheme.fontFamily,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppTheme.textPrimary,
    fontFamily: AppTheme.fontFamily,
  );

  static const TextStyle h5 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppTheme.textPrimary,
    fontFamily: AppTheme.fontFamily,
  );

  static const TextStyle h6 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppTheme.textPrimary,
    fontFamily: AppTheme.fontFamily,
  );

  // Body Text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppTheme.textPrimary,
    fontFamily: AppTheme.fontFamily,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppTheme.textPrimary,
    fontFamily: AppTheme.fontFamily,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppTheme.textSecondary,
    fontFamily: AppTheme.fontFamily,
  );

  // Button Text
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppTheme.textOnPrimary,
    fontFamily: AppTheme.fontFamily,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppTheme.textOnPrimary,
    fontFamily: AppTheme.fontFamily,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppTheme.textOnPrimary,
    fontFamily: AppTheme.fontFamily,
  );

  // Caption
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: AppTheme.textTertiary,
    fontFamily: AppTheme.fontFamily,
  );

  // Label
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppTheme.textSecondary,
    fontFamily: AppTheme.fontFamily,
  );
}
