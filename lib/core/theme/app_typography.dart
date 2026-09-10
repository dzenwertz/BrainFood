import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTypography {
  static TextStyle _style(
    double size,
    FontWeight weight, {
    Color? color,
    double spacing = 0,
  }) => TextStyle(
    fontFamily: 'BrainSans',
    fontSize: size,
    fontWeight: weight,
    color: color ?? AppColors.textPrimary,
    height: 1.4,
    letterSpacing: spacing,
  );
  static TextStyle get displayLarge =>
      _style(32, FontWeight.w700, spacing: -1.4);
  static TextStyle get displayMedium =>
      _style(28, FontWeight.w700, spacing: -0.9);
  static TextStyle get titleLarge => _style(21, FontWeight.w700, spacing: -0.5);
  static TextStyle get titleMedium =>
      _style(17, FontWeight.w600, spacing: -0.25);
  static TextStyle get bodyLarge => _style(16, FontWeight.w400);
  static TextStyle get bodyMedium =>
      _style(14, FontWeight.w400, color: AppColors.textSecondary);
  static TextStyle get bodySmall =>
      _style(12, FontWeight.w400, color: AppColors.textSecondary);
  static TextStyle get labelLarge => _style(14, FontWeight.w600);
  static TextStyle get labelSmall => _style(11, FontWeight.w600, spacing: 0.4);
}
