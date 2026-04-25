# Skin Futurista · Iteración 2E · Paridad de comportamiento · Diseño

**Fecha:** 2026-04-25
**Estado:** aprobado para plan de implementación
**Scope:** Cerrar la brecha de **comportamiento** entre la skin futurista y la skin v2 en los fundamentos del shell, el botón "Pasar" en tarjetas de tarea, y la navegabilidad/valoración del historial. NO añade pantallas nuevas; corrige paridad funcional sobre las ya existentes.
**Fuera de scope:** features de `all_tasks` (selection mode, swipe freeze/delete, filter Active/Frozen real, search), confetti/animaciones de check, paridad pantalla-por-pantalla de subscription/profile/home_settings/etc. Esos quedan para iteraciones posteriores.

**Spec anterior:** [2026-04-25-skin-futurista-2d-design.md](2026-04-25-skin-futurista-2d-design.md).

---

## 1 · Contexto

Tras 2A-2D la skin futurista cubre todas las pantallas operativas. Sin embargo, durante QA visual se detecta que la **conducta** del shell y de algunos widgets clave **no replica v2**:

1. `MainShellFuturista` es un esqueleto: no tiene AdBanner real, no aplica `extendBody`, no expone API de padding, y no captura el botón hardware BACK para volver a Hoy.
2. `adAwareBottomPadding` lee constantes hardcoded de `MainShellV2` (56+12=68); en futurista la `TockaTabBar` mide 64+12=76 → desfase de 8 px que deja el último item parcialmente tapado.
3. `TaskCardFuturista` esconde el botón "Pasar" detrás de tap-en-card, rompiendo descubribilidad respecto a v2 (que muestra `[Hecho][Pasar]` lado a lado).
4. `TaskCardFuturista` no aplica el gating `_isActionable()` de v2: permite completar tareas semanales/mensuales/anuales antes de su ventana.
5. `HistoryScreenFuturista` no permite tap en eventos para navegar al detalle, no tiene botón valorar (★), y no muestra el banner premium intercalado para usuarios free.

Esta spec arregla esos cinco frentes con cambios localizados en 8 archivos, 3 archivos nuevos y 1 borrado.

---

## 2 · Invariantes anclados

- **Mismo VM**: ningún cambio toca providers ni viewmodels existentes; toda la modificación es de presentación.
- **Mismo dialog**: `CompleteTaskDialog`, `PassTurnDialog`, `RateEventSheet` se reutilizan tal cual.
- **Diálogos heredan theme**: AlertDialog/BottomSheet siguen sin replicarse en variante futurista.
- **API pública v2 intacta**: `MainShellV2.kNavBarHeight`, `kNavBarBottom`, `bottomContentPadding`, `fabBottomPadding` siguen accesibles con la misma firma. Internamente delegan a la nueva metrics.

---

## 3 · Decisiones tomadas

### 3.1 AdBanner real (AdMob) en shell futurista

El `AdBanner` actual de `lib/shared/widgets/ad_banner.dart` (320×58, refresh 60s, gating por `adBannerConfigProvider`) **se reusa** en `MainShellFuturista` posicionado al pie igual que en v2. El widget `AdBannerFuturista` (mockup visual sin SDK) **se elimina** porque ya no aporta valor — su única razón de existir era simular el banner mientras no había shell que lo soportara.

### 3.2 Botón "Pasar" siempre visible en `TaskCardFuturista`

Cuando `mine && !done`, debajo del row principal se añade una fila con dos botones full-width:
- `TockaBtn glow size lg fullWidth icon=check label="Hecho"` → `onComplete`.
- `TockaBtn ghost size lg icon=swap_horiz` (botón cuadrado) → `onPass`.

El slot derecho 38×38 que hoy contiene el check **se elimina** cuando es propia (los botones pasan abajo). Cuando NO es propia, sigue habiendo slot derecho con `lock_outline` muted (UI actual sin cambios).

`onTap` de la card cambia su semántica: ya no dispara pass; navega al detalle (`context.push('/tasks/:id')`). Patrón estándar Material para listas tap-to-detail.

### 3.3 Gating `_isActionable()` portado a futurista

Se añade lógica idéntica a `_TodayTaskCardTodoV2State._isActionable()`:
- `hourly`: actionable si vence en la hora actual o antes.
- `daily`: actionable si vence hoy o antes.
- `weekly`: actionable si vence en la semana ISO actual o antes.
- `monthly`: actionable si vence en el mes actual o antes.
- `yearly`: actionable si vence en el año actual o antes.
- `oneTime`: actionable si vence o ya venció.
- Tareas con `isOverdue=true` siempre son actionable.

