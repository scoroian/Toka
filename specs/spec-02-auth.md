# Spec-02: Autenticación

**Dependencias previas:** Spec-00, Spec-01  
**Oleada:** Oleada 1

---

## Objetivo

Implementar el sistema de autenticación completo: Google Sign-In, Apple Sign-In, email/contraseña, recuperación de contraseña, verificación de email, vinculación de proveedores y cierre de sesión.

---

## Reglas de negocio

1. Los métodos de acceso son: Google, Apple y email con contraseña.
2. El cambio de contraseña está disponible **solo** para cuentas email/contraseña.
3. Las cuentas sociales pueden vincular otros proveedores para evitar cuentas duplicadas.
4. Si un usuario inicia sesión con un proveedor distinto al habitual, el sistema **debe** ofrecer vincular credenciales.
5. La verificación de email es obligatoria para cuentas email/contraseña antes de poder operar.
6. Al cerrar sesión, se limpia todo el estado local (providers de Riverpod).
7. La cuenta se crea una sola vez; las pertenencias a hogares se gestionan aparte.

---

## Archivos a crear

```
lib/features/auth/
├── data/
│   ├── auth_repository_impl.dart
│   └── exceptions/
│       └── auth_exceptions.dart
├── domain/
│   ├── auth_repository.dart
│   ├── auth_user.dart              (modelo freezed)
│   └── failures/
│       └── auth_failure.dart
├── application/
│   ├── auth_state.dart             (freezed)
│   └── auth_provider.dart
└── presentation/
    ├── login_screen.dart
    ├── register_screen.dart
    ├── forgot_password_screen.dart
    └── widgets/
        ├── social_auth_button.dart
        └── email_auth_form.dart
```

---

## Implementación

### 1. Modelo AuthUser

```dart
@freezed
class AuthUser with _$AuthUser {
  const factory AuthUser({
    required String uid,
    required String? email,
    required String? displayName,
    required String? photoUrl,
    required bool emailVerified,
    required List<String> providers,  // ["google.com", "password", ...]
  }) = _AuthUser;
  
  factory AuthUser.fromFirebaseUser(User user) => AuthUser(
    uid: user.uid,
    email: user.email,
    displayName: user.displayName,
    photoUrl: user.photoURL,
    emailVerified: user.emailVerified,
    providers: user.providerData.map((p) => p.providerId).toList(),
  );
}
```

### 2. Repositorio de autenticación

```dart
abstract interface class AuthRepository {
  Stream<AuthUser?> get authStateChanges;
  AuthUser? get currentUser;
  
  Future<AuthUser> signInWithGoogle();
  Future<AuthUser> signInWithApple();
  Future<AuthUser> signInWithEmailPassword(String email, String password);
  Future<AuthUser> registerWithEmailPassword(String email, String password);
  Future<void> sendPasswordResetEmail(String email);
  Future<void> sendEmailVerification();
  Future<void> linkWithGoogle();
  Future<void> linkWithApple();
  Future<void> linkWithEmailPassword(String email, String password);
  Future<void> updatePassword(String currentPassword, String newPassword);
  Future<void> signOut();
}
```

### 3. AuthState

```dart
@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated(AuthUser user) = _Authenticated;
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.error(AuthFailure failure) = _Error;
}
```

### 4. AuthProvider

```dart
@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  @override
  AuthState build() {
    // Escuchar cambios de estado de Firebase Auth
    ref.listen(
      authStateChangesProvider,
      (_, next) => next.whenData((user) {
        if (user != null) {
          state = AuthState.authenticated(user);
          // Inicializar locale del usuario
          ref.read(localeNotifierProvider.notifier).initialize(user.uid);
        } else {
          state = const AuthState.unauthenticated();
        }
      }),
    );
    return const AuthState.initial();
  }
  
  Future<void> signInWithGoogle() async { ... }
  Future<void> signInWithApple() async { ... }
  Future<void> signInWithEmail(String email, String password) async { ... }
  Future<void> register(String email, String password) async { ... }
  Future<void> signOut() async {
    await _repo.signOut();
    ref.invalidateSelf();
    // Limpiar todos los providers dependientes del hogar
    ref.invalidate(homesProvider);
  }
}
```

### 5. Manejo de proveedor duplicado

Cuando Firebase lanza `auth/account-exists-with-different-credential`:
1. Obtener los proveedores vinculados al email.
2. Mostrar un diálogo informando al usuario y ofreciendo vincular.
3. Si acepta, hacer sign-in con el proveedor existente y luego `linkWithCredential`.

### 6. Pantalla de login

- Botón "Continuar con Google" (Material style).
- Botón "Continuar con Apple" (solo iOS/macOS, HIG style).
- Separador "o" y formulario email/contraseña.
- Link "¿Olvidaste tu contraseña?".
- Link "Crear cuenta".
- Selector de idioma en la esquina superior derecha (icono de idioma → abre `LanguageSelectorWidget`).

