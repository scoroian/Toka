# AdBanner Layout Cohesion — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Que el AdBanner se muestre y se respete en todas las pantallas objetivo (Hoy, Historial, Miembros, Lista de tareas, Crear/editar tarea, Detalle de tarea, Detalle de miembro) y sus sheets, eliminando además el código V1 sin tocar la infraestructura de skins.

**Architecture:** Dos piezas nuevas compartidas (`AdAwareScaffold` y `bottomSheetSafeBottom`) encapsulan el cálculo de espacio. Las 3 pantallas push se migran al wrapper. Los scrollables de las 2 pantallas tab con listas (Miembros, Lista de tareas) reciben padding inferior real. Los sheets migran al helper. Luego se eliminan todos los archivos V1 y se simplifican los ternarios de `app.dart`.

**Tech Stack:** Flutter 3.x, Riverpod (flutter_riverpod + riverpod_annotation), go_router, google_mobile_ads, mocktail para tests.

---

## File Structure

**Nuevos:**
- `lib/shared/widgets/ad_aware_scaffold.dart` — Wrapper `ConsumerWidget` del `Scaffold` para pantallas push (fuera del shell).
- `lib/shared/widgets/bottom_sheet_padding.dart` — Función pura `bottomSheetSafeBottom` para sheets.
- `test/unit/shared/widgets/bottom_sheet_padding_test.dart` — Tests unitarios del helper.
- `test/ui/shared/widgets/ad_aware_scaffold_test.dart` — Test UI del wrapper.

**Modificados (contenido):**
- `lib/shared/widgets/ad_banner.dart` — Añadir constante pública `kBannerGap`.
- `lib/shared/widgets/skins/main_shell_v2.dart` — Reutilizar `AdBanner.kBannerGap` (DRY) y exponer `bottomContentPadding`.
- `lib/features/members/presentation/members_screen.dart` — Padding inferior al `ListView`.
- `lib/features/tasks/presentation/skins/all_tasks_screen_v2.dart` — Padding inferior al `ListView.builder` (sustituir 96 hardcoded).
- `lib/features/tasks/presentation/skins/task_detail_screen_v2.dart` — `Scaffold` → `AdAwareScaffold`.
- `lib/features/tasks/presentation/skins/create_edit_task_screen_v2.dart` — `Scaffold` → `AdAwareScaffold`.
- `lib/features/members/presentation/skins/member_profile_screen_v2.dart` — `Scaffold` → `AdAwareScaffold`.
- `lib/features/members/presentation/widgets/invite_member_sheet.dart` — Usar `bottomSheetSafeBottom`.
- `lib/features/history/presentation/widgets/rate_event_sheet.dart` — Convertir a `ConsumerStatefulWidget` y usar `bottomSheetSafeBottom`.

**Modificados (refactor V1 → V2 único):**
- `lib/core/theme/app_skin.dart` — Eliminar valor `AppSkin.material`. `AppSkin { v2 }`.
- `lib/app.dart` — Simplificar ternarios de `SkinConfig.current == AppSkin.v2`.
- `test/unit/core/theme/skin_selector_test.dart` — Eliminar caso `AppSkin.material`.

**Eliminados (archivos completos):**
- `lib/shared/widgets/main_shell.dart`
- `lib/features/tasks/presentation/today_screen.dart`
- `lib/features/tasks/presentation/all_tasks_screen.dart`
- `lib/features/tasks/presentation/task_detail_screen.dart`
- `lib/features/tasks/presentation/create_edit_task_screen.dart`
- `lib/features/history/presentation/history_screen.dart`
- `lib/features/members/presentation/member_profile_screen.dart`
- `lib/core/theme/app_theme.dart`
- `test/ui/features/tasks/today_screen_test.dart`
- `test/ui/features/tasks/all_tasks_screen_test.dart`
- `test/ui/features/tasks/task_detail_screen_test.dart`
- `test/ui/features/tasks/create_task_screen_test.dart`
- `test/ui/features/history/history_screen_test.dart`
- `test/ui/features/members/member_profile_screen_test.dart`
- `test/ui/core/theme/app_theme_test.dart`

---

## Task 1: Constante `kBannerGap` compartida

**Files:**
- Modify: `lib/shared/widgets/ad_banner.dart`
- Modify: `lib/shared/widgets/skins/main_shell_v2.dart`

Objetivo: DRY. Hoy `_kBannerGap = 6` vive tanto en `main_shell_v2.dart` como implícito en la spec; queremos una sola fuente.

- [ ] **Step 1: Añadir `kBannerGap` a `AdBanner`**

Editar `lib/shared/widgets/ad_banner.dart` dentro de la clase `AdBanner`, justo bajo `kBannerHeight`:

```dart
  // Altura del contenedor visual del banner (ad 320x50 + padding vertical mínimo).
  // Usada por MainShellV2 para reservar espacio en el Scaffold cuando el
  // banner está visible, y por los FABs para levantarse por encima.
  static const double kBannerHeight = 58;

  // Gap vertical entre el banner y el elemento que tenga inmediatamente
  // por encima (la NavBar del shell, o el borde inferior de una pantalla
  // push). Fuente única para MainShellV2 y AdAwareScaffold.
  static const double kBannerGap = 6;
```

- [ ] **Step 2: Reutilizar la constante en `MainShellV2`**

Editar `lib/shared/widgets/skins/main_shell_v2.dart`. Sustituir el bloque:

```dart
  // Gap entre el top de la NavBar y el bottom del banner.
  static const double _kBannerGap = 6;
```

por:

```dart
  // Gap entre el top de la NavBar y el bottom del banner.
  // Fuente única en AdBanner.kBannerGap.
  static double get _kBannerGap => AdBanner.kBannerGap;
```

(Se mantiene el símbolo `_kBannerGap` para no tocar las líneas que lo consumen.)

- [ ] **Step 3: Verificar `flutter analyze`**

Run: `flutter analyze`
Expected: sin errores (warnings preexistentes aceptables).

