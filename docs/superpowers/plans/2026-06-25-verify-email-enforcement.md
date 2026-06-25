# Verify-Email Dead-End + Enforcement — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dar salida real a `/verify-email` (botón "Ya verifiqué/Continuar" con `reload()`, "Volver", polling suave) y exigir email verificado a las cuentas email/contraseña antes de operar (modelo A).

**Architecture:** El router (`RouterNotifier.redirect`) gana un gate `providers.contains('password') && !emailVerified → /verify-email`. El repo gana `reloadUser()` (recarga real desde Firebase, que no re-emite por stream). El notifier `Auth` gana `refreshEmailVerified()` que recarga y republica `AuthState.authenticated`, disparando la re-evaluación del router. La pantalla pasa a `ConsumerStatefulWidget` con polling y tres acciones.

**Tech Stack:** Flutter 3 / Dart 3, Riverpod (`@riverpod`), freezed, go_router, firebase_auth, mocktail, flutter_test, ARB/intl.

## Global Constraints

- **Modelo A confirmado:** verificar es **obligatorio** para cuentas email/contraseña; Google/Apple (`emailVerified=true`) no se ven afectados. El gate clave: `user.providers.contains('password') && !user.emailVerified`.
- **i18n:** nada de texto UI hardcodeado. Strings nuevas en `app_es.arb` (template), `app_en.arb`, `app_ro.arb`; acceso por `l10n.clave`. Regenerar con `flutter gen-l10n`.
- **Errores reusados (no añadir claves de error):** red → `l10n.auth_error_network`; genérico → `l10n.error_generic`.
- **Tests obligatorios** (CLAUDE.md): caso feliz + edge/error por unidad; widget para pantalla.
- **Mocks:** `mocktail` (no mockito).
- **SnackBars sin acción** → duración por defecto; no requieren `persist:false` (ese flag solo aplica a SnackBars CON acción).
- **Sin commitear:** el lote "UX Hallazgos 2026-06-25" deja el trabajo sin commitear; el usuario commitea en lote. Cada tarea termina ejecutando sus gates (analyze + tests), **no** `git commit`. No commitear salvo petición explícita del usuario.
- **build_runner:** tras tocar el `@freezed` del estado, `dart run build_runner build --delete-conflicting-outputs` (build completo; NO usar `--build-filter` con `--delete-conflicting-outputs` — borra outputs no relacionados).
- **Entorno tests:** ejecutar en WSL con `flutter test`. Si antes se hizo `pub get` en Windows, restaurar con `flutter pub get` en WSL (rutas `/C:/...` rompen los tests).

---

### Task 1: `reloadUser()` en el repositorio de auth

Recargar el `User` de Firebase y devolver un `AuthUser` fresco. `authStateChanges()` NO re-emite cuando el email se verifica server-side; por eso hace falta una recarga explícita.

**Files:**
- Modify: `lib/features/auth/domain/auth_repository.dart` (añadir método a la interfaz)
- Modify: `lib/features/auth/data/auth_repository_impl.dart` (implementar)
- Modify (compilación): `test/unit/features/auth/auth_provider_test.dart` (`_FakeRepo` gana `reloadUser`)
- Modify (compilación): `test/unit/features/auth/verify_email_view_model_test.dart` (`_FakeRepo` gana `reloadUser`)
- Test: `test/unit/features/auth/auth_repository_impl_test.dart`

**Interfaces:**
- Produces: `Future<AuthUser> AuthRepository.reloadUser()` — recarga y devuelve el usuario actual; lanza `AuthFailure` (red, etc.) o `AuthFailure.unknown` si no hay sesión.

- [ ] **Step 1: Escribir el test que falla** — añadir a `auth_repository_impl_test.dart` un nuevo grupo (antes del cierre `}` de `main`):

