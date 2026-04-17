# Spec: Navegación con BACK — primer toque va a Hoy, segundo sale (Bug #39)

**Fecha:** 2026-04-17
**Estado:** Aprobado
**Bug:** #39 (pulsación de BACK desde cualquier tab navega directamente al launcher sin pasar por Hoy)

---

## Contexto

La barra de navegación de Toka es una `FloatingNavBar` custom implementada con `GestureDetector` + `context.go(route)`. Al ser custom, no hay ningún mecanismo de interceptación del botón físico BACK de Android ni del gesto de deslizamiento de iOS.

Comportamiento actual: pulsar BACK desde cualquier tab (Historial, Miembros, Tareas, Ajustes) cierra la app directamente porque Flutter devuelve la app al SO.

Comportamiento esperado:
- Si el tab activo **no es Hoy (índice 0)**: BACK navega a Hoy.
- Si el tab activo **es Hoy (índice 0)**: BACK sale de la app (comportamiento por defecto de Flutter).

**Archivo afectado:** `lib/shared/widgets/skins/main_shell_v2.dart`

---

## Solución

Envolver el `Scaffold` del `MainShellV2` en un `PopScope` que intercepte la acción de pop cuando el tab activo no es Hoy.

```dart
// main_shell_v2.dart — método build

@override
Widget build(BuildContext context) {
  final location  = GoRouterState.of(context).matchedLocation;
  final tabIndex  = _tabIndex(location);
  final safeBottom = MediaQuery.of(context).padding.bottom;

  return PopScope(
    // canPop = true solo cuando ya estamos en Hoy (índice 0),
    // lo que deja que Flutter salga de la app normalmente.
    canPop: tabIndex == 0,
    onPopInvokedWithResult: (didPop, _) {
      // Si didPop == true ya salió (tab == 0), no hacer nada.
      if (didPop) return;
      // Navegar a Hoy sin añadir entrada al historial de go_router.
      context.go(AppRoutes.home);
    },
    child: Scaffold(
      extendBody: true,
      bottomNavigationBar: SizedBox(
        height: _kNavBarHeight + _kNavBarBottom + safeBottom,
      ),
      body: Stack(
        children: [
          child,
          Positioned(
            left: 16, right: 16,
            bottom: _kNavBarBottom + safeBottom,
            child: _FloatingNavBar(selectedIndex: tabIndex),
          ),
        ],
      ),
    ),
  );
}
```

### Notas de implementación

- `PopScope.canPop` controla si Flutter permite el pop. Con `false`, Flutter llama `onPopInvokedWithResult` en lugar de salir.
- `onPopInvokedWithResult` reemplaza el obsoleto `onPopInvoked` desde Flutter 3.22. Usar `onPopInvokedWithResult` para compatibilidad futura.
- `context.go(AppRoutes.home)` en lugar de `context.pop()` porque la shell no tiene historial propio: queremos ir **a** Hoy, no "hacia atrás".
- No se necesita ningún cambio en las pantallas individuales ni en el router.

---

## Archivos afectados

| Archivo | Acción |
|---|---|
| `lib/shared/widgets/skins/main_shell_v2.dart` | Envolver `Scaffold` en `PopScope` |

---

## Tests requeridos

### Widget
- Con tab en Historial (índice 1): simular pop → el router navega a `AppRoutes.home`.
- Con tab en Miembros (índice 2): simular pop → el router navega a `AppRoutes.home`.
- Con tab en Tareas (índice 3): simular pop → el router navega a `AppRoutes.home`.
- Con tab en Ajustes (índice 4): simular pop → el router navega a `AppRoutes.home`.
- Con tab en Hoy (índice 0): `PopScope.canPop == true`, pop sale de la app (no redirige).
