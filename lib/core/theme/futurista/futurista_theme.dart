import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'futurista_colors.dart';

abstract class FuturistaTheme {
  static ThemeData get dark {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);
    return base.copyWith(
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: FuturistaColors.primary,
        onPrimary: FuturistaColors.onPrimary,
        secondary: FuturistaColors.primaryAlt,
        onSecondary: FuturistaColors.onPrimary,
        error: FuturistaColors.error,
        onError: FuturistaColors.textPrimary,
        surface: FuturistaColors.bg1,
        onSurface: FuturistaColors.textPrimary,
      ),
      scaffoldBackgroundColor: FuturistaColors.bg0,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: FuturistaColors.textPrimary,
        displayColor: FuturistaColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: FuturistaColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      dividerTheme: const DividerThemeData(
        color: FuturistaColors.line, thickness: 1, space: 1,
      ),
      cardTheme: CardThemeData(
        color: FuturistaColors.bg2,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FuturistaColors.primary,
          foregroundColor: FuturistaColors.onPrimary,
          shadowColor: const Color(0x5938BDF8),
          elevation: 8,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FuturistaColors.bg2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: FuturistaColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: FuturistaColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: FuturistaColors.primary, width: 1.5),
        ),
      ),
    );
  }

  // TODO(skin-futurista-iteracion-2): implementar versión light real.
  // De momento devolvemos `dark` para que la skin funcione aunque el usuario
  // tenga ThemeMode.light activo. Documentado en el spec.
  static ThemeData get light => dark;
}
