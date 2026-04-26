# Skin Futurista 2G · Out-of-shell padding + cleanup · Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hacer que `adAwareBottomPadding` detecte cuándo está fuera del `ShellRoute` y devuelva solo `safeArea + extra` en ese caso (eliminando ~64-140px de espacio muerto en 9 pantallas push). Cleanup colateral: override redundante en vacation test + docstring "ISO" en TaskActionability.

**Architecture:** Un nuevo `ShellPresenceMarker extends InheritedWidget` se inserta en el `body` de `MainShellV2` y `MainShellFuturista` envolviendo el `child`. `adAwareBottomPadding` chequea `ShellPresenceMarker.of(context)` al inicio: si es `false` (out-of-shell), early-returns `safeArea + extra` sin leer providers. Esto resuelve además el Timer leak indirecto que motivó el override defensivo en `vacation_screen_futurista_test.dart` durante 2F.

**Tech Stack:** Flutter 3.x, Dart 3.x, Riverpod, GoRouter, `flutter_test`. Sin nuevas dependencias.

**Spec:** [docs/superpowers/specs/2026-04-26-skin-futurista-2g-design.md](../specs/2026-04-26-skin-futurista-2g-design.md)

---

## File map

### Crear (2)

- `lib/shared/widgets/skins/shell_presence_marker.dart` — `ShellPresenceMarker extends InheritedWidget` con método estático `of(BuildContext) → bool`.
- `test/ui/shared/widgets/skins/shell_presence_marker_test.dart` — 3 tests widget: presente → true; ausente → false; propaga a hijos anidados.

### Modificar (5)

- `lib/shared/widgets/skins/main_shell_v2.dart` — wrappear `child` en el `Stack.children[0]` con `ShellPresenceMarker(child: child)`.
- `lib/shared/widgets/skins/main_shell_futurista.dart` — idem.
- `lib/shared/widgets/ad_aware_bottom_padding.dart` — early-return `safeArea + extra` cuando `!ShellPresenceMarker.of(context)`.
- `test/ui/features/members/skins/futurista/vacation_screen_futurista_test.dart` — eliminar override `adBannerConfigProvider` + import + comentario.
- `lib/features/tasks/domain/task_actionability.dart` — corregir docstring weekly (quitar "ISO 8601").

### Borrar

Nada.

---

## Task 1: Core — ShellPresenceMarker + helper refactor + shells (Ola 1)

**Files:**
- Create: `lib/shared/widgets/skins/shell_presence_marker.dart`
- Create: `test/ui/shared/widgets/skins/shell_presence_marker_test.dart`
- Modify: `lib/shared/widgets/skins/main_shell_v2.dart`
- Modify: `lib/shared/widgets/skins/main_shell_futurista.dart`
- Modify: `lib/shared/widgets/ad_aware_bottom_padding.dart`

### Step 1.1: Escribir tests fallidos para `ShellPresenceMarker`

- [ ] Crear archivo `test/ui/shared/widgets/skins/shell_presence_marker_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/shared/widgets/skins/shell_presence_marker.dart';

void main() {
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
}
```

### Step 1.2: Verificar que los tests fallan

Run: `flutter test test/ui/shared/widgets/skins/shell_presence_marker_test.dart`
Expected: FAIL — "Target of URI doesn't exist: 'package:toka/shared/widgets/skins/shell_presence_marker.dart'".

### Step 1.3: Crear `shell_presence_marker.dart`

- [ ] Crear archivo `lib/shared/widgets/skins/shell_presence_marker.dart`:

```dart
import 'package:flutter/widgets.dart';

/// `InheritedWidget` que marca la presencia de un shell de skin
/// (`MainShellV2` o `MainShellFuturista`) como ancestro.
///
/// Permite a widgets descendientes (especialmente `adAwareBottomPadding`)
/// saber si están renderizándose bajo un shell con NavBar y AdBanner
/// flotantes, o si están en una ruta push sin shell (paywall, profile,
/// vacation, etc.).
///
/// Uso típico:
/// ```dart
/// final inShell = ShellPresenceMarker.of(context);
/// if (!inShell) return safeArea + extra;  // sin nav ni banner
/// // ...resto del cálculo con banner+navBar
/// ```
///
/// `updateShouldNotify` siempre devuelve `false`: la presencia/ausencia
/// del marker es estable durante el lifetime del shell — nunca cambia,
/// nunca dispara rebuild.
class ShellPresenceMarker extends InheritedWidget {
  const ShellPresenceMarker({super.key, required super.child});

  /// Devuelve `true` si algún ancestro es un `ShellPresenceMarker`,
  /// `false` en caso contrario.
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellPresenceMarker>() != null;

  @override
  bool updateShouldNotify(ShellPresenceMarker oldWidget) => false;
}
```

### Step 1.4: Verificar que los tests pasan

Run: `flutter test test/ui/shared/widgets/skins/shell_presence_marker_test.dart`
Expected: 3 tests verdes.

### Step 1.5: Wrappear `child` en `MainShellV2`

- [ ] Editar `lib/shared/widgets/skins/main_shell_v2.dart`. Añadir import al inicio (junto a otros imports relativos):

```dart
import 'shell_presence_marker.dart';
```

- [ ] Localizar el `Stack` dentro del `body` (alrededor de líneas 134-150). Reemplazar:

```dart
        body: Stack(
          children: [
            child,
            if (bannerVisible)
              Positioned(
                left: 0,
                right: 0,
                bottom: navBarSlot + safeBottom + _kBannerGap,
                child: const AdBanner(key: Key('ad_banner')),
              ),
            if (!keyboardVisible)
              Positioned(
                left: 16, right: 16,
                bottom: _kNavBarBottom + safeBottom,
                child: _FloatingNavBar(selectedIndex: tabIndex),
              ),
          ],
        ),
```

por:

```dart
        body: Stack(
          children: [
            ShellPresenceMarker(child: child),
            if (bannerVisible)
              Positioned(
                left: 0,
                right: 0,
                bottom: navBarSlot + safeBottom + _kBannerGap,
                child: const AdBanner(key: Key('ad_banner')),
              ),
            if (!keyboardVisible)
              Positioned(
                left: 16, right: 16,
                bottom: _kNavBarBottom + safeBottom,
                child: _FloatingNavBar(selectedIndex: tabIndex),
              ),
          ],
        ),
```

### Step 1.6: Wrappear `child` en `MainShellFuturista`

- [ ] Editar `lib/shared/widgets/skins/main_shell_futurista.dart`. Añadir import al inicio (junto a otros imports relativos):

```dart
import 'shell_presence_marker.dart';
```

- [ ] Localizar el `Stack` dentro del `body` (alrededor de líneas 84-105). Reemplazar:

```dart
        body: Stack(
          children: [
            child,
            if (bannerVisible)
              Positioned(
                left: 0,
                right: 0,
                bottom: navBarSlot + safeBottom + metrics.bannerGap,
                child: const AdBanner(key: Key('ad_banner_futurista_shell')),
              ),
            if (!keyboardVisible)
              Positioned(
                left: 10,
                right: 10,
                bottom: metrics.navBarBottom + safeBottom,
                child: TockaTabBar(
                  activeIndex: tabIndex,
                  items: items,
                  onTap: (i) => context.go(_routes[i]),
                ),
              ),
          ],
        ),
```

por:

```dart
        body: Stack(
          children: [
            ShellPresenceMarker(child: child),
            if (bannerVisible)
              Positioned(
                left: 0,
                right: 0,
                bottom: navBarSlot + safeBottom + metrics.bannerGap,
                child: const AdBanner(key: Key('ad_banner_futurista_shell')),
              ),
            if (!keyboardVisible)
              Positioned(
                left: 10,
                right: 10,
                bottom: metrics.navBarBottom + safeBottom,
                child: TockaTabBar(
                  activeIndex: tabIndex,
                  items: items,
                  onTap: (i) => context.go(_routes[i]),
                ),
              ),
          ],
        ),