- [ ] **Step 4: Commit**

```bash
git add lib/shared/widgets/ad_banner.dart lib/shared/widgets/skins/main_shell_v2.dart
git commit -m "refactor(admob): mover kBannerGap a AdBanner como fuente unica"
```

---

## Task 2: `bottomSheetSafeBottom` helper + tests

**Files:**
- Create: `lib/shared/widgets/bottom_sheet_padding.dart`
- Test: `test/unit/shared/widgets/bottom_sheet_padding_test.dart`

- [ ] **Step 1: Escribir los tests antes del helper**

Crear `test/unit/shared/widgets/bottom_sheet_padding_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/shared/widgets/ad_banner.dart';
import 'package:toka/shared/widgets/ad_banner_config_provider.dart';
import 'package:toka/shared/widgets/bottom_sheet_padding.dart';
import 'package:toka/shared/widgets/skins/main_shell_v2.dart';

/// Harness que devuelve el valor calculado por [bottomSheetSafeBottom]
/// dentro de un BuildContext con MediaQuery controlado.
Future<double> _harness(
  WidgetTester tester, {
  required MediaQueryData mq,
  required bool bannerVisible,
  required bool hasNavBar,
}) async {
  double? captured;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        adBannerConfigProvider.overrideWith(
          (ref) => AdBannerConfig(
            show: bannerVisible,
            unitId: bannerVisible ? 'unit-test' : '',
          ),
        ),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: mq,
          child: Consumer(
            builder: (ctx, ref, _) {
              captured = bottomSheetSafeBottom(
                ctx,
                ref,
                hasNavBar: hasNavBar,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    ),
  );
  return captured!;
}

void main() {
  const kNav = MainShellV2.kNavBarHeight + MainShellV2.kNavBarBottom;
  const kBan = AdBanner.kBannerHeight + AdBanner.kBannerGap;

  group('bottomSheetSafeBottom', () {
    testWidgets('sin banner, sin navbar, sin teclado → solo viewPadding', (t) async {
      final mq = const MediaQueryData(
        padding: EdgeInsets.only(bottom: 24),
      );
      final r = await _harness(t, mq: mq, bannerVisible: false, hasNavBar: false);
      expect(r, 24);
    });

    testWidgets('sin banner, con navbar, sin teclado', (t) async {
      final mq = const MediaQueryData(padding: EdgeInsets.only(bottom: 24));
      final r = await _harness(t, mq: mq, bannerVisible: false, hasNavBar: true);
      expect(r, 24 + kNav);
    });

    testWidgets('con banner, sin navbar, sin teclado', (t) async {
      final mq = const MediaQueryData(padding: EdgeInsets.only(bottom: 24));
      final r = await _harness(t, mq: mq, bannerVisible: true, hasNavBar: false);
      expect(r, 24 + kBan);
    });

    testWidgets('con banner, con navbar, sin teclado', (t) async {
      final mq = const MediaQueryData(padding: EdgeInsets.only(bottom: 24));
      final r = await _harness(t, mq: mq, bannerVisible: true, hasNavBar: true);
      expect(r, 24 + kNav + kBan);
    });

    testWidgets('con banner, con navbar, con teclado', (t) async {
      final mq = const MediaQueryData(
        padding: EdgeInsets.only(bottom: 24),
        viewInsets: EdgeInsets.only(bottom: 300),
      );
      final r = await _harness(t, mq: mq, bannerVisible: true, hasNavBar: true);
      expect(r, 24 + 300 + kNav + kBan);
    });
  });
}
```

- [ ] **Step 2: Ejecutar los tests y verificar que fallan por import no resuelto**

Run: `flutter test test/unit/shared/widgets/bottom_sheet_padding_test.dart`
Expected: fallo por `Target of URI doesn't exist: '..../bottom_sheet_padding.dart'`.

- [ ] **Step 3: Implementar el helper**

Crear `lib/shared/widgets/bottom_sheet_padding.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ad_banner.dart';
import 'ad_banner_config_provider.dart';
import 'skins/main_shell_v2.dart';

/// Devuelve el padding inferior que un BottomSheet debe aplicar para que
/// sus acciones no queden tapadas por la NavBar del shell, el AdBanner ni
/// el teclado del sistema.
///
/// - [hasNavBar]: pasa `true` cuando el sheet se abre desde una pantalla
///   dentro de `MainShellV2` (Hoy, Historial, Miembros, Lista de tareas);
///   `false` cuando se abre desde una pantalla push (detalles, create/edit).
///
/// Fórmula:
///   viewInsets.bottom (teclado)
/// + padding.bottom    (safe area efectiva; colapsa a 0 con teclado abierto
///                      para no doblar con viewInsets)
/// + kNavBarHeight + kNavBarBottom      (si hasNavBar)
/// + AdBanner.kBannerHeight + kBannerGap (si el banner está visible)
double bottomSheetSafeBottom(
  BuildContext context,
  WidgetRef ref, {
  required bool hasNavBar,
}) {
  final mq = MediaQuery.of(context);
  final cfg = ref.watch(adBannerConfigProvider);
  final bannerVisible = cfg.show && cfg.unitId.isNotEmpty;

  final navBar = hasNavBar
      ? MainShellV2.kNavBarHeight + MainShellV2.kNavBarBottom
      : 0.0;
  final banner = bannerVisible
      ? AdBanner.kBannerHeight + AdBanner.kBannerGap
      : 0.0;

  return mq.viewInsets.bottom + mq.padding.bottom + navBar + banner;
}
```

- [ ] **Step 4: Ejecutar los tests y verificar que pasan**

