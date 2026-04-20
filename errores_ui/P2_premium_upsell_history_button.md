# P2 — Botón "Actualizar a Premium" en historial sin acción

## Bug que corrige
- **Bug #14** — El botón "Actualizar a Premium" en el banner de upsell del historial tiene `onPressed: () {}` vacío. No navega a la pantalla de suscripción ni lanza el paywall.

## Archivos a modificar

| Archivo | Línea |
|---------|-------|
| `lib/features/history/presentation/skins/history_screen_v2.dart` | ~148 |

## Cambio requerido

Localizar el botón en `history_screen_v2.dart` y añadir la navegación:

```dart
// ANTES
ElevatedButton(
  onPressed: () {},
  child: Text(l10n.upgradeToPremium),
),

// DESPUÉS
ElevatedButton(
  onPressed: () => context.push('/subscription'),
  child: Text(l10n.upgradeToPremium),
),
```

Si la ruta de suscripción no es `/subscription`, buscar la ruta correcta en `app.dart` y en `core/constants/routes.dart`.

Alternativamente, si el paywall se muestra como BottomSheet:

```dart
onPressed: () => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (_) => const PaywallSheet(),
),
```

## Verificar la ruta de suscripción

```bash
grep -rn "subscription\|paywall\|premium" lib/core/constants/routes.dart lib/app.dart
```

## Criterios de aceptación

- [ ] Pulsar "Actualizar a Premium" en el banner del historial abre la pantalla de suscripción o el paywall.
- [ ] La pantalla/sheet de suscripción muestra los planes (29.99€/año, 3.99€/mes) como se verificó en el QA (paso 8.2).
- [ ] Al volver desde la suscripción, el historial sigue mostrando el banner si el usuario no se suscribió.

## Tests requeridos

- Test de widget: `HistoryScreenV2` en modo free → botón "Actualizar a Premium" → al tap navega correctamente (verificar con `NavigatorObserver` mock o `GoRouter` test helper).
