// lib/core/theme/app_theme_v2.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors_v2.dart';

abstract class AppThemeV2 {
  static ThemeData get light {
    final base = ThemeData(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColorsV2.primary,
        onPrimary: AppColorsV2.onPrimary,
        secondary: AppColorsV2.successLight,
        onSecondary: AppColorsV2.onPrimary,
        error: AppColorsV2.errorLight,
        onError: AppColorsV2.onPrimary,
        surface: AppColorsV2.surfaceLight,
        onSurface: AppColorsV2.textPrimaryLight,
      ),
      scaffoldBackgroundColor: AppColorsV2.backgroundLight,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: AppColorsV2.textPrimaryLight,
        displayColor: AppColorsV2.textPrimaryLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColorsV2.backgroundLight,
        foregroundColor: AppColorsV2.textPrimaryLight,
        elevation: 0,
        centerTitle: false,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColorsV2.borderLight,
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsV2.textPrimaryLight,
          foregroundColor: AppColorsV2.onPrimary,
          textStyle: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800, fontSize: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsV2.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorsV2.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorsV2.borderLight),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);
    return base.copyWith(
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColorsV2.primary,
        onPrimary: AppColorsV2.onPrimary,
        secondary: AppColorsV2.successDark,
        onSecondary: AppColorsV2.onPrimary,
        error: AppColorsV2.errorDark,
        onError: AppColorsV2.backgroundDark,
        surface: AppColorsV2.surfaceDark,
        onSurface: AppColorsV2.textPrimaryDark,
      ),
      scaffoldBackgroundColor: AppColorsV2.backgroundDark,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: AppColorsV2.textPrimaryDark,
        displayColor: AppColorsV2.textPrimaryDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColorsV2.backgroundDark,
        foregroundColor: AppColorsV2.textPrimaryDark,
        elevation: 0,
        centerTitle: false,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColorsV2.borderDark,
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsV2.textPrimaryDark,
          foregroundColor: AppColorsV2.backgroundDark,
          textStyle: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800, fontSize: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsV2.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorsV2.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorsV2.borderDark),
        ),
      ),
    );
  }
}
