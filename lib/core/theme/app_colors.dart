import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFFF7F8F2);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFEEF0E7);
  static const surfaceHighlight = Color(0xFFE3E9DB);
  static const primary = Color(0xFF183E32);
  static const primaryLight = Color(0xFFE7EFDF);
  static const primaryHover = Color(0xFF102D24);
  static const lime = Color(0xFFD6EF8A);
  static const accent = Color(0xFFA44529);
  static const accentLight = Color(0xFFF9EADF);
  static const accentHover = Color(0xFF893821);
  static const textPrimary = Color(0xFF20352D);
  static const textSecondary = Color(0xFF657067);
  static const textTertiary = Color(0xFF738076);
  static const border = Color(0xFFE0E5D9);
  static const borderFocus = primary;
  static const statusSuccess = primary;
  static const statusSuccessLight = primaryLight;
  static const statusWarning = Color(0xFF91570D);
  static const statusWarningLight = Color(0xFFFFF0D4);
  static const statusUrgent = Color(0xFFB23C37);
  static const statusUrgentLight = Color(0xFFFFE9E6);
  static List<BoxShadow> get softShadow => [
    const BoxShadow(
      color: Color(0x0620392B),
      blurRadius: 20,
      offset: Offset(0, 6),
    ),
  ];
  static List<BoxShadow> get floatingShadow => [
    const BoxShadow(
      color: Color(0x1020392B),
      blurRadius: 30,
      offset: Offset(0, -3),
    ),
  ];
}