```

### Step 1.7: Refactor `adAwareBottomPadding` con early-return

- [ ] Editar `lib/shared/widgets/ad_aware_bottom_padding.dart`. Añadir import al inicio:

```dart
import 'skins/shell_presence_marker.dart';
```

- [ ] Reemplazar el body de la función `adAwareBottomPadding` completa (líneas ~28-52) por:

```dart
double adAwareBottomPadding(
  BuildContext context,
  WidgetRef ref, {
  double extra = 0,
}) {
  final safeArea = MediaQuery.paddingOf(context).bottom;

  // Pantallas fuera del shell (push routes como /paywall, /profile,
  // /vacation, etc.) no renderizan NavBar ni AdBanner. Solo necesitan
  // safeArea + extra. Esto evita ~64-140px de espacio muerto al fondo.
  // Bonus: al no leer adBannerConfigProvider/shellMetricsProvider/etc.
  // se evita disparar la cadena que mantiene vivo el Timer 15s de
  // authProvider en tests sin mock completo.
  if (!ShellPresenceMarker.of(context)) {
    return safeArea + extra;
  }

  final metrics = ref.watch(shellMetricsProvider);
  final config = ref.watch(adBannerConfigProvider);
  final keyboardVisible = ref.watch(keyboardVisibleProvider);
  final location = _safeLocation(context);
  final suppressedHere = metrics.suppressBannerFor(location);
  final bannerVisible = config.show
      && config.unitId.isNotEmpty
      && !keyboardVisible
      && !suppressedHere;

  final banner = bannerVisible
      ? AdBanner.kBannerHeight + metrics.bannerGap
      : 0.0;
  final navBar = keyboardVisible
      ? 0.0
      : metrics.navBarHeight + metrics.navBarBottom;

  return banner + navBar + safeArea + extra;
}
```

(Mantener `_safeLocation` al final del archivo intacto.)

- [ ] Actualizar el dartdoc de la función (líneas ~10-27). Reemplazar:

```dart
/// Padding inferior total que cualquier `ScrollView` de contenido
/// debe aplicar para que su último ítem quede visible por encima
/// del banner publicitario, la NavigationBar flotante y la safe area.
///
/// Devuelve:
///
///   banner + navBar + safeArea + extra
///
/// Tanto `banner` como `navBar` se evalúan a 0 cuando el teclado del
/// sistema está visible: la spec oculta ambos mientras el usuario escribe
/// para no tapar el input (ver `keyboard_visible_provider.dart`).
/// Adicionalmente `banner` es 0 cuando la config remota no lo muestra
/// (Premium, `showBanner=false`), el `unitId` está vacío, o la ruta actual
/// está en la lista de rutas que suprimen el banner (p. ej. `/settings`).
///
/// Las dimensiones (NavBar height/bottom, bannerGap) se obtienen del
/// `shellMetricsProvider`, que devuelve la impl correcta según la skin
/// activa. Esto evita el desfase entre v2 (56+12) y futurista (64+12).
```

por:

```dart
/// Padding inferior total que cualquier `ScrollView` de contenido
/// debe aplicar para que su último ítem quede visible por encima
/// del banner publicitario, la NavigationBar flotante y la safe area.
///
/// Devuelve:
///   - `safeArea + extra` si el widget está FUERA del shell (push routes
///     como /paywall, /profile, /vacation: no renderizan NavBar ni AdBanner).
///   - `banner + navBar + safeArea + extra` si está bajo un `MainShellV2` o
///     `MainShellFuturista` (detectado vía `ShellPresenceMarker`).
///
/// Tanto `banner` como `navBar` se evalúan a 0 cuando el teclado del
/// sistema está visible: la spec oculta ambos mientras el usuario escribe
/// para no tapar el input (ver `keyboard_visible_provider.dart`).
/// Adicionalmente `banner` es 0 cuando la config remota no lo muestra
/// (Premium, `showBanner=false`), el `unitId` está vacío, o la ruta actual
/// está en la lista de rutas que suprimen el banner (p. ej. `/settings`).
///
/// Las dimensiones (NavBar height/bottom, bannerGap) se obtienen del
/// `shellMetricsProvider`, que devuelve la impl correcta según la skin
/// activa. Esto evita el desfase entre v2 (56+12) y futurista (64+12).
```

### Step 1.8: Run all tests

Run: `flutter test`
Expected: baseline preservado (951 verdes / 55 reds pre-existentes). Sin regresiones nuevas.

Si surge alguna nueva regresión:
- Si es un test que mountaba `MainShellV2` o `MainShellFuturista` directamente y asertaba dimensiones exactas, investigar.
- Si es un test out-of-shell que ahora falla por cambio de comportamiento esperado, probablemente el test ya estaba mal — revisar caso por caso.

### Step 1.9: `flutter analyze lib test`

Expected: 0 errores nuevos.

### Step 1.10: Commit

```bash
git add lib/shared/widgets/skins/shell_presence_marker.dart \
        test/ui/shared/widgets/skins/shell_presence_marker_test.dart \
        lib/shared/widgets/skins/main_shell_v2.dart \
        lib/shared/widgets/skins/main_shell_futurista.dart \
        lib/shared/widgets/ad_aware_bottom_padding.dart
