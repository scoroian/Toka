# P0 — Race condition en router por currentHomeProvider keepAlive

## Bug que corrige
- **Bug #15** — Al cerrar sesión con Cuenta1 e iniciar sesión como Cuenta2 (nueva, sin hogar), `currentHomeProvider` retiene brevemente el valor del usuario anterior (es `keepAlive: true`). Cuando el redirect del router evalúa el estado, ve un hogar no-nulo y redirige a `/home` en lugar de `/onboarding`. La nueva cuenta nunca completa el onboarding.

## Causa raíz

`currentHomeProvider` está marcado como `keepAlive: true` en Riverpod, lo que significa que su valor persiste en memoria entre re-renders. Al cambiar de usuario:
1. `authStateProvider` emite el nuevo `User`.
2. `currentHomeProvider` aún devuelve el hogar del usuario anterior (caché).
3. El `redirect` del GoRouter evalúa `currentHome != null` → navega a `/home`.
4. El provider se invalida async y descubre que el nuevo usuario no tiene hogar, pero el router ya navegó.

**Workaround actual**: `adb shell pm clear com.toka.toka` antes de cada nuevo login.

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `lib/features/homes/application/current_home_provider.dart` | Invalidar provider al cambiar de usuario |
| `lib/app.dart` | Añadir guardia en redirect para estado `loading` del provider |

## Cambios requeridos

### 1. Invalidar currentHomeProvider al cambiar de usuario

En el provider que gestiona el estado de autenticación o en un efecto sobre `authStateProvider`:

```dart
// En un provider que observe authStateProvider
@riverpod
class CurrentHomeNotifier extends _$CurrentHomeNotifier {
  @override
  Future<Home?> build() async {
    // Observar el UID del usuario actual
    final user = ref.watch(authStateProvider).value;
    
    // Si el UID cambia, el provider se reconstruye automáticamente
    // porque está observando authStateProvider
    if (user == null) return null;
    
    return _fetchHomeForUser(user.uid);
  }
}
```

Si `currentHomeProvider` es un `StreamProvider`, asegurarse de que la stream se basa en el UID actual y se reinicia cuando el UID cambia:

```dart
@riverpod
Stream<Home?> currentHome(CurrentHomeRef ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);
  
  // La stream se reinicia automáticamente cuando user cambia,
  // porque ref.watch(authStateProvider) crea una dependencia.
  return _homeStreamForUser(user.uid);
}
```

### 2. Eliminar keepAlive o acotarlo

Si `currentHomeProvider` tiene `@riverpodKeepAlive`, eliminar la anotación para que Riverpod lo descarte cuando no hay listeners, o acotar el keepAlive:

```dart
// Antes
@riverpodKeepAlive
Future<Home?> currentHome(...) { ... }

// Después — sin keepAlive, o con keepAlive solo si hay listener activo
@riverpod
Future<Home?> currentHome(...) { ... }
```

### 3. Manejar estado loading en el redirect del router

En `app.dart`, el redirect de GoRouter debe retornar `null` (no redirigir) cuando los providers aún están cargando:

```dart
redirect: (context, state) {
  final authState = ref.read(authStateProvider);
  final homeState = ref.read(currentHomeProvider);
  
  // Si cualquier estado está cargando, no redirigir todavía
  if (authState.isLoading || homeState.isLoading) return null;
  
  final user = authState.value;
  final home = homeState.value;
  
  if (user == null) return '/login';
  if (home == null) return '/onboarding';
  return null; // usuario con hogar → dejar pasar
},
```

### 4. Invalidar manualmente al hacer logout

En la función de logout, invalidar explícitamente el provider antes de cambiar el estado de auth:

```dart
Future<void> signOut() async {
  ref.invalidate(currentHomeProvider); // Limpiar caché antes de logout
  await FirebaseAuth.instance.signOut();
}
```

## Criterios de aceptación

- [ ] Registrar Cuenta2 tras una sesión de Cuenta1 (sin `pm clear`) → Cuenta2 va a onboarding.
- [ ] Login de Cuenta2 tras logout de Cuenta1 → Cuenta2 va a onboarding si no tiene hogar.
- [ ] Login de Cuenta1 tras logout de Cuenta2 → Cuenta1 va a `/home` si tiene hogar.
- [ ] No hay flash de pantalla Home antes de redirigir a onboarding.

## Tests requeridos

- Test unitario: `currentHomeProvider` con cambio de UID → el valor anterior no persiste.
- Test de integración: login Cuenta1 → logout → login Cuenta2 sin hogar → verificar ruta es `/onboarding`.
- Test de integración: login Cuenta1 → logout → login Cuenta1 de nuevo → verificar ruta es `/home`.
