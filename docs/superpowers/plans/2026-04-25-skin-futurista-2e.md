# Skin Futurista 2E · Paridad de comportamiento · Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cerrar la brecha de comportamiento entre la skin futurista y la skin v2 en shell, TaskCardFuturista (botón Pasar + actionable gating) e HistoryScreenFuturista (tap, valorar, banner premium).

**Architecture:** Se introduce `ShellMetrics` como single source of truth para alturas de NavBar y reglas de banner. Ambos shells (`MainShellV2` y `MainShellFuturista`) y `adAwareBottomPadding` lo consumen vía `shellMetricsProvider`. `MainShellFuturista` se reescribe siguiendo el patrón de `MainShellV2` (extendBody + Stack con AdBanner + PopScope). `TaskCardFuturista` añade fila inferior de dos botones cuando es propia, con gating `actionable`. `HistoryScreenFuturista` añade tap-en-evento, slot trailing star y banner premium intercalado.

**Tech Stack:** Flutter 3.x, Dart 3.x, Riverpod (`flutter_riverpod`), GoRouter, `flutter_test`, `mocktail`.

**Spec:** [docs/superpowers/specs/2026-04-25-skin-futurista-2e-design.md](../specs/2026-04-25-skin-futurista-2e-design.md)

---

## File map

### Crear (3)

- `lib/shared/widgets/skins/shell_metrics.dart` — `ShellMetrics` interface, `MainShellV2Metrics`, `MainShellFuturistaMetrics`, `shellMetricsProvider`.
- `lib/shared/widgets/futurista/premium_banner_futurista.dart` — `PremiumBannerFuturista` widget intercalado en history futurista.
- `test/ui/shared/widgets/skins/shell_metrics_test.dart` — provider devuelve la impl correcta según skin.

### Modificar (8)

- `lib/shared/widgets/skins/main_shell_v2.dart` — `kNavBarHeight/kNavBarBottom` referencian `MainShellV2Metrics`. Sin cambios de comportamiento.
- `lib/shared/widgets/skins/main_shell_futurista.dart` — Reescritura completa (extendBody + AdBanner + PopScope + Stack).
- `lib/shared/widgets/ad_aware_bottom_padding.dart` — Consume `shellMetricsProvider` en lugar de constantes hardcoded.
- `lib/shared/widgets/futurista/task_card_futurista.dart` — Fila inferior `[Hecho][Pasar]` cuando `mine && !done`. Acepta `actionable` y `onActionableHint`.
- `lib/features/tasks/presentation/skins/futurista/today_screen_futurista.dart` — Eliminar `AdBannerFuturista` sliver, padding `extra: 96 → 16`, pasar `actionable` y nuevo `onTap` a las cards, helpers `_isActionable` y `_snackNotYet`.
- `lib/features/tasks/presentation/skins/futurista/all_tasks_screen_futurista.dart` — Padding hardcoded `120` → `adAwareBottomPadding(extra: 16)`.
- `lib/features/tasks/presentation/skins/futurista/task_detail_screen_futurista.dart` — Padding hardcoded `32` → `adAwareBottomPadding(extra: 16)`.
- `lib/features/history/presentation/skins/futurista/history_screen_futurista.dart` — Tap en evento, slot trailing star, banner premium intercalado, padding `extra: 80 → 16`.

### Borrar (2)

- `lib/shared/widgets/futurista/ad_banner_futurista.dart`
- `test/ui/shared/widgets/futurista/ad_banner_futurista_test.dart`

### Tests modificar (2)

- `test/ui/shared/widgets/futurista/task_card_futurista_test.dart` — Añadir 4 escenarios para nuevos botones y gating.
- `test/ui/features/history/skins/futurista/history_screen_futurista_test.dart` — Añadir 3 escenarios para tap, star, premium banner.

---

## Task 1: Shell metrics + ad-aware padding refactor (Ola 1)

**Files:**
- Create: `lib/shared/widgets/skins/shell_metrics.dart`
- Create: `test/ui/shared/widgets/skins/shell_metrics_test.dart`
- Modify: `lib/shared/widgets/skins/main_shell_v2.dart`
- Modify: `lib/shared/widgets/ad_aware_bottom_padding.dart`

### Step 1.1: Escribir test fallido para `shellMetricsProvider`

- [ ] Crear archivo `test/ui/shared/widgets/skins/shell_metrics_test.dart` con:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toka/core/constants/routes.dart';
import 'package:toka/core/theme/app_skin.dart';
import 'package:toka/core/theme/skin_provider.dart';
import 'package:toka/shared/widgets/skins/shell_metrics.dart';

class _FakeSkinMode extends SkinMode {
  @override
  AppSkin build() => AppSkin.v2;
  @override
  Future<void> set(AppSkin skin) async => state = skin;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('returns MainShellV2Metrics when skin is v2', () {
    final c = ProviderContainer(
      overrides: [skinModeProvider.overrideWith(_FakeSkinMode.new)],
    );
    addTearDown(c.dispose);
    c.read(skinModeProvider.notifier).set(AppSkin.v2);
    final metrics = c.read(shellMetricsProvider);
    expect(metrics, isA<MainShellV2Metrics>());
    expect(metrics.navBarHeight, 56);
    expect(metrics.navBarBottom, 12);
  });

  test('returns MainShellFuturistaMetrics when skin is futurista', () {
    final c = ProviderContainer(
      overrides: [skinModeProvider.overrideWith(_FakeSkinMode.new)],
    );
    addTearDown(c.dispose);
    c.read(skinModeProvider.notifier).set(AppSkin.futurista);
    final metrics = c.read(shellMetricsProvider);
    expect(metrics, isA<MainShellFuturistaMetrics>());
    expect(metrics.navBarHeight, 64);
    expect(metrics.navBarBottom, 12);
  });

  test('suppresses banner only on /settings in both impls', () {
    const v2 = MainShellV2Metrics();
    const fut = MainShellFuturistaMetrics();
    expect(v2.suppressBannerFor(AppRoutes.settings), isTrue);
    expect(v2.suppressBannerFor(AppRoutes.home), isFalse);
    expect(fut.suppressBannerFor(AppRoutes.settings), isTrue);
    expect(fut.suppressBannerFor(AppRoutes.home), isFalse);
  });
}
```

### Step 1.2: Verificar que el test falla

Run: `flutter test test/ui/shared/widgets/skins/shell_metrics_test.dart`
Expected: FAIL con "Target of URI doesn't exist: 'package:toka/shared/widgets/skins/shell_metrics.dart'".

### Step 1.3: Crear `shell_metrics.dart`

- [ ] Crear archivo `lib/shared/widgets/skins/shell_metrics.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/routes.dart';
import '../../../core/theme/app_skin.dart';
import '../../../core/theme/skin_provider.dart';
import '../ad_banner.dart';