```dart
  group('reloadUser', () {
    test('returns refreshed AuthUser (emailVerified actualizado)', () async {
      final mockUser = _MockUser();
      _stubUser(mockUser, uid: 'reload-uid', emailVerified: true);
      when(() => mockUser.reload()).thenAnswer((_) async {});
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      final result = await repo.reloadUser();

      expect(result.uid, 'reload-uid');
      expect(result.emailVerified, true);
      verify(() => mockUser.reload()).called(1);
    });

    test('throws AuthFailure.networkError if reload fails (network)', () async {
      final mockUser = _MockUser();
      _stubUser(mockUser);
      when(() => mockUser.reload())
          .thenThrow(FirebaseAuthException(code: 'network-request-failed'));
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      await expectLater(
        () => repo.reloadUser(),
        throwsA(const AuthFailure.networkError()),
      );
    });

    test('throws AuthFailure.unknown if there is no current user', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      await expectLater(
        () => repo.reloadUser(),
        throwsA(isA<AuthFailure>()),
      );
    });
  });
```

- [ ] **Step 2: Ejecutar y verificar que falla**

Run: `flutter test test/unit/features/auth/auth_repository_impl_test.dart`
Expected: FAIL de compilación — `The method 'reloadUser' isn't defined for the type 'AuthRepositoryImpl'`.

- [ ] **Step 3: Implementar**

En `lib/features/auth/domain/auth_repository.dart`, añadir a la interfaz (junto a los demás métodos):

```dart
  Future<AuthUser> reloadUser();
```

En `lib/features/auth/data/auth_repository_impl.dart`, añadir el método (p. ej. tras `sendEmailVerification`):

```dart
  @override
  Future<AuthUser> reloadUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw const AuthFailure.unknown('No current user');
      }
      await user.reload();
      final refreshed = _auth.currentUser;
      if (refreshed == null) {
        throw const AuthFailure.unknown('No current user after reload');
      }
      return AuthUser.fromFirebaseUser(refreshed);
    } on FirebaseAuthException catch (e) {
      throw _map(e);
    }
  }
```

Actualizar las DOS fakes para que el suite compile.

En `test/unit/features/auth/verify_email_view_model_test.dart`, dentro de `_FakeRepo` (devuelve su `currentUser`, ya no-verificado):

```dart
  @override
  Future<AuthUser> reloadUser() async => currentUser!;
```

En `test/unit/features/auth/auth_provider_test.dart`, dentro de `_FakeRepo` (placeholder hasta la Task 2):

```dart
  @override
  Future<AuthUser> reloadUser() => throw UnimplementedError();
```

- [ ] **Step 4: Ejecutar y verificar que pasa**

Run: `flutter test test/unit/features/auth/auth_repository_impl_test.dart`
Expected: PASS (todos los grupos, incl. `reloadUser`).

- [ ] **Step 5: Gate**

Run: `flutter analyze lib/features/auth && flutter test test/unit/features/auth/`
Expected: analyze sin errores; todos los tests de auth verdes (las fakes ya compilan).

---

### Task 2: `Auth.refreshEmailVerified()` (republica el estado para el router)

**Files:**
- Modify: `lib/features/auth/application/auth_provider.dart`
- Test: `test/unit/features/auth/auth_provider_test.dart`

**Interfaces:**
- Consumes: `AuthRepository.reloadUser()` (Task 1).
- Produces: `Future<bool> Auth.refreshEmailVerified()` — recarga vía repo, hace `state = AuthState.authenticated(fresh)`, devuelve `fresh.emailVerified`. Propaga `AuthFailure` del repo.

- [ ] **Step 1: Escribir el test que falla** — en `auth_provider_test.dart`:

  (a) Hacer configurable `reloadUser` en `_FakeRepo`: añadir al constructor el parámetro y el campo, y reemplazar el `reloadUser` placeholder de la Task 1:

```dart
  // En el constructor de _FakeRepo, añadir:
  //   Future<AuthUser> Function()? reload,
  // y el campo:   final Future<AuthUser> Function()? _reload;
  // inicializando: _reload = reload,
  @override
  Future<AuthUser> reloadUser() =>
      _reload != null ? _reload() : throw UnimplementedError();
```

  (b) Añadir el test:

