// lib/shared/widgets/premium_upgrade_banner.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors_v2.dart';

/// Banner unificado "Hazte Premium" con el mismo look&feel en toda la app.
///
/// Modelo visual: el banner del Historial.
/// Surface clara/oscura, borde fino, radio 14, título en w800,
/// cuerpo en texto secundario y CTA a ancho completo.
class PremiumUpgradeBanner extends StatelessWidget {
  const PremiumUpgradeBanner({
    super.key,
    this.title,
    required this.message,
    this.highlight,
    required this.cta,
    required this.onCta,
    this.ctaKey,
    this.margin = EdgeInsets.zero,
  });

  final String? title;
  final String message;
  final String? highlight;
  final String cta;
  final VoidCallback onCta;
  final Key? ctaKey;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColorsV2.surfaceDark : AppColorsV2.surfaceLight;
    final bd = isDark ? AppColorsV2.borderDark : AppColorsV2.borderLight;
    final textSecondary = isDark
        ? AppColorsV2.textSecondaryDark
        : AppColorsV2.textSecondaryLight;

    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            message,
            style: GoogleFonts.plusJakartaSans(color: textSecondary),
          ),
          if (highlight != null) ...[
            const SizedBox(height: 4),
            Text(
              highlight!,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: ctaKey,
              onPressed: onCta,
              child: Text(cta),
            ),
          ),
        ],
      ),
    );
  }
}
