import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors - "Premium Emerald & Harvest Gold"
  static const Color primaryDark = Color(0xFF00251A);
  static const Color primary = Color(0xFF004D40); // Deep Emerald
  static const Color primaryLight = Color(0xFF26A69A);
  static const Color accent = Color(0xFFFFC107); // Harvest Gold for highlights
  
  // Neutral Palette
  static const Color background = Color(0xFFFBFDFA); // Natural Off-White
  static const Color surface = Colors.white;
  static const Color cardBg = Color(0xFFFFFFFF);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1A1C1E); // Deep Slate
  static const Color textSecondary = Color(0xFF42474E); // Muted Slate
  static const Color textPlaceholder = Color(0xFF72777A);
  
  // Specific UI Meanings
  static const Color healthy = Color(0xFF2E7D32); // Success/Growth
  static const Color warning = Color(0xFFF57C00); // Low Stock/Caution
  static const Color danger = Color(0xFFD32F2F);  // Out of Stock/Critical
  static const Color medical = Color(0xFF0288D1); // Dosage/Advice

  // Glassmorphism overlays
  static Color glassWhite = Colors.white.withOpacity(0.7);
  static Color glassBlack = Colors.black.withOpacity(0.1);

  // Borders
  static const Color border = Color(0xFFC4C7C5);
  static Color borderLight = const Color(0xFFE1E3E1);
}