Cuando NO actionable, el botón Done:
- Visualmente: variante `disabled` (border muted) con icono `Icons.lock_clock` antes del label.
- Al pulsar: invoca `onActionableHint` (callback opcional pasado por el consumidor) en vez de `onComplete`. La `TaskCardFuturista` NO conoce `task.nextDueAt` ni `recurrenceType`, así que delega el formato del mensaje al consumidor.

El consumidor (`today_screen_futurista`) implementa los helpers privados:

```dart
bool _isActionable(TaskPreview t) { /* misma lógica que _TodayTaskCardTodoV2State._isActionable */ }

void _snackNotYet(BuildContext ctx, AppLocalizations l10n, TaskPreview t) {
  final dateStr = _formatDueForMessage(ctx, t); // misma lógica que v2
  ScaffoldMessenger.of(ctx)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
      content: Text(l10n.today_hecho_not_yet(dateStr)),
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
    ));
}
```

Y al construir cada card pasa:
```dart
TaskCardFuturista(
  // ...
  actionable: _isActionable(t),
  onActionableHint: () => _snackNotYet(context, l10n, t),
  onComplete: () => _onDone(context, vm, t),
)
```

### 3.4 Shell metrics como single source of truth

Para evitar el desfase de altura nav bar entre skins:

```dart
// lib/shared/widgets/skins/shell_metrics.dart
abstract class ShellMetrics {
  double get navBarHeight;
  double get navBarBottom;
  double get bannerGap;
  bool suppressBannerFor(String location);
}

class MainShellV2Metrics implements ShellMetrics {
  static const double kNavBarHeight = 56;
  static const double kNavBarBottom = 12;
  @override double get navBarHeight => kNavBarHeight;
  @override double get navBarBottom => kNavBarBottom;
  @override double get bannerGap => AdBanner.kBannerGap;
  @override bool suppressBannerFor(String loc) =>
    loc.startsWith(AppRoutes.settings);
}

class MainShellFuturistaMetrics implements ShellMetrics {
  static const double kNavBarHeight = 64;
  static const double kNavBarBottom = 12;
  // ... idéntico, mismo suppressBannerFor
}

final shellMetricsProvider = Provider<ShellMetrics>((ref) {
  final skin = ref.watch(skinModeProvider);
  return skin == AppSkin.futurista
    ? MainShellFuturistaMetrics()
    : MainShellV2Metrics();
});
```

`adAwareBottomPadding` consume el provider:

```dart
double adAwareBottomPadding(BuildContext context, WidgetRef ref, {double extra = 0}) {
  final metrics = ref.watch(shellMetricsProvider);
  final config = ref.watch(adBannerConfigProvider);
  final keyboardVisible = ref.watch(keyboardVisibleProvider);
  final location = GoRouterState.of(context).matchedLocation;
  final suppressedHere = metrics.suppressBannerFor(location);
  final bannerVisible = config.show && config.unitId.isNotEmpty
    && !keyboardVisible && !suppressedHere;
  final banner = bannerVisible
    ? AdBanner.kBannerHeight + metrics.bannerGap : 0.0;
  final navBar = keyboardVisible ? 0.0 : metrics.navBarHeight + metrics.navBarBottom;
  final safeArea = MediaQuery.paddingOf(context).bottom;
  return banner + navBar + safeArea + extra;
}
```

`MainShellV2.kNavBarHeight` y `kNavBarBottom` se mantienen como `static const = MainShellV2Metrics.kNavBarHeight` etc., para no romper consumidores externos (`subscription_management_screen_v2.dart`, `members_screen_v2.dart`, etc.).

### 3.5 `MainShellFuturista` rediseñado siguiendo el patrón v2

```dart
return PopScope(
  canPop: tabIndex == 0,
  onPopInvokedWithResult: (didPop, _) {
    if (didPop) return;
    context.go(AppRoutes.home);
  },
  child: Scaffold(
    extendBody: true,
    bottomNavigationBar: SizedBox(height: navSlot + safeBottom + bannerSlot),
    body: Stack(
      children: [
        child,
        if (bannerVisible)
          Positioned(
            left: 0, right: 0,
            bottom: navSlot + safeBottom + metrics.bannerGap,
            child: const AdBanner(key: Key('ad_banner_futurista_shell')),
          ),
        if (!keyboardVisible)
          Positioned(
            left: 10, right: 10,
            bottom: metrics.navBarBottom + safeBottom,
            child: TockaTabBar(/* ... */),
          ),
      ],
    ),
  ),
);
```

