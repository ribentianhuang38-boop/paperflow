import 'package:flutter/material.dart';

class AppTheme {
  static const _seedColor = Color(0xFF1A1A2E);

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: _seedColor,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      dividerTheme: const DividerThemeData(
        thickness: 0.5,
        space: 0,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontWeight: FontWeight.w300, letterSpacing: -1.5),
        displayMedium: TextStyle(fontWeight: FontWeight.w300, letterSpacing: -0.5),
        headlineLarge: TextStyle(fontWeight: FontWeight.w400, letterSpacing: -0.5),
        headlineMedium: TextStyle(fontWeight: FontWeight.w400),
        titleLarge: TextStyle(fontWeight: FontWeight.w500, letterSpacing: 0.15),
        titleMedium: TextStyle(fontWeight: FontWeight.w500, letterSpacing: 0.15),
        bodyLarge: TextStyle(fontWeight: FontWeight.w400, letterSpacing: 0.5, height: 1.6),
        bodyMedium: TextStyle(fontWeight: FontWeight.w400, letterSpacing: 0.25, height: 1.5),
        labelLarge: TextStyle(fontWeight: FontWeight.w500, letterSpacing: 1.2),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: _seedColor,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade800),
        ),
      ),
      dividerTheme: const DividerThemeData(
        thickness: 0.5,
        space: 0,
      ),
    );
  }
}