/// Métricas del shell según skin activo. Single source of truth para alturas
/// de NavBar y reglas de supresión de banner. `adAwareBottomPadding`,
/// `MainShellV2.bottomContentPadding/fabBottomPadding` y `MainShellFuturista`
/// la consumen vía `shellMetricsProvider`.
abstract class ShellMetrics {
  const ShellMetrics();
  double get navBarHeight;
  double get navBarBottom;
  double get bannerGap;
  bool suppressBannerFor(String location);
}

class MainShellV2Metrics extends ShellMetrics {
  const MainShellV2Metrics();
  static const double kNavBarHeight = 56;
  static const double kNavBarBottom = 12;
  @override
  double get navBarHeight => kNavBarHeight;
  @override
  double get navBarBottom => kNavBarBottom;
  @override
  double get bannerGap => AdBanner.kBannerGap;
  @override
  bool suppressBannerFor(String location) =>
      location.startsWith(AppRoutes.settings);
}

class MainShellFuturistaMetrics extends ShellMetrics {
  const MainShellFuturistaMetrics();
  static const double kNavBarHeight = 64;
  static const double kNavBarBottom = 12;
  @override
  double get navBarHeight => kNavBarHeight;
  @override
  double get navBarBottom => kNavBarBottom;
  @override
  double get bannerGap => AdBanner.kBannerGap;
  @override
  bool suppressBannerFor(String location) =>
      location.startsWith(AppRoutes.settings);
}

final shellMetricsProvider = Provider<ShellMetrics>((ref) {
  final skin = ref.watch(skinModeProvider);
  switch (skin) {
    case AppSkin.v2:
      return const MainShellV2Metrics();
    case AppSkin.futurista:
      return const MainShellFuturistaMetrics();
  }
});
```

### Step 1.4: Verificar que el test pasa

Run: `flutter test test/ui/shared/widgets/skins/shell_metrics_test.dart`
Expected: PASS — los 3 tests verdes.

### Step 1.5: Refactor `MainShellV2` para delegar las constantes

- [ ] Editar `lib/shared/widgets/skins/main_shell_v2.dart`. Reemplazar el bloque (aproximadamente líneas 33-50):

```dart
  // Altura total que la barra flotante ocupa desde el borde inferior de la pantalla.
  // Usada tanto para el placeholder transparente (MediaQuery) como para el Positioned.
  // Públicas para que los inner Scaffolds puedan calcular el padding del FAB.
  static const double kNavBarHeight  = 56;
  static const double kNavBarBottom  = 12;
  // Compatibilidad interna
  static const double _kNavBarHeight = kNavBarHeight;
  static const double _kNavBarBottom = kNavBarBottom;

  // Gap entre el top de la NavBar y el bottom del banner.
  // Fuente única en AdBanner.kBannerGap.
  static double get _kBannerGap => AdBanner.kBannerGap;
```

por:

```dart
  // Constantes públicas reexportadas desde ShellMetrics. Ningún consumidor
  // externo necesita migrar — siguen funcionando con el mismo nombre y valor.
  static const double kNavBarHeight  = MainShellV2Metrics.kNavBarHeight;
  static const double kNavBarBottom  = MainShellV2Metrics.kNavBarBottom;
  // Compatibilidad interna
  static const double _kNavBarHeight = kNavBarHeight;
  static const double _kNavBarBottom = kNavBarBottom;

  // Gap entre el top de la NavBar y el bottom del banner.
  // Fuente única en AdBanner.kBannerGap.
  static double get _kBannerGap => AdBanner.kBannerGap;
```

- [ ] Añadir el import al inicio del archivo, debajo de los imports existentes:

```dart
import 'shell_metrics.dart';
```

### Step 1.6: Refactor `ad_aware_bottom_padding.dart`

- [ ] Reemplazar el contenido completo de `lib/shared/widgets/ad_aware_bottom_padding.dart` por:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'ad_banner.dart';
import 'ad_banner_config_provider.dart';
import 'keyboard_visible_provider.dart';
import 'skins/shell_metrics.dart';

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
double adAwareBottomPadding(
  BuildContext context,
  WidgetRef ref, {
  double extra = 0,
}) {
  final metrics = ref.watch(shellMetricsProvider);
  final config = ref.watch(adBannerConfigProvider);
  final keyboardVisible = ref.watch(keyboardVisibleProvider);
  final location = GoRouterState.of(context).matchedLocation;
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
  final safeArea = MediaQuery.paddingOf(context).bottom;

  return banner + navBar + safeArea + extra;
}
```

Notas:
- Se quita el import directo a `skins/main_shell_v2.dart` (ya no hace falta).
- Se añade `GoRouter` para conocer la ruta actual y aplicar la supresión de banner — antes esto solo se hacía dentro del shell v2, no en el padding. Ahora es consistente.

### Step 1.7: Verificar que tests existentes siguen verdes

Run: `flutter test`
Expected: todos los tests existentes en verde. Si alguno falla por la introducción del `GoRouterState.of(context)`, el harness del test no monta GoRouter — investigar y wrappear con un `MaterialApp.router` mínimo o usar un mock.

**Mitigación común:** muchos tests llaman a `adAwareBottomPadding` desde un widget montado en `MaterialApp(home: ...)` sin GoRouter. Para esos casos, fallback seguro:

- [ ] Si surgen fallos, envolver la lectura de location en try/catch:

```dart
String _safeLocation(BuildContext context) {
  try {
    return GoRouterState.of(context).matchedLocation;
  } catch (_) {
    return ''; // fuera de un GoRouter context, no aplicar suppression
  }
}
```

Y reemplazar `final location = GoRouterState.of(context).matchedLocation;` por `final location = _safeLocation(context);`.

### Step 1.8: `flutter analyze`

Run: `flutter analyze lib test`
Expected: 0 errores nuevos.

### Step 1.9: Commit

```bash
git add lib/shared/widgets/skins/shell_metrics.dart \
        test/ui/shared/widgets/skins/shell_metrics_test.dart \
        lib/shared/widgets/skins/main_shell_v2.dart \
        lib/shared/widgets/ad_aware_bottom_padding.dart
git commit -m "refactor(shell): extraer ShellMetrics + provider y refactor adAwareBottomPadding"
```

---

## Task 2: MainShellFuturista rewrite + remove AdBannerFuturista (Ola 2)

**Files:**
- Modify: `lib/shared/widgets/skins/main_shell_futurista.dart`
- Modify: `lib/features/tasks/presentation/skins/futurista/today_screen_futurista.dart`
- Delete: `lib/shared/widgets/futurista/ad_banner_futurista.dart`
- Delete: `test/ui/shared/widgets/futurista/ad_banner_futurista_test.dart`

### Step 2.1: Reescribir `MainShellFuturista`

- [ ] Reemplazar el contenido completo de `lib/shared/widgets/skins/main_shell_futurista.dart` por:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../ad_banner.dart';
import '../ad_banner_config_provider.dart';
import '../futurista/tocka_tab_bar.dart';
import '../keyboard_visible_provider.dart';
import 'shell_metrics.dart';