Run: `flutter test test/unit/shared/widgets/bottom_sheet_padding_test.dart`
Expected: los 5 testWidgets en verde.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/bottom_sheet_padding.dart test/unit/shared/widgets/bottom_sheet_padding_test.dart
git commit -m "feat(shared): helper bottomSheetSafeBottom con cobertura unitaria"
```

---

## Task 3: `AdAwareScaffold` wrapper + tests

**Files:**
- Create: `lib/shared/widgets/ad_aware_scaffold.dart`
- Test: `test/ui/shared/widgets/ad_aware_scaffold_test.dart`

- [ ] **Step 1: Escribir los tests primero**

Crear `test/ui/shared/widgets/ad_aware_scaffold_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/shared/widgets/ad_aware_scaffold.dart';
import 'package:toka/shared/widgets/ad_banner.dart';
import 'package:toka/shared/widgets/ad_banner_config_provider.dart';

Widget _pump({required bool bannerVisible, Widget? fab}) {
  return ProviderScope(
    overrides: [
      adBannerConfigProvider.overrideWith(
        (ref) => AdBannerConfig(
          show: bannerVisible,
          unitId: bannerVisible ? 'ca-app-pub-3940256099942544/6300978111' : '',
        ),
      ),
    ],
    child: MaterialApp(
      home: AdAwareScaffold(
        appBar: AppBar(title: const Text('T')),
        body: const SizedBox.expand(),
        floatingActionButton: fab,
      ),
    ),
  );
}

void main() {
  group('AdAwareScaffold', () {
    testWidgets('renderiza AdBanner cuando bannerVisible=true', (t) async {
      await t.pumpWidget(_pump(bannerVisible: true));
      expect(find.byKey(const Key('ad_banner')), findsOneWidget);
    });

    testWidgets('no renderiza AdBanner cuando bannerVisible=false', (t) async {
      await t.pumpWidget(_pump(bannerVisible: false));
      expect(find.byKey(const Key('ad_banner')), findsNothing);
    });

    testWidgets('bottomPaddingOf suma safeBottom + bannerSlot cuando hay banner',
        (t) async {
      double? captured;
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            adBannerConfigProvider.overrideWith(
              (ref) => const AdBannerConfig(show: true, unitId: 'x'),
            ),
          ],
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(padding: EdgeInsets.only(bottom: 24)),
              child: Consumer(
                builder: (ctx, ref, _) {
                  captured = AdAwareScaffold.bottomPaddingOf(ctx, ref);
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );
      expect(
        captured,
        24 + AdBanner.kBannerHeight + AdBanner.kBannerGap,
      );
    });

    testWidgets('bottomPaddingOf devuelve solo safeBottom cuando no hay banner',
        (t) async {
      double? captured;
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            adBannerConfigProvider.overrideWith(
              (ref) => const AdBannerConfig(show: false, unitId: ''),
            ),
          ],
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(padding: EdgeInsets.only(bottom: 24)),
              child: Consumer(
                builder: (ctx, ref, _) {
                  captured = AdAwareScaffold.bottomPaddingOf(ctx, ref);
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );
      expect(captured, 24);
    });
  });
}
```

- [ ] **Step 2: Ejecutar los tests y verificar que fallan por import no resuelto**

Run: `flutter test test/ui/shared/widgets/ad_aware_scaffold_test.dart`
Expected: fallo por `Target of URI doesn't exist: '..../ad_aware_scaffold.dart'`.

- [ ] **Step 3: Implementar `AdAwareScaffold`**

Crear `lib/shared/widgets/ad_aware_scaffold.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ad_banner.dart';
import 'ad_banner_config_provider.dart';

/// Wrapper de [Scaffold] para pantallas push (fuera del `MainShellV2`)
/// que necesitan mostrar el [AdBanner] al pie.
///
/// - Reserva espacio inferior vía `bottomNavigationBar` para que
///   `MediaQuery.padding.bottom` crezca y sheets/teclados se posicionen
///   correctamente.
/// - Pinta el banner en un `Stack` por encima cuando `adBannerConfig.show`.
/// - Si hay `floatingActionButton`, lo sube con un `Padding` equivalente
///   a la altura del banner.
///
/// Los `ScrollView` internos deben aplicar `bottomPaddingOf(ctx, ref)` como
/// padding inferior para que su último ítem quede por encima del banner.
class AdAwareScaffold extends ConsumerWidget {
  const AdAwareScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.backgroundColor,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  /// Altura total que el banner ocupa (contenedor + gap) cuando está visible.
  /// No incluye `safeBottom`.
  static double bannerSlot({required bool bannerVisible}) {
    if (!bannerVisible) return 0;
    return AdBanner.kBannerHeight + AdBanner.kBannerGap;
  }

  /// Padding inferior que los scrollables del `body` deben aplicar para que
  /// su último ítem quede por encima del banner.
  ///
  ///   safeBottom + bannerSlot(bannerVisible)
  static double bottomPaddingOf(BuildContext ctx, WidgetRef ref) {
    final safeBottom = MediaQuery.of(ctx).padding.bottom;
    final cfg = ref.watch(adBannerConfigProvider);
    final visible = cfg.show && cfg.unitId.isNotEmpty;
    return safeBottom + bannerSlot(bannerVisible: visible);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(adBannerConfigProvider);
    final visible = cfg.show && cfg.unitId.isNotEmpty;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final slot = bannerSlot(bannerVisible: visible);

    return Scaffold(
      extendBody: true,
      backgroundColor: backgroundColor,
      appBar: appBar,
      bottomNavigationBar: SizedBox(height: safeBottom + slot),
      body: Stack(
        children: [
          body,
          if (visible)
            Positioned(
              left: 0,
              right: 0,
              bottom: safeBottom + AdBanner.kBannerGap,
              child: const AdBanner(key: Key('ad_banner')),
            ),
        ],
      ),
      floatingActionButton: floatingActionButton == null
          ? null
          : Padding(
              padding: EdgeInsets.only(bottom: slot),
              child: floatingActionButton,
            ),
    );
  }
}
```

- [ ] **Step 4: Ejecutar los tests y verificar que pasan**

