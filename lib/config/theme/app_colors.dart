import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color gradientStart = Color(0xFFD7D1C5);
  static const Color gradientEnd = Color(0xFFA49E86);
  static const Color primary = Color(0xFFA49E86);
  static const Color primaryDark = Color(0xFF4F4A34);
  static const Color cardBackground = Colors.white;
  static const Color cardBorder = Color(0xFF1D2838);
  static const Color surfaceLight = Color(0xFFF3F4F6);

  // Form colors
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGray = Color(0xFF757575);
  static const Color inputBackground = Color(0xFFEBEBEB);
  static const Color inputBorder = Color(0xFFE0E0E0);
  static const Color socialButtonBg = Color(0xFFC4BEAE);
  static const Color error = Color(0xFFDE3737);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientEnd],
  );

  static Color decorativeCircle = Colors.white.withValues(alpha: 0.10);
  static Color textSecondary = Colors.white.withValues(alpha: 0.80);
  static Color textTertiary = Colors.white.withValues(alpha: 0.60);
}
