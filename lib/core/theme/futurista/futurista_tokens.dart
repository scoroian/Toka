import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'futurista_colors.dart';

/// Radios — la clave del look.
class FRadii {
  static const double sm = 8, md = 12, lg = 14, xl = 18, xxl = 22, hero = 26;
  static const double pill = 999;
}

/// Glows y sombras con color.
class FShadows {
  static const List<BoxShadow> glowCyan = [
    BoxShadow(color: Color(0x5938BDF8), blurRadius: 40, offset: Offset(0, 20)),
  ];
  static const List<BoxShadow> glowGold = [
    BoxShadow(color: Color(0x80F5B544), blurRadius: 30, offset: Offset(0, 10)),
  ];
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 24, offset: Offset(0, 12)),
  ];
}

/// Tipografía — Inter + JetBrains Mono.
class FText {
  static TextStyle display(double size, {Color? color, FontWeight? weight}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w800,
        letterSpacing: size > 22 ? -1.2 : -0.6,
        color: color ?? FuturistaColors.textPrimary,
      );

  static TextStyle body(double size, {Color? color, FontWeight? weight}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w500,
        color: color ?? FuturistaColors.textPrimary,
      );

  static TextStyle mono(double size, {Color? color}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        color: color ?? FuturistaColors.textTertiary,
      );
}

/// Mesh background para pantallas hero.
class FMesh {
  static const Widget background = _MeshBg();
}

class _MeshBg extends StatelessWidget {
  const _MeshBg();
  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: RadialGradient(
        center: Alignment(-0.8, -1),
        radius: 1.2,
        colors: [Color(0x2E38BDF8), Color(0x0038BDF8)],
      ),
    ),
  );
}
