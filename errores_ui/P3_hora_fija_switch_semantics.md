# P3 — Switch "Hora fija" con estado de accesibilidad incorrecto

## Bug que corrige
- **Bug #13** — El switch "Hora fija" en el formulario de crear tarea reporta `checked=false` en la jerarquía de accesibilidad aunque visualmente aparece activado. Los usuarios de TalkBack o tecnologías de asistencia ven el estado incorrecto.

## Causa raíz probable

Posibles causas en Flutter:
1. El `Switch` o `SwitchListTile` recibe un `value` que no coincide con el estado visual actual (p.ej., el provider tiene `true` pero se pasa `false` al widget).
2. La `Semantics` del widget no está actualizada: el widget padre envuelve el Switch en un `Semantics` con `checked: false` hardcodeado.
3. El `Switch` es `AnimatedSwitcher` o se re-construye con el valor anterior antes de que el estado se propague.

## Archivos a investigar

| Archivo | Qué buscar |
|---------|-----------|
| `lib/features/tasks/presentation/skins/create_edit_task_screen_v2.dart` | Uso del switch de hora fija |
| `lib/features/tasks/application/task_form_provider.dart` | Campo `fixedTime` o `isFixedHour` en el estado |

## Cambio requerido

### 1. Verificar que el value del Switch coincide con el estado del provider

```dart
// Leer el valor del estado del formulario
final formState = ref.watch(taskFormProvider);

SwitchListTile(
  title: Text(l10n.fixedTime),
  value: formState.isFixedHour, // ← debe ser el valor real del provider
  onChanged: (v) => ref.read(taskFormProvider.notifier).setFixedHour(v),
),
```

Si hay discrepancia, puede haber un bug donde el estado del provider y el valor mostrado no están sincronizados (p.ej., inicialización del formulario en modo edición).

### 2. Verificar que no hay Semantics hardcodeados

```bash
grep -n "Semantics\|checked:" lib/features/tasks/presentation/skins/create_edit_task_screen_v2.dart
```

Si hay un `Semantics(checked: false, ...)` hardcodeado, actualizarlo para que use el valor dinámico:

```dart
// ANTES
Semantics(checked: false, child: Switch(...)),

// DESPUÉS
// No añadir Semantics manualmente — Switch lo gestiona automáticamente
Switch(value: formState.isFixedHour, ...),
```

### 3. Test de accesibilidad

Usar el `SemanticsHandle` de Flutter para verificar el estado semántico:

```dart
testWidgets('hora fija switch has correct accessibility state', (tester) async {
  // Activar el switch
  await tester.tap(find.byType(Switch));
  await tester.pumpAndSettle();
  
  // Verificar semántica
  final semantics = tester.getSemantics(find.byType(Switch));
  expect(semantics.hasFlag(SemanticsFlag.isChecked), isTrue);
});
```

## Criterios de aceptación

- [ ] Al activar el switch "Hora fija", el estado de accesibilidad reporta `checked=true`.
- [ ] Al desactivar el switch, el estado de accesibilidad reporta `checked=false`.
- [ ] El estado visual y el estado semántico son siempre coherentes.
- [ ] Verificado con `adb shell uiautomator dump` en el emulador.

## Tests requeridos

- Test de widget (accesibilidad): activar switch → `SemanticsFlag.isChecked == true`.
- Test de widget (accesibilidad): desactivar switch → `SemanticsFlag.isChecked == false`.