/// Shell futurista con TockaTabBar floating + AdBanner flotante al pie y
/// PopScope que redirige a Hoy desde otras tabs (paridad con MainShellV2).
///
/// Mismo contrato que MainShellV2:
///  - `extendBody: true` + bottomNavigationBar placeholder transparente para
///    que MediaQuery.padding.bottom crezca y los hijos posicionen FABs/sheets
///    por encima del banner + nav bar.
///  - AdBanner real (AdMob) en `Positioned` flotante encima de la nav bar.
///  - Banner se oculta en `/settings` (regla legal compartida con v2) y
///    cuando el teclado está visible.
///  - `PopScope` captura el botón hardware BACK: si la tab activa no es Hoy,
///    redirige a Hoy en lugar de salir de la app.
class MainShellFuturista extends ConsumerWidget {
  const MainShellFuturista({super.key, required this.child});
  final Widget child;

  static const _routes = [
    AppRoutes.home,
    AppRoutes.history,
    AppRoutes.members,
    AppRoutes.tasks,
    AppRoutes.settings,
  ];

  int _indexFromRoute(String location) {
    for (var i = 0; i < _routes.length; i++) {
      if (location.startsWith(_routes[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final location = GoRouterState.of(context).matchedLocation;
    final tabIndex = _indexFromRoute(location);
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final metrics = ref.watch(shellMetricsProvider);

    final adConfig = ref.watch(adBannerConfigProvider);
    final keyboardVisible = ref.watch(keyboardVisibleProvider);
    final bannerVisible = adConfig.show
        && adConfig.unitId.isNotEmpty
        && !metrics.suppressBannerFor(location)
        && !keyboardVisible;
    final bannerSlot = bannerVisible
        ? AdBanner.kBannerHeight + metrics.bannerGap
        : 0.0;
    final navBarSlot = keyboardVisible
        ? 0.0
        : metrics.navBarHeight + metrics.navBarBottom;

    final items = [
      TockaTabBarItem(icon: Icons.home_outlined, label: l10n.today_screen_title),
      TockaTabBarItem(icon: Icons.history, label: l10n.history_title),
      TockaTabBarItem(icon: Icons.group_outlined, label: l10n.members_title),
      TockaTabBarItem(icon: Icons.check_circle_outline, label: l10n.tasks_title),
      TockaTabBarItem(icon: Icons.settings_outlined, label: l10n.settings_title),
    ];

    return PopScope(
      canPop: tabIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go(AppRoutes.home);
      },
      child: Scaffold(
        extendBody: true,
        bottomNavigationBar: SizedBox(
          height: navBarSlot + safeBottom + bannerSlot,
        ),
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
      ),
    );
  }
}
```

### Step 2.2: Limpiar `today_screen_futurista` — quitar AdBannerFuturista inline y ajustar padding

- [ ] Editar `lib/features/tasks/presentation/skins/futurista/today_screen_futurista.dart`:

  1. Borrar el import:

```dart
import '../../../../../shared/widgets/futurista/ad_banner_futurista.dart';
```

  2. Borrar el sliver inline (aproximadamente líneas 134-139):

```dart
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: AdBannerFuturista(),
                  ),
                ),
```

  Eliminar ese bloque completamente.

  3. Cambiar el último sliver de padding (aproximadamente líneas 166-171) de:

```dart
                SliverToBoxAdapter(
                  child: SizedBox(
                    height:
                        adAwareBottomPadding(context, ref, extra: 96),
                  ),
                ),
```

por:

```dart
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: adAwareBottomPadding(context, ref, extra: 16),
                  ),
                ),
```

  4. Actualizar el docstring de la clase (líneas 27-37) eliminando la mención al `AdBannerFuturista`. Reemplazar:

```dart
/// 1. `TockaTopBar` con nombre de hogar y avatars de miembros.
/// 2. Hero "Te toca ahora" cuando hay tarea asignada al usuario actual.
/// 3. `AdBannerFuturista` (maqueta visual, respeta el config provider).
/// 4. Bloques por recurrencia (HORA, DÍA, SEMANA, MES, AÑO) con
///    `BlockHeader` + `TaskCardFuturista`.
/// 5. Bloque `HECHAS · HOY` con las tareas completadas del día.
```

por:

```dart
/// 1. `TockaTopBar` con nombre de hogar y avatars de miembros.
/// 2. Hero "Te toca ahora" cuando hay tarea asignada al usuario actual.
/// 3. Bloques por recurrencia (HORA, DÍA, SEMANA, MES, AÑO) con
///    `BlockHeader` + `TaskCardFuturista`.
/// 4. Bloque `HECHAS · HOY` con las tareas completadas del día.
/// El banner publicitario lo pinta el shell (`MainShellFuturista`), no esta
/// pantalla — paridad con `TodayScreenV2`.
```

### Step 2.3: Borrar `ad_banner_futurista.dart` y su test

- [ ] Borrar archivo `lib/shared/widgets/futurista/ad_banner_futurista.dart`.
- [ ] Borrar archivo `test/ui/shared/widgets/futurista/ad_banner_futurista_test.dart`.

```bash
git rm lib/shared/widgets/futurista/ad_banner_futurista.dart
git rm test/ui/shared/widgets/futurista/ad_banner_futurista_test.dart
```

### Step 2.4: Verificar que no hay otros consumidores

Run: `grep -r "AdBannerFuturista\|ad_banner_futurista" lib test`
Expected: 0 resultados. Si aparece alguna referencia (p. ej. en otros tests), eliminarla.

### Step 2.5: Run all tests

Run: `flutter test`
Expected: todos verdes. Si `today_screen_futurista_test.dart` esperaba un `AdBannerFuturista`, eliminar esa expectativa.

### Step 2.6: `flutter analyze`

Run: `flutter analyze lib test`
Expected: 0 errores.

### Step 2.7: Commit

```bash
git add lib/shared/widgets/skins/main_shell_futurista.dart \
        lib/features/tasks/presentation/skins/futurista/today_screen_futurista.dart
