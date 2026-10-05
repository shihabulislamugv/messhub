import 'package:flutter/material.dart';

class AppColors {
  // Brand Primary (Emerald / Teal green - representing trust, wealth, Bangladesh green)
  static const Color primary = Color(0xFF0F766E); // Deep Teal
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color primaryDark = Color(0xFF115E59);
  static const Color primaryContainer = Color(0xFFCCFBF1);
  static const Color onPrimaryContainer = Color(0xFF134E4A);

  // Accent / Secondary
  static const Color secondary = Color(0xFF0284C7); // Sky Blue
  static const Color secondaryContainer = Color(0xFFE0F2FE);

  // Financial Semantics
  static const Color positive = Color(0xFF16A34A); // Receive money (Green)
  static const Color positiveBg = Color(0xFFDCFCE7);
  static const Color negative = Color(0xFFDC2626); // Need to pay (Red/Amber)
  static const Color negativeBg = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFD97706); // Amber
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color neutral = Color(0xFF64748B); // Slate
  static const Color neutralBg = Color(0xFFF1F5F9);

  // Background & Surfaces
  static const Color background = Color(0xFFF8FAFC); // Clean off-white
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);

  // Typography
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textTertiary = Color(0xFF94A3B8); // Slate 400
  static const Color textOnPrimary = Colors.white;

  // Dark Mode Support
  static const Color darkBackground = Color(0xFF0B132B);
  static const Color darkSurface = Color(0xFF1C2541);
  static const Color darkBorder = Color(0xFF3A506B);
}
