// lib/core/theme/app_theme_oceano.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta de la skin cosmética "Océano" (Toka Plus). Variante fría azul que
/// reutiliza el armazón visual de v2 (mismas tipografías, radios y estructura
/// de pantallas vía `SkinSwitch`) cambiando el color de marca y los neutros a
/// tonos fríos. Los colores son hardcodeados a propósito (definición de una
/// skin), excepción documentada a "sin colores nuevos hardcodeados".
abstract class AppColorsOceano {
  static const Color primary = Color(0xFF2E6BE6); // azul océano
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Light
  static const Color backgroundLight = Color(0xFFF3F7FD);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFDCE6F4);
  static const Color successLight = Color(0xFF3FB6A8);
  static const Color errorLight = Color(0xFFEF4444);
  static const Color textPrimaryLight = Color(0xFF132033);
  // Dark
  static const Color backgroundDark = Color(0xFF0E1420);
  static const Color surfaceDark = Color(0xFF161E2E);
  static const Color borderDark = Color(0xFF26324A);
  static const Color successDark = Color(0xFF3FB6A8);
  static const Color errorDark = Color(0xFFF87171);
  static const Color onErrorDark = Color(0xFF0E1420);
  static const Color textPrimaryDark = Color(0xFFE9F0FB);
  static const Color primaryDark = Color(0xFF5B9DF7);
}

abstract class AppThemeOceano {
  static ThemeData get light {
    final base = ThemeData(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColorsOceano.primary,
        onPrimary: AppColorsOceano.onPrimary,
        secondary: AppColorsOceano.successLight,
        onSecondary: AppColorsOceano.onPrimary,
        error: AppColorsOceano.errorLight,
        onError: AppColorsOceano.onPrimary,
        surface: AppColorsOceano.surfaceLight,
        onSurface: AppColorsOceano.textPrimaryLight,
      ),
      scaffoldBackgroundColor: AppColorsOceano.backgroundLight,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: AppColorsOceano.textPrimaryLight,
        displayColor: AppColorsOceano.textPrimaryLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColorsOceano.backgroundLight,
        foregroundColor: AppColorsOceano.textPrimaryLight,
        elevation: 0,
        centerTitle: false,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColorsOceano.borderLight,
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsOceano.primary,
          foregroundColor: AppColorsOceano.onPrimary,
          textStyle: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800, fontSize: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsOceano.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorsOceano.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorsOceano.borderLight),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);
    return base.copyWith(
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColorsOceano.primaryDark,
        onPrimary: AppColorsOceano.onPrimary,
        secondary: AppColorsOceano.successDark,
        onSecondary: AppColorsOceano.onPrimary,
        error: AppColorsOceano.errorDark,
        onError: AppColorsOceano.onErrorDark,
        surface: AppColorsOceano.surfaceDark,
        onSurface: AppColorsOceano.textPrimaryDark,
      ),
      scaffoldBackgroundColor: AppColorsOceano.backgroundDark,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: AppColorsOceano.textPrimaryDark,
        displayColor: AppColorsOceano.textPrimaryDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColorsOceano.backgroundDark,
        foregroundColor: AppColorsOceano.textPrimaryDark,
        elevation: 0,
        centerTitle: false,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColorsOceano.borderDark,
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsOceano.primaryDark,
          foregroundColor: AppColorsOceano.backgroundDark,
          textStyle: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800, fontSize: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsOceano.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorsOceano.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorsOceano.borderDark),
        ),
      ),
    );
  }
}