git commit -m "feat(skin): MainShellFuturista con AdBanner + PopScope + extendBody (paridad v2)"
```

---

## Task 3: Padding cleanup en `all_tasks` y `task_detail` futurista (Ola 3)

**Files:**
- Modify: `lib/features/tasks/presentation/skins/futurista/all_tasks_screen_futurista.dart`
- Modify: `lib/features/tasks/presentation/skins/futurista/task_detail_screen_futurista.dart`

### Step 3.1: Padding ad-aware en `all_tasks_screen_futurista`

- [ ] Editar `lib/features/tasks/presentation/skins/futurista/all_tasks_screen_futurista.dart`. Asegurar import:

```dart
import '../../../../../shared/widgets/ad_aware_bottom_padding.dart';
```

(Si ya existe, dejar.)

- [ ] Reemplazar (línea ~142):

```dart
                  return ListView.separated(
                    key: const Key('tasks_list'),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
```

por:

```dart
                  return ListView.separated(
                    key: const Key('tasks_list'),
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 4,
                      bottom: adAwareBottomPadding(context, ref, extra: 16),
                    ),
```

### Step 3.2: Padding ad-aware en `task_detail_screen_futurista`

- [ ] Editar `lib/features/tasks/presentation/skins/futurista/task_detail_screen_futurista.dart`. Añadir import:

```dart
import '../../../../../shared/widgets/ad_aware_bottom_padding.dart';
```

- [ ] La build de `_Content` actualmente recibe solo `BuildContext` y lee del provider con `ref`. Verificar que `_Content extends ConsumerWidget` (lo es, según líneas 67-71). Reemplazar (línea ~88):

```dart
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
```

por:

```dart
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        adAwareBottomPadding(context, ref, extra: 16),
      ),
```

### Step 3.3: Run tests

Run: `flutter test test/ui/features/tasks/skins/futurista/`
Expected: todos verdes.

### Step 3.4: `flutter analyze`

Run: `flutter analyze lib test`
Expected: 0 errores.

### Step 3.5: Commit

```bash
git add lib/features/tasks/presentation/skins/futurista/all_tasks_screen_futurista.dart \
        lib/features/tasks/presentation/skins/futurista/task_detail_screen_futurista.dart
git commit -m "fix(skin): padding ad-aware en all_tasks/task_detail futurista"
```

---

## Task 4: TaskCardFuturista con dos botones + actionable gating (Ola 4)

**Files:**
- Modify: `lib/shared/widgets/futurista/task_card_futurista.dart`
- Modify: `lib/features/tasks/presentation/skins/futurista/today_screen_futurista.dart`
- Modify: `test/ui/shared/widgets/futurista/task_card_futurista_test.dart`

### Step 4.1: Escribir tests fallidos para nueva signatura

- [ ] Reemplazar el contenido completo de `test/ui/shared/widgets/futurista/task_card_futurista_test.dart` por:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/shared/widgets/futurista/task_card_futurista.dart';
import 'package:toka/shared/widgets/futurista/task_glyph.dart';

Widget harness(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders title and assignee', (tester) async {
    await tester.pumpWidget(harness(const TaskCardFuturista(
      title: 'Sacar basura',
      assignee: 'Ana',
      assigneeColor: Color(0xFF38BDF8),
      when: 'vence 11:30',
      glyph: TaskGlyphKind.ring,
    )));
    expect(find.text('Sacar basura'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('· vence 11:30'), findsOneWidget);
  });

  testWidgets('mine + actionable shows [Hecho][Pasar] row, fires onComplete and onPass',
      (tester) async {
    var completed = false;
    var passed = false;
    await tester.pumpWidget(harness(TaskCardFuturista(
      title: 't',
      assignee: 'A',
      assigneeColor: const Color(0xFF38BDF8),
      mine: true,
      actionable: true,
      onComplete: () => completed = true,
      onPass: () => passed = true,
    )));
    final doneBtn = find.byKey(const Key('task_card_done_btn'));
    final passBtn = find.byKey(const Key('task_card_pass_btn'));
    expect(doneBtn, findsOneWidget);
    expect(passBtn, findsOneWidget);
    await tester.tap(doneBtn);
    expect(completed, true);
    await tester.tap(passBtn);
    expect(passed, true);
  });

  testWidgets('mine + NOT actionable: tap done fires onActionableHint, not onComplete',
      (tester) async {
    var completed = false;
    var hinted = false;
    await tester.pumpWidget(harness(TaskCardFuturista(
      title: 't',
      assignee: 'A',
      assigneeColor: const Color(0xFF38BDF8),
      mine: true,
      actionable: false,
      onComplete: () => completed = true,
      onActionableHint: () => hinted = true,
    )));
    expect(find.byIcon(Icons.lock_clock), findsOneWidget);
    await tester.tap(find.byKey(const Key('task_card_done_btn')));
    expect(completed, false);
    expect(hinted, true);
  });

  testWidgets('mine + done hides buttons row and applies strikethrough',
      (tester) async {
    await tester.pumpWidget(harness(const TaskCardFuturista(
      title: 't',
      assignee: 'A',
      assigneeColor: Color(0xFF38BDF8),
      mine: true,
      done: true,
    )));
    expect(find.byKey(const Key('task_card_done_btn')), findsNothing);
    expect(find.byKey(const Key('task_card_pass_btn')), findsNothing);
    final titleText = tester.widget<Text>(find.text('t'));
    expect(titleText.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('!mine shows lock icon in right slot, no buttons row',
      (tester) async {
    await tester.pumpWidget(harness(const TaskCardFuturista(
      title: 't',
      assignee: 'A',
      assigneeColor: Color(0xFF38BDF8),
    )));
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.byKey(const Key('task_card_done_btn')), findsNothing);
    expect(find.byKey(const Key('task_card_pass_btn')), findsNothing);
  });

  testWidgets('onTap fires when card body tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(harness(TaskCardFuturista(
      title: 't',
      assignee: 'A',
      assigneeColor: const Color(0xFF38BDF8),
      onTap: () => tapped = true,
    )));
    await tester.tap(find.byType(TaskCardFuturista));
    expect(tapped, true);
  });
}
```

### Step 4.2: Verificar que los tests fallan

Run: `flutter test test/ui/shared/widgets/futurista/task_card_futurista_test.dart`
Expected: FAIL — el campo `actionable` no existe, los keys no existen.

### Step 4.3: Reescribir `TaskCardFuturista`

- [ ] Reemplazar el contenido completo de `lib/shared/widgets/futurista/task_card_futurista.dart` por:

```dart
import 'package:flutter/material.dart';

import 'task_glyph.dart';
import 'tocka_avatar.dart';
import 'tocka_btn.dart';

/// Tarjeta de tarea futurista. Estados: mine (glow + fila inferior con
/// [Hecho][Pasar]), done (tachado), urgent (warning color), overdue (danger).
///
/// Cuando `mine && !done`, debajo del row principal aparece una fila con dos
/// botones: `TockaBtn glow lg fullWidth icon=check` (Hecho) + `TockaBtn ghost
/// lg icon=swap_horiz` (Pasar). El botón Hecho aplica gating: si `actionable`
/// es false, se renderiza con icono `lock_clock` y al pulsarlo invoca
/// `onActionableHint` en vez de `onComplete`. La card NO conoce
/// `task.nextDueAt` ni `recurrenceType`, así que el cálculo de `actionable`
/// y el formato del SnackBar viven en el consumidor.
///
/// `onTap` representa "tap general en la card" (para navegar al detalle).
/// Es independiente de `onComplete`/`onPass`.
class TaskCardFuturista extends StatelessWidget {
  const TaskCardFuturista({
    super.key,
    required this.title,
    required this.assignee,
    required this.assigneeColor,
    this.when,
    this.done = false,
    this.glyph = TaskGlyphKind.ring,
    this.urgent = false,
    this.overdue = false,
    this.mine = false,
    this.compact = false,
    this.actionable = true,
    this.onTap,
    this.onComplete,
    this.onPass,
    this.onActionableHint,
    this.doneLabel = 'Hecho',
  });

