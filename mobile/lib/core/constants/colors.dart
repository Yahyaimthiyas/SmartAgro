import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors (Google Palette)
  static const Color primary = Color(0xFF1A73E8);        // Google Blue
  static const Color primaryContainer = Color(0xFFD2E3FC); // Light Blue Surface
  static const Color secondary = Color(0xFF34A853);      // Google Green
  static const Color secondaryContainer = Color(0xFFE6F4EA); // Light Green Surface
  static const Color accent = Color(0xFFFBBC05);         // Google Yellow
  static const Color error = Color(0xFFEA4335);           // Google Red (Warning)
  static const Color googleRed = Color(0xFFEA4335);       
  static const Color googleBlue = Color(0xFF1A73E8);
  static const Color googleGreen = Color(0xFF34A853);
  static const Color googleYellow = Color(0xFFFBBC05);

  // Backgrounds & Surfaces
  static const Color background = Color(0xFFF8F9FA);     // Minimalist Light Gray
  static const Color surface = Colors.white;             // Card/List Backgrounds
  static const Color surfaceVariant = Color(0xFFEEEEEE); // Alternative Surfaces
  static const Color surfaceTonal = Color(0xFFF1F3F4);   // Google Tonal Surface

  // Text Colors
  static const Color textPrimary = Color(0xFF202124);   // Standard Black Text
  static const Color textSecondary = Color(0xFF5F6368); // Secondary Dark Gray
  static const Color textTertiary = Color(0xFF70757A);  // Faint Text
  static const Color textPlaceholder = Color(0xFF9AA0A6); // Input Placeholder

  // Border & Dividers
  static const Color border = Color(0xFFDADCE0);         // Subtle Component Borders
  static const Color borderLight = Color(0xFFE8EAED);    // Lightest Dividers

  // Semantic States
  static const Color success = Color(0xFF34A853);
  static const Color warning = Color(0xFFFBBC05);
  static const Color info = Color(0xFF1A73E8);

  // Box Shadows
  static List<BoxShadow> premiumShadow = [
    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
  ];

  // Aliases for compatibility
  static const Color primaryDark = Color(0xFF174EA6);
  static const Color primaryLight = Color(0xFFD2E3FC);
  static const Color danger = error;
  static const Color cardBg = surface;
}
