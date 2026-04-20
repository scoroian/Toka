# AdBanner layout cohesion across screens

**Fecha:** 2026-04-20
**Estado:** Draft
**Autor:** Sebastian + Claude

## Contexto

Toka muestra un `AdBanner` de 320×50 (58px de contenedor) en las pantallas del shell principal (Hoy, Historial, Miembros, Tareas). El shell V2 (`MainShellV2`) ya inyecta el banner vía `Positioned` y reserva espacio en `bottomNavigationBar` para que `MediaQuery.padding.bottom` crezca automáticamente.

Problemas actuales:

1. **FABs tapados**: el FAB de "Crear tarea" (Lista de tareas V2) y el FAB "Invitar" (Miembros) ya compensan `bannerSlot`, pero el final del `ListView` queda por debajo del banner+NavBar cuando se scrollea hasta el fondo.
2. **BottomSheets tapados**: `InviteMemberSheet` compensa sólo la altura de la NavBar (hardcoded `56+12=68`), no el banner — los botones del sheet quedan ocultos. `RateEventSheet` (abierto desde Historial) sufre lo mismo.
3. **Pantallas fuera del shell sin banner**: `TaskDetailScreenV2`, `CreateEditTaskScreenV2` y `MemberProfileScreenV2` son rutas `push` fuera del `ShellRoute`. Nunca muestran el banner y no tienen reserva de espacio — inconsistente con el resto.
4. **Dead code V1**: el proyecto ya sólo usa skin V2 (`SkinConfig.current == AppSkin.v2` en cada ruta). Los archivos legacy V1 (pantallas y `MainShell`) son dead code.

## Objetivo

Que el AdBanner se comporte de forma consistente en las 7 pantallas objetivo (Hoy, Historial, Miembros, Lista de tareas, Crear/editar tarea, Detalle de tarea, Detalle de miembro):

- El banner se ve completo siempre que `adBannerConfig.show` sea `true`.
- Cualquier FAB queda visible encima del banner.
- El final de una lista scrollable queda por encima del banner (no tapado).
- Cualquier BottomSheet abierto desde esas pantallas tiene sus acciones visibles encima del banner.
- Si no hay banner (premium, carga inicial, flag off), los FABs y el scroll se comportan como si nunca hubiera existido.

## Decisiones clave

- **Wrapper compartido `AdAwareScaffold`** para pantallas fuera del shell.
- **Helper puro `bottomSheetSafeBottom`** para todos los BottomSheets.
- **Scroll de las listas no pasa por detrás del banner**: se añade padding inferior al `ScrollView` (el banner ya tiene fondo opaco con sombra, dejar contenido detrás degrada la legibilidad).
- **Eliminación total de V1**: pantallas legacy, `MainShell` y el switch `SkinConfig` por ruta.

## Arquitectura

### `AdAwareScaffold` — nuevo widget compartido

**Archivo:** `lib/shared/widgets/ad_aware_scaffold.dart`

Wrapper minimalista de `Scaffold` para pantallas fuera del shell. Replica el patrón de `MainShellV2` pero sin NavBar: reserva espacio para el banner, lo pinta vía `Positioned` y expone el padding correcto para los scrollables internos.

API:

```dart
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

  /// Altura total reservada en la parte inferior cuando el banner está
  /// visible (sin `safeBottom`). Usada por scrollables internos.
  static double bannerSlot({required bool bannerVisible}) {
    if (!bannerVisible) return 0;
    return AdBanner.kBannerHeight + _kBannerGap;
  }

  /// Padding inferior total que los scrollables deben aplicar para que su
  /// último ítem quede por encima del banner.
  ///
  /// = safeBottom + bannerSlot(bannerVisible)
  static double bottomPaddingOf(BuildContext ctx, WidgetRef ref) {
    final safeBottom = MediaQuery.of(ctx).padding.bottom;
    final cfg = ref.watch(adBannerConfigProvider);
    final bannerVisible = cfg.show && cfg.unitId.isNotEmpty;
    return safeBottom + bannerSlot(bannerVisible: bannerVisible);
  }
}
```