Las dependencias `adBannerConfigProvider`, `keyboardVisibleProvider`, `currentRouteLocation` se watchean igual que en v2.

### 3.6 History futurista — tap, valorar y banner premium

`_EventRow.build` se envuelve condicionalmente en `InkWell`:

```dart
final isDetailable = item.raw is CompletedEvent || item.raw is PassedEvent;
final homeId = ref.read(currentHomeProvider).valueOrNull?.id;
if (isDetailable && homeId != null) {
  return InkWell(
    key: Key('history_tile_tap_${item.raw.id}'),
    onTap: () => context.push(
      AppRoutes.historyEventDetail
        .replaceFirst(':homeId', homeId)
        .replaceFirst(':eventId', item.raw.id),
    ),
    child: row,
  );
}
return row;
```

Slot trailing condicional dentro de la fila (igual lógica que `HistoryScreenV2._buildTile`):

| Estado | Trailing |
|---|---|
| `vm.isPremium && item.isRated` | Icon `Icons.star` ámbar 18 |
| `vm.isPremium && item.canRate` | IconButton `Icons.star_border` → `RateEventSheet` |
| `!vm.isPremium && (raw is CompletedEvent && !isOwnEvent)` | IconButton `Icons.star_border` muted → upgrade sheet |
| Resto | nada |

Banner premium intercalado: si `!vm.isPremium`, en `ListView.builder` se inserta un widget `PremiumBannerFuturista` en la posición `groups.length` (detrás del último día). Layout:

```
Container(
  padding: 14, radius: 16,
  bg: surfaceContainerHighest,
  border: primary.alpha .25,
  child: Column [
    Row [Icon(lock, primary), Text(history_premium_banner_title 14/700)],
    Subtitle 12 muted (history_premium_banner_body),
    TockaBtn primary fullWidth size md "Hazte Premium" → push paywall,
  ],
)
```

### 3.7 `today_screen_futurista` cleanup

- Eliminar el `SliverToBoxAdapter` con `AdBannerFuturista` (queda obsoleto).
- Cambiar el último sliver de padding de `extra: 96` a `extra: 16` (el shell ya reserva nav+banner).
- Pasar `actionable: _isActionable(t)` y `onActionableHint: () => _snackNotYet(...)` a `TaskCardFuturista`.
- Cambiar `onTap` de la card de "abre pass dialog" a "navega al detalle".

### 3.8 Padding ad-aware en pantallas con valores hardcodeados

| Pantalla | Antes | Después |
|---|---|---|
| `all_tasks_screen_futurista.dart` línea ~142 | `padding: EdgeInsets.fromLTRB(16,4,16,120)` | `padding: EdgeInsets.only(left:16,right:16,top:4, bottom: adAwareBottomPadding(context, ref, extra: 16))` |
| `task_detail_screen_futurista.dart` línea ~88 | `padding: EdgeInsets.fromLTRB(16,12,16,32)` | `padding: EdgeInsets.fromLTRB(16,12,16, adAwareBottomPadding(context, ref, extra: 16))` |
| `history_screen_futurista.dart` línea ~134 | `extra: 80` | `extra: 16` |

(El resto de pantallas futurista quedan fuera de scope. Se auditarán en una iteración 2F si surge la necesidad.)

---

## 4 · Arquitectura y archivos

### 4.1 Crear (3)

| Path | Contenido |
|---|---|
| `lib/shared/widgets/skins/shell_metrics.dart` | `ShellMetrics` interface + `MainShellV2Metrics` + `MainShellFuturistaMetrics` + `shellMetricsProvider`. |
| `lib/shared/widgets/futurista/premium_banner_futurista.dart` | `PremiumBannerFuturista` widget descrito en §3.6. |
| `test/widget/shared/shell_metrics_test.dart` | Verifica que el provider devuelve la impl correcta según `skinModeProvider`. |

### 4.2 Modificar (8)