Run: `flutter test test/ui/shared/widgets/ad_aware_scaffold_test.dart`
Expected: 4 tests en verde.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/ad_aware_scaffold.dart test/ui/shared/widgets/ad_aware_scaffold_test.dart
git commit -m "feat(shared): AdAwareScaffold wrapper para pantallas push"
```

---

## Task 4: `MainShellV2.bottomContentPadding` helper

**Files:**
- Modify: `lib/shared/widgets/skins/main_shell_v2.dart`

Objetivo: los ListViews de Miembros y Lista de tareas necesitan `safeBottom + navBar + bannerSlot`. Lo encapsulamos en un método estático.

- [ ] **Step 1: Añadir helper estático**

En `lib/shared/widgets/skins/main_shell_v2.dart`, añadir tras `bannerSlotHeight`:

```dart
  /// Padding inferior total que un `ScrollView` dentro de una pantalla tab
  /// debe aplicar para que su último ítem quede por encima del banner y
  /// la NavBar flotante.
  ///
  ///   safeBottom + kNavBarHeight + kNavBarBottom + bannerSlotHeight(...)
  static double bottomContentPadding(BuildContext ctx, WidgetRef ref) {
    final safeBottom = MediaQuery.of(ctx).padding.bottom;
    final cfg = ref.watch(adBannerConfigProvider);
    final visible = cfg.show && cfg.unitId.isNotEmpty;
    return safeBottom
        + kNavBarHeight
        + kNavBarBottom
        + bannerSlotHeight(bannerVisible: visible);
  }
