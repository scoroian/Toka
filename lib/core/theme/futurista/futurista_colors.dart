import 'package:flutter/material.dart';

abstract class FuturistaColors {
  // Brand
  static const primary    = Color(0xFF38BDF8);   // cyan eléctrico
  static const primaryAlt = Color(0xFFA78BFA);   // violeta
  static const premium    = Color(0xFFF5B544);   // gold
  static const onPrimary  = Color(0xFF001018);

  // Dark surfaces
  static const bg0             = Color(0xFF07090E);
  static const bg1             = Color(0xFF0B0F16);
  static const bg2             = Color(0xFF121826);
  static const bg3             = Color(0xFF1A2235);
  static const line            = Color(0x14E2E8F0); //  8% E2E8F0
  static const lineStrong      = Color(0x29E2E8F0); // 16%
  static const textPrimary     = Color(0xFFE8EEF7);
  static const textSecondary   = Color(0xA3E8EEF7); // 64%
  static const textTertiary    = Color(0x6BE8EEF7); // 42%
  static const textFaint       = Color(0x38E8EEF7); // 22%
  static const success         = Color(0xFF34D399);
  static const warning         = Color(0xFFF5B544);
  static const error           = Color(0xFFFB7185);

  // Light alternativo (más frío que el v2)
  static const bgLight           = Color(0xFFF6F7FB);
  static const surfaceLight      = Color(0xFFFFFFFF);
  static const surfaceVariantLight = Color(0xFFEEF2F7); // usada para inputs
  static const textPrimLight     = Color(0xFF0B1220);
  static const textSecondaryLight = Color(0xA30B1220); // 64%
  static const textTertiaryLight = Color(0x6B0B1220); // 42%
  static const textFaintLight    = Color(0x380B1220); // 22%
  static const lineLight         = Color(0x14000000); //  8% negro
  static const lineStrongLight   = Color(0x29000000); // 16% negro

  // Accents light (tomados de tokens.jsx del canvas).
  // El cyan dark #38BDF8 satura en fondos claros; el canvas usa un cyan más
  // oscuro para mantener contraste AA sin perder identidad.
  static const primaryLight   = Color(0xFF0284C7);
  static const successLight   = Color(0xFF059669);
  static const warningLight   = Color(0xFFB45309);
  static const errorLight     = Color(0xFFE11D48);
  static const premiumLight   = Color(0xFFB45309);
}