| Path | Cambio |
|---|---|
| `lib/shared/widgets/skins/main_shell_v2.dart` | `kNavBarHeight/kNavBarBottom` referencian a `MainShellV2Metrics.kNavBarHeight/kNavBarBottom`. Sin cambios de comportamiento. |
| `lib/shared/widgets/skins/main_shell_futurista.dart` | Reescritura completa según §3.5. |
| `lib/shared/widgets/ad_aware_bottom_padding.dart` | Consume `shellMetricsProvider` (§3.4). |
| `lib/shared/widgets/futurista/task_card_futurista.dart` | Nueva fila de 2 botones cuando `mine && !done`. Acepta `actionable: bool = true` y `onActionableHint: VoidCallback?` (§3.2-3.3). |
| `lib/features/tasks/presentation/skins/futurista/today_screen_futurista.dart` | Cleanup §3.7: eliminar AdBanner inline, ajustar padding, pasar `actionable` y nuevo `onTap`. |
| `lib/features/tasks/presentation/skins/futurista/all_tasks_screen_futurista.dart` | Padding ad-aware §3.8. |
| `lib/features/tasks/presentation/skins/futurista/task_detail_screen_futurista.dart` | Padding ad-aware §3.8. |
| `lib/features/history/presentation/skins/futurista/history_screen_futurista.dart` | Tap, trailing star, banner premium, padding §3.6+§3.8. |

### 4.3 Borrar (1)

- `lib/shared/widgets/futurista/ad_banner_futurista.dart` — ya no tiene consumidores tras §3.7.

(Si hay tests que lo importen, se eliminan también.)

---

## 5 · Estrategia de delegación

Sin paralelización: todos los items dependen del shell metrics. Olas lineales, cada una commit propio:

| Ola | Trabajo | Estimación |
|---|---|---|
| **1 — Fundación** | Crear `shell_metrics.dart` + test. Refactor `main_shell_v2.dart` (delegar constantes). Refactor `ad_aware_bottom_padding.dart`. `flutter analyze` + tests existentes. | 15-20 min |
| **2 — Shell futurista** | Reescribir `main_shell_futurista.dart`. Borrar `ad_banner_futurista.dart`. Limpiar `today_screen_futurista` (sin sliver banner, `extra: 16`). Verificar build + screenshot dispositivo. | 20-25 min |
| **3 — Padding cleanup** | `all_tasks_screen_futurista` + `task_detail_screen_futurista` (hardcoded → ad-aware). Tests existentes verdes. | 5-10 min |
| **4 — TaskCardFuturista** | Reescribir card con dos botones + `actionable` + SnackBar. Cablear `today_screen_futurista` para pasar `actionable` y nuevo `onTap`. Test widget de la card cubriendo: mine+actionable, mine+not actionable (SnackBar), mine+done, no-mine. | 25-30 min |
| **5 — History tap + rate + banner** | Crear `premium_banner_futurista`. Modificar `history_screen_futurista` (InkWell + star trailing + banner). Test widget verificando: tap navega, star aparece para premium, banner aparece para free. | 20-25 min |

**Total esperado:** 85-110 min end-to-end.

### 5.1 Control de riesgos

- **`MainShellV2` API pública**: las constantes `kNavBarHeight/kNavBarBottom` y métodos `bottomContentPadding/fabBottomPadding` se preservan con la misma firma; cambia solo la implementación interna.
- **`AdBanner` lifecycle duplicado**: solo el shell activo según skin construye el `AdBanner`. Como solo hay un `MainShell` activo a la vez, no hay duplicación de timers.
- **`TockaTabBar` height drift**: se añade `TockaTabBar.kHeight = 64` como `static const` y `MainShellFuturistaMetrics.kNavBarHeight` lo referencia. Si el design del tab bar cambia, un único punto de actualización.
- **PopScope conflictos con dialogs**: ya verificado en v2. `PopScope` del shell solo intercepta cuando la ruta no puede pop más, así que dialogs/bottom sheets siguen funcionando.

---

## 6 · Tests

### 6.1 Nuevos (3 ficheros)

- `test/widget/shared/shell_metrics_test.dart`
  - `shellMetricsProvider` con `skinModeProvider == v2` → `MainShellV2Metrics`.
  - `shellMetricsProvider` con `skinModeProvider == futurista` → `MainShellFuturistaMetrics`.
  - Suppression `/settings` funciona en ambas impls.

