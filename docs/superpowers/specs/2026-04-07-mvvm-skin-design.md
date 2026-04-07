# MVVM + Skin Architecture — Toka

**Fecha:** 2026-04-07  
**Estado:** Aprobado  
**Objetivo:** Refactorizar la capa Application + Presentation para separar completamente la lógica de negocio de la UI, de modo que cualquier pantalla pueda tener múltiples diseños visuales (skins) sin duplicar lógica.

---

## Motivación

El proyecto ya tiene domain y data bien separados. El problema está en la capa de presentación:

- Algunos screens contienen lógica de negocio (`TodayScreen._onPass` hace lecturas directas a Firestore).
- Otros screens llaman al repositorio directamente (`AllTasksScreen` usa `tasksRepositoryProvider`).
- Los screens dependen de providers concretos — no hay contrato entre ViewModel y View.
- No existe ningún mecanismo que garantice que dos diseños de una pantalla expongan los mismos datos.

---

## Arquitectura objetivo

```
Domain      → entidades, interfaces de repositorio       [sin cambios]
Data        → implementaciones de repositorio            [sin cambios]
Application → ViewModel interface + ViewModel impl       [nueva interfaz por pantalla]
Presentation→ screens que solo consumen la interfaz      [refactorizados]
```

---

## Patrón ViewModel Contract

### Estructura de ficheros por feature

```
lib/features/<feature>/
  application/
    <screen>_view_model.dart    ← contrato (abstract class) + notifier impl + provider tipado
  presentation/
    <screen>_screen.dart        ← skin por defecto
    skins/                      ← se crea solo cuando existe un 2º diseño real
      <screen>_screen_v2.dart
```

### Anatomía de `<screen>_view_model.dart`

```dart
// 1. EL CONTRATO
abstract class LoginViewModel {
  // Estado
  bool get isLoading;
  AuthFailure? get error;

  // Acciones
  Future<void> signInWithGoogle();
  Future<void> signInWithEmail(String email, String password);
  Future<void> signInWithApple();
  void clearError();
}

// 2. ESTADO INTERNO (privado)
@freezed
class _LoginState with _$LoginState {
  const factory _LoginState({
    @Default(false) bool isLoading,
    AuthFailure? error,
  }) = __LoginState;
}

// 3. IMPLEMENTACIÓN (Riverpod Notifier)
@riverpod
class LoginViewModelNotifier extends _$LoginViewModelNotifier
    implements LoginViewModel {

  @override
  _LoginState build() => const _LoginState();

  @override
  bool get isLoading => state.isLoading;

  @override
  AuthFailure? get error => state.error;

  @override
  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } on AuthFailure catch (f) {
      state = state.copyWith(isLoading: false, error: f);
    }
  }

  @override
  void clearError() => state = state.copyWith(error: null);
}

// 4. PROVIDER TIPADO — lo único que los screens importan
@riverpod
LoginViewModel loginViewModel(Ref ref) {
  ref.watch(loginViewModelNotifierProvider); // re-ejecuta al cambiar estado
  return ref.read(loginViewModelNotifierProvider.notifier);
}
```

### Cómo lo consume el screen

```dart
class LoginScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(loginViewModelProvider); // tipo: LoginViewModel
    // Solo usa vm.isLoading, vm.error, vm.signInWithGoogle(), etc.
  }
}

// Skin alternativa — mismo contrato, layout diferente
class LoginScreenV2 extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(loginViewModelProvider); // MISMO tipo
    // Layout completamente distinto
  }
}
```

---

## Reglas del contrato

| Qué va en el ViewModel | Qué queda en el Screen |
|---|---|
| Estado de carga/error | Mostrar CircularProgressIndicator / SnackBar |
| Acciones de negocio (signIn, deleteTask) | Mostrar diálogos de confirmación |
| Estado derivado (canCreateTask, isPremium) | Traducciones l10n de mensajes de error |
| Lógica de Firestore / repositorios | Navegación con GoRouter |
| Paginación y gestión de scroll state | Widgets, layout, animaciones |

### Navegación

El ViewModel **nunca** importa GoRouter ni BuildContext. El screen reacciona al estado con `ref.listen`:

```dart
ref.listen<LoginViewModel>(loginViewModelProvider, (_, vm) {
  if (vm.isAuthenticated) context.go(AppRoutes.home);
});
```

### Diálogos de confirmación

El screen muestra el diálogo y pasa el resultado al ViewModel:

```dart
void _onDelete(Task task) async {
  final confirmed = await showDialog<bool>(...);
  if (confirmed == true) vm.deleteTask(task.id);
}
```

### Errores

El ViewModel expone el tipo de fallo del dominio (e.g. `AuthFailure?`). El screen lo mapea a strings localizados. Esto mantiene i18n en la capa de presentación donde pertenece.

---

## Mecanismo de cambio de skin

### SkinConfig

```dart
// lib/core/theme/app_skin.dart

enum AppSkin { material, v2 }

class SkinConfig {
  static AppSkin current = AppSkin.material;
}
```

En el futuro `current` puede leerlo de Firebase Remote Config, feature flags, o SharedPreferences — sin cambiar ningún screen.

### Router