git commit -m "feat(shell): ShellPresenceMarker para detectar out-of-shell en adAwareBottomPadding"
```

---

## Task 2: Cleanup — vacation test override + docstring TaskActionability (Ola 2)

**Files:**
- Modify: `test/ui/features/members/skins/futurista/vacation_screen_futurista_test.dart`
- Modify: `lib/features/tasks/domain/task_actionability.dart`

### Step 2.1: Eliminar override redundante en vacation test

- [ ] Editar `test/ui/features/members/skins/futurista/vacation_screen_futurista_test.dart`. Eliminar el import:

```dart
import 'package:toka/shared/widgets/ad_banner_config_provider.dart';
```

- [ ] Reemplazar el bloque del `_container()` (líneas ~30-42):

```dart
ProviderContainer _container() => ProviderContainer(overrides: [
      memberVacationProvider(homeId: 'h1', uid: 'u1')
          .overrideWith((_) => Stream.value(null)),
      // VacationScreenFuturista usa adAwareBottomPadding → adBannerConfigProvider
      // → dashboardProvider → currentHomeProvider → authProvider, cuyo
      // `Auth.build()` arma un `Timer(15s)` para el fallback de login. Sin este
      // override, ese timer queda colgando al cierre del test ("Timer is still
      // pending"). Override conservador (show: false, unitId: '') corta la
      // cadena al primer eslabón y mantiene el helper coherente con producción.
      adBannerConfigProvider.overrideWith(
        (ref) => const AdBannerConfig(show: false, unitId: ''),
      ),
    ]);
```

por:

```dart
ProviderContainer _container() => ProviderContainer(overrides: [
      memberVacationProvider(homeId: 'h1', uid: 'u1')
          .overrideWith((_) => Stream.value(null)),
    ]);
