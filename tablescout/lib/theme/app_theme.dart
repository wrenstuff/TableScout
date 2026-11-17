import 'package:flutter/material.dart';

import 'app_colours.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      //Application Defaults
      useMaterial3: false,
      brightness: Brightness.light,

      //  Main Colour Scheme
      primaryColor: AppColours.accent,
      cardColor: AppColours.primary,

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

      // Application Typography
      textTheme: const TextTheme(
        bodyLarge: AppTextStyles.body,
        bodyMedium: AppTextStyles.body,
        bodySmall: AppTextStyles.bodySmall,
        titleLarge: AppTextStyles.pageTitle,
        titleMedium: AppTextStyles.sectionTitle,
        titleSmall: AppTextStyles.cardTitle,
        labelLarge: AppTextStyles.label,
        labelMedium: AppTextStyles.bodySmall,
        labelSmall: AppTextStyles.caption,
      ),

      //App bars
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColours.background,
        foregroundColor: AppColours.textPrimary,
        elevation: 0,
        titleTextStyle: AppTextStyles.pageTitle,
      ),

      // Elevated Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColours.accent,
          foregroundColor: AppColours.textLight,
          textStyle: AppTextStyles.button,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
            side: const BorderSide(color: AppColours.accent, width: 2),
          ),
        ),
      ),

      // Outlined Buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColours.accent,
          textStyle: AppTextStyles.button.copyWith(color: AppColours.accent),
          side: const BorderSide(color: AppColours.accent, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
      ),

      //Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColours.surface,

        labelStyle: AppTextStyles.label,
        floatingLabelStyle: AppTextStyles.label.copyWith(
          color: AppColours.accent,
        ),
        hintStyle: AppTextStyles.hint,
        errorStyle: AppTextStyles.caption.copyWith(color: AppColours.error),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: AppColours.accent, width: 1),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: AppColours.accent, width: 1),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: AppColours.secondary, width: 2),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: AppColours.error),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: AppColours.error, width: 2),
        ),
      ),

      // Text Fields
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColours.accent,
        selectionColor: AppColours.secondary,
        selectionHandleColor: AppColours.accent,
      ),

      // Dropdowns
      dropdownMenuTheme: const DropdownMenuThemeData(textStyle: AppTextStyles.input),

      // Dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: AppColours.surface,
        titleTextStyle: AppTextStyles.sectionTitle,
        contentTextStyle: AppTextStyles.body,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.circular(10),
        ),
      ),

      // Date Picker
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColours.surface,

        // Header
        headerBackgroundColor: AppColours.primary,
        headerForegroundColor: AppColours.textPrimary,

        headerHeadlineStyle: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColours.textLight,
        ),

        headerHelpStyle: const TextStyle(
          fontSize: 12,
          color: AppColours.textLight,
        ),
        
        // Calendar Text
        weekdayStyle: AppTextStyles.bodySmall,
        dayStyle: AppTextStyles.body,
        yearStyle: AppTextStyles.body,

        // Selected and Today's date
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColours.textLight;
          }
          return AppColours.textPrimary;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColours.accent;
          }
          return null;
        }),
        todayForegroundColor: WidgetStateProperty.all(AppColours.accent),
        todayBackgroundColor: WidgetStateProperty.all(AppColours.primary),
        todayBorder: const BorderSide(
          color: AppColours.accent,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),

      // Time Picker
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColours.surface,

        // Selected Hour and minute
        hourMinuteColor: AppColours.primary,
        hourMinuteTextColor: AppColours.accent,

        // Clock dial
        dialHandColor: AppColours.secondary,
        dialBackgroundColor: AppColours.primary,
        dialTextColor: AppColours.accent,

        // AM / PM selection
        entryModeIconColor: AppColours.accent,
        dayPeriodColor: AppColours.primary,
        dayPeriodTextColor: AppColours.accent,


        helpTextStyle: AppTextStyles.label,

        hourMinuteTextStyle: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColours.textPrimary,
        ),

        dayPeriodTextStyle: AppTextStyles.label,
        dialTextStyle: AppTextStyles.body,
        
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)
        ),
      ),

      // Dialog Buttons (Including Date/Time picker actions
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColours.accent,
          textStyle: AppTextStyles.button.copyWith(color: AppColours.accent),
        ),
      ),
    );
  }
}
