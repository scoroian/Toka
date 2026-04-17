# Spec: Selector de hogar siempre visible en pantalla Hoy (Bug #36)

**Fecha:** 2026-04-17
**Estado:** Aprobado
**Bug:** #36 (HomeDropdownButton solo aparece con 2+ hogares)

---

## Contexto

En `TodayScreenV2`, el selector de hogar en la AppBar solo se muestra cuando el usuario tiene más de un hogar (`vm.homes.length > 1`). Si solo tiene uno, se muestra un `Text` estático con el título de la pantalla. Esto impide que el usuario con un único hogar acceda a las opciones de crear/unirse a otro hogar, y además es inconsistente con el comportamiento esperado.

**Código actual (`today_screen_v2.dart`, línea 54–61):**
```dart
appBar: AppBar(
  title: vm.homes.length > 1
      ? HomeDropdownButton(
          homes: vm.homes,
          onSelect: vm.selectHome,
          onCreateHome: () => showCreateHomeSheet(context, ref, vm.homes.length),
          onJoinHome:   () => showJoinHomeSheet(context, ref, vm.homes.length),
        )
      : Text(l10n.today_screen_title),
),
```

---

## Solución

Reemplazar la condición ternaria por `HomeSelectorWidget`, que ya encapsula toda la lógica de mostrar el nombre del hogar actual, abrir el sheet de selección/creación/unión, y manejar estados con 0, 1 o N hogares.

El widget `HomeSelectorWidget` (definido en `lib/features/homes/presentation/home_selector_widget.dart`) ya está importado en `today_screen_v2.dart` y tiene la función `showCreateHomeSheet` / `showJoinHomeSheet` disponibles.

**Cambio en `today_screen_v2.dart`, líneas 53–62:**

```dart
// Antes:
appBar: AppBar(
  title: vm.homes.length > 1
      ? HomeDropdownButton(
          homes: vm.homes,
          onSelect: vm.selectHome,
          onCreateHome: () => showCreateHomeSheet(context, ref, vm.homes.length),
          onJoinHome:   () => showJoinHomeSheet(context, ref, vm.homes.length),
        )
      : Text(l10n.today_screen_title),
),

// Después:
appBar: AppBar(
  title: HomeSelectorWidget(
    homes: vm.homes,
    currentHomeId: vm.currentHomeId,
    onSelect: vm.selectHome,
  ),
),
```

`HomeSelectorWidget` internamente ya muestra el nombre del hogar activo y presenta el sheet con opciones de crear/unirse cuando el usuario toca el selector, incluso con un único hogar.

> **Nota:** Verificar que `TodayViewModel` expone `currentHomeId` (o equivalente). Si no existe, añadir el getter al view model leyendo de `currentHomeProvider`.

---

## Archivos afectados

| Archivo | Acción |
|---|---|
| `lib/features/tasks/presentation/skins/today_screen_v2.dart` | Reemplazar condición ternaria por `HomeSelectorWidget` |
| `lib/features/tasks/application/today_view_model.dart` | Añadir `currentHomeId` getter si falta |

---

## Tests requeridos

### Widget
- Con `homes.length == 1`: el AppBar muestra `HomeSelectorWidget` (no un `Text` estático).
- Con `homes.length == 2`: el AppBar sigue mostrando `HomeSelectorWidget`.
- Con `homes.length == 0`: `HomeSelectorWidget` muestra el estado sin hogar (comportamiento ya cubierto por el widget).
- Tap sobre el selector con `homes.length == 1` abre el sheet de opciones (crear / unirse).