  final String title;
  final String assignee;
  final Color assigneeColor;
  final String? when;
  final bool done;
  final TaskGlyphKind glyph;
  final bool urgent;
  final bool overdue;
  final bool mine;
  final bool compact;
  final bool actionable;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onPass;
  final VoidCallback? onActionableHint;
  final String doneLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Color glyphColor;
    if (urgent) {
      glyphColor = const Color(0xFFF5B544);
    } else if (mine) {
      glyphColor = cs.primary;
    } else {
      glyphColor = cs.onSurfaceVariant;
    }

    final borderColor = (mine && !done)
        ? cs.primary.withValues(alpha: 0.25)
        : theme.dividerColor;

    final bgColor = done ? Colors.transparent : cs.surface;

    final shadow = (mine && !done)
        ? [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.15),
              blurRadius: 0,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.35),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ]
        : null;

    final showButtonsRow = mine && !done;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(compact ? 12 : 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: shadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _leftSlot(context, glyphColor),
                  const SizedBox(width: 12),
                  Expanded(child: _center(context)),
                  if (!showButtonsRow) ...[
                    const SizedBox(width: 8),
                    _rightSlotForNonOwn(context, cs),
                  ],
                ],
              ),
              if (showButtonsRow) ...[
                const SizedBox(height: 12),
                _buttonsRow(context, cs),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _leftSlot(BuildContext context, Color glyphColor) {
    if (done) {
      return const SizedBox(
        width: 44,
        height: 44,
        child: Icon(Icons.check, color: Color(0xFF34D399), size: 20),
      );
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: glyphColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: glyphColor.withValues(alpha: 0.19),
          width: 1,
        ),
      ),
      child: Center(
        child: TaskGlyph(kind: glyph, color: glyphColor, size: 22),
      ),
    );
  }

  Widget _center(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.15,
            color: cs.onSurface,
            decoration: done ? TextDecoration.lineThrough : null,
            decorationColor: cs.onSurface.withValues(alpha: 0.22),
          ),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Text(
              done ? 'Hecho por ' : 'Toca a ',
              style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant),
            ),
            TockaAvatar(name: assignee, color: assigneeColor, size: 16),
            const SizedBox(width: 5),
            Text(
              assignee,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            if (when != null) ...[
              const SizedBox(width: 6),
              Text(
                '· $when',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'JetBrainsMono',
                  letterSpacing: 0.2,
                  color: overdue
                      ? cs.error
                      : cs.onSurface.withValues(alpha: 0.42),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _rightSlotForNonOwn(BuildContext context, ColorScheme cs) {
    if (done) return const SizedBox.shrink();
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Icon(
        Icons.lock_outline,
        size: 14,
        color: cs.onSurface.withValues(alpha: 0.22),
      ),
    );
  }

  Widget _buttonsRow(BuildContext context, ColorScheme cs) {
    final isLocked = !actionable;
    return Row(
      children: [
        Expanded(
          child: TockaBtn(
            key: const Key('task_card_done_btn'),
            variant: isLocked ? TockaBtnVariant.ghost : TockaBtnVariant.glow,
            size: TockaBtnSize.lg,
            fullWidth: true,
            icon: Icon(isLocked ? Icons.lock_clock : Icons.check),
            onPressed: isLocked ? onActionableHint : onComplete,
            child: Text(doneLabel),
          ),
        ),
        const SizedBox(width: 8),
        TockaBtn(
          key: const Key('task_card_pass_btn'),
          variant: TockaBtnVariant.ghost,
          size: TockaBtnSize.lg,
          onPressed: onPass,
          child: const Icon(Icons.swap_horiz),
        ),
      ],
    );
  }
}
```

### Step 4.4: Verificar que los tests pasan

Run: `flutter test test/ui/shared/widgets/futurista/task_card_futurista_test.dart`
Expected: 6 tests verdes.

### Step 4.5: Cablear `today_screen_futurista` con `actionable`, `onPass` separado y `onTap` a detalle

- [ ] Editar `lib/features/tasks/presentation/skins/futurista/today_screen_futurista.dart`. Añadir import al inicio:

```dart
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/routes.dart';
import '../../../../../core/utils/toka_dates.dart';
```

(`go_router` y `routes.dart` para el push, `toka_dates.dart` para formatear el SnackBar.)

- [ ] Añadir helpers privados al final de la clase `TodayScreenFuturista` (después de `_whenLabel`):

```dart
  /// Determina si la tarea puede completarse ahora según su tipo de
  /// recurrencia. Lógica idéntica a `_TodayTaskCardTodoV2State._isActionable`
  /// para mantener paridad con la skin v2.
  bool _isActionable(TaskPreview t, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final due = t.nextDueAt;
    if (due.isBefore(n)) return true;
    switch (t.recurrenceType) {
      case 'hourly':
        final hourEnd = DateTime(n.year, n.month, n.day, n.hour + 1);
        return due.isBefore(hourEnd);
      case 'daily':
        final dayEnd = DateTime(n.year, n.month, n.day + 1);
        return due.isBefore(dayEnd);
      case 'weekly':
        final daysFromMonday = n.weekday - 1;
        final weekStart = DateTime(n.year, n.month, n.day - daysFromMonday);
        final weekEnd = weekStart.add(const Duration(days: 7));
        return due.isBefore(weekEnd);
      case 'monthly':
        final monthEnd = DateTime(n.year, n.month + 1, 1);
        return due.isBefore(monthEnd);
      case 'yearly':
        final yearEnd = DateTime(n.year + 1, 1, 1);
        return due.isBefore(yearEnd);
      default:
        final dayEnd = DateTime(n.year, n.month, n.day + 1);
        return due.isBefore(dayEnd);
    }
  }

  /// Formato del mensaje "aún no es momento — vence el {date}" según el tipo
  /// de recurrencia. Mismas reglas que `_TodayTaskCardTodoV2State._formatDueForMessage`.
  String _formatDueForMessage(BuildContext context, TaskPreview t) {
    final locale = Localizations.localeOf(context);
    final due = t.nextDueAt.toLocal();
    switch (t.recurrenceType) {
      case 'hourly':
        return TokaDates.timeShort(due, locale);
      case 'daily':
        return '${TokaDates.dateMediumWithWeekday(due, locale)} · '
            '${TokaDates.timeShort(due, locale)}';
      case 'weekly':
        return TokaDates.dateMediumWithWeekday(due, locale);
      case 'monthly':
        return TokaDates.dateLongDayMonth(due, locale);
      case 'yearly':
        return TokaDates.monthYearLong(due, locale);
      default:
        return '${TokaDates.dateMediumWithWeekday(due, locale)} · '
            '${TokaDates.timeShort(due, locale)}';
    }
  }

  void _snackNotYet(BuildContext ctx, AppLocalizations l10n, TaskPreview t) {
    final dateStr = _formatDueForMessage(ctx, t);
    ScaffoldMessenger.of(ctx)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(l10n.today_hecho_not_yet(dateStr)),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ));
  }
