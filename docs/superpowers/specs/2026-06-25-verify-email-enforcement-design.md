# Diseño — Hallazgo #03: `/verify-email` dead-end + enforcement de email verificado

**Fecha:** 2026-06-25
**Lote:** UX Hallazgos 2026-06-25 (prompt `03-auth-verify-email-deadend-enforcement.md`)
**Decisión de producto:** **Modelo A — enforcement estricto** (confirmado por el usuario; lo exige spec-02 regla #5).

---

## Problema

Dos defectos acoplados:

1. **Dead-end:** tras registrarse, la app fuerza `/verify-email`, una pantalla con un único botón "Reenviar". No hay "Continuar", ni `reload()`, ni salida. El usuario verifica en su correo, vuelve y **no pasa nada**: la única salida es matar la app.
2. **Sin enforcement:** el router (`lib/app.dart` `RouterNotifier.redirect`) decide por `authenticated` + tener hogar; **nunca lee `user.emailVerified`**. `AuthFailure.emailNotVerified` existe pero no se usa. La pantalla de verificación es puramente cosmética.

## Decisión

**Modelo A (enforcement estricto).** Un usuario **email/contraseña** sin verificar queda retenido en `/verify-email` y no puede operar hasta verificar. Las cuentas sociales (Google/Apple) llegan con `emailVerified=true`, así que el gate no les afecta. El arreglo del dead-end (salida real) hace la fricción recuperable y es el patrón estándar.

---

## Arquitectura por capas

### 1. Dominio + datos — recargar el usuario desde Firebase

`firebase_auth` **no** re-emite por `authStateChanges()` cuando el email se verifica en el servidor; hay que recargar explícitamente.

- **`AuthRepository`** (`domain/auth_repository.dart`): nuevo método
  ```dart
  Future<AuthUser> reloadUser();
  ```
- **`AuthRepositoryImpl`** (`data/auth_repository_impl.dart`):
  ```dart
  @override
  Future<AuthUser> reloadUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw const AuthFailure.unknown('No current user');
      await user.reload();
      final refreshed = _auth.currentUser;
      if (refreshed == null) {
        throw const AuthFailure.unknown('No current user after reload');
      }
      return AuthUser.fromFirebaseUser(refreshed);
    } on FirebaseAuthException catch (e) {
      throw _map(e); // red, too-many-requests, etc.
    }
  }
  ```
- **Coste de compilación:** toda clase que `implements AuthRepository` debe añadir `reloadUser`. Fakes a actualizar (enumeradas con `grep -rln "implements AuthRepository" test`): **`test/unit/features/auth/auth_provider_test.dart`** y **`test/unit/features/auth/verify_email_view_model_test.dart`** (solo 2). `auth_repository_impl_test` mockea `FirebaseAuth`, no `AuthRepository` → no afectado.

### 2. Estado global — que el router reaccione

- **`Auth`** (`application/auth_provider.dart`): nuevo método
  ```dart
  Future<bool> refreshEmailVerified() async {
    final fresh = await _repo.reloadUser();      // puede lanzar AuthFailure
    state = AuthState.authenticated(fresh);      // re-evalúa el router
    return fresh.emailVerified;
  }
  ```
- El UID no cambia → `RouterNotifier` re-evalúa el redirect **sin** invalidar `currentHomeProvider`/`onboardingCompletedProvider` (la guarda `prevUid != nextUid` no se dispara). Si `emailVerified` pasó a `true`, el `AuthUser` es distinto (igualdad freezed) → cambia el estado → `notify()` → redirect avanza. Si sigue `false`, el estado es igual → no hay rebote inútil.
- `authStateChanges()` no emite en `reload()`, así que el listener de `Auth.build()` no pisa el estado manual.

### 3. Router — el gate (corazón del enforcement)

En `RouterNotifier.redirect`, rama `authenticated(user)`, **antes** de la lógica de hogar/onboarding:

```dart
authenticated: (user) {
  // Enforcement de verificación de email (modelo A, spec-02 regla #5):
  // solo afecta a cuentas email/contraseña; Google/Apple llegan verificadas.
  final needsVerification =
      user.providers.contains('password') && !user.emailVerified;
  if (needsVerification) {
    return location == AppRoutes.verifyEmail ? null : AppRoutes.verifyEmail;
  }
  // ... (lógica actual de hogar/onboarding sin cambios) ...
}
```

- `'password'` es el `providerId` de email/contraseña en Firebase.
- Verificado o social → flujo intacto. El orden correcto queda **verificar → onboarding → operar**.
- **Comportamiento legacy:** usuarios email/contraseña sin verificar quedan retenidos al reabrir la app. Correcto por spec; aceptable porque la app aún no está publicada (dev).

### 4. View model — `VerifyEmailViewModel`

Ampliar la interfaz (conservando `email`, `resendCooldownSeconds`, `isSending`, `resendVerification`):

```dart
enum VerifyCheckOutcome { verified, notVerified, networkError, unknownError }

abstract class VerifyEmailViewModel {
  String get email;
  int get resendCooldownSeconds;
  bool get isSending;
  bool get isChecking;                          // recargando → spinner/disable
  Future<void> resendVerification();
  Future<VerifyCheckOutcome> continueIfVerified();
  Future<void> cancelAndSignOut();
}
```

- `continueIfVerified()`: pone `isChecking=true`; llama `ref.read(authProvider.notifier).refreshEmailVerified()`; mapea `AuthFailure.networkError → networkError`, otros `AuthFailure`/error → `unknownError`; `true → verified`, `false → notVerified`. En `verified` el router avanza solo (cambio de estado).
- `cancelAndSignOut()`: `ref.read(authRepositoryProvider).signOut()` → router → `/login`. Es el botón "Volver".
- Estado freezed amplía con `@Default(false) bool isChecking`.

### 5. Pantalla — `VerifyEmailScreen` → `ConsumerStatefulWidget`

- Botones:
  - **Reenviar** (existente, cooldown 60s).
  - **Ya verifiqué / Continuar** — key `btn_continue_verification`; disabled mientras `isChecking`; llama `continueIfVerified()` y traduce el outcome a SnackBar (`persist:false`):
    - `notVerified` → `auth_verify_email_not_yet`.
    - `networkError` → clave de red.
    - `unknownError` → clave de error genérico.
    - `verified` → sin UI (el router avanza).
  - **Volver** — `TextButton`; llama `cancelAndSignOut()`.
- **Polling suave:** `Timer.periodic` cada 4s mientras la pantalla está visible + recheck en `didChangeAppLifecycleState(resumed)`, llamando a una comprobación **silenciosa** (no muestra SnackBar en `notVerified`; solo avanza si verifica). Se cancela en `dispose`. Esto cubre "al volver del correo, la app avanza sin reinicio manual" aunque el usuario no pulse Continuar.

### 6. i18n (es/en/ro)

Añadir a `app_es.arb`, `app_en.arb`, `app_ro.arb` (y regenerar localizaciones):

| Clave | es (referencia) |
|---|---|
| `auth_verify_email_continue` | "Ya verifiqué, continuar" |
| `auth_verify_email_back` | "Volver" |
| `auth_verify_email_not_yet` | "Aún no detectamos la verificación. Revisa tu correo y vuelve a intentarlo." |
| `auth_verify_email_checking` | "Comprobando…" |

Errores: **reusar** claves existentes — red → `auth_error_network` ("Error de red. Comprueba tu conexión."); genérico (`unknownError`) → `error_generic`. No se añaden claves de error nuevas.

---

## Tests

### Unit / Widget
- **`app_router_redirect_test.dart`** (extender):
  - `authenticated` + `providers:['password']` + `emailVerified:false` → redirige a `verifyEmail` desde `splash`, `home`, `onboarding`.
  - Misma cuenta ya en `/verify-email` → `null` (se queda).
  - `emailVerified:true` (password) → flujo normal (no bloquea).
  - `providers:['google.com']` + `emailVerified:true` → no bloquea aunque… (social siempre verificado).
- **`verify_email_view_model_test.dart`** (extender; añadir `reloadUser` al fake):
  - `continueIfVerified` con repo que devuelve verificado → `verified`.
  - con repo que devuelve no verificado → `notVerified`.
  - con repo que lanza `networkError` → `networkError`.
  - cooldown de reenvío (60s) intacto.
- **`verify_email_screen_test.dart`** (extender; actualizar mock por la interfaz ampliada):
  - botón "Continuar" presente.
  - outcome `notVerified` → muestra SnackBar.
  - botón "Volver" invoca `cancelAndSignOut`.
- **`auth_repository_impl_test.dart`** (extender): `reloadUser` feliz (mock `User.reload`) + mapeo de `FirebaseAuthException` a `AuthFailure`.

### Verificación en dispositivo (Firebase real, `main.dart`, MI_9 + emulador)
1. Registrar cuenta nueva por email → **no** queda atrapado: hay "Continuar" y "Volver".
2. Verificar desde el enlace real → al volver (o por polling) la app avanza sin matarla. Capturas antes/después.
3. Sin verificar **no** puede crear hogar/operar; con verificar sí (modelo A).
4. "Continuar" sin red → mensaje claro, sin colgarse.

---

## Gates de cierre (de `_CONVENCIONES.md`)
1. `flutter analyze` sin errores.
2. `flutter test test/unit/` + tests nuevos verde (documentar los ~6 goldens preexistentes que fallan por entorno sin red).
3. Verificación en ambos dispositivos contra Firebase real, con capturas.
4. Actualizar `INDICE.md` (✅ + fecha + nota: modelo A elegido). Trabajo **sin commitear** salvo petición explícita.

## Fuera de alcance
- Backend / Cloud Functions (no hay enforcement server-side de `emailVerified` en este hallazgo; el gate es de cliente/router).
- Vinculación de proveedores (hallazgo #22) y errores de cancelación de Google (#13).

## Addendum (verificación en dispositivo, 2026-06-25)
La verificación en dispositivo destapó un bug que los tests unitarios no cubrían: pulsar **"Volver"** (signOut) desde `/verify-email` NO sacaba al usuario de la pantalla (otro dead-end), porque las ramas `unauthenticated` y `error` de `redirect` usaban `authScreens` —que incluye `verifyEmail`— como conjunto de "quedarse". Fix: nueva const `unauthScreens` (login/register/forgotPassword, **sin** verifyEmail) usada en esas dos ramas; `verifyEmail` solo es destino válido para un usuario autenticado-sin-verificar. Test de regresión añadido (`unauthenticated`/`error` + `/verify-email` → `/login`). Verificado en MI_9 tras rebuild.