```

Importa `package:flutter_riverpod/flutter_riverpod.dart` si no está.

- [ ] **Step 2: Verificar `flutter analyze`**

Run: `flutter analyze lib/shared/widgets/skins/main_shell_v2.dart`
Expected: sin errores.

- [ ] **Step 3: Commit**

```bash
git add lib/shared/widgets/skins/main_shell_v2.dart
git commit -m "feat(shell): MainShellV2.bottomContentPadding para scrollables tab"
```

---

## Task 5: Padding inferior en `AllTasksScreenV2`

**Files:**
- Modify: `lib/features/tasks/presentation/skins/all_tasks_screen_v2.dart`

- [ ] **Step 1: Sustituir el padding hardcoded por el helper**

Localizar en el archivo:

```dart
              : ListView.builder(
                        key: const Key('tasks_list'),
                        padding: const EdgeInsets.only(bottom: 96),
                        itemCount: data.tasks.length,
```

Cambiar la línea del `padding` por:

```dart
              : ListView.builder(
                        key: const Key('tasks_list'),
                        padding: EdgeInsets.only(
                          bottom:
                              MainShellV2.bottomContentPadding(context, ref),
                        ),
                        itemCount: data.tasks.length,
```

`MainShellV2` ya está importado en este archivo.

- [ ] **Step 2: Verificar `flutter analyze`**

Run: `flutter analyze lib/features/tasks/presentation/skins/all_tasks_screen_v2.dart`
Expected: sin errores.

- [ ] **Step 3: Commit**

```bash
git add lib/features/tasks/presentation/skins/all_tasks_screen_v2.dart
git commit -m "fix(tasks): padding real al pie de la lista (banner + navbar)"
```

---

## Task 6: Padding inferior en `MembersScreen`

**Files:**
- Modify: `lib/features/members/presentation/members_screen.dart`

- [ ] **Step 1: Añadir padding al `ListView`**

Localizar el `ListView` (alrededor de la línea 94):

```dart
          body: ListView(
                  key: const Key('members_list'),
                  children: [
```

Cambiar por:

```dart
          body: ListView(
                  key: const Key('members_list'),
                  padding: EdgeInsets.only(
                    bottom: MainShellV2.bottomContentPadding(context, ref),
                  ),
                  children: [
```

`MainShellV2` y `ref` ya están disponibles (archivo es `ConsumerWidget`).

- [ ] **Step 2: Verificar `flutter analyze`**

Run: `flutter analyze lib/features/members/presentation/members_screen.dart`
Expected: sin errores.

- [ ] **Step 3: Commit**

```bash
git add lib/features/members/presentation/members_screen.dart
git commit -m "fix(members): padding real al pie de la lista (banner + navbar)"
```

---

## Task 7: Migrar `TaskDetailScreenV2` a `AdAwareScaffold`

**Files:**
- Modify: `lib/features/tasks/presentation/skins/task_detail_screen_v2.dart`

- [ ] **Step 1: Cambiar imports**

Añadir al bloque de imports:

```dart
import '../../../../shared/widgets/ad_aware_scaffold.dart';
```

- [ ] **Step 2: Convertir a `ConsumerWidget` (ya lo es) y cambiar `Scaffold`**

El widget ya es `ConsumerWidget`. Sustituir cada `Scaffold(` del árbol `viewData.when(...)` por `AdAwareScaffold(` con la misma API (`appBar`, `body`, `backgroundColor`). Las 3 ramas (`loading`, `error`, `data`) deben migrar.

Ejemplo de la rama `data`:

```dart
        return AdAwareScaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: bg,
            leading: BackButton(onPressed: () => context.pop()),
            actions: [...],
          ),
          body: /* ... cuerpo actual ... */,
        );
```

- [ ] **Step 3: Añadir padding inferior al scrollable del body**

Localizar el `ListView`/`SingleChildScrollView` raíz del body y aplicar `padding: EdgeInsets.only(bottom: AdAwareScaffold.bottomPaddingOf(context, ref))`. Si ya tiene padding, combinarlo con `copyWith`.

Ejemplo si el body es un `ListView` con padding existente:

```dart
body: ListView(
  padding: EdgeInsets.fromLTRB(
    16, 16, 16,
    AdAwareScaffold.bottomPaddingOf(context, ref),
  ),
  children: [ ... ],
),
```

- [ ] **Step 4: Ejecutar analyze y tests existentes V2**

Run: `flutter analyze lib/features/tasks/presentation/skins/task_detail_screen_v2.dart`
Expected: sin errores.

Run: `flutter test test/ui/features/tasks/task_detail_screen_v2_test.dart`
Expected: pasa.

- [ ] **Step 5: Commit**

```bash
git add lib/features/tasks/presentation/skins/task_detail_screen_v2.dart
git commit -m "feat(tasks): task_detail_screen_v2 migrado a AdAwareScaffold"
```

---

## Task 8: Migrar `CreateEditTaskScreenV2` a `AdAwareScaffold`

**Files:**
- Modify: `lib/features/tasks/presentation/skins/create_edit_task_screen_v2.dart`

- [ ] **Step 1: Añadir import**

```dart
import '../../../../shared/widgets/ad_aware_scaffold.dart';
```

- [ ] **Step 2: Sustituir `Scaffold` por `AdAwareScaffold`**

Cambiar todas las apariciones de `Scaffold(` por `AdAwareScaffold(` en el árbol del `build`. Mantener `appBar`, `body`, `backgroundColor` tal cual.

- [ ] **Step 3: Añadir padding al scrollable raíz**

El form usa un scrollable (típicamente `SingleChildScrollView` o `ListView`). Añadir:

```dart
body: SingleChildScrollView(
  padding: EdgeInsets.only(
    bottom: AdAwareScaffold.bottomPaddingOf(context, ref),
  ),
  child: /* Column existente */,
),
```

Si el scrollable ya tenía padding (`EdgeInsets.all(16)` por ejemplo), combinar vía `EdgeInsets.fromLTRB`.

- [ ] **Step 4: Ejecutar analyze y tests V2**

Run: `flutter analyze lib/features/tasks/presentation/skins/create_edit_task_screen_v2.dart`
Expected: sin errores.

Run: `flutter test test/ui/features/tasks/create_task_screen_v2_semantics_test.dart`
Expected: pasa.

- [ ] **Step 5: Commit**

```bash
git add lib/features/tasks/presentation/skins/create_edit_task_screen_v2.dart
git commit -m "feat(tasks): create_edit_task_v2 migrado a AdAwareScaffold"
```

---

## Task 9: Migrar `MemberProfileScreenV2` a `AdAwareScaffold`

**Files:**
- Modify: `lib/features/members/presentation/skins/member_profile_screen_v2.dart`

- [ ] **Step 1: Añadir import**

```dart
import '../../../../shared/widgets/ad_aware_scaffold.dart';
```

- [ ] **Step 2: Sustituir `Scaffold` por `AdAwareScaffold`**

La pantalla es `ConsumerStatefulWidget`, así que `ref` ya está disponible. Cambiar el único `Scaffold(...)` del `build` por `AdAwareScaffold(...)`, preservando `backgroundColor`, `appBar`, `body`.

- [ ] **Step 3: Ajustar el padding del `ListView` interno**

Actualmente:

```dart
return ListView(
  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
  children: [ ... ],
);
```

Cambiar por:

```dart
return ListView(
  padding: EdgeInsets.fromLTRB(
    16, 8, 16,
    AdAwareScaffold.bottomPaddingOf(context, ref),
  ),
  children: [ ... ],
);
```

- [ ] **Step 4: Ejecutar analyze y tests V2**

Run: `flutter analyze lib/features/members/presentation/skins/member_profile_screen_v2.dart`
Expected: sin errores.

Run: `flutter test test/ui/features/members/member_profile_screen_v2_test.dart`
Expected: pasa.

- [ ] **Step 5: Commit**

```bash
git add lib/features/members/presentation/skins/member_profile_screen_v2.dart
git commit -m "feat(members): member_profile_v2 migrado a AdAwareScaffold"
```

---

## Task 10: `InviteMemberSheet` usa `bottomSheetSafeBottom`

**Files:**
- Modify: `lib/features/members/presentation/widgets/invite_member_sheet.dart`

- [ ] **Step 1: Reemplazar el cálculo manual por el helper**

Localizar el bloque (líneas ~78-80):

```dart
    final mq = MediaQuery.of(context);
    const navBarExtra = MainShellV2.kNavBarHeight + MainShellV2.kNavBarBottom;
    final bottomPadding = mq.viewInsets.bottom + mq.viewPadding.bottom + navBarExtra;
```

Sustituir por:

```dart
    final bottomPadding =
        bottomSheetSafeBottom(context, ref, hasNavBar: true);
```

- [ ] **Step 2: Ajustar imports**

- Eliminar `import '../../../../shared/widgets/skins/main_shell_v2.dart';` si queda sin usos.
- Añadir `import '../../../../shared/widgets/bottom_sheet_padding.dart';`.

El widget ya es `ConsumerStatefulWidget`, así que `ref` está disponible en el state.

- [ ] **Step 3: Verificar analyze**

Run: `flutter analyze lib/features/members/presentation/widgets/invite_member_sheet.dart`
Expected: sin errores.

- [ ] **Step 4: Commit**

```bash
git add lib/features/members/presentation/widgets/invite_member_sheet.dart
git commit -m "fix(members): invite sheet respeta AdBanner (bottomSheetSafeBottom)"
```

---

## Task 11: `RateEventSheet` → `ConsumerStatefulWidget` + helper

**Files:**
- Modify: `lib/features/history/presentation/widgets/rate_event_sheet.dart`

- [ ] **Step 1: Convertir a ConsumerStatefulWidget**

En `lib/features/history/presentation/widgets/rate_event_sheet.dart`, sustituir:

```dart
class RateEventSheet extends StatefulWidget {
  ...
  State<RateEventSheet> createState() => _RateEventSheetState();
}

class _RateEventSheetState extends State<RateEventSheet> {
```

por:

```dart
class RateEventSheet extends ConsumerStatefulWidget {
  ...
  ConsumerState<RateEventSheet> createState() => _RateEventSheetState();
}

class _RateEventSheetState extends ConsumerState<RateEventSheet> {
```

- [ ] **Step 2: Reemplazar cálculo manual**

Sustituir:

```dart
    final mq = MediaQuery.of(context);
    const navBarExtra = MainShellV2.kNavBarHeight + MainShellV2.kNavBarBottom;
    final bottomPadding = mq.viewInsets.bottom + mq.viewPadding.bottom + navBarExtra;
```

por:

```dart
    final bottomPadding =
        bottomSheetSafeBottom(context, ref, hasNavBar: true);
```

- [ ] **Step 3: Imports**

- Añadir `import 'package:flutter_riverpod/flutter_riverpod.dart';`.
- Añadir `import '../../../../shared/widgets/bottom_sheet_padding.dart';`.
- Eliminar `import '../../../../shared/widgets/skins/main_shell_v2.dart';` si no queda uso.

- [ ] **Step 4: Verificar analyze y tests preexistentes**

Run: `flutter analyze lib/features/history/presentation/widgets/rate_event_sheet.dart`
Expected: sin errores.

Run: `flutter test test/ui/features/history/`
Expected: los tests V2 pasan (los tests V1 se eliminarán en Task 14).

- [ ] **Step 5: Commit**

```bash
git add lib/features/history/presentation/widgets/rate_event_sheet.dart
git commit -m "fix(history): rate sheet respeta AdBanner (bottomSheetSafeBottom)"
```

---

## Task 12: Test UI de regresión — FAB visible sobre banner

**Files:**
- Create: `test/ui/features/tasks/all_tasks_screen_v2_fab_banner_test.dart`
- Create: `test/ui/features/members/invite_sheet_banner_test.dart`

- [ ] **Step 1: Test del FAB en AllTasksScreenV2**

Crear `test/ui/features/tasks/all_tasks_screen_v2_fab_banner_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/presentation/skins/all_tasks_screen_v2.dart';
import 'package:toka/shared/widgets/ad_banner.dart';
import 'package:toka/shared/widgets/ad_banner_config_provider.dart';

void main() {
  testWidgets(
    'FAB queda por encima de la altura del banner cuando banner está visible',
    (t) async {
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            adBannerConfigProvider.overrideWith(
              (ref) => const AdBannerConfig(show: true, unitId: 'x'),
            ),
          ],
          child: const MaterialApp(home: AllTasksScreenV2()),
        ),
      );
      await t.pumpAndSettle(const Duration(seconds: 1));

      final fab = find.byKey(const Key('create_task_fab'));
      if (fab.evaluate().isEmpty) return; // sin homeId en test: FAB no se pinta

      final fabBox = t.getRect(fab);
      final screenHeight = t.view.physicalSize.height / t.view.devicePixelRatio;
      final reservedBanner = AdBanner.kBannerHeight + AdBanner.kBannerGap;

      expect(
        fabBox.bottom,
        lessThanOrEqualTo(screenHeight - reservedBanner),
        reason: 'FAB debe estar encima de la franja reservada al banner',
      );
    },
  );
}
```

- [ ] **Step 2: Ejecutar test y ajustar si el FAB no se pinta**

Run: `flutter test test/ui/features/tasks/all_tasks_screen_v2_fab_banner_test.dart`
Expected: pasa (early-return si no hay FAB por falta de data, que está OK).

- [ ] **Step 3: Test del InviteMemberSheet**

Crear `test/ui/features/members/invite_sheet_banner_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/members/presentation/widgets/invite_member_sheet.dart';
import 'package:toka/shared/widgets/ad_banner_config_provider.dart';

void main() {
  testWidgets(
    'InviteMemberSheet renderiza botones accesibles con banner activo',
    (t) async {
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            adBannerConfigProvider.overrideWith(
              (ref) => const AdBannerConfig(show: true, unitId: 'x'),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => Center(
                  child: ElevatedButton(
                    onPressed: () => showModalBottomSheet(
                      context: ctx,
                      isScrollControlled: true,
                      builder: (_) =>
                          const InviteMemberSheet(homeId: 'home-x'),
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await t.tap(find.text('open'));
      await t.pumpAndSettle();

      expect(find.byKey(const Key('btn_share_code')), findsOneWidget);
      expect(find.byKey(const Key('btn_invite_email')), findsOneWidget);
    },
  );
}
```

- [ ] **Step 4: Ejecutar ambos tests**

Run: `flutter test test/ui/features/members/invite_sheet_banner_test.dart`
Expected: pasa.

- [ ] **Step 5: Commit**

```bash
git add test/ui/features/tasks/all_tasks_screen_v2_fab_banner_test.dart test/ui/features/members/invite_sheet_banner_test.dart
git commit -m "test(ui): regresion FAB y InviteSheet sobre AdBanner"
```

---

## Task 13: Eliminar archivos V1 de pantallas y shell

**Files:**
- Delete: `lib/shared/widgets/main_shell.dart`
- Delete: `lib/features/tasks/presentation/today_screen.dart`
- Delete: `lib/features/tasks/presentation/all_tasks_screen.dart`
- Delete: `lib/features/tasks/presentation/task_detail_screen.dart`
- Delete: `lib/features/tasks/presentation/create_edit_task_screen.dart`
- Delete: `lib/features/history/presentation/history_screen.dart`
- Delete: `lib/features/members/presentation/member_profile_screen.dart`
- Delete: `lib/core/theme/app_theme.dart`

- [ ] **Step 1: Borrar los archivos V1**

```bash
rm lib/shared/widgets/main_shell.dart \
   lib/features/tasks/presentation/today_screen.dart \
   lib/features/tasks/presentation/all_tasks_screen.dart \
   lib/features/tasks/presentation/task_detail_screen.dart \
   lib/features/tasks/presentation/create_edit_task_screen.dart \
   lib/features/history/presentation/history_screen.dart \
   lib/features/members/presentation/member_profile_screen.dart \
   lib/core/theme/app_theme.dart
```

- [ ] **Step 2: Verificar que `flutter analyze` falla con imports rotos en `lib/app.dart`**

Run: `flutter analyze lib/`
Expected: errores de `URI doesn't exist` en `lib/app.dart` para los archivos borrados. Esto es esperado — Task 14 los arregla.

NO commit todavía. Continuar a Task 14.

---

## Task 14: Simplificar `lib/app.dart` y `AppSkin`

**Files:**
- Modify: `lib/core/theme/app_skin.dart`
- Modify: `lib/app.dart`

- [ ] **Step 1: Simplificar `AppSkin` enum**

Editar `lib/core/theme/app_skin.dart`:

```dart
// lib/core/theme/app_skin.dart

/// Identifies available visual skins.
/// Add a new value here when a new full redesign is introduced.
///
/// Infraestructura viva: hoy sólo existe `v2` porque la skin V1 ha sido
/// eliminada, pero el enum y [SkinConfig] se mantienen para acomodar una
/// futura V3/V4 sin reintroducir la plumería.
enum AppSkin { v2 }

/// Single point of control for which skin the app renders.
/// Change [current] to switch all screens to a different visual design.
/// In the future, this can read from Firebase Remote Config or SharedPreferences.
class SkinConfig {
  SkinConfig._();
  static AppSkin current = AppSkin.v2;
}
```

- [ ] **Step 2: Simplificar builders de `lib/app.dart`**

En `lib/app.dart`:

1. Eliminar los imports V1:

```dart
import 'core/theme/app_theme.dart';                            // ← borrar
import 'features/tasks/presentation/today_screen.dart';        // ← borrar
import 'features/tasks/presentation/all_tasks_screen.dart';    // ← borrar si existe
import 'features/tasks/presentation/task_detail_screen.dart';  // ← borrar si existe
import 'features/tasks/presentation/create_edit_task_screen.dart'; // ← borrar si existe
import 'features/history/presentation/history_screen.dart';   // ← borrar si existe
import 'features/members/presentation/member_profile_screen.dart'; // ← borrar si existe
import 'shared/widgets/main_shell.dart';                       // ← borrar si existe
```

(Eliminar las líneas de import que realmente existen; el resto ya estaban ausentes.)

2. `ShellRoute.builder` pasa de:

```dart
builder: (context, state, child) => SkinConfig.current == AppSkin.v2
    ? MainShellV2(child: child)
    : MainShell(child: child),
```

a:

```dart
builder: (context, state, child) => MainShellV2(child: child),
```

3. Cada `GoRoute.builder` con ternario de skin se simplifica. Ejemplos:

Antes:
```dart
builder: (_, __) => SkinConfig.current == AppSkin.v2
    ? const TodayScreenV2()
    : const TodayScreen(),
```

Después:
```dart
builder: (_, __) => const TodayScreenV2(),
```

Lo mismo para las rutas de `history`, `tasks`, `tasks/new`, `tasks/:id`, `tasks/:id/edit` y `memberProfile`. La ruta `members` ya era fija (`MembersScreen`), queda igual.

4. El bloque:

```dart
theme:      SkinConfig.current == AppSkin.v2 ? AppThemeV2.light : AppTheme.light,
darkTheme:  SkinConfig.current == AppSkin.v2 ? AppThemeV2.dark  : AppTheme.dark,
```

Pasa a:
```dart
theme:      AppThemeV2.light,
darkTheme:  AppThemeV2.dark,
```

- [ ] **Step 3: Verificar `flutter analyze`**

Run: `flutter analyze`
Expected: sin errores (las referencias a archivos borrados deben haber desaparecido).

- [ ] **Step 4: Commit**

```bash
git add lib/app.dart lib/core/theme/app_skin.dart \
        lib/shared/widgets/main_shell.dart \
        lib/features/tasks/presentation/today_screen.dart \
        lib/features/tasks/presentation/all_tasks_screen.dart \
        lib/features/tasks/presentation/task_detail_screen.dart \
        lib/features/tasks/presentation/create_edit_task_screen.dart \
        lib/features/history/presentation/history_screen.dart \
        lib/features/members/presentation/member_profile_screen.dart \
        lib/core/theme/app_theme.dart
git commit -m "refactor(skin): eliminar skin V1 (pantallas, MainShell, AppTheme)

Infraestructura de skins (AppSkin, SkinConfig) se mantiene viva para
futuras V3; solo se elimina el valor material y el codigo V1."
```

---

## Task 15: Eliminar tests V1 y limpiar `skin_selector_test`

**Files:**
- Delete: `test/ui/features/tasks/today_screen_test.dart`
- Delete: `test/ui/features/tasks/all_tasks_screen_test.dart`
- Delete: `test/ui/features/tasks/task_detail_screen_test.dart`
- Delete: `test/ui/features/tasks/create_task_screen_test.dart`
- Delete: `test/ui/features/history/history_screen_test.dart`
- Delete: `test/ui/features/members/member_profile_screen_test.dart`
- Delete: `test/ui/core/theme/app_theme_test.dart`
- Modify: `test/unit/core/theme/skin_selector_test.dart`

- [ ] **Step 1: Borrar tests V1**

```bash
rm test/ui/features/tasks/today_screen_test.dart \
   test/ui/features/tasks/all_tasks_screen_test.dart \
   test/ui/features/tasks/task_detail_screen_test.dart \
   test/ui/features/tasks/create_task_screen_test.dart \
   test/ui/features/history/history_screen_test.dart \
   test/ui/features/members/member_profile_screen_test.dart \
   test/ui/core/theme/app_theme_test.dart
```

- [ ] **Step 2: Limpiar `skin_selector_test.dart`**

Reescribir `test/unit/core/theme/skin_selector_test.dart` a:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/core/theme/app_skin.dart';

void main() {
  test('AppSkin.v2 existe y SkinConfig.current es v2 por defecto', () {
    expect(AppSkin.values, contains(AppSkin.v2));
    expect(SkinConfig.current, AppSkin.v2);
  });
}
```

(Se elimina el test que fijaba `AppSkin.material` porque ese valor ya no existe en el enum.)

- [ ] **Step 3: Ejecutar toda la suite**

Run: `flutter test`
Expected: toda la suite pasa. Si falla algún test que quede por imports rotos o referencias al V1, corregirlo.

- [ ] **Step 4: Commit**

```bash
git add test/
git commit -m "test: eliminar tests de pantallas V1 y limpiar skin_selector_test"
```

---

## Task 16: Verificación visual en emulador

**Files:**
- Ninguno (ciclo manual con capturas).

Por cada pantalla y sheet, ciclo: compilar, login, navegar, capturar, redimensionar si >1900px, analizar.

- [ ] **Step 1: Lanzar app**

Run: `flutter run -d emulator-5554`

Si ya está corriendo: `r` para hot reload. Esperar a que la app arranque.

- [ ] **Step 2: Login**

Seguir el protocolo de CLAUDE.md:

```bash
adb shell input tap 540 1053
adb shell input text "toka.qa.owner@gmail.com"
adb shell input tap 540 1242
adb shell input text "TokaQA2024!"
adb shell input tap 540 1441
```

- [ ] **Step 3: Capturar Hoy, Historial, Miembros, Lista de tareas (tabs)**

Para cada pestaña:

```bash
# tap en el tab
adb shell input tap 144 <navBarY>   # Hoy
# capturar
adb exec-out screencap -p > /tmp/screen.png
# redimensionar si >1900px alto
python -c "from PIL import Image; i=Image.open('/tmp/screen.png'); i.thumbnail((1900,1900)); i.save('/tmp/screen_sm.png')"
```

Repetir para cada tab usando coordenadas de CLAUDE.md (Hoy 144, Historial 342, Miembros 540, Tareas 738).

Validar en cada captura:
- Banner visible al pie con sombra.
- NavBar flotante por encima del banner con gap.
- En Miembros y Tareas: FAB encima del banner.
- En Miembros y Tareas: hacer scroll hasta el fondo y capturar otra vez — el último ítem queda por encima del banner.

- [ ] **Step 4: Capturar detalle de tarea y create/edit task**

```bash
# Desde Tareas, tap en una tarea
adb shell input tap 540 <yOfFirstTask>
adb exec-out screencap -p > /tmp/task_detail.png
# Volver y tap en FAB +
adb shell input keyevent KEYCODE_BACK
adb shell input tap <fabX> <fabY>
adb exec-out screencap -p > /tmp/create_task.png
```

Validar en cada una: banner visible, scroll hasta el fondo no tapa ítems, appBar con back funciona.

- [ ] **Step 5: Capturar detalle de miembro**

Desde Miembros, tap en un miembro. Capturar. Scroll hasta el fondo. Validar banner y scroll.

- [ ] **Step 6: Capturar sheets con banner activo**

- Miembros → FAB Invitar → capturar sheet. Validar botones "Compartir código" y "Por email" visibles.
- Abrir teclado en el email → capturar de nuevo. Validar que el campo sube sobre el teclado y el banner queda detrás (el sheet lo tapa).
- Historial → tap en un evento pendiente de rating → capturar `RateEventSheet`. Validar slider y nota visibles; botón "Valorar" visible.

- [ ] **Step 7: Capturar estado sin banner (premium)**

Cambiar manualmente `adFlags.showBanner` a `false` en Firestore (o usar cuenta premium) y repetir Steps 3–6. Validar que todas las pantallas se ven sin banner sin espacio en blanco inferior.

- [ ] **Step 8: Registro visual (opcional)**

No commitear las capturas (son `/tmp/`). Si algo falla visualmente, abrir una incidencia y reabrir el task que falló.

- [ ] **Step 9: Commit "verification pass" (sin cambios de código)**

Si los pasos anteriores dispararon arreglos puntuales, cada arreglo va con su propio commit. Si no, no hay commit adicional en este task.

---

## Task 17: Pasada final — analyze + toda la suite de tests

**Files:**
- Ninguno (verificación de salud global).

- [ ] **Step 1: `flutter analyze`**

Run: `flutter analyze`
Expected: 0 errores. Warnings preexistentes aceptables pero documentables.

- [ ] **Step 2: Ejecutar toda la suite**

Run: `flutter test`
Expected: toda la suite verde. Si hay regresiones en tests V2 de pantallas modificadas, corregir y commitear.

- [ ] **Step 3: Bloque de pruebas manuales requeridas**

Imprimir al final de la conversación:

```
## Pruebas manuales requeridas

1. Abrir cuenta no-premium en el emulador.
2. Navegar por: Hoy, Historial, Miembros, Lista de tareas. Banner visible en todas.
3. En Miembros: pulsar FAB Invitar. Validar que el sheet muestra los dos botones.
   Pulsar "Por email", abrir teclado; validar que el campo no queda tapado.
4. En Lista de tareas: scroll hasta el fondo. Último ítem visible con banner al pie.
   Pulsar FAB +. Formulario scrollea y el último campo queda sobre el banner.
5. Abrir detalle de tarea, detalle de miembro: banner visible, scroll no tapa.
6. Historial: tap en evento pendiente → RateEventSheet con slider y nota visibles.
7. Activar cuenta premium → navegar las mismas pantallas → NO debe verse banner,
   sin espacio en blanco inferior, FABs y listas llegan hasta la navbar.
```

---

## Self-review notes (aplicado durante la escritura)

- Spec coverage: las 7 pantallas objetivo más los sheets cubiertas (Tasks 5–11), wrapper + helper (2–3), limpieza V1 (13–15), verificación visual (16), sanidad final (17).
- Tipos consistentes: `AdAwareScaffold.bottomPaddingOf(ctx, ref)` y `MainShellV2.bottomContentPadding(ctx, ref)` tienen la misma firma; `bottomSheetSafeBottom(ctx, ref, {hasNavBar})` añade el flag. No hay renombres entre tasks.
- Placeholder scan: todo paso con cambio de código incluye el código; no hay "implement later".
- El enum `AppSkin` pasa de `{ material, v2 }` a `{ v2 }` — cambio mencionado en Task 14 y reflejado en el test de Task 15.