```

- [ ] Localizar el helper `_recurrenceBlock` (líneas ~205-250). Reemplazar el `itemBuilder` interno (la sección que crea cada `TaskCardFuturista`):

```dart
          itemBuilder: (ctx, i) {
            final t = todos[i];
            final isMine = t.currentAssigneeUid != null &&
                t.currentAssigneeUid == currentUid;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TaskCardFuturista(
                key: Key('task_card_fut_${t.taskId}'),
                title: t.title,
                assignee: t.currentAssigneeName ?? '—',
                assigneeColor: _colorFromUid(t.currentAssigneeUid),
                when: _whenLabel(ctx, t),
                glyph: _glyphForRecurrence(recType),
                mine: isMine && !t.isOverdue ? true : isMine,
                overdue: t.isOverdue,
                urgent: t.isOverdue,
                onTap: onPass == null ? null : () => onPass(t),
                onComplete: onDone == null ? null : () => onDone(t),
              ),
            );
          },
```

por:

```dart
          itemBuilder: (ctx, i) {
            final t = todos[i];
            final isMine = t.currentAssigneeUid != null &&
                t.currentAssigneeUid == currentUid;
            final l10n = AppLocalizations.of(ctx);
            final actionable = _isActionable(t);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TaskCardFuturista(
                key: Key('task_card_fut_${t.taskId}'),
                title: t.title,
                assignee: t.currentAssigneeName ?? '—',
                assigneeColor: _colorFromUid(t.currentAssigneeUid),
                when: _whenLabel(ctx, t),
                glyph: _glyphForRecurrence(recType),
                mine: isMine,
                overdue: t.isOverdue,
                urgent: t.isOverdue,
                actionable: actionable,
                doneLabel: l10n.today_btn_done,
                onTap: () => ctx.push(
                  AppRoutes.taskDetail.replaceAll(':id', t.taskId),
                ),
                onComplete: onDone == null ? null : () => onDone(t),
                onPass: onPass == null ? null : () => onPass(t),
                onActionableHint: () => _snackNotYet(ctx, l10n, t),
              ),
            );
          },
```

### Step 4.6: Run all tests

Run: `flutter test`
Expected: todos verdes.

### Step 4.7: `flutter analyze`

Run: `flutter analyze lib test`
Expected: 0 errores.

### Step 4.8: Commit

```bash
git add lib/shared/widgets/futurista/task_card_futurista.dart \
        lib/features/tasks/presentation/skins/futurista/today_screen_futurista.dart \
        test/ui/shared/widgets/futurista/task_card_futurista_test.dart
git commit -m "feat(skin): TaskCardFuturista con botón Pasar + actionable gating + SnackBar"
```

---

## Task 5: History futurista navegable + valorar + banner premium (Ola 5)

**Files:**
- Create: `lib/shared/widgets/futurista/premium_banner_futurista.dart`
- Modify: `lib/features/history/presentation/skins/futurista/history_screen_futurista.dart`
- Modify: `test/ui/features/history/skins/futurista/history_screen_futurista_test.dart`

### Step 5.1: Crear `PremiumBannerFuturista`

- [ ] Crear archivo `lib/shared/widgets/futurista/premium_banner_futurista.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../l10n/app_localizations.dart';
import 'tocka_btn.dart';

/// Banner intercalado para usuarios free en history futurista.
/// Reusa los strings `history_premium_banner_*` de v2 con un look acorde
/// al lenguaje futurista (surfaceContainerHighest + border primary muted).
class PremiumBannerFuturista extends ConsumerWidget {
  const PremiumBannerFuturista({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return Container(
      key: const Key('premium_banner_futurista'),
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.lock, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.history_premium_banner_title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.history_premium_banner_body,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          TockaBtn(
            key: const Key('premium_banner_futurista_cta'),
            variant: TockaBtnVariant.primary,
            size: TockaBtnSize.md,
            fullWidth: true,
            onPressed: () => context.push(AppRoutes.paywall),
            child: Text(l10n.history_premium_banner_cta),
          ),
        ],
      ),
    );
  }
}
```

### Step 5.2: Actualizar `history_screen_futurista.dart` con tap, trailing star y banner premium

- [ ] Editar `lib/features/history/presentation/skins/futurista/history_screen_futurista.dart`. Añadir imports al inicio:

```dart
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/routes.dart';
import '../../../../../shared/widgets/bottom_sheet_padding.dart';
import '../../../../../shared/widgets/futurista/premium_banner_futurista.dart';
import '../../widgets/rate_event_sheet.dart';
```

- [ ] En el `ListView.builder` (líneas ~126-144), reemplazar:

```dart
                  return ListView.builder(
                    key: const Key('history_list_futurista'),
                    controller: _scroll,
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 4,
                      bottom:
                          adAwareBottomPadding(context, ref, extra: 80),
                    ),
                    itemCount: groups.length,
                    itemBuilder: (ctx, i) {
                      final g = groups[i];
                      return _DayGroup(
                        label: g.label,
                        items: g.items,
                      );
                    },
                  );
```

por:

```dart
                  final showPremiumBanner = !vm.isPremium;
                  final extras = showPremiumBanner ? 1 : 0;
                  return ListView.builder(
                    key: const Key('history_list_futurista'),
                    controller: _scroll,
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 4,
                      bottom: adAwareBottomPadding(context, ref, extra: 16),
                    ),
                    itemCount: groups.length + extras,
                    itemBuilder: (ctx, i) {
                      if (i >= groups.length) {
                        return const PremiumBannerFuturista();
                      }
                      final g = groups[i];
                      return _DayGroup(
                        label: g.label,
                        items: g.items,
                        isPremium: vm.isPremium,
                        onRate: (item) => _showRateSheet(ctx, vm, item),
                        onUpgradeFromRate: () => _showUpgradeSheet(ctx),
                      );
                    },
                  );