Implementación (pseudo):

```
Scaffold(
  extendBody: true,
  backgroundColor: backgroundColor,
  appBar: appBar,
  bottomNavigationBar: SizedBox(
    height: safeBottom + bannerSlot(bannerVisible),
  ),
  body: Stack(
    children: [
      body,
      if (bannerVisible)
        Positioned(
          left: 0, right: 0,
          bottom: safeBottom + _kBannerGap,
          child: const AdBanner(key: Key('ad_banner')),
        ),
    ],
  ),
  floatingActionButton: floatingActionButton != null
      ? Padding(
          padding: EdgeInsets.only(
            bottom: bannerSlot(bannerVisible: bannerVisible),
          ),
          child: floatingActionButton,
        )
      : null,
)
```

Notas:

- La constante `_kBannerGap = 6` duplica la de `MainShellV2`. Se extrae a `AdBanner.kBannerGap` como fuente única y ambos la usan.
- `extendBody: true` permite que el fondo (`backgroundColor`) se extienda bajo el banner, evitando un rectángulo de otro color detrás del banner cuando su fondo semitransparente deje ver algo. El contenido real del `body` no queda tapado porque los scrollables aplican `bottomPaddingOf`, que reserva altura de banner + safeBottom.
- No se usa `InheritedWidget`: `bottomPaddingOf` lee `adBannerConfigProvider` vía `ref` y calcula en el sitio. Los consumidores son `ConsumerWidget`/`ConsumerStatefulWidget`, así que ya tienen `ref`.

### `bottomSheetSafeBottom` — helper puro para sheets

**Archivo:** `lib/shared/widgets/bottom_sheet_padding.dart`

```dart
double bottomSheetSafeBottom(
  BuildContext ctx,
  WidgetRef ref, {
  required bool hasNavBar,
}) {
  final mq = MediaQuery.of(ctx);
  final bannerCfg = ref.watch(adBannerConfigProvider);
  final bannerVisible = bannerCfg.show && bannerCfg.unitId.isNotEmpty;

  return mq.viewInsets.bottom
      + mq.viewPadding.bottom
      + (hasNavBar
          ? MainShellV2.kNavBarHeight + MainShellV2.kNavBarBottom
          : 0)
      + (bannerVisible
          ? AdBanner.kBannerHeight + AdBanner.kBannerGap
          : 0);
}
```

- `hasNavBar: true` para sheets abiertos desde pantallas del shell (Miembros, Historial, Lista de tareas, Hoy). `false` para sheets abiertos desde detalle (donde ya no hay NavBar).
- `viewInsets.bottom` compensa el teclado si está abierto.
- Los sheets existentes que hardcodean `kNavBarHeight + kNavBarBottom` migran a este helper.

## Cambios pantalla por pantalla

### Dentro del shell (MainShellV2 ya inyecta el banner)

1. **`TodayScreenV2`** — sin cambios. Sin scroll infinito bajo el banner problemático; ya verificado.
2. **`HistoryScreenV2`** — sin cambios estructurales. Verificar que si usa `ListView` y `RateEventSheet` se abre, el sheet use el nuevo helper (cambio está en el sheet, no en la pantalla).
3. **`MembersScreen`**:
   - El FAB "Invitar" ya aplica `Padding(bottom: bannerSlot)`. OK.
   - Añadir `padding: EdgeInsets.only(bottom: bannerSlot + navBarSlot + safeBottom)` al `ListView`. Extraer el cálculo en un helper inline o `MainShellV2.bottomContentPadding(...)`.
4. **`AllTasksScreenV2`**:
   - Sustituir el `padding: EdgeInsets.only(bottom: 96)` hardcoded del `ListView.builder` por el cálculo real `bannerSlot + navBarSlot + safeBottom`.
   - El FAB ya tiene `Padding(bottom: bannerSlot)`. OK.

