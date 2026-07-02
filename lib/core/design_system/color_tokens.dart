import 'package:flutter/material.dart';

class ColorTokens {
  // Light Mode Colors
  static const lightBackground = Color(0xFFFFFFFF);
  static const lightSurface = Color(0xFFFAFAFA);
  static const lightSurfaceSecondary = Color(0xFFF7F7F8);
  static const lightTextPrimary = Color(0xFF111111);
  static const lightTextSecondary = Color(0xFF666666);
  static const lightTextTertiary = Color(0xFF999999);
  static const lightDivider = Color(0xFFECECEC);

  // Dark Mode Colors
  static const darkBackground = Color(0xFF000000);
  static const darkSurface = Color(0xFF0A0A0A);
  static const darkSurfaceSecondary = Color(0xFF161618);
  static const darkTextPrimary = Color(0xFFF5F5F7);
  static const darkTextSecondary = Color(0xFFA1A1A5);
  static const darkTextTertiary = Color(0xFF6C6C70);
  static const darkDivider = Color(0xFF242426);

  // Brand / Common Colors
  static const accent = Color(0xFF4F6BFF); // Premium Accent Blue
  
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);

  static Color getBackground(bool isDark) => isDark ? darkBackground : lightBackground;
  static Color getSurface(bool isDark) => isDark ? darkSurface : lightSurface;
  static Color getSurfaceSecondary(bool isDark) => isDark ? darkSurfaceSecondary : lightSurfaceSecondary;
  static Color getTextPrimary(bool isDark) => isDark ? darkTextPrimary : lightTextPrimary;
  static Color getTextSecondary(bool isDark) => isDark ? darkTextSecondary : lightTextSecondary;
  static Color getTextTertiary(bool isDark) => isDark ? darkTextTertiary : lightTextTertiary;
  static Color getDivider(bool isDark) => isDark ? darkDivider : lightDivider;

  // Premium Light Shadows (Apple style)
  static List<BoxShadow> getShadow(bool isDark) {
    if (isDark) {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 12,
          offset: const Offset(0, 4),
        )
      ];
    }
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.03),
        blurRadius: 10,
        offset: const Offset(0, 3),
      )
    ];
  }
}