```

### Step 2.2: Verificar vacation test verde

Run: `flutter test test/ui/features/members/skins/futurista/vacation_screen_futurista_test.dart`
Expected: 2/2 tests verdes (los wrappers v2/futurista).

Si falla con "Timer is still pending":
- El test mounta `VacationScreen` directamente (no bajo un shell), por lo que `ShellPresenceMarker.of(context)` retorna `false` y `adAwareBottomPadding` early-returns sin leer `adBannerConfigProvider`.
- Si aun así falla, hay otro provider en la cadena no relacionado con `adAwareBottomPadding`. Investigar y restaurar el override si necesario.

### Step 2.3: Corregir docstring de `TaskActionability.isActionable`

- [ ] Editar `lib/features/tasks/domain/task_actionability.dart`. Localizar el bloque dartdoc del método `isActionable` (alrededor de líneas 17-24). Reemplazar:

```dart
  /// Determina si la tarea puede completarse ahora según su tipo de
  /// recurrencia. Reglas:
  /// - Tareas vencidas (due < now) son siempre actionable.
  /// - hourly: due cae en la hora actual.
  /// - daily: due cae hoy.
  /// - weekly: due cae en la semana ISO actual (lunes-domingo).
  /// - monthly: due cae en el mes actual.
  /// - yearly: due cae en el año actual.
  /// - oneTime / desconocido: equivalente a daily.
```

por:

```dart
  /// Determina si la tarea puede completarse ahora según su tipo de
  /// recurrencia. Reglas:
  /// - Tareas vencidas (due < now) son siempre actionable.
  /// - hourly: due cae en la hora actual.
  /// - daily: due cae hoy.
  /// - weekly: due cae en la semana actual lunes-domingo, calculada con
  ///   `DateTime.weekday` (NO cumple ISO 8601 estricto en fronteras de año).
  /// - monthly: due cae en el mes actual.
  /// - yearly: due cae en el año actual.
  /// - oneTime / desconocido: equivalente a daily.
```

### Step 2.4: Run all tests

Run: `flutter test`
Expected: baseline preservado (951 verdes / 55 reds pre-existentes).

### Step 2.5: `flutter analyze lib test`

Expected: 0 errores nuevos.

### Step 2.6: Commit

```bash
git add test/ui/features/members/skins/futurista/vacation_screen_futurista_test.dart \
        lib/features/tasks/domain/task_actionability.dart
git commit -m "chore(skin): cleanup vacation test + docstring TaskActionability tras 2G"
```

---

## Verificación final manual (después de Task 2)

Antes de marcar la spec como DONE, verificar en dispositivo `43340fd2`:

1. **Skin futurista activado.** Navegar a cada pantalla **out-of-shell** y scrollear a fondo. El último item debe quedar JUSTO sobre la safe area (~50px máx de respiración):
   - `/my-homes`
   - `/home-settings`
   - `/vacation`
   - `/notification-settings`
   - `/subscription`
   - `/subscription/paywall`
   - `/subscription/rescue`
   - `/profile`
   - `/profile/edit`

2. **Skin futurista, pantallas in-shell.** Confirmar que el padding sigue siendo amplio (deja sitio para nav+banner):
   - `/home` (Hoy)
   - `/history`
   - `/members`
   - `/tasks`

3. **Toggle a skin Clásico.** Repetir comprobación in-shell vs out-of-shell — comportamiento idéntico.

4. **Sin Premium (banner visible).** Repetir 1+2 con Free user. El banner real flotante de AdMob debe seguir mostrándose en in-shell, ausente en out-of-shell.

---

## Self-review checklist

- [x] **Spec coverage:** §3.1 (InheritedWidget) → Task 1 Steps 1.1-1.4. §3.2 (wrap shells) → Steps 1.5-1.6. §3.3 (early-return) → Step 1.7. §3.4 (cleanup vacation) → Steps 2.1-2.2. §3.5 (docstring) → Step 2.3.
- [x] **Placeholder scan:** ninguno; todos los pasos tienen código completo y comandos exactos.
- [x] **Type consistency:** `ShellPresenceMarker.of(BuildContext) → bool` consistente en spec (§3.1, §3.3), implementación (Step 1.3) y consumidor (Step 1.7).
- [x] **No types undefined:** `ShellPresenceMarker` se crea en Step 1.3 antes de ser usada en Steps 1.5, 1.6, 1.7.