```dart
  test('refreshEmailVerified publica el usuario recargado y devuelve verified',
      () async {
    const verified = AuthUser(
      uid: 'uid',
      email: 'u@u.com',
      displayName: 'U',
      photoUrl: null,
      emailVerified: true,
      providers: ['password'],
    );
    container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
        localeNotifierProvider.overrideWith(() => _FakeLocaleNotifier()),
        authRepositoryProvider.overrideWithValue(
          _FakeRepo(reload: () async => verified),
        ),
        currentHomeProvider.overrideWith(() => _FakeCurrentHome()),
      ],
    );

    container.read(authProvider);
    final result =
        await container.read(authProvider.notifier).refreshEmailVerified();

    expect(result, true);
    expect(container.read(authProvider),
        const AuthState.authenticated(verified));
  });
```

- [ ] **Step 2: Ejecutar y verificar que falla**

Run: `flutter test test/unit/features/auth/auth_provider_test.dart`
Expected: FAIL — `The method 'refreshEmailVerified' isn't defined for the type 'Auth'`.

- [ ] **Step 3: Implementar** — en `lib/features/auth/application/auth_provider.dart`, dentro de `class Auth`, añadir (p. ej. tras `register`):

```dart
  /// Recarga el usuario desde Firebase y publica el estado para que el router
  /// re-evalúe (modelo A de verificación de email). Devuelve si quedó
  /// verificado. Propaga AuthFailure (p. ej. red) al llamante.
  Future<bool> refreshEmailVerified() async {
    final fresh = await _repo.reloadUser();
    state = AuthState.authenticated(fresh);
    return fresh.emailVerified;
  }
```

- [ ] **Step 4: Ejecutar y verificar que pasa**

Run: `flutter test test/unit/features/auth/auth_provider_test.dart`
Expected: PASS.

- [ ] **Step 5: Gate**

Run: `flutter analyze lib/features/auth && flutter test test/unit/features/auth/`
Expected: verde.

---

### Task 3: Gate de verificación en el router

**Files:**
- Modify: `lib/app.dart` (rama `authenticated` de `RouterNotifier.redirect`, ~líneas 135-160)
- Test: `test/unit/app_router_redirect_test.dart`

**Interfaces:**
- Consumes: `AuthUser.providers`, `AuthUser.emailVerified` (ya existen), `AppRoutes.verifyEmail`.

- [ ] **Step 1: Escribir el test que falla** — en `app_router_redirect_test.dart`, añadir dentro de `main`:

```dart
  group('enforcement de email verificado (modelo A, Hallazgo #03)', () {
    AuthState unverifiedPassword() => AuthState.authenticated(const AuthUser(
          uid: 'u',
          email: 'a@b.c',
          displayName: null,
          photoUrl: null,
          emailVerified: false,
          providers: ['password'],
        ));

    AuthState verifiedPassword() => AuthState.authenticated(const AuthUser(
          uid: 'u',
          email: 'a@b.c',
          displayName: null,
          photoUrl: null,
          emailVerified: true,
          providers: ['password'],
        ));

    AuthState socialUser() => AuthState.authenticated(const AuthUser(
          uid: 'g',
          email: 'g@b.c',
          displayName: null,
          photoUrl: null,
          emailVerified: true,
          providers: ['google.com'],
        ));

    test('password sin verificar en /home redirige a /verify-email', () {
      expect(_redirectFor(unverifiedPassword(), AppRoutes.home),
          AppRoutes.verifyEmail);
    });

    test('password sin verificar en /onboarding redirige a /verify-email', () {
      expect(_redirectFor(unverifiedPassword(), AppRoutes.onboarding),
          AppRoutes.verifyEmail);
    });

    test('password sin verificar en /splash redirige a /verify-email', () {
      expect(_redirectFor(unverifiedPassword(), AppRoutes.splash),
          AppRoutes.verifyEmail);
    });

    test('password sin verificar YA en /verify-email se queda', () {
      expect(_redirectFor(unverifiedPassword(), AppRoutes.verifyEmail), isNull);
    });

    test('password verificado en /verify-email avanza (no se queda)', () {
      // currentHome=null + onboardingCompleted=false → /onboarding.
      expect(_redirectFor(verifiedPassword(), AppRoutes.verifyEmail),
          AppRoutes.onboarding);
    });

    test('cuenta social no se bloquea aunque pase por /home', () {
      expect(_redirectFor(socialUser(), AppRoutes.home), isNull);
    });
  });
```

