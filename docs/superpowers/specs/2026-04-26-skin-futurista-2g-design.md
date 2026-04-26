# Skin Futurista · Iteración 2G · Out-of-shell padding + cleanup · Diseño

**Fecha:** 2026-04-26
**Estado:** aprobado para plan de implementación
**Scope:** Cierra los 3 follow-ups del final reviewer de 2F. (1) Hacer que `adAwareBottomPadding` detecte cuándo está fuera del `ShellRoute` y devuelva solo `safeArea + extra` (en lugar de ~64-140px innecesarios para nav+banner que no se renderizan). (2) Cleanup del override defensivo añadido en `vacation_screen_futurista_test.dart` durante 2F (queda redundante tras item 1). (3) Corregir el docstring "ISO" en `TaskActionability.isActionable` (calendar week, no ISO 8601 estricto).
**Fuera de scope:** mover rutas dentro/fuera del shell, refactor de `adBannerConfigProvider`, golden tests de scroll, cambios en `ShellMetrics`.

**Spec anterior:** [2026-04-26-skin-futurista-2f-design.md](2026-04-26-skin-futurista-2f-design.md).

---

## 1 · Contexto

Tras 2F (commits `3f1269b`..`db25e2b`), los reviewers detectaron 3 puntos de deuda:

1. **`adAwareBottomPadding` over-padding fuera del shell.** Spec §3.4 de 2F asumió "todas las push están bajo `MainShellFuturista` vía `ShellRoute`". Verificación en `lib/app.dart:266-339` muestra que **9 de las 10 pantallas migradas en 2F están fuera del `ShellRoute`** y nunca renderizan NavBar ni AdBanner. El helper devuelve `banner + navBar + safeArea + extra`, sobre-reservando ~64-140px de espacio muerto al fondo. v2 hace lo mismo (deuda heredada, no regresión introducida).

2. **Override defensivo en `vacation_screen_futurista_test.dart`** (añadido durante 2F Task 2): existe porque `adAwareBottomPadding` triggera la cadena `adBannerConfigProvider → dashboardProvider → currentHomeProvider → authProvider Timer 15s` cuando se monta `VacationScreen` directamente sin shell. Es un workaround sintomático.

3. **Docstring de `TaskActionability.isActionable` afirma "semana ISO 8601"** pero implementa "semana del calendario lunes-domingo según `DateTime.weekday`". Diferencia relevante en fronteras de año.

Esta spec arregla los tres con cambios localizados: 1 archivo nuevo + 5 modificados.

---

## 2 · Invariantes anclados

- **Pantallas in-shell siguen recibiendo el mismo padding** (`banner + navBar + safeArea + extra`): tests existentes deben pasar sin tocar.
- **Pantallas out-of-shell pasan de `~banner + navBar + safeArea + extra` a `safeArea + extra`**: cambio visual deliberado y deseado.
- **API pública de `adAwareBottomPadding` intacta**: misma firma, mismo nombre.
- **`ShellMetrics` y `shellMetricsProvider` no cambian**: siguen siendo single source of truth para dimensiones del shell.
- **`MainShellV2` y `MainShellFuturista` solo añaden 1 widget invisible** (`ShellPresenceMarker`) — sin cambio de comportamiento visible.

---

## 3 · Decisiones tomadas

### 3.1 InheritedWidget como detector de shell

`ShellPresenceMarker extends InheritedWidget` es el seam más limpio:
- **No acopla con paths de rutas**: si `app.dart` cambia, no se rompe.
- **No requiere providers nuevos**: usa el árbol de widgets que ya existe.
- **Resuelve el item 2 automáticamente**: cuando `!inShell`, `adAwareBottomPadding` early-returns sin leer providers, eliminando la cadena que dispara el Timer leak.

Alternativas descartadas:
- **Path-based check en `ShellMetrics`**: edge case `/history` (tab, in-shell) vs `/history/:homeId/:eventId` (detail, out-of-shell) requiere lógica `startsWith` + exclusiones. Acopla con app.dart.
- **Parámetro explícito `inShell: bool`**: 14+ call sites a actualizar; fácil de olvidar.

### 3.2 Layout del marker dentro del shell

Cada shell envuelve solo su `child` (la pantalla de tab) con el marker. AdBanner y TabBar quedan fuera del marker — correcto, no son consumidores de `adAwareBottomPadding`:

```dart
// MainShellFuturista (idem para v2)
body: Stack(
  children: [
    ShellPresenceMarker(child: child),  // <-- solo el child
    if (bannerVisible) Positioned(...AdBanner...),
    if (!keyboardVisible) Positioned(...TockaTabBar...),
  ],
),
```

`updateShouldNotify` retorna `false`: la presencia/ausencia del marker es estable durante el lifetime del shell — nunca cambia, nunca dispara rebuild.

