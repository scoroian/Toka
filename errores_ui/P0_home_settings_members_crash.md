# P0 — Crash en HomeSettings → Miembros (assertion navigator key)

## Bug que corrige
- **Bug #19** — Al pulsar el botón "Miembros" dentro de `HomeSettingsScreen`, la app se cierra con crash de Flutter: `Failed assertion: line 5066 pos 12: '!keyReservation.contains(key)' is not true` en `navigator.dart`. Reproducible para Owner y Admin. La pantalla de ajustes del hogar queda completamente inaccesible.

## Causa raíz probable

El error `!keyReservation.contains(key)` se produce cuando un `Navigator` intenta usar un `GlobalKey` que ya está registrado en otro widget del árbol. Causas típicas:

1. **Reutilización de GlobalKey**: La pantalla de Miembros (o un widget dentro de ella) crea un `GlobalKey` en el constructor del widget, lo que provoca que al navegar dos veces al mismo widget se intente registrar la misma key.
2. **Nested Navigator con go_router**: Si `HomeSettingsScreen` navega a una sub-ruta que ya está activa en el Navigator raíz de go_router, se produce conflicto de keys.
3. **Widget duplicado en el árbol**: Un BottomSheet o Dialog que permanece en el árbol cuando se intenta abrir la pantalla de Miembros.

## Archivos a investigar

| Archivo | Qué buscar |
|---------|-----------|
| `lib/features/homes/presentation/home_settings_screen.dart` | Cómo navega a la pantalla de Miembros |
| `lib/features/members/presentation/members_screen.dart` | ¿Tiene GlobalKey en nivel de clase o de `State`? |
| `lib/app.dart` | ¿Hay rutas anidadas que conflicten? |
| Cualquier widget que use `GlobalKey` en Members | Verificar que se instancian dentro de `build()`, no como campo de clase |

## Cambios requeridos

### 1. Identificar el GlobalKey problemático

```bash
grep -rn "GlobalKey" lib/features/members/
grep -rn "GlobalKey" lib/features/homes/
```

### 2. Si el GlobalKey está como campo de clase, moverlo a `State`

```dart
// MAL — comparte la key entre instancias
class MemberListWidget extends StatefulWidget {
  final GlobalKey _key = GlobalKey(); // ❌ Se reutiliza
}

// BIEN — key única por instancia de State
class _MemberListWidgetState extends State<MemberListWidget> {
  final GlobalKey _key = GlobalKey(); // ✅ Recreada con cada State
}
```

### 3. Si la navegación abre una ruta que ya existe en el stack

En `home_settings_screen.dart`, verificar cómo se navega a Miembros:

```dart
// Si usa Navigator.push directamente:
// Reemplazar por go_router context.push('/members') para que go_router
// gestione el stack correctamente.

// Si ya usa go_router, verificar que la ruta no está duplicada en el stack.
```

### 4. Verificar que no se usa el mismo Navigator key en múltiples lugares

En `app.dart`, asegurar que el `navigatorKey` del router solo se pasa una vez:

```dart
// Solo debe haber UN GoRouter con un navigatorKey dado
final _router = GoRouter(
  navigatorKey: _rootNavigatorKey, // Solo una vez
  ...
);
```

## Criterios de aceptación

- [ ] Pulsar "Miembros" en `HomeSettingsScreen` navega a la lista de miembros sin crash.
- [ ] Navegar repetidamente a HomeSettings → Miembros → Atrás → Miembros no produce crash.
- [ ] Tanto Owner como Admin pueden acceder a la lista de miembros desde HomeSettings.
- [ ] No hay regresión en la pantalla principal de Miembros (tab de navegación).

## Tests requeridos

- Test de integración: navegar a HomeSettings → pulsar Miembros → verificar que se muestra la lista sin exception.
- Test de integración: navegar Miembros → Atrás → Miembros → verificar sin crash.