```dart
GoRoute(
  path: AppRoutes.login,
  builder: (_, __) => SkinConfig.current == AppSkin.v2
      ? const LoginScreenV2()
      : const LoginScreen(),
),
```

Un único punto de decisión por ruta. No hay if/switch duplicados en la app.

### Garantía en tiempo de compilación

Como ambos screens hacen `ref.watch(loginViewModelProvider)` y el tipo devuelto es `LoginViewModel` (la clase abstracta), es imposible en tiempo de compilación que `LoginScreenV2` muestre datos distintos o llame acciones fuera del contrato.

---

## Lógica a mover de screens a ViewModels

Problemas concretos encontrados en el código actual que el refactor corrige:

| Screen | Problema | Corrección |
|---|---|---|
| `TodayScreen._onPass()` | Lectura directa de Firestore para calcular compliance del miembro | Mover a `TodayViewModelNotifier.passTurn()` |
| `AllTasksScreen` | Llama `tasksRepositoryProvider` directamente para freeze/unfreeze/delete | Mover a `AllTasksViewModelNotifier` |
| `AllTasksScreen` | Filtrado y ordenación de tareas dentro del `build()` | Mover a `AllTasksViewModelNotifier` como estado derivado |
| `HistoryScreen` | Gestión de scroll + paginación (`_onScroll`, `_loadMore`) en el widget | El ViewModel expone `loadMore()` y `hasMore`; el screen llama `loadMore()` desde el listener de scroll |
| `OnboardingFlowScreen._init()` | Lógica de `isCompleted()` y `loadSavedProgress()` dentro del widget | Mover a `OnboardingViewModelNotifier.initialize()` |

---

## Pantallas a refactorizar (23 total)

| Feature | Screens | ViewModels nuevos |
|---|---|---|
| auth | login, register, verify_email, forgot_password | `LoginViewModel`, `RegisterViewModel`, `VerifyEmailViewModel`, `ForgotPasswordViewModel` |
| onboarding | onboarding_flow | `OnboardingViewModel` |
| homes | my_homes, home_settings | `MyHomesViewModel`, `HomeSettingsViewModel` |
| tasks | today, all_tasks, create_edit_task, task_detail | `TodayViewModel`, `AllTasksViewModel`, `CreateEditTaskViewModel`, `TaskDetailViewModel` |
| members | members, member_profile, vacation | `MembersViewModel`, `MemberProfileViewModel`, `VacationViewModel` |
| profile | own_profile, edit_profile | `OwnProfileViewModel`, `EditProfileViewModel` |
| subscription | paywall, downgrade_planner, subscription_management, rescue | `PaywallViewModel`, `DowngradePlannerViewModel`, `SubscriptionManagementViewModel`, `RescueViewModel` |
| history | history | `HistoryViewModel` |
| notifications | notification_settings | `NotificationSettingsViewModel` |
| settings | settings | `SettingsViewModel` |

---

## Orden de migración

1. **auth** — base de todo, sin dependencias hacia arriba
2. **onboarding** — segunda pantalla que ve el usuario
3. **homes** — necesario para tasks y members
4. **tasks** — feature principal de la app
5. **members / profile** — independientes entre sí
6. **history / notifications / settings** — sin dependencias complejas
7. **subscription** — la más compleja (múltiples estados, lógica de compra)

---

## Tests

Cada ViewModel nuevo requiere:

- 1 test unitario por caso feliz de cada acción
- 1 test unitario por caso de error / edge case
- Los screens existentes mantienen sus tests de UI — al pasar a consumir la interfaz, se mockea `LoginViewModel` directamente sin necesidad de providers reales

### Ejemplo de mock en tests de UI

```dart
class MockLoginViewModel extends Mock implements LoginViewModel {}

// En el test:
final mock = MockLoginViewModel();
when(() => mock.isLoading).thenReturn(false);
when(() => mock.error).thenReturn(null);

await tester.pumpWidget(
  ProviderScope(
    overrides: [
      loginViewModelProvider.overrideWithValue(mock),
    ],
    child: const MaterialApp(home: LoginScreen()),
  ),
);
```

---

## Convenciones de nombrado

| Elemento | Nombre |
|---|---|
| Contrato (abstract class) | `XxxViewModel` |
| Riverpod Notifier | `XxxViewModelNotifier` |
| Estado interno (freezed, privado) | `_XxxState` |
| Provider tipado (lo que usan los screens) | `xxxViewModelProvider` |
| Skin por defecto | `XxxScreen` |
| Skin alternativa | `XxxScreenV2`, `XxxScreenV3`, etc. |
| Carpeta de skins | `presentation/skins/` (se crea solo cuando hay ≥2 diseños) |

---

## Lo que NO cambia

- Domain layer: entidades, repositorios, casos de uso
- Data layer: implementaciones de repositorios
- Providers de repositorio existentes (`authRepositoryProvider`, etc.)
- Providers de infraestructura (`currentHomeProvider`, `dashboardProvider`, etc.) — quedan como proveedores internos usados por los ViewModels
- Estructura de rutas en `AppRoutes`
- ARB files e i18n
- Tests existentes de integración (tocan Firestore, no dependen de la capa de presentación)