### 7. Pantalla de registro

- Email, contraseña (con toggle visible/oculto), confirmar contraseña.
- Validaciones: email válido, contraseña mínimo 8 chars, coincidencia.
- Al registrar, enviar email de verificación y redirigir a pantalla de "Verifica tu email".
- Pantalla de verificación con botón "Reenviar email" (con cooldown de 60s).

### 8. Recuperación de contraseña

- Input de email.
- Botón "Enviar enlace".
- Confirmación visual de envío.

### 9. Gestión de proveedores en perfil

Vista "Gestionar acceso" (en la pantalla de perfil):
- Mostrar proveedores vinculados con iconos.
- Botón para vincular proveedores adicionales.
- Botón de cierre de sesión.
- Botón de cambio de contraseña (solo si el proveedor `password` está vinculado).

---

## Routing

```dart
// core/constants/routes.dart
class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const verifyEmail = '/verify-email';
  static const onboarding = '/onboarding';
  static const home = '/home';
  // ...
}
```

El router debe usar un `redirect` basado en `AuthState`:
- `initial/loading` → pantalla de splash.
- `unauthenticated` → `/login`.
- `authenticated` + sin hogares → `/onboarding`.
- `authenticated` + con hogares → `/home`.

---

## Tests requeridos

### Unitarios

**`test/unit/features/auth/auth_user_test.dart`**
- `AuthUser.fromFirebaseUser` mapea correctamente todos los campos.
- `providers` lista los proveedores correctamente.

**`test/unit/features/auth/auth_repository_impl_test.dart`** (con `firebase_auth_mocks`)
- `signInWithGoogle` devuelve `AuthUser` al éxito.
- `signInWithGoogle` lanza `AuthFailure.networkError` si no hay red.
- `signInWithEmailPassword` lanza `AuthFailure.invalidCredentials` con credenciales incorrectas.
- `registerWithEmailPassword` lanza `AuthFailure.emailAlreadyInUse` si el email existe.
- `sendPasswordResetEmail` completa sin error.
- `signOut` limpia el estado de Firebase Auth.

**`test/unit/features/auth/auth_provider_test.dart`**
- Estado inicial es `AuthState.initial`.
- Al recibir usuario de Firebase, estado cambia a `AuthState.authenticated`.
- Al recibir null de Firebase, estado cambia a `AuthState.unauthenticated`.
- `signOut` invalida providers de hogar.

### De integración

**`test/integration/features/auth/auth_flow_test.dart`** (emuladores)
- Registro con email/contraseña → usuario creado en Firebase Auth.
- Login con email/contraseña → devuelve AuthUser correcto.
- Login con credenciales incorrectas → error correcto.
- `signOut` → `authStateChanges` emite null.

### UI

**`test/ui/features/auth/login_screen_test.dart`**
- Pantalla renderiza los tres botones de auth.
- Botón Apple solo visible en iOS.
- Formulario de email muestra errores de validación al intentar enviar vacío.
- Estado de carga muestra un spinner.
- Golden test de la pantalla de login.

**`test/ui/features/auth/register_screen_test.dart`**
- Validación de email inválido.
- Validación de contraseña < 8 chars.
- Validación de contraseñas no coincidentes.

---

## Pruebas manuales requeridas al terminar esta spec

1. **Registro con email:**
   - Abrir la app → pantalla de login.
   - Tocar "Crear cuenta" → pantalla de registro.
   - Introducir email y contraseña válidos → se crea cuenta.
   - Verificar en Firebase Auth Emulator que el usuario existe.
   - Verificar que aparece la pantalla de "Verifica tu email".

2. **Login con email:**
   - Hacer logout si hay sesión.
   - Pantalla de login → email + contraseña → login exitoso.
   - Redirige a onboarding (si no tiene hogar) o home (si tiene hogar).

3. **Login con credenciales incorrectas:**
   - Pantalla de login → email + contraseña incorrecta → mensaje de error claro.
   - La app no se cuelga ni muestra pantalla en blanco.

4. **Recuperación de contraseña:**
   - Tocar "¿Olvidaste tu contraseña?" → pantalla de recuperación.
   - Introducir email → mensaje de confirmación de envío.
   - En el emulador, verificar que se generó el enlace de reset.

5. **Cierre de sesión:**
   - Estando en la app, ir a perfil → "Cerrar sesión".
   - Redirige a pantalla de login.
   - Volver atrás no debe llevar al home (limpieza de estado).

6. **Persistencia de sesión:**
   - Hacer login.
   - Cerrar completamente la app y volver a abrirla.
   - Debe reanudar la sesión sin pedir credenciales.

7. **Selector de idioma en login:**
   - Tocar el icono de idioma en la esquina de la pantalla de login.
   - Debe aparecer el selector con los tres idiomas.
   - Seleccionar un idioma → la pantalla de login se actualiza al idioma seleccionado.
