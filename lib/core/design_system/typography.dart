import 'package:flutter/material.dart';

class AppTypography {
  static const String uiFontFamily = 'Inter';
  static const String readerFontFamily = 'Source Serif 4';

  static TextStyle get largeTitle => const TextStyle(
        fontFamily: uiFontFamily,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      );

  static TextStyle get title1 => const TextStyle(
        fontFamily: uiFontFamily,
        fontSize: 26,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.4,
      );

  static TextStyle get title2 => const TextStyle(
        fontFamily: uiFontFamily,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.3,
      );

  static TextStyle get title3 => const TextStyle(
        fontFamily: uiFontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      );

  static TextStyle get headline => const TextStyle(
        fontFamily: uiFontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      );

  static TextStyle get subheadline => const TextStyle(
        fontFamily: uiFontFamily,
        fontSize: 14,
        fontWeight: FontWeight.normal,
        letterSpacing: -0.1,
      );

  static TextStyle get body => const TextStyle(
        fontFamily: readerFontFamily,
        fontSize: 18,
        fontWeight: FontWeight.normal,
        height: 1.8,
      );

  static TextStyle get bodySans => const TextStyle(
        fontFamily: uiFontFamily,
        fontSize: 16,
        fontWeight: FontWeight.normal,
        letterSpacing: -0.1,
      );

  static TextStyle get caption1 => const TextStyle(
        fontFamily: uiFontFamily,
        fontSize: 12,
        fontWeight: FontWeight.normal,
      );

  static TextStyle get caption2 => const TextStyle(
        fontFamily: uiFontFamily,
        fontSize: 11,
        fontWeight: FontWeight.normal,
      );
}
