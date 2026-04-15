import 'package:flutter/material.dart';
import 'package:discovaa/core/constants/app_theme.dart' as theme;

class AppThemes {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: theme.AppTheme.primaryColor,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: theme.AppTheme.elevationNone,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: theme.AppTheme.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: theme.AppTheme.fontFamily,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.AppTheme.primaryColor,
          foregroundColor: theme.AppTheme.textOnPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(theme.AppTheme.radiusMedium),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: theme.AppTheme.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(theme.AppTheme.radiusMedium),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: theme.AppTheme.borderColor),
          borderRadius: BorderRadius.circular(theme.AppTheme.radiusMedium),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: theme.AppTheme.primaryColor),
          borderRadius: BorderRadius.circular(theme.AppTheme.radiusMedium),
        ),
        filled: true,
        fillColor: theme.AppTheme.surfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        hintStyle: const TextStyle(color: theme.AppTheme.textTertiary),
        labelStyle: const TextStyle(color: theme.AppTheme.textSecondary),
      ),
      cardTheme: CardThemeData(
        color: theme.AppTheme.surfaceColor,
        elevation: theme.AppTheme.elevationSmall,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.AppTheme.radiusLarge),
        ),
        margin: const EdgeInsets.all(8),
      ),
    );
  }

  // static ThemeData get darkTheme {
  //   return ThemeData(
  //     useMaterial3: true,
  //     colorScheme: ColorScheme.fromSeed(
  //       seedColor: theme.AppTheme.primaryColor,
  //       brightness: Brightness.dark,
  //     ),
  //     appBarTheme: const AppBarTheme(
  //       backgroundColor: Colors.transparent,
  //       elevation: theme.AppTheme.elevationNone,
  //       centerTitle: true,
  //       titleTextStyle: TextStyle(
  //         color: theme.AppTheme.textPrimary,
  //         fontSize: 20,
  //         fontWeight: FontWeight.w600,
  //         fontFamily: theme.AppTheme.fontFamily,
  //       ),
  //     ),
  //     elevatedButtonTheme: ElevatedButtonThemeData(
  //       style: ElevatedButton.styleFrom(
  //         backgroundColor: theme.AppTheme.primaryColor,
  //         foregroundColor: theme.AppTheme.textOnPrimary,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(theme.AppTheme.radiusMedium),
  //         ),
  //         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  //       ),
  //     ),
  //     textButtonTheme: TextButtonThemeData(
  //       style: TextButton.styleFrom(
  //         foregroundColor: theme.AppTheme.primaryColor,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(theme.AppTheme.radiusMedium),
  //         ),
  //       ),
  //     ),
  //     inputDecorationTheme: InputDecorationTheme(
  //       border: OutlineInputBorder(
  //         borderSide: const BorderSide(color: theme.AppTheme.borderColor),
  //         borderRadius: BorderRadius.circular(theme.AppTheme.radiusMedium),
  //       ),
  //       focusedBorder: OutlineInputBorder(
  //         borderSide: const BorderSide(color: theme.AppTheme.primaryColor),
  //         borderRadius: BorderRadius.circular(theme.AppTheme.radiusMedium),
  //       ),
  //       filled: true,
  //       fillColor: theme.AppTheme.surfaceColor,
  //       contentPadding: const EdgeInsets.symmetric(
  //         horizontal: 16,
  //         vertical: 12,
  //       ),
  //       hintStyle: const TextStyle(color: theme.AppTheme.textTertiary),
  //       labelStyle: const TextStyle(color: theme.AppTheme.textSecondary),
  //     ),
  //     cardTheme: CardThemeData(
  //       color: theme.AppTheme.surfaceColor,
  //       elevation: theme.AppTheme.elevationSmall,
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(theme.AppTheme.radiusLarge),
  //       ),
  //       margin: const EdgeInsets.all(8),
  //     ),
  //   );
  // }

  // static ThemeData get statusBarTheme {
  //   return ThemeData(
  //     useMaterial3: true,
  //     colorScheme: ColorScheme.fromSeed(
  //       seedColor: theme.AppTheme.primaryColor,
  //       brightness: Brightness.light,
  //     ),
  //     appBarTheme: AppBarTheme(
  //       systemOverlayStyle: SystemUiOverlayStyle.dark,
  //       backgroundColor: Colors.transparent,
  //       elevation: theme.AppTheme.elevationNone,
  //       centerTitle: true,
  //       titleTextStyle: TextStyle(
  //         color: Colors.white,
  //         fontSize: 20,
  //         fontWeight: FontWeight.w600,
  //         fontFamily: theme.AppTheme.fontFamily,
  //       ),
  //     ),
  //     elevatedButtonTheme: ElevatedButtonThemeData(
  //       style: ElevatedButton.styleFrom(
  //         backgroundColor: theme.AppTheme.primaryColor,
  //         foregroundColor: Colors.white,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(theme.AppTheme.radiusMedium),
  //         ),
  //         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  //       ),
  //     ),
  //     textButtonTheme: TextButtonThemeData(
  //       style: TextButton.styleFrom(
  //         foregroundColor: Colors.white,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(theme.AppTheme.radiusMedium),
  //         ),
  //       ),
  //     ),
  //     inputDecorationTheme: InputDecorationTheme(
  //       border: OutlineInputBorder(
  //         borderSide: const BorderSide(color: Colors.white),
  //         borderRadius: BorderRadius.circular(theme.AppTheme.radiusMedium),
  //       ),
  //       focusedBorder: OutlineInputBorder(
  //         borderSide: const BorderSide(color: Colors.white),
  //         borderRadius: BorderRadius.circular(theme.AppTheme.radiusMedium),
  //       ),
  //       filled: true,
  //       fillColor: Colors.white,
  //       contentPadding: const EdgeInsets.symmetric(
  //         horizontal: 16,
  //         vertical: 12,
  //       ),
  //       hintStyle: const TextStyle(color: Colors.black54),
  //       labelStyle: const TextStyle(color: Colors.black87),
  //     ),
  //     cardTheme: CardThemeData(
  //       color: Colors.white,
  //       elevation: theme.AppTheme.elevationSmall,
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(theme.AppTheme.radiusLarge),
  //       ),
  //       margin: const EdgeInsets.all(8),
  //     ),
  //   );
  // }
}
