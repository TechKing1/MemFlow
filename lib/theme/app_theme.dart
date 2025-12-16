import 'package:flutter/material.dart';

class AppTheme {
  // Colors - Modern Vibrant Theme
  static const Color primaryColor = Color(0xFF4F46E5);  // Indigo-600
  static const Color primaryLight = Color(0x804F46E5);  // 50% opacity
  static const Color primaryDark = Color(0xFF4338CA);   // Indigo-700
  static const Color secondaryColor = Color(0xFF10B981); // Emerald-500
  static const Color accentColor = Color(0xFF8B5CF6);    // Violet-500
  static const Color successColor = Color(0xFF10B981);   // Emerald-500
  static const Color successLight = Color(0x2010B981);   // 12% opacity
  static const Color successDark = Color(0xFF059669);    // Emerald-600
  static const Color errorColor = Color(0xFFEF4444);     // Red-500
  static const Color warningColor = Color(0xFFF59E0B);   // Amber-500
  static const Color infoColor = Color(0xFF3B82F6);      // Blue-500
  
  // Background & Surface
  static const Color backgroundColor = Color(0xFFF8FAFC); // Cool Gray-50
  static const Color surfaceColor = Colors.white;
  static const Color onSurfaceColor = Color(0xFF1E293B);  // Cool Gray-800
  static const Color hintColor = Color(0xFF94A3B8);       // Cool Gray-400
  static const Color borderColor = Color(0xFFE2E8F0);     // Cool Gray-200

  // Text Styles
  static const TextStyle headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: onSurfaceColor,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: onSurfaceColor,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: onSurfaceColor,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: onSurfaceColor,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: hintColor,
    height: 1.5,
  );

  // Light Theme
  static ThemeData get lightTheme {
    final baseTheme = ThemeData.light(useMaterial3: true);
    
    return baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: primaryColor,
        primaryContainer: primaryDark,
        secondary: secondaryColor,
        surface: surfaceColor,
        background: backgroundColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: onSurfaceColor,
        onBackground: onSurfaceColor,
        onError: Colors.white,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      cardTheme: baseTheme.cardTheme.copyWith(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: primaryDark,
        contentTextStyle: TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: headingLarge,
        displayMedium: headingMedium,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
      ),
      scaffoldBackgroundColor: backgroundColor,
    );
  }

  // Dark Theme
  static ThemeData get darkTheme => ThemeData.dark().copyWith(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: Color(0xFF1E293B), // Dark surface
      background: Color(0xFF0F172A), // Dark background
      error: errorColor,
    ),
    // Add more dark theme customizations as needed
  );
}