- [ ] **Step 2: Ejecutar y verificar que falla**

Run: `flutter test test/unit/app_router_redirect_test.dart`
Expected: FAIL — p. ej. `password sin verificar en /home` espera `/verify-email` pero hoy devuelve `null`.

- [ ] **Step 3: Implementar** — en `lib/app.dart`, en la rama `authenticated:` del `return authState.when(...)`, sustituir la firma e insertar el gate **al inicio**. Reemplazar:

```dart
      authenticated: (_) {
        if (authScreens.contains(location) || location == AppRoutes.splash) {
```

por:

```dart
      authenticated: (user) {
        // Enforcement de verificación de email (modelo A, spec-02 regla #5):
        // solo afecta a cuentas email/contraseña; Google/Apple llegan
        // verificadas. Sin verificar → retener en /verify-email hasta verificar.
        final needsVerification =
            user.providers.contains('password') && !user.emailVerified;
        if (needsVerification) {
          return location == AppRoutes.verifyEmail
              ? null
              : AppRoutes.verifyEmail;
        }
        if (authScreens.contains(location) || location == AppRoutes.splash) {
```

(El resto de la rama `authenticated` queda igual.)

- [ ] **Step 4: Ejecutar y verificar que pasa**

Run: `flutter test test/unit/app_router_redirect_test.dart`
Expected: PASS (nuevos + los existentes; el test "pérdida de hogar" usa `emailVerified: true`, sigue verde).

- [ ] **Step 5: Gate**

Run: `flutter analyze lib/app.dart && flutter test test/unit/app_router_redirect_test.dart`
Expected: verde.

---

### Task 4: Ampliar `VerifyEmailViewModel` (continuar / poll / volver)

**Files:**
- Modify: `lib/features/auth/application/verify_email_view_model.dart`
- Regen: `lib/features/auth/application/verify_email_view_model.freezed.dart` (build_runner)
- Test: `test/unit/features/auth/verify_email_view_model_test.dart`

**Interfaces:**
- Consumes: `Auth.refreshEmailVerified()` (Task 2), `authRepositoryProvider.signOut()`.
- Produces:
  - `enum VerifyCheckOutcome { verified, notVerified, networkError, unknownError }`
  - `bool VerifyEmailViewModel.isChecking`
  - `Future<VerifyCheckOutcome> VerifyEmailViewModel.continueIfVerified()`
  - `Future<void> VerifyEmailViewModel.pollVerification()` (silencioso)
  - `Future<void> VerifyEmailViewModel.cancelAndSignOut()`

- [ ] **Step 1: Escribir el test que falla** — añadir al `_FakeRepo` de `verify_email_view_model_test.dart` un `reloadUser` configurable y nuevos tests. Reemplazar el `reloadUser` fijo (de la Task 1) por uno parametrizable y añadir un flag de signOut:

```dart
class _FakeRepo implements AuthRepository {
  _FakeRepo({this.reloadResult, this.reloadError});
  final AuthUser? reloadResult;
  final Object? reloadError;
  bool signedOut = false;

  @override
  Future<AuthUser> reloadUser() async {
    if (reloadError != null) throw reloadError!;
    return reloadResult ?? currentUser!;
  }

  @override
  Future<void> signOut() async {
    signedOut = true;
  }
  // ... (resto de overrides existentes sin cambios) ...
```

Añadir los tests (no hace falta override de `currentHomeProvider` ni `localeNotifierProvider`: el stream de auth va vacío y `refreshEmailVerified` no llama a `initialize`):

