# Spec-03: Onboarding

**Dependencias previas:** Spec-00, Spec-01, Spec-02  
**Oleada:** Oleada 1

---

## Objetivo

Implementar el flujo de onboarding para nuevos usuarios: selección de idioma, configuración de perfil básico, y primera acción en la app (crear hogar o unirse a uno existente).

---

## Reglas de negocio

1. El onboarding se muestra solo a usuarios recién registrados (sin hogares).
2. El flujo es: **Bienvenida → Idioma → Perfil básico → Crear o unirse a hogar**.
3. El paso de idioma consulta la colección `languages` de Firebase (única consulta permitida aquí).
4. El perfil básico requiere: apodo/nombre visible (obligatorio). Foto y teléfono son opcionales.
5. Al crear un hogar, se consume una plaza de la cuenta (las cuentas nuevas tienen 2).
6. Al unirse a un hogar, también se consume una plaza.
7. Tras completar el onboarding, el usuario va a la pantalla principal del hogar.
8. Si el usuario cierra la app durante el onboarding y vuelve, debe reanudar desde donde lo dejó.

---

## Pasos del onboarding

### Paso 1: Bienvenida

- Ilustración/logo de Toka.
- Título: "Bienvenido a Toka" (en el idioma del dispositivo, fallback a es).
- Subtítulo: descripción breve.
- Botón "Empezar".

### Paso 2: Selección de idioma

- Título "¿En qué idioma prefieres usar Toka?".
- Lista de idiomas obtenida de Firebase (bandera + nombre).
- El idioma del dispositivo aparece preseleccionado si está disponible.
- Botones "Anterior" y "Siguiente".
- Al avanzar, guarda la selección en SharedPreferences (aún no hay hogar).

### Paso 3: Perfil básico

- Avatar circular (foto de perfil, opcional): toca para subir desde galería o cámara.
- Campo "¿Cómo te llaman?" (apodo, obligatorio, máx 30 chars).
- Campo teléfono (opcional) con selector de prefijo de país.
- Toggle "Mostrar mi teléfono a miembros del hogar" (default: oculto).
- Botones "Anterior" y "Siguiente".

### Paso 4: Crear o unirse a un hogar

- Dos opciones grandes:
  - **Crear un hogar nuevo**: icono de casa + descripción.
  - **Unirme a un hogar existente**: icono de personas + descripción.

#### Paso 4a: Crear hogar

- Campo nombre del hogar (obligatorio, máx 40 chars).
- Selector de emoji de casa (opcional, decorativo).
- Botón "Crear hogar".
- Crea el documento del hogar en Firestore y la membresía.
- El creador es automáticamente `owner`.

#### Paso 4b: Unirse a hogar

- Campo para introducir el código de invitación (6 chars alfanumérico).
- Botón "Unirme".
- Valida el código contra la colección `homes/{homeId}/invitations`.
- Si válido, crea la membresía y va al hogar.
- Si inválido o expirado, muestra error.

---

## Archivos a crear

```
lib/features/onboarding/
├── data/
│   ├── onboarding_repository_impl.dart
│   └── home_creation_repository_impl.dart
├── domain/
│   ├── onboarding_repository.dart
│   └── home_creation_repository.dart
├── application/
│   ├── onboarding_state.dart         (freezed)
│   ├── onboarding_provider.dart
│   └── home_creation_provider.dart
└── presentation/
    ├── onboarding_flow_screen.dart   (PageView o IndexedStack)
    ├── steps/
    │   ├── welcome_step.dart
    │   ├── language_step.dart
    │   ├── profile_step.dart
    │   └── home_choice_step.dart
    └── widgets/
        ├── onboarding_progress_bar.dart
        └── home_join_form.dart
```

---

## Implementación

### OnboardingState

```dart
@freezed
class OnboardingState with _$OnboardingState {
  const factory OnboardingState({
    @Default(0) int currentStep,
    @Default(4) int totalSteps,
    String? selectedLocale,
    String? nickname,
    String? phoneNumber,
    @Default(false) bool phoneVisible,
    String? photoUrl,
    @Default(false) bool isLoading,
    String? error,
  }) = _OnboardingState;
}
```

### OnboardingProvider

```dart
@riverpod
class OnboardingNotifier extends _$OnboardingNotifier {
  @override
  OnboardingState build() => const OnboardingState();

  void nextStep() => state = state.copyWith(currentStep: state.currentStep + 1);
  void prevStep() => state = state.copyWith(currentStep: state.currentStep - 1);
  void setLocale(String code) { ... }
  void setNickname(String name) { ... }
  Future<void> saveProfileAndContinue() async { ... }
  Future<void> createHome(String name, String? emoji) async { ... }
  Future<void> joinHome(String code) async { ... }
}
```

### Persistencia del progreso de onboarding

Guardar en SharedPreferences el paso actual y los datos introducidos, para que si el usuario cierra la app pueda continuar:

```dart
static const _stepKey = 'onboarding_step';
static const _nicknameKey = 'onboarding_nickname';
// etc.
```

### Creación de hogar (llamada a Function)

La creación del hogar debe pasar por una **Callable Function** `createHome` que:

1. Verifica que el usuario tiene plazas disponibles (`homeSlotCap - currentHomeCount > 0`).
2. Crea el documento `homes/{homeId}`.
3. Crea `homes/{homeId}/members/{uid}` con rol `owner`.
4. Crea `homes/{homeId}/views/dashboard` vacío.
5. Crea `homes/{homeId}/system/meta`.
6. Actualiza `users/{uid}/memberships/{homeId}`.
7. Actualiza `users/{uid}.lastSelectedHomeId`.

### Guardado del perfil inicial

Al completar el paso 3 (perfil básico):

1. Crear o actualizar `users/{uid}` con `nickname`, `phoneNumber`, `phoneVisibility`, `locale`.
2. Si hay foto, subirla a `Storage` en `users/{uid}/profile.jpg` y obtener URL.
3. Actualizar `users/{uid}.photoUrl`.
4. Actualizar `users/{uid}.locale` con la selección del paso 2.

---

## Tests requeridos

### Unitarios

**`test/unit/features/onboarding/onboarding_provider_test.dart`**

- `nextStep` incrementa `currentStep`.
- `prevStep` decrementa `currentStep`.
- `prevStep` no va por debajo de 0.
- `setLocale` actualiza el estado correctamente.
- `saveProfileAndContinue` con nickname vacío → no avanza y muestra error.
- `createHome` con nombre vacío → error de validación.
- `joinHome` con código de longitud incorrecta → error de validación.

**`test/unit/features/onboarding/home_creation_repository_test.dart`**

- `createHome` retorna el homeId creado.
- `createHome` lanza excepción si no hay plazas disponibles.
- `joinHome` con código inválido → lanza `InvalidInviteCodeException`.
- `joinHome` con código expirado → lanza `ExpiredInviteCodeException`.

### De integración

**`test/integration/features/onboarding/home_creation_test.dart`** (emuladores)

- Crear hogar → documento creado en `homes/` con campos correctos.
- Crear hogar → membresía creada en `homes/{id}/members/{uid}` con role `owner`.
- Crear hogar → `users/{uid}/memberships/{homeId}` creado.
- Crear hogar → `users/{uid}.lastSelectedHomeId` actualizado.
- Crear dos hogares → segundo consume la segunda plaza base.
- Intentar crear tercer hogar sin plazas → error.

**`test/integration/features/onboarding/profile_save_test.dart`** (emuladores)

- Guardar perfil → `users/{uid}.nickname` actualizado.
- Guardar perfil con locale → `users/{uid}.locale` actualizado.

### UI

**`test/ui/features/onboarding/onboarding_flow_test.dart`**

- El paso 1 muestra el logo y botón "Empezar".
- El paso 2 muestra la lista de idiomas (mockeada).
- El paso 3 muestra el formulario de perfil con validación.
- El paso 4 muestra las dos opciones (crear / unirse).
- Avanzar más allá del total de pasos no hace nada.
- La barra de progreso refleja el paso actual.
- Golden test de cada paso.

---

## Pruebas manuales requeridas al terminar esta spec

1. **Flujo completo — crear hogar:**
   - Registrar una cuenta nueva.
   - Completar los 4 pasos del onboarding.
   - En el paso 2, seleccionar "English" → el resto del onboarding continúa en inglés.
   - En el paso 3, introducir apodo "Carlos" y dejar foto vacía.
   - En el paso 4, elegir "Crear un hogar" → nombre "Casa de prueba".
   - → Redirige a la pantalla principal del hogar.
   - Verificar en Firestore Emulator: documento en `homes/`, membresía en `members/`.

2. **Flujo completo — unirse a hogar:**
   - Con otra cuenta, crear un hogar previamente y obtener un código de invitación.
   - Nueva cuenta → onboarding → "Unirme a un hogar" → introducir código → accede al hogar.

3. **Código de invitación inválido:**
   - Paso 4 → "Unirme" → introducir código "XXXXXX" → mensaje de error claro.

4. **Reanudar onboarding:**
   - Completar pasos 1 y 2 del onboarding.
   - Cerrar la app completamente.
   - Reabrir → debe continuar en el paso 3 (o al menos no empezar desde 0 sin datos).

5. **Verificar foto de perfil:**
   - En el paso 3, tocar el avatar → seleccionar una foto de la galería.
   - → La foto aparece en el avatar.
   - → Al completar el onboarding, verificar en Firebase Storage que la foto está en `users/{uid}/profile.jpg`.

6. **Límite de plazas:**
   - Crear una cuenta nueva y completar el onboarding creando el hogar 1.
   - Completar el onboarding con el hogar 1 y luego ir a crear un segundo hogar (desde ajustes).
   - Intentar crear un tercer hogar → debe mostrar un mensaje de "sin plazas disponibles".