Helper auxiliar: añadir a `MainShellV2` un método estático:

```dart
static double bottomContentPadding(BuildContext ctx, WidgetRef ref) {
  final safeBottom = MediaQuery.of(ctx).padding.bottom;
  final cfg = ref.watch(adBannerConfigProvider);
  final bannerVisible = cfg.show && cfg.unitId.isNotEmpty;
  return kNavBarHeight + kNavBarBottom + safeBottom
      + bannerSlotHeight(bannerVisible: bannerVisible);
}
```

### Fuera del shell (migrar a AdAwareScaffold)

5. **`TaskDetailScreenV2`**: `Scaffold` → `AdAwareScaffold`. El body actual es un scrollable (verificar en implementación si es `ListView` o `SingleChildScrollView`). Añadir padding inferior `AdAwareScaffold.bottomPaddingOf(ctx, ref)`.
6. **`CreateEditTaskScreenV2`**: `Scaffold` → `AdAwareScaffold`. El form scrollea; mismo padding inferior en el scrollable raíz.
7. **`MemberProfileScreenV2`**: `Scaffold` → `AdAwareScaffold`. El body es `ListView`; cambiar `padding: EdgeInsets.fromLTRB(16, 8, 16, 96)` por `EdgeInsets.fromLTRB(16, 8, 16, AdAwareScaffold.bottomPaddingOf(ctx, ref))`.

### Sheets

8. **`InviteMemberSheet`**: sustituir `bottomPadding` actual por `bottomSheetSafeBottom(context, ref, hasNavBar: true) + 16` (el +16 es el margen interno que ya usa).
9. **`RateEventSheet`**: aplicar el mismo helper con `hasNavBar: true` (se abre desde Historial).
10. **Otros sheets** que resulten tapados durante las pruebas manuales: mismo patrón.

## Eliminación de V1 (código, no infraestructura)

**Se mantiene** toda la infraestructura de skins, que seguirá viva para futuras V3, V4, etc.:

- `lib/core/theme/app_skin.dart` — `AppSkin` enum y `SkinConfig.current`.
- `SkinConfig.current` seguirá siendo el único punto de control.
- Los ternarios `SkinConfig.current == AppSkin.v2 ? ... : ...` en `lib/app.dart` se **simplifican** (no se eliminan del todo): como hoy sólo hay una skin operativa, la rama `else` desaparece y queda el `if`/el valor directo. Cuando llegue una V3, se reintroduce el ternario con la comparación que corresponda.

**Se elimina** el código V1 propiamente dicho (archivos completos):

- `lib/shared/widgets/main_shell.dart`
- `lib/features/tasks/presentation/today_screen.dart`
- `lib/features/tasks/presentation/all_tasks_screen.dart`
- `lib/features/tasks/presentation/task_detail_screen.dart`
- `lib/features/tasks/presentation/create_edit_task_screen.dart`
- `lib/features/history/presentation/history_screen.dart`
- `lib/features/members/presentation/member_profile_screen.dart`
- `lib/core/theme/app_theme.dart` (el tema de la skin V1; se mantiene `app_theme_v2.dart`).

Cambio en `AppSkin` enum:

```dart
// Antes
enum AppSkin { material, v2 }

// Después
enum AppSkin { v2 }
// Y cuando llegue la siguiente: enum AppSkin { v2, v3 }
```

El valor `material` se elimina porque ya no hay código que lo respalde. `v2` se deja igual para no tocar el único valor vivo.

Refactor de `lib/app.dart`:

- Quitar imports de los archivos V1 eliminados.
- Cada `GoRoute.builder` que hoy hace `SkinConfig.current == AppSkin.v2 ? V2() : Legacy()` pasa a devolver directamente `V2()`.
- El `builder` del `ShellRoute` pasa a ser siempre `MainShellV2(child: child)`.
- El switch `theme`/`darkTheme` entre `AppTheme` y `AppThemeV2` se resuelve a `AppThemeV2` directo.
- **No se elimina** el import ni el uso de `SkinConfig`/`AppSkin` como concepto: si está ya en desuso en los builders tras la simplificación, quedarse un `SkinConfig` importado sin referencias es aceptable (o se deja solo en `app_skin.dart`). La clase sigue existiendo para cuando vuelva a usarse.

