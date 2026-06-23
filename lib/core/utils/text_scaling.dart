import 'package:flutter/widgets.dart';

/// Accesibilidad (H-019).
///
/// Toka respeta el tamaño de fuente del sistema, pero acota el factor a un
/// rango razonable para que la UI siga siendo legible con fuente grande sin
/// desbordar tarjetas ni botones. Por debajo de 0.8 el texto sería ilegible;
/// por encima de 1.3 las tarjetas de "Hoy" empiezan a desbordar.
const double kMinTextScaleFactor = 0.8;
const double kMaxTextScaleFactor = 1.3;

/// Devuelve el [TextScaler] del sistema acotado a [kMinTextScaleFactor,
/// kMaxTextScaleFactor]. Se aplica en `MaterialApp.builder`.
TextScaler clampedTextScaler(TextScaler systemScaler) => systemScaler.clamp(
      minScaleFactor: kMinTextScaleFactor,
      maxScaleFactor: kMaxTextScaleFactor,
    );
