import 'package:flutter/material.dart';
import 'app_colours.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      //Application Defaults
      useMaterial3: false,
      brightness: Brightness.light,

      //  Main Colour Scheme
      primaryColor: AppColours.accent,

      colorScheme: const ColorScheme.light(
        primary: AppColours.accent,
        secondary: AppColours.secondary,
        surface: AppColours.surface,
        error: AppColours.error,
        onPrimary: AppColours.textLight,
        onSecondary: AppColours.textPrimary,
        onSurface: AppColours.textPrimary,
        onError: AppColours.textLight,
      ),

      // Default page background
      scaffoldBackgroundColor: AppColours.background,

      //App bars
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColours.background,
        foregroundColor: AppColours.textLight,
        elevation: 0,
      ),

      //Text Styling
      textTheme: const TextTheme(
        bodyLarge: TextStyle(
          color: AppColours.textPrimary,
        ),
        bodyMedium: TextStyle(
          color: AppColours.textPrimary
        ),
        bodySmall:  TextStyle(
          color: AppColours.textSecondary,
        ),
        titleLarge: TextStyle(
          color: AppColours.accent,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: AppColours.accent,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Elevated Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColours.accent,
          foregroundColor: AppColours.textLight,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
            side: const BorderSide(
              color: AppColours.accent,
              width: 2,
            ),
          ),
        ),
      ),

      // Outlined Buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColours.accent,
          side: const BorderSide(
            color: AppColours.accent,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),

      //Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColours.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(
            color: AppColours.accent,
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(
            color: AppColours.secondary,
          ),
        ),
      ),
    );
  }
}