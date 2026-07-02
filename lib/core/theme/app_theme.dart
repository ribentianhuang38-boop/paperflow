import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_system/color_tokens.dart';
import '../design_system/typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: ColorTokens.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: ColorTokens.accent,
        surface: ColorTokens.lightSurface,
        onSurface: ColorTokens.lightTextPrimary,
        outline: ColorTokens.lightDivider,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.uiFontFamily,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: ColorTokens.lightTextPrimary,
        ),
        iconTheme: IconThemeData(color: ColorTokens.lightTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: ColorTokens.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: ColorTokens.lightDivider,
        thickness: 0.5,
        space: 0,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.largeTitle,
        headlineLarge: AppTypography.title1,
        headlineMedium: AppTypography.title2,
        titleLarge: AppTypography.title3,
        titleMedium: AppTypography.headline,
        bodyLarge: AppTypography.body,
        bodyMedium: AppTypography.bodySans,
        bodySmall: AppTypography.subheadline,
        labelLarge: AppTypography.caption1,
        labelSmall: AppTypography.caption2,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ColorTokens.lightTextPrimary,
        contentTextStyle: AppTypography.subheadline.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ColorTokens.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorTokens.lightSurfaceSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ColorTokens.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: AppTypography.bodySans.copyWith(color: ColorTokens.lightTextTertiary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ColorTokens.accent,
          foregroundColor: Colors.white,
          textStyle: AppTypography.headline.copyWith(color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorTokens.accent,
          textStyle: AppTypography.headline.copyWith(color: ColorTokens.accent),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: const BorderSide(color: ColorTokens.lightDivider),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ColorTokens.accent,
          textStyle: AppTypography.headline.copyWith(color: ColorTokens.accent),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: ColorTokens.accent,
        inactiveTrackColor: ColorTokens.lightDivider,
        thumbColor: ColorTokens.accent,
        overlayColor: ColorTokens.accent.withOpacity(0.1),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) => Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return ColorTokens.accent;
          return ColorTokens.lightDivider;
        }),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ColorTokens.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: ColorTokens.accent,
        surface: ColorTokens.darkSurface,
        onSurface: ColorTokens.darkTextPrimary,
        outline: ColorTokens.darkDivider,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.uiFontFamily,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: ColorTokens.darkTextPrimary,
        ),
        iconTheme: IconThemeData(color: ColorTokens.darkTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: ColorTokens.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: ColorTokens.darkDivider,
        thickness: 0.5,
        space: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ColorTokens.darkSurface,
        contentTextStyle: AppTypography.subheadline.copyWith(color: ColorTokens.darkTextPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ColorTokens.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorTokens.darkSurfaceSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ColorTokens.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: AppTypography.bodySans.copyWith(color: ColorTokens.darkTextTertiary),
      ),
    );
  }
}
