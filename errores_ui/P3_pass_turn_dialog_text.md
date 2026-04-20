# P3 — Texto contradictorio en diálogo de "Pasar turno"

## Bug que corrige
- **Bug #12** — El diálogo de "Pasar turno" muestra "Tu cumplimiento bajará de 100% a ~100%" cuando el cambio de cumplimiento es < 1% (por ejemplo, con solo 1 miembro). El texto dice "bajará" pero los valores son prácticamente iguales, lo que resulta confuso y contradictorio.

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `lib/features/tasks/presentation/widgets/pass_turn_dialog.dart` (o similar) | Lógica condicional del texto |

## Cambio requerido

Añadir lógica condicional para el texto de impacto de cumplimiento:

```dart
// Calcular la diferencia real
final currentRate = member.complianceRate; // p.ej. 100.0
final projectedRate = calculateProjectedRate(...); // p.ej. 99.7

final diff = currentRate - projectedRate;
final isNegligible = diff < 1.0; // menos de 1 punto porcentual

// Mostrar texto apropiado
if (isNegligible) {
  // Opción A: no mostrar el banner de advertencia si el impacto es mínimo
  // Opción B: mostrar mensaje neutral
  Text(l10n.passTurnMinimalImpact) // "El impacto en tu cumplimiento será mínimo."
} else {
  // Texto actual: "Tu cumplimiento bajará de X% a Y%"
  Text(l10n.passTurnComplianceWillDrop(
    currentRate.toStringAsFixed(0),
    projectedRate.toStringAsFixed(0),
  ))
}
```

### Opción A (recomendada): suprimir el banner si el impacto es mínimo

```dart
// En PassTurnDialog
if (complianceDiff >= 1.0)
  WarningBanner(
    text: l10n.passTurnComplianceWillDrop(
      currentRate.toStringAsFixed(0),
      projectedRate.toStringAsFixed(0),
    ),
  ),
// Si diff < 1, no mostrar banner → el usuario confirma sin presión innecesaria
```

### Claves ARB requeridas

```json
"passTurnMinimalImpact": "El impacto en tu cumplimiento será mínimo.",
"@passTurnMinimalImpact": {
  "description": "Message shown when passing turn has negligible compliance impact"
}
```

## Criterios de aceptación

- [ ] Con 1 miembro (diff < 1%), el diálogo de pasar turno NO muestra el banner de advertencia roja.
- [ ] Con múltiples miembros y diff >= 1%, el diálogo sigue mostrando el banner con valores correctos.
- [ ] Los valores numéricos en el texto son siempre distintos cuando se muestra el banner (no "100% → ~100%").

## Tests requeridos

- Test unitario: `calculateComplianceDiff` con 1 miembro → diff < 1.
- Test de widget: `PassTurnDialog` con diff < 1% → no renderiza el `WarningBanner`.
- Test de widget: `PassTurnDialog` con diff = 10% → renderiza `WarningBanner` con los valores correctos.