```

- [ ] Añadir métodos privados de la clase `_HistoryScreenFuturistaState` después de `_groupByDay`:

```dart
  void _showRateSheet(
    BuildContext ctx,
    HistoryViewModel vm,
    TaskEventItem item,
  ) {
    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      builder: (_) => RateEventSheet(
        onSubmit: (rating, note) =>
            vm.rateEvent(item.raw.id, rating, note: note),
      ),
    );
  }

  void _showUpgradeSheet(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx);
    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + bottomSheetSafeBottom(sheetCtx, ref, hasNavBar: true),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.star, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.free_reviews_upgrade_title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Text(l10n.free_reviews_upgrade_body),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('btn_upgrade_from_rate_fut'),
                onPressed: () {
                  Navigator.of(sheetCtx).pop();
                  ctx.push(AppRoutes.paywall);
                },
                child: Text(l10n.free_go_premium_cta),
              ),
            ),
          ],
        ),
      ),
    );
  }
```

- [ ] En la clase `_DayGroup`, añadir parámetros y propagar a `_EventRow`:

Reemplazar la definición de `_DayGroup`:

```dart
class _DayGroup extends StatelessWidget {
  const _DayGroup({required this.label, required this.items});

  final String label;
  final List<TaskEventItem> items;
```

por:

```dart
class _DayGroup extends StatelessWidget {
  const _DayGroup({
    required this.label,
    required this.items,
    required this.isPremium,
    required this.onRate,
    required this.onUpgradeFromRate,
  });

  final String label;
  final List<TaskEventItem> items;
  final bool isPremium;
  final void Function(TaskEventItem) onRate;
  final VoidCallback onUpgradeFromRate;
```

Y dentro del `Column` que renderiza items, reemplazar:

```dart
            for (final it in items) ...[
              _EventRow(item: it),
              const SizedBox(height: 8),
            ],
```

por:

```dart
            for (final it in items) ...[
              _EventRow(
                item: it,
                isPremium: isPremium,
                onRate: () => onRate(it),
                onUpgradeFromRate: onUpgradeFromRate,
              ),
              const SizedBox(height: 8),
            ],
```

- [ ] Modificar `_EventRow` para añadir tap navegable, trailing star y consumir los nuevos props. Reemplazar la clase entera por:

```dart
class _EventRow extends ConsumerWidget {
  const _EventRow({
    required this.item,
    required this.isPremium,
    required this.onRate,
    required this.onUpgradeFromRate,
  });

  final TaskEventItem item;
  final bool isPremium;
  final VoidCallback onRate;
  final VoidCallback onUpgradeFromRate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    final kind = _kindOf(item.raw);
    final (iconData, iconColor, bg, border) = switch (kind) {
      _EventKind.done => (
          Icons.check,
          FuturistaColors.success,
          FuturistaColors.success.withValues(alpha: 0.09),
          FuturistaColors.success.withValues(alpha: 0.25),
        ),
      _EventKind.pass => (
          Icons.switch_account,
          FuturistaColors.warning,
          FuturistaColors.warning.withValues(alpha: 0.09),
          FuturistaColors.warning.withValues(alpha: 0.25),
        ),
      _EventKind.sys => (
          Icons.settings,
          cs.onSurfaceVariant,
          cs.surfaceContainerHighest,
          theme.dividerColor,
        ),
    };

    final description = _descriptionFor(item, l10n);
    final timeLabel = _timeLabel(_eventDate(item.raw).toLocal());

    final trailing = _buildTrailing();

    final body = Container(
      key: Key('history_row_fut_${item.raw.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: border),
            ),
            child: Icon(iconData, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    TockaAvatar(
                      name: item.actorName,
                      color: _avatarColor(item),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeLabel,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10.5,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing,
          ],
        ],
      ),
    );