```dart
  group('continueIfVerified', () {
    test('verified cuando reloadUser devuelve emailVerified=true', () async {
      const verified = AuthUser(
        uid: 'u',
        email: 'test@test.com',
        displayName: 'U',
        photoUrl: null,
        emailVerified: true,
        providers: ['password'],
      );
      container = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(
            _FakeRepo(reloadResult: verified)),
        authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
      ]);
      final vm = container.read(verifyEmailViewModelProvider);
      expect(await vm.continueIfVerified(), VerifyCheckOutcome.verified);
    });

    test('notVerified cuando sigue sin verificar', () async {
      container = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(_FakeRepo()),
        authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
      ]);
      final vm = container.read(verifyEmailViewModelProvider);
      expect(await vm.continueIfVerified(), VerifyCheckOutcome.notVerified);
    });

    test('networkError cuando reloadUser lanza AuthFailure.networkError',
        () async {
      container = ProviderContainer(overrides: [
        authRepositoryProvider.overrideWithValue(
            _FakeRepo(reloadError: const AuthFailure.networkError())),
        authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
      ]);
      final vm = container.read(verifyEmailViewModelProvider);
      expect(await vm.continueIfVerified(), VerifyCheckOutcome.networkError);
    });
  });

  test('cancelAndSignOut llama a signOut del repo', () async {
    final repo = _FakeRepo();
    container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(repo),
      authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
    ]);
    final vm = container.read(verifyEmailViewModelProvider);
    await vm.cancelAndSignOut();
    expect(repo.signedOut, true);
  });
```

Añadir el import necesario en el test: `import 'package:toka/features/auth/domain/failures/auth_failure.dart';`.

- [ ] **Step 2: Ejecutar y verificar que falla**

Run: `flutter test test/unit/features/auth/verify_email_view_model_test.dart`
Expected: FAIL de compilación — `VerifyCheckOutcome`/`continueIfVerified` no definidos.

- [ ] **Step 3: Implementar** — en `lib/features/auth/application/verify_email_view_model.dart`:

  (a) Añadir el import del failure (junto a los demás imports):

```dart
import '../domain/failures/auth_failure.dart';
```

  (b) Definir el enum encima del `abstract class`:

```dart
enum VerifyCheckOutcome { verified, notVerified, networkError, unknownError }
```

  (c) Ampliar la interfaz:

```dart
abstract class VerifyEmailViewModel {
  String get email;
  int get resendCooldownSeconds;
  bool get isSending;
  bool get isChecking;

  Future<void> resendVerification();
  Future<VerifyCheckOutcome> continueIfVerified();
  Future<void> pollVerification();
  Future<void> cancelAndSignOut();
}
```

  (d) Añadir el campo al estado freezed:

```dart
@freezed
class _VerifyEmailState with _$VerifyEmailState {
  const factory _VerifyEmailState({
    @Default('') String email,
    @Default(0) int resendCooldownSeconds,
    @Default(false) bool isSending,
    @Default(false) bool isChecking,
  }) = __VerifyEmailState;
}
```

  (e) Implementar en el notifier (tras `resendVerification`/`_startCooldown`):

```dart
  @override
  bool get isChecking => state.isChecking;

  @override
  Future<VerifyCheckOutcome> continueIfVerified() async {
    if (state.isChecking) return VerifyCheckOutcome.notVerified;
    state = state.copyWith(isChecking: true);
    try {
      final verified =
          await ref.read(authProvider.notifier).refreshEmailVerified();
      // Si quedó verificado, el router avanza y esta pantalla se desmonta:
      // NO tocamos el estado para evitar escribir tras el dispose.
      if (verified) return VerifyCheckOutcome.verified;
      state = state.copyWith(isChecking: false);
      return VerifyCheckOutcome.notVerified;
    } on AuthFailure catch (f) {
      state = state.copyWith(isChecking: false);
      return f.maybeWhen(
        networkError: () => VerifyCheckOutcome.networkError,
        orElse: () => VerifyCheckOutcome.unknownError,
      );
    } catch (_) {
      state = state.copyWith(isChecking: false);
      return VerifyCheckOutcome.unknownError;
    }
  }

  @override
  Future<void> pollVerification() async {
    try {
      await ref.read(authProvider.notifier).refreshEmailVerified();
    } catch (_) {
      // Silencioso: el polling no molesta al usuario con errores.
    }
  }

  @override
  Future<void> cancelAndSignOut() async {
    await ref.read(authRepositoryProvider).signOut();
  }
```

  Nota: `authProvider` y `authRepositoryProvider` ya están disponibles vía `import 'auth_provider.dart';`.