### 3.3 Early-return en `adAwareBottomPadding`

```dart
double adAwareBottomPadding(BuildContext context, WidgetRef ref, {double extra = 0}) {
  final safeArea = MediaQuery.paddingOf(context).bottom;

  if (!ShellPresenceMarker.of(context)) {
    return safeArea + extra;
  }

  // Resto: lectura de providers + cálculo de banner+navBar
  final metrics = ref.watch(shellMetricsProvider);
  final config = ref.watch(adBannerConfigProvider);
  final keyboardVisible = ref.watch(keyboardVisibleProvider);
  final location = _safeLocation(context);
  final suppressedHere = metrics.suppressBannerFor(location);
  final bannerVisible = config.show
      && config.unitId.isNotEmpty
      && !keyboardVisible
      && !suppressedHere;

  final banner = bannerVisible ? AdBanner.kBannerHeight + metrics.bannerGap : 0.0;
  final navBar = keyboardVisible ? 0.0 : metrics.navBarHeight + metrics.navBarBottom;

  return banner + navBar + safeArea + extra;
}
```

Notas:
- `_safeLocation` se mantiene como belt-and-suspenders aunque ya solo se llama en pantallas in-shell (donde `GoRouter` siempre existe).
- Cuando `!inShell`, no se leen `shellMetricsProvider`/`adBannerConfigProvider`/`keyboardVisibleProvider`. **Esto es la clave del item 2**: no se dispara la cadena de Timer.

### 3.4 Cleanup del override de vacation test

El override añadido en 2F Task 2 (commit `5f9b45d`):

```dart
adBannerConfigProvider.overrideWith(
  (ref) => const AdBannerConfig(show: false, unitId: ''),
),
```

…queda redundante tras §3.3. Se elimina el override + el import asociado + el comentario explicativo (corregido en `3a9e1d9`). Se ejecuta el test para confirmar que sigue verde.

### 3.5 Docstring de `TaskActionability.isActionable`

Cambio puntual de comentario (no afecta lógica):

**Antes:**
```dart
/// - weekly: due cae en la semana ISO actual (lunes-domingo).
```

**Después:**
```dart
/// - weekly: due cae en la semana actual lunes-domingo, calculada con
///   `DateTime.weekday` (NO cumple ISO 8601 estricto en fronteras de año).
```

---

## 4 · Arquitectura y archivos

### 4.1 Crear (2)

| Path | Contenido |
|---|---|
| `lib/shared/widgets/skins/shell_presence_marker.dart` | `ShellPresenceMarker extends InheritedWidget` con `static bool of(BuildContext)`. |
| `test/ui/shared/widgets/skins/shell_presence_marker_test.dart` | 3 tests: marker presente → true; marker ausente → false; marker propaga a hijos. |

### 4.2 Modificar (5)

| Path | Cambio |
|---|---|
| `lib/shared/widgets/skins/main_shell_v2.dart` | Wrappear `child` en el `Stack` del body con `ShellPresenceMarker`. |
| `lib/shared/widgets/skins/main_shell_futurista.dart` | Idem. |
| `lib/shared/widgets/ad_aware_bottom_padding.dart` | Early-return `safeArea + extra` cuando `!ShellPresenceMarker.of(context)`. |
| `test/ui/features/members/skins/futurista/vacation_screen_futurista_test.dart` | Eliminar override `adBannerConfigProvider` (ya redundante) + import + comentario. |
| `lib/features/tasks/domain/task_actionability.dart` | Corregir docstring de `isActionable` weekly branch. |

### 4.3 Borrar

Nada.

---

## 5 · Estrategia de delegación

| Ola | Trabajo | Estimación | Commit |
|---|---|---|---|
| **1 — Core** | Crear `shell_presence_marker.dart` + tests. Wrap shells. Refactor `adAwareBottomPadding`. `flutter analyze` + `flutter test`. | 25-35 min | `feat(shell): ShellPresenceMarker para detectar out-of-shell en adAwareBottomPadding` |
| **2 — Cleanup** | Quitar override redundante en vacation test. Fix docstring `TaskActionability`. Verificar tests verdes. | 10-15 min | `chore(skin): cleanup vacation test + docstring TaskActionability tras 2G` |

**2 olas lineales, 2 commits.** Total esperado: 35-50 min.

### 5.1 Control de riesgos

- **Tests in-shell siguen verdes**: la presencia del marker en shells de prod no introduce ningún cambio observable.
- **Tests out-of-shell que asertaban dimensiones**: ninguno conocido. Los tests existentes verifican `find.byType` y `find.text`, no medidas exactas.
- **Performance**: `dependOnInheritedWidgetOfExactType` walking up el árbol es O(altura). Cacheado en el subscription. `updateShouldNotify` false → cero rebuilds. Imperceptible.
- **Edge case: `MainShellRoot`**: usa `SkinSwitch(v2: ..., futurista: ...)`. Cada shell aplica su propio marker en su body. Cuando se cambia de skin via `SkinSwitch`, el marker se desmonta+remonta, pero como solo se usa para detección presencia/ausencia y `updateShouldNotify` es false, no hay efecto secundario.

