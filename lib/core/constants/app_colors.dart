import 'package:flutter/material.dart';

class AppColors {
  // Brand Primary (Directly sampled from 'Mess' text & emblem pine green)
  static const Color primary = Color(0xFF02584D); // Deep Logo Pine/Teal Green
  static const Color primaryLight = Color(0xFF0E805C); // Roof / Accent Green
  static const Color primaryDark = Color(0xFF013E36);
  static const Color primaryContainer = Color(0xFFE0F4EF);
  static const Color onPrimaryContainer = Color(0xFF013A31);

  // Brand Secondary (Directly sampled from 'Hub' text & ৳ Taka emblem)
  static const Color secondary = Color(0xFFFE8D0D); // Logo Vibrant Amber Orange
  static const Color secondaryLight = Color(0xFFFFA63E);
  static const Color secondaryContainer = Color(0xFFFFF3E0);
  static const Color onSecondaryContainer = Color(0xFF7A3A00);

  // Brand Accent (Directly sampled from roommate avatar in logo)
  static const Color accentBlue = Color(0xFF0F71D2); // Logo Vibrant Blue
  static const Color accentBlueContainer = Color(0xFFE0F2FE);

  // Financial Semantics
  static const Color positive = Color(0xFF0E805C); // Receive money (Matches logo green)
  static const Color positiveBg = Color(0xFFE0F4EF);
  static const Color negative = Color(0xFFDC2626); // Need to pay (Red)
  static const Color negativeBg = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFFE8D0D); // Pending / Warning (Matches logo orange)
  static const Color warningBg = Color(0xFFFFF3E0);
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
