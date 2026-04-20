# P0 — Spinner infinito en pantalla de Notificaciones

## Bug que corrige
- **Bug #29** — `NotificationSettingsScreen` muestra un `CircularProgressIndicator` indefinidamente. La pantalla de ajustes de notificaciones es inutilizable.

## Causa raíz confirmada

En `lib/features/notifications/application/notification_settings_view_model.dart` líneas ~44-59:

```dart
@override
Future<_NotifVMState> build() async {
  final prefsAsync = ref.watch(notifPrefsProvider);
  final sub = ref.watch(subscriptionStateProvider);

  if (!state.isLoaded) {
    Future.microtask(() => state = _NotifVMState(isLoaded: true, ...));
  }
  return _NotifVMState(isLoaded: false, ...); // ← siempre devuelve false
}
```

El problema: cuando `subscriptionStateProvider` cambia (al resolver `currentHomeProvider` al inicio de sesión), `build()` se re-invoca y devuelve `_NotifVMState(isLoaded: false)`. La guardia `if (!state.isLoaded)` lee el estado **anterior** (ya `true`) y no reprograma el microtask. El estado queda permanentemente en `isLoaded: false`.

## Archivos a modificar

| Archivo | Líneas |
|---------|--------|
| `lib/features/notifications/application/notification_settings_view_model.dart` | ~44-59 |

## Cambio requerido

Reemplazar el patrón `Future.microtask + isLoaded` por un `return` directo basado en el estado de los providers observados:

```dart
// ANTES (problemático)
@override
Future<_NotifVMState> build() async {
  final prefsAsync = ref.watch(notifPrefsProvider);
  final sub = ref.watch(subscriptionStateProvider);

  if (!state.isLoaded) {
    Future.microtask(() => state = _NotifVMState(isLoaded: true, ...));
  }
  return _NotifVMState(isLoaded: false);
}

// DESPUÉS (correcto)
@override
Future<_NotifVMState> build() async {
  final prefsAsync = await ref.watch(notifPrefsProvider.future);
  ref.watch(subscriptionStateProvider); // solo para invalidar cuando cambia

  return _NotifVMState(
    isLoaded: true,
    pushEnabled: prefsAsync.pushEnabled,
    dailyReminder: prefsAsync.dailyReminder,
    // ... resto de campos desde prefsAsync
  );
}
```

Si el provider `notifPrefsProvider` es un `FutureProvider`, usar `AsyncNotifier` y `build()` devuelve directamente el estado final:

```dart
@riverpod
class NotificationSettingsViewModelNotifier
    extends AsyncNotifier<_NotifVMState> {
  
  @override
  Future<_NotifVMState> build() async {
    // Observar dependencias para invalidación automática
    ref.watch(subscriptionStateProvider);
    
    // Obtener prefs sin microtask
    final prefs = await ref.watch(notifPrefsProvider.future);
    
    return _NotifVMState(
      isLoaded: true,
      pushEnabled: prefs.pushEnabled,
      // ...
    );
  }
}
```

En la UI, usar `AsyncValue.when` de Riverpod para manejar el estado de carga:

```dart
// En NotificationSettingsScreen
final vmState = ref.watch(notificationSettingsViewModelNotifierProvider);

return vmState.when(
  loading: () => const CircularProgressIndicator(),
  error: (e, st) => ErrorWidget(e),
  data: (state) => _NotifSettingsBody(state: state),
);
```

## Criterios de aceptación

- [ ] `NotificationSettingsScreen` carga y muestra los toggles en menos de 2 segundos.
- [ ] El spinner desaparece y los switches son interactuables.
- [ ] Al volver a la pantalla (pop y push), los toggles mantienen el estado guardado.
- [ ] No hay regresión al cambiar de usuario (re-login no produce spinner infinito).

## Tests requeridos

- Test unitario: `NotificationSettingsViewModelNotifier.build()` con prefs mock → devuelve `isLoaded: true`.
- Test unitario: al invalidar `subscriptionStateProvider`, el VM se reconstruye y sigue devolviendo `isLoaded: true`.
- Test de widget: `NotificationSettingsScreen` con provider mock → no muestra `CircularProgressIndicator` después de 500ms.