---

## 6 · Tests

### 6.1 Nuevos (1 fichero, 3 tests)

`test/ui/shared/widgets/skins/shell_presence_marker_test.dart`:

```dart
testWidgets('of(context) returns true under marker', (tester) async {
  bool? observed;
  await tester.pumpWidget(MaterialApp(
    home: ShellPresenceMarker(
      child: Builder(builder: (ctx) {
        observed = ShellPresenceMarker.of(ctx);
        return const SizedBox();
      }),
    ),
  ));
  expect(observed, isTrue);
});

testWidgets('of(context) returns false without marker', (tester) async {
  bool? observed;
  await tester.pumpWidget(MaterialApp(
    home: Builder(builder: (ctx) {
      observed = ShellPresenceMarker.of(ctx);
      return const SizedBox();
    }),
  ));
  expect(observed, isFalse);
});

testWidgets('of(context) propagates through nested widgets', (tester) async {
  bool? observed;
  await tester.pumpWidget(MaterialApp(
    home: ShellPresenceMarker(
      child: Scaffold(
        body: Container(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Builder(builder: (ctx) {
              observed = ShellPresenceMarker.of(ctx);
              return const SizedBox();
            }),
          ),
        ),
      ),
    ),
  ));
  expect(observed, isTrue);
});
```

### 6.2 Existentes

- Tests de `adAwareBottomPadding` indirectos vía wrappers de pantallas: deben seguir verdes.
- `vacation_screen_futurista_test.dart` debe seguir verde tras quitar el override.
- `main_shell_root_test.dart` mantiene su override (mounta el shell directamente, en cuyo caso `inShell=true` y se leen los providers).
- `task_actionability_test.dart` no se toca (cambio solo en docstring, no en lógica).

---

## 7 · Criterios de aceptación

| # | Criterio | Verificación |
|---|---|---|
| AC1 | `ShellPresenceMarker.of(ctx)` retorna true bajo el marker, false sin él, y propaga a hijos anidados | tests widget |
| AC2 | `adAwareBottomPadding` retorna solo `safeArea + extra` cuando no hay marker (sin leer providers) | inspección de código + manual |
| AC3 | En pantallas in-shell (Hoy, Tareas, Historial, Miembros, Settings, TaskDetail) el padding sigue siendo `banner + navBar + safeArea + extra` | tests existentes pasan |
| AC4 | Tras quitar el override en `vacation_screen_futurista_test.dart`, el test sigue verde | CI |
| AC5 | Las 9 pantallas out-of-shell (paywall, rescue, profile, edit_profile, my_homes, home_settings, vacation, notification_settings, subscription_management) ya no muestran ~64-140px de espacio muerto al fondo | manual en dispositivo |
| AC6 | Docstring weekly de `TaskActionability` ya no afirma "ISO 8601" | inspección |
| AC7 | `flutter analyze lib test` 0 errores nuevos | CI |
| AC8 | `flutter test` baseline preservado (951/55) | CI |

---

## 8 · Commits previstos

| # | Mensaje | Ola |
|---|---|---|
| 1 | `feat(shell): ShellPresenceMarker para detectar out-of-shell en adAwareBottomPadding` | 1 |
| 2 | `chore(skin): cleanup vacation test + docstring TaskActionability tras 2G` | 2 |

Total **2 commits**.

---

## 9 · Pruebas manuales requeridas

Antes de cerrar la spec, verificar en dispositivo `43340fd2`:

1. **Skin futurista activado.** Navegar a cada pantalla out-of-shell y scrollear a fondo. El último item debe quedar JUSTO sobre la safe area (no más de ~50px de respiración):
   - `/my-homes`
   - `/home-settings`
   - `/vacation`
   - `/notification-settings`
   - `/subscription`
   - `/subscription/paywall`
   - `/subscription/rescue`
   - `/profile`
   - `/profile/edit`
2. **Skin futurista, pantallas in-shell.** Confirmar que el padding sigue siendo amplio (deja sitio para nav+banner) y el último item NO se clipea bajo el banner ni la TockaTabBar:
   - `/home` (Hoy)
   - `/history` (Historial)
   - `/members`
   - `/tasks`
3. Toggle a skin Clásico. Repetir comprobación en in-shell vs out-of-shell — comportamiento idéntico.
4. **Sin Premium (banner visible).** Repetir 1+2 con Free user. El banner real flotante de AdMob debe seguir mostrándose en in-shell, ausente en out-of-shell.