    final isDetailable = item.raw is CompletedEvent || item.raw is PassedEvent;
    final homeId = ref.read(currentHomeProvider).valueOrNull?.id;
    if (isDetailable && homeId != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('history_tile_tap_${item.raw.id}'),
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push(
            AppRoutes.historyEventDetail
                .replaceFirst(':homeId', homeId)
                .replaceFirst(':eventId', item.raw.id),
          ),
          child: body,
        ),
      );
    }
    return body;
  }

  Widget? _buildTrailing() {
    if (isPremium) {
      if (item.isRated) {
        return const Icon(Icons.star, color: Colors.amber, size: 18);
      }
      if (item.canRate) {
        return IconButton(
          key: Key('rate_button_fut_${item.raw.id}'),
          icon: const Icon(Icons.star_border),
          iconSize: 18,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: onRate,
        );
      }
      return null;
    }
    final isRateable = item.raw is CompletedEvent && !item.isOwnEvent;
    if (isRateable) {
      return IconButton(
        key: Key('rate_upgrade_fut_${item.raw.id}'),
        icon: Icon(Icons.star_border, color: Colors.grey.shade500),
        iconSize: 18,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        onPressed: onUpgradeFromRate,
      );
    }
    return null;
  }

  Color _avatarColor(TaskEventItem it) {
    final palette = <Color>[
      FuturistaColors.primary,
      FuturistaColors.primaryAlt,
      FuturistaColors.success,
      FuturistaColors.warning,
      FuturistaColors.error,
    ];
    final seed = it.actorName.codeUnits.fold<int>(0, (a, b) => a + b);
    return palette[seed % palette.length];
  }

  _EventKind _kindOf(TaskEvent e) => switch (e) {
        CompletedEvent _ => _EventKind.done,
        PassedEvent _ => _EventKind.pass,
        MissedEvent _ => _EventKind.sys,
      };

  String _descriptionFor(TaskEventItem it, AppLocalizations l10n) {
    final e = it.raw;
    return switch (e) {
      CompletedEvent c =>
        '${l10n.history_event_completed(it.actorName)} · ${c.taskTitleSnapshot}',
      PassedEvent p =>
        '${it.actorName} → ${it.toName ?? '?'} · ${p.taskTitleSnapshot}',
      MissedEvent m =>
        '${l10n.history_event_missed(it.actorName)} · ${m.taskTitleSnapshot}',
    };
  }

  String _timeLabel(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
```

Notas:
- `_EventRow` pasa de `StatelessWidget` a `ConsumerWidget` para poder leer `currentHomeProvider`.
- El padding del ListView pasa de `extra: 80` a `extra: 16` (consistente con resto).

### Step 5.3: Añadir tests al wrapper de history futurista

- [ ] Editar `test/ui/features/history/skins/futurista/history_screen_futurista_test.dart`. Añadir 3 tests al final del `void main()`. El fake actual `_FakeHistoryViewModel` tiene `isPremium: false` e `items: []`. Hay que extender para emitir items concretos.

Reemplazar la clase `_FakeHistoryViewModel` por:

```dart
class _FakeHistoryViewModel implements HistoryViewModel {
  _FakeHistoryViewModel({
    this.itemsList = const <TaskEventItem>[],
    this.premium = false,
  });

  final List<TaskEventItem> itemsList;
  final bool premium;

  @override
  AsyncValue<List<TaskEventItem>> get items => AsyncValue.data(itemsList);

  @override
  HistoryFilter get filter => const HistoryFilter();

  @override
  bool get hasMore => false;

  @override
  bool get isPremium => premium;

  @override
  bool get hasHome => true;

  @override
  void loadMore() {}

  @override
  void applyFilter(HistoryFilter newFilter) {}

  @override
  Future<void> rateEvent(String eventId, double rating, {String? note}) async {}
}
```

- [ ] Añadir helper para construir un `TaskEventItem` de test al inicio del archivo (después de los imports):

```dart
TaskEventItem _completedItem({
  required String id,
  bool isOwnEvent = false,
  bool isRated = false,
  bool canRate = false,
}) {
  final ev = CompletedEvent(
    id: id,
    homeId: 'h1',
    taskId: 't1',
    taskTitleSnapshot: 'Sacar basura',
    completedAt: DateTime(2026, 4, 25, 10, 0),
    completedByUid: 'u-actor',
  );
  return TaskEventItem(
    raw: ev,
    actorName: 'Ana',
    isOwnEvent: isOwnEvent,
    isRated: isRated,
    canRate: canRate,
  );
}
```

Y añadir el import necesario:

```dart
import 'package:toka/features/history/domain/task_event.dart';
```

- [ ] Añadir tres tests al final de `void main()`:

```dart
  testWidgets('futurista: free user sees PremiumBannerFuturista at end of list',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {SkinMode.persistKey: AppSkin.futurista.persistKey});
    final c = ProviderContainer(overrides: [
      historyViewModelProvider.overrideWith(
        (ref) => _FakeHistoryViewModel(
          itemsList: [_completedItem(id: 'e1')],
          premium: false,
        ),
      ),
      authProvider.overrideWith(_FakeAuth.new),
      currentHomeProvider.overrideWith(_FakeCurrentHome.new),
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(_harness(container: c));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    expect(find.byKey(const Key('premium_banner_futurista')), findsOneWidget);
  });

  testWidgets('futurista: premium user does NOT see PremiumBannerFuturista',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {SkinMode.persistKey: AppSkin.futurista.persistKey});
    final c = ProviderContainer(overrides: [
      historyViewModelProvider.overrideWith(
        (ref) => _FakeHistoryViewModel(
          itemsList: [_completedItem(id: 'e1')],
          premium: true,
        ),
      ),
      authProvider.overrideWith(_FakeAuth.new),
      currentHomeProvider.overrideWith(_FakeCurrentHome.new),
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(_harness(container: c));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    expect(find.byKey(const Key('premium_banner_futurista')), findsNothing);
  });

  testWidgets('futurista: premium user sees star rate button on canRate event',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {SkinMode.persistKey: AppSkin.futurista.persistKey});
    final c = ProviderContainer(overrides: [
      historyViewModelProvider.overrideWith(
        (ref) => _FakeHistoryViewModel(
          itemsList: [_completedItem(id: 'e1', canRate: true)],
          premium: true,
        ),
      ),
      authProvider.overrideWith(_FakeAuth.new),
      currentHomeProvider.overrideWith(_FakeCurrentHome.new),
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(_harness(container: c));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    expect(find.byKey(const Key('rate_button_fut_e1')), findsOneWidget);
  });
```

Nota: el constructor exacto de `CompletedEvent` puede tener parámetros adicionales (`completedByPhotoUrl`, etc.). Revisar el archivo `lib/features/history/domain/task_event.dart` y completar los args requeridos. Los tests fallarán claramente si falta algo.

### Step 5.4: Run tests y verificar

Run: `flutter test test/ui/features/history/skins/futurista/history_screen_futurista_test.dart`
Expected: los 3 tests nuevos verdes + los 2 existentes verdes.

Si fallan por la firma de `CompletedEvent`, abrir [lib/features/history/domain/task_event.dart](lib/features/history/domain/task_event.dart) y completar los argumentos requeridos.

### Step 5.5: Run all tests

Run: `flutter test`
Expected: todos verdes.

### Step 5.6: `flutter analyze`

Run: `flutter analyze lib test`
Expected: 0 errores.

### Step 5.7: Commit

```bash
git add lib/shared/widgets/futurista/premium_banner_futurista.dart \
        lib/features/history/presentation/skins/futurista/history_screen_futurista.dart \
        test/ui/features/history/skins/futurista/history_screen_futurista_test.dart
git commit -m "feat(skin): History futurista navegable + valorar + banner premium"
```

---

## Verificación final manual (después de Task 5)

Antes de cerrar la spec como DONE, ejecutar las siguientes pruebas manuales según §9 de la spec:

1. **AdBanner shell futurista:** instalar APK con `flutter run -d 43340fd2`, activar skin futurista. Verificar AdBanner real visible al pie en Hoy/Tareas/Historial/Miembros. Oculto en Ajustes.

   ```bash
   adb -s 43340fd2 shell input tap 937 [Y_de_navbar]   # tab Ajustes
   adb -s 43340fd2 exec-out screencap -p > c:/tmp/screen_settings.png
   ```

2. **Scroll a fondo:** en cada tab, scrollear hasta el final y verificar que el último item se ve completo por encima del banner.

3. **PopScope:** desde la tab Tareas, pulsar BACK físico (`adb shell input keyevent 4`). Verificar que vuelve a Hoy. Desde Hoy, BACK → cierra app.

4. **TaskCardFuturista [Hecho][Pasar]:** en Hoy, identificar tarea propia. Verificar que muestra los 2 botones lado a lado. Tap "Pasar" → abre `PassTurnDialog`. Tap zona vacía de la card → navega a detalle.

5. **Actionable gating:** crear (vía UI) tarea semanal para próxima semana. En Hoy, tap "Hecho" → SnackBar visible con texto "El botón 'Hecho' estará activo el {fecha}". La tarea NO se completa.

6. **History tap:** en Historial, tap en evento "completada" → navega a detalle.

7. **History rate (premium):** activar Premium debug. Verificar estrella en eventos rateable. Tap → `RateEventSheet`.

8. **History rate (free):** desactivar Premium debug. Verificar estrella muted en eventos rateable de otros. Tap → upgrade sheet.

9. **History premium banner:** como free, verificar banner intercalado al final de la lista.

10. **Toggle skin Clásico ↔ Futurista:** ambos skins funcionan sin regresión.

---

## Self-review checklist

- [x] **Spec coverage:** las 9 decisiones de §3 mapean a Tasks 1-5. AC1-AC11 mapean a Steps + verificación manual.
- [x] **Placeholder scan:** ninguno; todos los pasos contienen código completo.
- [x] **Type consistency:** `actionable: bool`, `onActionableHint: VoidCallback?`, `doneLabel: String` son consistentes entre la spec, el widget y los tests. `shellMetricsProvider` consumido en la misma forma en ambos shells y en `adAwareBottomPadding`.
- [x] **No types undefined:** `MainShellV2Metrics`, `MainShellFuturistaMetrics`, `ShellMetrics`, `PremiumBannerFuturista` se crean en Task 1/5 antes de ser referenciadas.
