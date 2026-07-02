import 'package:flutter/material.dart';

class AppTypography {
  static const String uiFontFamily = 'Inter';
  static const String readerFontFamily = 'Source Serif 4';

  static TextStyle get largeTitle => const TextStyle(
        fontFamily: uiFontFamily,
        fontSize: 34,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.37,
      );

  static TextStyle get title1 => const TextStyle(
        fontFamily: uiFontFamily,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.36,
      );

  static TextStyle get title2 => const TextStyle(
        fontFamily: uiFontFamily,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.35,
      );

  static TextStyle get title3 => const TextStyle(
        fontFamily: uiFontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.38,
      );

  static TextStyle get headline => const TextStyle(
        fontFamily: uiFontFamily,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.41,
      );

  static TextStyle get subheadline => const TextStyle(
        fontFamily: uiFontFamily,
        fontSize: 15,
        fontWeight: FontWeight.normal,
        letterSpacing: -0.24,
      );

  static TextStyle get body => const TextStyle(
        fontFamily: readerFontFamily,
        fontSize: 17,
        fontWeight: FontWeight.normal,
        letterSpacing: -0.41,
        height: 1.6,
      );

  static TextStyle get bodySans => const TextStyle(
        fontFamily: uiFontFamily,
        fontSize: 17,
        fontWeight: FontWeight.normal,
        letterSpacing: -0.41,
      );

  static TextStyle get caption1 => const TextStyle(
        fontFamily: uiFontFamily,
        fontSize: 12,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.0,
      );

  static TextStyle get caption2 => const TextStyle(
        fontFamily: uiFontFamily,
        fontSize: 11,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.07,
      );
}