- `test/widget/shared/futurista/task_card_futurista_test.dart` (extender o crear)
  - mine + actionable → 2 botones visibles, tap "Hecho" llama `onComplete`.
  - mine + NOT actionable → botón "Hecho" muestra lock_clock, tap llama `onActionableHint` (no `onComplete`).
  - mine + done → sin botones, lineThrough en título.
  - !mine → slot derecho con lock_outline, sin botones.
  - tap general en card llama `onTap` (que en today_screen apuntará a detail).

- `test/widget/features/history/skins/futurista/history_screen_futurista_test.dart` (extender)
  - tap en CompletedEvent → navega a `historyEventDetail` (verificar mock router).
  - premium → estrella visible para evento `canRate`; tap abre RateEventSheet.
  - free → estrella muted visible para evento rateable de otro; tap abre upgrade sheet.
  - free → `PremiumBannerFuturista` visible al final de la lista.

### 6.2 Existentes

Todos los tests v2 deben seguir verdes tras los cambios:
- Tests que importan `MainShellV2.kNavBarHeight/kNavBarBottom`.
- Tests de `adAwareBottomPadding`.
- Tests de `TaskCardFuturista` previos (ajustar a la nueva signatura).

---

## 7 · Criterios de aceptación

| # | Criterio | Verificación |
|---|---|---|
| AC1 | En futurista, AdBanner real aparece flotante al pie en Hoy/Tareas/Historial/Miembros y se oculta en Settings | Manual + screenshot |
| AC2 | El último item de cualquier ScrollView en futurista (Hoy/Tareas/Historial/Miembros/TaskDetail) queda visible por encima de NavBar y banner | Manual: scroll a fondo en cada tab |
| AC3 | Hardware BACK desde tab no-Hoy → vuelve a Hoy. Desde Hoy → sale de la app | Manual |
| AC4 | TaskCardFuturista en Hoy: muestra `[Hecho][Pasar]` cuando es propia. Ambos accionan el flujo correcto. Tap-en-card navega al detalle | Manual + test widget |
| AC5 | "Hecho" en tarea no-actionable → muestra SnackBar con fecha y NO completa | Manual + test |
| AC6 | History futurista: tap en evento Completed/Passed navega al detalle | Manual |
| AC7 | History futurista para premium: estrella visible. Tap → RateEventSheet | Manual |
| AC8 | History futurista para free: banner premium intercalado al final. Tap CTA → paywall. Estrella muted en eventos rateable de otros | Manual |
| AC9 | `flutter analyze` 0 errores nuevos | CI |
| AC10 | `flutter test` verde | CI |
| AC11 | Tests v2 existentes siguen verdes (no regresión en MainShellV2) | CI |

---

## 8 · Commits previstos

| # | Mensaje | Ola |
|---|---|---|
| 1 | `refactor(shell): extraer ShellMetrics + provider y refactor adAwareBottomPadding` | 1 |
| 2 | `feat(skin): MainShellFuturista con AdBanner + PopScope + extendBody (paridad v2)` | 2 |
| 3 | `fix(skin): padding ad-aware en all_tasks/task_detail futurista` | 3 |
| 4 | `feat(skin): TaskCardFuturista con botón Pasar + actionable gating + SnackBar` | 4 |
| 5 | `feat(skin): History futurista navegable + valorar + banner premium` | 5 |

Total **5 commits**.

---

## 9 · Pruebas manuales requeridas (al cerrar la spec)

Antes de marcar la spec como DONE el desarrollador debe verificar en dispositivo `43340fd2`:

1. Skin futurista activado: AdBanner real aparece al pie en Hoy/Tareas/Historial/Miembros. Oculto en Ajustes.
2. Scroll a fondo en Hoy/Tareas/Historial: último item se ve completo por encima del banner.
3. BACK físico desde Tareas → vuelve a Hoy. BACK desde Hoy → cierra app.
4. En Hoy, tarea propia: `[Hecho][Pasar]` visibles. Tap "Hecho" abre dialog. Tap "Pasar" abre dialog. Tap en zona vacía de la card → navega al detalle.
5. Tarea semanal cuya semana aún no empezó: tap "Hecho" → SnackBar "Aún no es momento — vence el {fecha}".
6. En Historial, tap en evento "completada" → abre detalle.
7. Como Premium: estrella en eventos rateable, tap abre sheet.
8. Como Free: banner premium al final de la lista. Estrella muted en eventos rateable de otros, tap abre upgrade sheet.
9. Toggle a skin Clásico → todo sigue funcionando igual que antes.
