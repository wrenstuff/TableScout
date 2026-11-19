import 'package:flutter/material.dart';
import 'app_colours.dart';

class AppTextStyles {
  //Page Headings
  static const TextStyle pageTitle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: AppColours.accent,
  );

  // Section Headings
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w600,
    color: AppColours.textPrimary,
  );

  // Card Headings
  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColours.textPrimary,
  );

  // Standard Applicaton Text
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColours.textPrimary,
  );

  // Secondary Information
  static const bodySmall = TextStyle(
    fontSize: 13,
    color: AppColours.textSecondary,
  );

  // Form Labels
  static const label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColours.accent,
  );

  // Text entered into form fields
  static const TextStyle input = TextStyle(
    fontSize: 14,
    color: AppColours.textPrimary,
  );

  // Placeholder Text
  static const TextStyle hint = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColours.textSecondary,
  );

  // Buttons
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColours.textLight,
  );

  // Small Supporting Text
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    color: AppColours.textSecondary,
  );
}