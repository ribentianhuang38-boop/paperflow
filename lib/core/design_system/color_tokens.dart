import 'package:flutter/material.dart';

class ColorTokens {
  // Light Mode Colors
  static const lightBackground = Color(0xFFFAFADB);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceSecondary = Color(0xFFF2F2F7);
  static const lightTextPrimary = Color(0xFF1C1C1E);
  static const lightTextSecondary = Color(0xFF48484A);
  static const lightTextTertiary = Color(0xFF8E8E93);
  static const lightDivider = Color(0xFFE5E5EA);

  // Dark Mode Colors
  static const darkBackground = Color(0xFF000000);
  static const darkSurface = Color(0xFF1C1C1E);
  static const darkSurfaceSecondary = Color(0xFF2C2C2E);
  static const darkTextPrimary = Color(0xFFF5F5F7);
  static const darkTextSecondary = Color(0xFFAEAEB2);
  static const darkTextTertiary = Color(0xFF636366);
  static const darkDivider = Color(0xFF38383A);

  // Brand / Common Colors
  static const accent = Color(0xFF007AFF); // Apple Blue
  static const accentLight = Color(0xFF3593FF);
  
  static const success = Color(0xFF34C759); // iOS Green
  static const warning = Color(0xFFFF9500); // iOS Orange
  static const error = Color(0xFFFF3B30); // iOS Red

  static Color getBackground(bool isDark) => isDark ? darkBackground : lightBackground;
  static Color getSurface(bool isDark) => isDark ? darkSurface : lightSurface;
  static Color getSurfaceSecondary(bool isDark) => isDark ? darkSurfaceSecondary : lightSurfaceSecondary;
  static Color getTextPrimary(bool isDark) => isDark ? darkTextPrimary : lightTextPrimary;
  static Color getTextSecondary(bool isDark) => isDark ? darkTextSecondary : lightTextSecondary;
  static Color getTextTertiary(bool isDark) => isDark ? darkTextTertiary : lightTextTertiary;
  static Color getDivider(bool isDark) => isDark ? darkDivider : lightDivider;
}