Renombrar (fuera del scope estricto pero recomendado como follow-up): eliminar la carpeta `skins/` y mover las pantallas V2 a la raíz del feature, quitando el sufijo `V2`. Esto implicaría actualizar imports y tests. Se evalúa por separado.

Tests afectados:

- Tests que importan pantallas V1 → eliminarlos (no hay equivalencia que "migrar": los V2 ya tienen sus propios tests).
- Tests que usan `SkinConfig.current = AppSkin.material` → eliminar la línea (la skin por defecto ya es V2 y es la única).

## Verificación visual

Por cada pantalla objetivo, ciclo:

1. `flutter run -d emulator-5554` (o hot reload).
2. Login QA con el procedimiento de CLAUDE.md.
3. Navegar a la pantalla.
4. `adb exec-out screencap -p > /tmp/screen.png`.
5. Si la captura supera 1900px de alto (caso normal en 1080×2400), redimensionar antes de analizar.
6. Checks visuales:
   - Banner completo con su sombra.
   - FAB (si aplica) encima del banner.
   - Scroll hasta el fondo: último ítem queda por encima del banner con gap visible (no pegado, no tapado).
   - Sheets: al abrirse, botón principal visible con banner activo; con teclado abierto, también.
7. Estados a cubrir: con banner (cuenta no premium) y sin banner (cuenta premium o `adFlags.showBanner=false`).

## Testing

- **`AdBanner` widget test** (existente): sin cambios.
- **`bottomSheetSafeBottom` unit test** nuevo: 8 casos (hasNavBar × bannerVisible × keyboardOpen).
- **`AdAwareScaffold` widget test** nuevo: verificar que reserva espacio correcto en `bottomNavigationBar`, que pinta `AdBanner` cuando `show=true`, y que no lo pinta cuando `show=false`.
- **Regresión UI** (golden o widget test) de `AllTasksScreenV2`, `MembersScreen`, `MemberProfileScreenV2`: el FAB y el final de la lista quedan sobre el banner.
- **`InviteMemberSheet` widget test** nuevo: con banner simulado activo, el botón "Enviar" es visible (no offscreen) y respeta `viewInsets` cuando hay teclado.

## Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Eliminar V1 rompe imports transitivos | `flutter analyze` tras el borrado; cualquier referencia a `TodayScreen`/`MainShell`/etc. salta como error y se migra |
| Tests V1 romperían CI tras el borrado | Se identifican y eliminan/migran en el mismo commit |
| `extendBody: true` + `AdAwareScaffold` dobla padding inferior por error | `bottomPaddingOf` es la única fuente: scrollables lo usan, FAB no (ya lo compensa el wrapper con `Padding`) |
| Banner se refresca cada 60s y hace un rebuild del `Positioned`: scroll puede saltar | `AdBanner` es un widget interno con `SizedBox` fijo durante recarga — no cambia la altura del layout |
| Sheets ya no pasan `ref`: `ConsumerStatefulWidget` implica convertir alguno | `InviteMemberSheet` y `RateEventSheet` ya son `ConsumerStatefulWidget`. Cualquier sheet nuevo que no lo sea, se convierte al migrar |

## Fuera de scope

- Rediseño visual del banner (sombra, bordes). Se reutiliza el widget actual.
- Cambios en `adBannerConfigProvider` o en el dashboard flags.
- Pantalla de Ajustes (no estaba en el listado del usuario).
- `OnboardingFlowScreen`, `MyHomesScreen`, `HomeSettingsScreen`: no aparecen en el alcance pedido. Si luego se quiere extender, se reutilizará `AdAwareScaffold` sin cambios.