- [ ] **Step 4: Regenerar código generado**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: regenera `verify_email_view_model.freezed.dart` (estado con `isChecking`). Sin errores.

- [ ] **Step 5: Ejecutar y verificar que pasa**

Run: `flutter test test/unit/features/auth/verify_email_view_model_test.dart`
Expected: PASS (incl. los tests originales de cooldown).

- [ ] **Step 6: Gate**

Run: `flutter analyze lib/features/auth && flutter test test/unit/features/auth/`
Expected: verde.

---

### Task 5: Strings localizadas (es/en/ro)

**Files:**
- Modify: `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb`, `lib/l10n/app_ro.arb`
- Regen: `lib/l10n/app_localizations*.dart` (`flutter gen-l10n`)

**Interfaces:**
- Produces getters: `l10n.auth_verify_email_continue`, `l10n.auth_verify_email_back`, `l10n.auth_verify_email_not_yet`, `l10n.auth_verify_email_checking`.

- [ ] **Step 1: Añadir las claves** — en cada ARB, justo después del bloque `auth_resend_cooldown` / `@auth_resend_cooldown`, insertar:

`app_es.arb`:
```json
  "auth_verify_email_continue": "Ya verifiqué, continuar",
  "@auth_verify_email_continue": { "description": "Button: re-check email verification and continue" },
  "auth_verify_email_back": "Volver",
  "@auth_verify_email_back": { "description": "Button: leave verify-email screen (sign out)" },
  "auth_verify_email_not_yet": "Aún no detectamos la verificación. Revisa tu correo y vuelve a intentarlo.",
  "@auth_verify_email_not_yet": { "description": "SnackBar: email still not verified after manual check" },
  "auth_verify_email_checking": "Comprobando…",
  "@auth_verify_email_checking": { "description": "Button label while re-checking verification" },
```

`app_en.arb`:
```json
  "auth_verify_email_continue": "I've verified, continue",
  "auth_verify_email_back": "Back",
  "auth_verify_email_not_yet": "We haven't detected the verification yet. Check your email and try again.",
  "auth_verify_email_checking": "Checking…",
```

`app_ro.arb`:
```json
  "auth_verify_email_continue": "Am verificat, continuă",
  "auth_verify_email_back": "Înapoi",
  "auth_verify_email_not_yet": "Încă nu am detectat verificarea. Verifică-ți e-mailul și încearcă din nou.",
  "auth_verify_email_checking": "Se verifică…",
```

(En `app_es.arb` van con sus bloques `@`; en en/ro solo los valores, como el resto del archivo.)

- [ ] **Step 2: Regenerar localizaciones**

Run: `flutter gen-l10n`
Expected: sin errores; `app_localizations.dart` ahora declara `String get auth_verify_email_continue;` (etc.).

- [ ] **Step 3: Verificar getters generados**

Run: `grep -n "auth_verify_email_continue\|auth_verify_email_back\|auth_verify_email_not_yet\|auth_verify_email_checking" lib/l10n/app_localizations.dart`
Expected: las 4 claves presentes.

- [ ] **Step 4: Gate**

Run: `flutter analyze lib/l10n`
Expected: sin errores.

---

### Task 6: Pantalla `VerifyEmailScreen` con salida + polling

**Files:**
- Modify: `lib/features/auth/presentation/verify_email_screen.dart` (→ `ConsumerStatefulWidget`)
- Test: `test/ui/features/auth/verify_email_screen_test.dart`

**Interfaces:**
- Consumes: `VerifyEmailViewModel.{isChecking, continueIfVerified, pollVerification, cancelAndSignOut, resendVerification, ...}` (Task 4); `VerifyCheckOutcome`; claves l10n (Task 5).

- [ ] **Step 1: Escribir/actualizar los tests que fallan** — reemplazar el contenido de `verify_email_screen_test.dart` por:

