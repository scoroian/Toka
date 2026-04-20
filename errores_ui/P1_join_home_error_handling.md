# P1 — Errores de "Unirse al hogar" silenciados en la UI

## Bug que corrige
- **Bug #17** — Errores genéricos en `joinHome()` se silencian. El `HomeJoinForm` solo muestra UI de error para `'invalid_invite'` y `'expired_invite'`. Cualquier otra excepción (`FirebaseException`, network error, etc.) se captura con `catch (e)` y el string se guarda en state pero no se muestra al usuario. El botón "Unirme" no hace nada visible.

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `lib/features/onboarding/presentation/home_join_form.dart` | Mostrar todos los tipos de error |
| `lib/features/onboarding/application/onboarding_view_model.dart` | Propagar errores correctamente |

## Cambios requeridos

### 1. Mostrar el error genérico en la UI

En `HomeJoinForm`, el widget que muestra el error debe cubrir todos los casos:

```dart
// ANTES — solo maneja casos específicos
if (state.error == 'invalid_invite')
  Text(l10n.invalidInviteCode, style: errorStyle),
else if (state.error == 'expired_invite')
  Text(l10n.expiredInviteCode, style: errorStyle),

// DESPUÉS — muestra cualquier error
if (state.error != null)
  Text(
    switch (state.error!) {
      'invalid_invite' => l10n.invalidInviteCode,
      'expired_invite' => l10n.expiredInviteCode,
      'network_error' => l10n.networkError,
      _ => l10n.unexpectedError, // fallback genérico
    },
    style: errorStyle,
  ),
```

### 2. Mejorar la propagación del error en el ViewModel

En `OnboardingViewModel.joinHome()`:

```dart
Future<void> joinHome(String code) async {
  state = state.copyWith(isLoading: true, error: null);
  try {
    await ref.read(homeRepositoryProvider).joinHome(code);
    state = state.copyWith(isLoading: false, step: OnboardingStep.done);
  } on FirebaseException catch (e) {
    final errorCode = e.code == 'permission-denied'
        ? 'permission_denied'
        : e.code == 'not-found'
            ? 'invalid_invite'
            : 'firebase_error';
    state = state.copyWith(isLoading: false, error: errorCode);
  } catch (e) {
    // Distinguir entre tipos de error
    final errorCode = e is SocketException ? 'network_error' : 'unexpected_error';
    state = state.copyWith(isLoading: false, error: errorCode);
  }
}
```

### 3. Claves ARB requeridas

```json
"networkError": "Sin conexión a internet. Comprueba tu red e inténtalo de nuevo.",
"unexpectedError": "Ha ocurrido un error inesperado. Inténtalo de nuevo.",
"permissionDeniedError": "No tienes permiso para unirte a este hogar."
```

## Criterios de aceptación

- [ ] Si el código es inválido, el usuario ve "Código de invitación inválido".
- [ ] Si el código está expirado, el usuario ve "El código de invitación ha caducado".
- [ ] Si hay un error de red, el usuario ve "Sin conexión a internet...".
- [ ] Si hay cualquier otro error, el usuario ve el mensaje genérico.
- [ ] El mensaje de error desaparece cuando el usuario modifica el campo de código.
- [ ] El botón "Unirme" nunca parece "no hacer nada" — siempre hay feedback visual (loader o error).

## Tests requeridos

- Test unitario: `OnboardingViewModel.joinHome('INVALID')` con repository que lanza `FirebaseException(code: 'not-found')` → `state.error == 'invalid_invite'`.
- Test unitario: `joinHome()` con `SocketException` → `state.error == 'network_error'`.
- Test de widget: `HomeJoinForm` con `state.error = 'unexpected_error'` → muestra el texto genérico de error.
