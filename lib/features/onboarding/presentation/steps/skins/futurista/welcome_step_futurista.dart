import 'package:flutter/material.dart';

import '../../../../../../shared/widgets/futurista/tocka_btn.dart';

/// Pantalla Welcome de la skin futurista. Layout según
/// `skin_futurista/screens-meta.jsx` (función `OnboardingScreen`).
///
/// Mantiene la misma signatura que [WelcomeStepV2] para compartir VM.
class WelcomeStepFuturista extends StatelessWidget {
  const WelcomeStepFuturista({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isIos = theme.platform == TargetPlatform.iOS;
    final topPad = isIos ? 52.0 : 14.0;
    final bottomPad = isIos ? 40.0 : 30.0;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Stack(
          children: [
            // Layer 1 — radial gradient desde top-center.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -1.0),
                    radius: 1.2,
                    colors: [
                      cs.primary.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Layer 2 — glow circular lateral.
            Positioned(
              right: -60,
              top: 200,
              child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      cs.primary.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Contenido principal.
            Padding(
              padding: EdgeInsets.fromLTRB(24, topPad, 24, bottomPad),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Wordmark.
                  Center(
                    child: Text(
                      'tocka',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Icon hero.
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            cs.primary.withValues(alpha: 0.19),
                            cs.primary.withValues(alpha: 0.04),
                          ],
                        ),
                        border: Border.all(
                          color: cs.primary.withValues(alpha: 0.33),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.55),
                            blurRadius: 80,
                            offset: const Offset(0, 30),
                            spreadRadius: -20,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer circle (stroke).
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: cs.primary.withValues(alpha: 0.5),
                                  width: 2,
                                ),
                              ),
                            ),
                            // Middle circle (semi-fill).
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cs.primary.withValues(alpha: 0.25),
                              ),
                            ),
                            // Inner circle (fill).
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cs.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Display title.
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.4,
                        height: 1.05,
                        color: cs.onSurface,
                      ),
                      children: [
                        const TextSpan(text: 'El hogar,\n'),
                        TextSpan(
                          text: 'en equilibrio.',
                          style: TextStyle(color: cs.primary),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  // Subtitle.
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: Text(
                        'Reparte tareas sin discutir. Ve qué te toca hoy en menos de 3 segundos.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Botones primarios.
                  TockaBtn(
                    variant: TockaBtnVariant.glow,
                    size: TockaBtnSize.lg,
                    fullWidth: true,
                    icon: const Icon(Icons.add, size: 16),
                    onPressed: onStart,
                    child: const Text('Crear un hogar'),
                  ),
                  const SizedBox(height: 10),
                  TockaBtn(
                    variant: TockaBtnVariant.soft,
                    size: TockaBtnSize.lg,
                    fullWidth: true,
                    icon: const Icon(Icons.arrow_forward, size: 14),
                    onPressed: onStart,
                    child: const Text('Unirme con un código'),
                  ),
                  const SizedBox(height: 6),
                  // Social row.
                  Row(
                    children: [
                      Expanded(
                        child: TockaBtn(
                          variant: TockaBtnVariant.ghost,
                          size: TockaBtnSize.md,
                          fullWidth: true,
                          onPressed: onStart,
                          child: const Text('Google'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TockaBtn(
                          variant: TockaBtnVariant.ghost,
                          size: TockaBtnSize.md,
                          fullWidth: true,
                          onPressed: onStart,
                          child: const Text('Apple'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TockaBtn(
                          variant: TockaBtnVariant.ghost,
                          size: TockaBtnSize.md,
                          fullWidth: true,
                          onPressed: onStart,
                          child: const Text('Email'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Al continuar aceptas Términos y Privacidad',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 10.5,
                          letterSpacing: 0.4,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