```dart
// test/ui/features/auth/verify_email_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/auth/application/verify_email_view_model.dart';
import 'package:toka/features/auth/presentation/verify_email_screen.dart';
import 'package:toka/l10n/app_localizations.dart';

class _MockVerifyEmailViewModel extends Mock implements VerifyEmailViewModel {}

_MockVerifyEmailViewModel _defaultMock() {
  final m = _MockVerifyEmailViewModel();
  when(() => m.email).thenReturn('user@example.com');
  when(() => m.resendCooldownSeconds).thenReturn(0);
  when(() => m.isSending).thenReturn(false);
  when(() => m.isChecking).thenReturn(false);
  when(() => m.resendVerification()).thenAnswer((_) async {});
  when(() => m.pollVerification()).thenAnswer((_) async {});
  when(() => m.cancelAndSignOut()).thenAnswer((_) async {});
  when(() => m.continueIfVerified())
      .thenAnswer((_) async => VerifyCheckOutcome.notVerified);
  return m;
}

Widget _wrap({_MockVerifyEmailViewModel? vm}) => ProviderScope(
      overrides: [
        verifyEmailViewModelProvider.overrideWithValue(vm ?? _defaultMock()),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('es')],
        // Polling desactivado en tests: un Timer.periodic vivo cuelga pumpAndSettle.
        home: VerifyEmailScreen(enablePolling: false),
      ),
    );

void main() {
  testWidgets('renders Scaffold + botón Continuar', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byKey(const Key('btn_continue_verification')), findsOneWidget);
  });

  testWidgets('Reenviar deshabilitado durante cooldown', (tester) async {
    final m = _defaultMock();
    when(() => m.resendCooldownSeconds).thenReturn(45);
    await tester.pumpWidget(_wrap(vm: m));
    await tester.pumpAndSettle();
    final button = tester.widget<OutlinedButton>(
        find.byKey(const Key('btn_resend_verification')));
    expect(button.onPressed, isNull);
  });

  testWidgets('Continuar con notVerified muestra SnackBar', (tester) async {
    final m = _defaultMock();
    when(() => m.continueIfVerified())
        .thenAnswer((_) async => VerifyCheckOutcome.notVerified);
    await tester.pumpWidget(_wrap(vm: m));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_continue_verification')));
    await tester.pump(); // dispara el SnackBar
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('Volver invoca cancelAndSignOut', (tester) async {
    final m = _defaultMock();
    await tester.pumpWidget(_wrap(vm: m));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_back_verification')));
    await tester.pump();
    verify(() => m.cancelAndSignOut()).called(1);
  });

  testWidgets('isChecking deshabilita Continuar', (tester) async {
    final m = _defaultMock();
    when(() => m.isChecking).thenReturn(true);
    await tester.pumpWidget(_wrap(vm: m));
    await tester.pumpAndSettle();
    final button = tester.widget<FilledButton>(
        find.byKey(const Key('btn_continue_verification')));
    expect(button.onPressed, isNull);
  });
}
```

- [ ] **Step 2: Ejecutar y verificar que falla**

Run: `flutter test test/ui/features/auth/verify_email_screen_test.dart`
Expected: FAIL de compilación — `VerifyEmailScreen` no acepta `enablePolling`; claves de botón ausentes.

- [ ] **Step 3: Implementar** — reemplazar el contenido de `lib/features/auth/presentation/verify_email_screen.dart` por:

```dart
// lib/features/auth/presentation/verify_email_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../application/verify_email_view_model.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, this.enablePolling = true});

  /// Polling suave que comprueba la verificación mientras la pantalla está
  /// visible. Se desactiva en tests de widget (un Timer.periodic vivo cuelga
  /// pumpAndSettle).
  final bool enablePolling;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen>
    with WidgetsBindingObserver {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.enablePolling) {
      _pollTimer = Timer.periodic(
        const Duration(seconds: 4),
        (_) => ref.read(verifyEmailViewModelProvider).pollVerification(),
      );
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al volver del cliente de correo, reintentar la comprobación.
    if (state == AppLifecycleState.resumed) {
      ref.read(verifyEmailViewModelProvider).pollVerification();
    }
  }

  Future<void> _onContinue() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final outcome =
        await ref.read(verifyEmailViewModelProvider).continueIfVerified();
    if (!mounted) return;
    switch (outcome) {
      case VerifyCheckOutcome.verified:
        break; // el router avanza solo
      case VerifyCheckOutcome.notVerified:
        messenger.showSnackBar(
            SnackBar(content: Text(l10n.auth_verify_email_not_yet)));
      case VerifyCheckOutcome.networkError:
        messenger
            .showSnackBar(SnackBar(content: Text(l10n.auth_error_network)));
      case VerifyCheckOutcome.unknownError:
        messenger.showSnackBar(SnackBar(content: Text(l10n.error_generic)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = ref.watch(verifyEmailViewModelProvider);
    final isResendDisabled = vm.isSending || vm.resendCooldownSeconds > 0;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.auth_verify_email_title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.mark_email_unread_outlined, size: 80),
              const SizedBox(height: 24),
              Text(
                l10n.auth_verify_email_title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.auth_verify_email_body(vm.email),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton(
                key: const Key('btn_continue_verification'),
                onPressed: vm.isChecking ? null : _onContinue,
                child: Text(
                  vm.isChecking
                      ? l10n.auth_verify_email_checking
                      : l10n.auth_verify_email_continue,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                key: const Key('btn_resend_verification'),
                onPressed: isResendDisabled ? null : vm.resendVerification,
                child: Text(
                  vm.resendCooldownSeconds > 0
                      ? l10n.auth_resend_cooldown(vm.resendCooldownSeconds)
                      : l10n.auth_resend_email,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                key: const Key('btn_back_verification'),
                onPressed: vm.isChecking ? null : vm.cancelAndSignOut,
                child: Text(l10n.auth_verify_email_back),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Ejecutar y verificar que pasa**

Run: `flutter test test/ui/features/auth/verify_email_screen_test.dart`
Expected: PASS (los 5 tests).

- [ ] **Step 5: Gate completo de la suite Flutter**

Run: `flutter analyze && flutter test test/unit/ test/ui/features/auth/`
Expected: analyze sin errores; tests verdes. (Documentar que los ~6 goldens preexistentes que fallan por `google_fonts` sin red son ambientales y ajenos a este hallazgo — no se ejecutan en estos paths.)

---

## Verificación en dispositivo (Firebase real — fuera del ciclo TDD)

Tras los gates verdes, build con `lib/main.dart` (NO `main_dev.dart`; confirmar en logcat que NO aparece `Mapping Auth Emulator host`) y verificar en **MI_9 físico + emulador**:

1. Registrar cuenta nueva por email → NO queda atrapado: aparecen "Ya verifiqué, continuar" y "Volver". Captura.
2. Verificar desde el enlace real de Firebase Auth y volver a la app → avanza sin matar la app (por botón Continuar y/o por polling). Capturas antes/después.
3. Modelo A: sin verificar NO puede crear hogar/operar (queda en /verify-email); tras verificar, sí. Captura.
4. "Continuar" sin red → SnackBar de error de red, sin colgarse. Captura.
5. "Volver" → vuelve a /login (signOut). Captura.

## Cierre (de `_CONVENCIONES.md` §10)

- Actualizar `Arreglos/ux_hallazgos_2026-06-25/INDICE.md`: fila 03 → ✅ Completado + fecha + nota (**modelo A**, archivos clave, capturas).
- Listar archivos nuevos/modificados y enlazar capturas en la respuesta final.
- Trabajo **sin commitear** salvo que el usuario lo pida.

## Self-Review (cobertura del spec)

- Dead-end con salida (Continuar + Volver + polling) → Task 6.
- `reload()` real → Task 1; router reacciona → Tasks 2+3.
- Enforcement modelo A respetado entre router y UI → Task 3 (router) + Task 6 (pantalla retenida).
- Strings es/en/ro → Task 5.
- Tests unit/widget (view model, router redirect, pantalla, repo) → Tasks 1-6.
- Verificación en dispositivo → sección dedicada.
