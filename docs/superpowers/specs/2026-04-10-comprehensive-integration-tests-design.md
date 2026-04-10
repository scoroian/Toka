# Spec: Tests de integración completos + corrección de bugs en creación de tareas

**Fecha:** 2026-04-10  
**Área:** Cobertura de tests — unit, widget, E2E Patrol  
**Enfoque:** Opción B (por flujo funcional, fixes primero)

---

## Contexto y motivación

Se detectaron dos bugs en producción que impiden crear tareas:

1. `create_edit_task_screen.dart:122` pasa `availableMembers: const []` a `AssignmentForm` — los miembros del hogar nunca se muestran.
2. `task_form_provider.dart:84` aborta el guardado con `return null` si `recurrenceRule == null` (valor inicial), sin emitir ningún error de campo visible. La pantalla no hace pop y la tarea no se crea.

Además, la suite E2E actual (`integration_test/flows/`) no cubre: gestión de hogares, perfil, historial, flujo de registro completo, ni el ciclo de vida completo (registro → operaciones → reset de contraseña → relogin).

---

## Bugs a corregir

### Bug 1 — Miembros no cargados en AssignmentForm

**Archivo:** `lib/features/tasks/presentation/create_edit_task_screen.dart`

Leer el `homeId` del `currentHomeProvider` y pasar los UIDs de los miembros activos del hogar a `AssignmentForm`:

```dart
// Antes:
AssignmentForm(
  availableMembers: const [],
  ...
)

// Después:
final homeId = ref.watch(currentHomeProvider).valueOrNull?.id ?? '';
final membersAsync = ref.watch(homeMembersProvider(homeId));
final memberUids = membersAsync.valueOrNull?.map((m) => m.uid).toList() ?? [];

AssignmentForm(
  availableMembers: memberUids,
  ...
)
```

### Bug 2 — Error de recurrencia se emite al estado pero nunca se muestra en la UI

**Causa real:** `task_form_provider.dart:84-89` ya emite `fieldErrors['recurrence']` correctamente cuando `recurrenceRule == null`. El problema es que `create_edit_task_screen.dart` lee `fieldErrors['title']` y `fieldErrors['assignees']` para mostrarlos, pero **nunca lee `fieldErrors['recurrence']`**, por lo que el usuario no recibe ningún feedback y no sabe por qué el guardado falla.

**Fix:** en `create_edit_task_screen.dart`, leer el error de recurrencia y mostrarlo debajo del `RecurrenceForm`, igual que se hace con `titleError` y `assigneesError`:

```dart
// En build(), junto a los otros errores:
final recurrenceError = formState.fieldErrors['recurrence'];

// En el body, debajo de RecurrenceForm:
if (recurrenceError != null)
  Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      l10n.tasks_validation_recurrence_required,
      style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
      key: const Key('recurrence_error'),
    ),
  ),
```

No se toca `task_form_provider.dart` ni `task_validator.dart` — el error ya se emite correctamente, solo falta mostrarlo.

---

## Área 1 — Task CRUD: cobertura completa

### Unit tests — `test/unit/features/tasks/`

**`task_validator_test.dart`** (expandir existente):
- Título vacío → error `title / tasks_validation_title_empty`
- Título > 60 caracteres → error `title / tasks_validation_title_too_long`
- Sin asignados → error `assignees / tasks_validation_no_assignees`
- Dificultad < 0.5 → error `difficulty / tasks_validation_difficulty_range`
- Dificultad > 3.0 → error `difficulty / tasks_validation_difficulty_range`
- Todos los campos válidos → `isOk`

**`create_edit_task_view_model_test.dart`** (expandir existente):
- Guardar con todos los campos válidos → `savedSuccessfully = true`
- Guardar sin recurrencia → `savedSuccessfully = false`, `fieldErrors['recurrence']` no nulo
- Guardar sin asignados → `savedSuccessfully = false`, `fieldErrors['assignees']` no nulo
- Guardar sin título → `savedSuccessfully = false`, `fieldErrors['title']` no nulo
- Modo edición: `initEdit(task)` pre-rellena todos los campos correctamente

### Widget tests — `test/ui/features/tasks/`

**`create_task_screen_test.dart`** (expandir existente):
- Guardar con título vacío muestra error debajo del campo sin navegar
- Guardar sin seleccionar recurrencia muestra error de recurrencia sin navegar
- Guardar sin seleccionar asignados muestra error de asignados sin navegar
- Seleccionar un miembro en `AssignmentForm` y guardar con datos válidos hace pop
- En modo edición, el campo título muestra el título de la tarea existente
- Los checkboxes de miembros se renderizan para cada UID en `availableMembers`

### E2E Patrol — expandir `integration_test/flows/task_completion_flow_test.dart`

**Añadir helper `_ensureHomeExists($)`**: si no hay `NavigationBar` o el usuario está en onboarding, ejecuta el flujo de creación de hogar antes de continuar.

**Tests nuevos / reemplazados:**
- `crear tarea completa`: título + recurrencia diaria + marcar owner como asignado → guardar → vuelve a lista y la tarea aparece
- `editar tarea existente`: abrir tarea desde lista → cambiar título → guardar → nuevo título visible
- `eliminar/congelar tarea`: abrir tarea → congelar → tarea desaparece de lista activa
- `validaciones visibles`: guardar formulario vacío → mensajes de error visibles, pantalla no navega
- `flujo completo Hoy - completar tarea`: tap en `btn_complete` → dialog → confirmar → tarea pasa a sección "Hechas"
- `flujo completo Hoy - pasar turno confirmado`: tap en `btn_pass` → dialog con penalización → confirmar → tarea cambia de asignado

---

## Área 2 — Homes: gestión de hogares

### Unit tests — `test/unit/features/homes/` (expandir existentes)

**`home_settings_view_model_test.dart`** (expandir):
- Cambiar nombre del hogar actualiza el estado
- Nombre vacío emite error de validación
- Guardar con nombre válido llama al repositorio

**`my_homes_view_model_test.dart`** (expandir):
- Lista de hogares se carga del repositorio
- Seleccionar hogar diferente actualiza `currentHomeProvider`

### E2E Patrol — nuevo `integration_test/flows/home_management_flow_test.dart`

**Helper:** usa `_ensureHomeExists($)` compartido.

**Tests:**
- `pantalla ajustes del hogar carga`: navegar a ajustes → nombre del hogar visible
- `cambiar nombre del hogar`: editar campo nombre → guardar → nombre actualizado visible
- `crear segundo hogar`: navegar a "Mis hogares" → crear → aparece en lista y se puede seleccionar
- `cambiar de hogar activo`: seleccionar otro hogar → pantalla Hoy carga con el nuevo hogar
- `salir de hogar como miembro no-owner`: salir → hogar desaparece de la lista
- `eliminar hogar como owner`: owner elimina el hogar → app navega a onboarding/selector; el siguiente test llama a `_ensureHomeExists($)` y crea un hogar nuevo con el flujo completo

---

## Área 3 — Profile: perfil y reseñas

### Unit tests — `test/unit/features/profile/` (expandir existentes)

**`edit_profile_view_model_test.dart`** (expandir):
- Cambiar nombre actualiza estado
- Nombre vacío emite error de validación
- Guardar con nombre válido pone `savedSuccessfully = true`

**`own_profile_view_model_test.dart`** (expandir):
- Perfil carga datos del usuario autenticado
- Estadísticas de tareas se calculan correctamente a partir de historial

**`review_validation_test.dart`** (expandir existente):
- Puntuación fuera de rango (< 1 o > 5) → error
- Nota vacía → permitido (son opcionales)
- Puntuación válida con nota → `isOk`

### Widget tests — `test/ui/features/profile/` (expandir existentes)

**`edit_profile_screen`** (nuevo test file o expandir):
- Campo nombre pre-rellena con valor actual del usuario
- Guardar con nombre vacío muestra error
- Botón guardar activa estado de loading

**`own_profile_screen`** (expandir `radar_chart_widget_test.dart`):
- Radar chart se renderiza sin errores con datos de ejemplo
- Lista de reseñas muestra items cuando hay datos

### E2E Patrol — nuevo `integration_test/flows/profile_flow_test.dart`

**Tests:**
- `ver perfil propio`: navegar desde Settings → pantalla carga con nombre de usuario
- `editar nombre`: cambiar nombre → guardar → nuevo nombre visible en perfil y en Settings
- `cambiar avatar/emoji`: seleccionar emoji diferente → guardar → persiste tras navegar y volver
- `ver radar chart`: pantalla de perfil muestra el gráfico de estadísticas
- `flujo de reseña`: desde perfil de un miembro → puntuar con 4 estrellas y nota → guardar → confirmación visible y la reseña aparece en el listado del perfil del autor

---

## Área 4 — History: historial y paginación

### Unit tests — `test/unit/features/history/` (expandir existente)

**`history_view_model_test.dart`** (expandir):
- Primera página carga correctamente con N entradas
- Llamar a `loadMore()` appends al listado sin duplicados
- Cuando no hay más páginas, `loadMore()` no dispara otra carga
- Estado de carga (`isLoadingMore`) es `true` mientras se carga la siguiente página

### E2E Patrol — nuevo `integration_test/flows/history_flow_test.dart`

**Tests:**
- `pantalla historial carga`: navegar a History → lista o estado vacío visible
- `scroll hasta el final activa paginación`: si hay entradas suficientes, scroll al fondo → se cargan más entradas
- `entrada de historial tiene datos correctos`: fecha, nombre de tarea y miembro asignado visibles en cada item
- `filtro por tarea/miembro`: si la UI tiene filtros, seleccionar uno → lista se actualiza (test se marca skip si la UI no tiene filtros aún)

---

## Área 5 — Onboarding completo y Auth

### E2E Patrol — expandir `integration_test/flows/auth_onboarding_flow_test.dart` y nuevo `onboarding_registration_flow_test.dart`

**Tests de validación en registro** (en `auth_onboarding_flow_test.dart`):
- Contraseña demasiado corta → error visible sin navegar
- Email malformado → error visible sin navegar

**Tests en `onboarding_registration_flow_test.dart`:**

- `registro nuevo usuario`: email único `e2e_<timestamp>@toka.dev` + contraseña → llega a pantalla de verificación o directamente al onboarding
- `flujo onboarding completo`: usuario recién registrado → idioma → perfil (nombre + avatar) → hogar (nombre) → llega al home shell con `NavigationBar`
- `registro con email ya existente`: intentar registrar con `test@toka.dev` → error de email en uso visible
- `forgot password desde login`: introducir email → mensaje de confirmación visible
- **`ciclo de vida completo`** (test de mayor valor):
  1. Registrar usuario con email único
  2. Completar onboarding: nombre de perfil, nombre de hogar
  3. Crear una tarea con título, recurrencia diaria, y owner asignado
  4. Cerrar sesión
  5. Desde login, ir a "Olvidé mi contraseña" → introducir email → confirmar
  6. Via REST al emulador de Auth, obtener el OOB code de reset y establecer nueva contraseña
  7. Iniciar sesión con la nueva contraseña
  8. Verificar que el hogar sigue visible con el nombre correcto
  9. Verificar que la tarea creada sigue apareciendo en la lista de tareas

El paso 6 usa la API REST del emulador de Auth (`GET /emulator/v1/projects/{projectId}/oobCodes`) para obtener el token de reset sin necesidad de email real, igual que `_ensureTestUser()` usa la API REST para crear usuarios.

---

## Helper compartido: `_ensureHomeExists`

Se define en `integration_test/helpers/test_setup.dart` y es reutilizable por todos los archivos de flow:

```dart
/// Si el usuario no tiene hogar activo (está en onboarding o pantalla sin hogar),
/// ejecuta el flujo completo de creación de hogar.
Future<void> ensureHomeExists(PatrolIntegrationTester $) async {
  // Si ya hay NavigationBar con acceso a Tasks, hay hogar activo
  if ($(find.byType(NavigationBar)).exists) return;

  // Si estamos en onboarding (PageView), completar el flujo
  if ($(find.byType(PageView)).exists) {
    // Navegar por los pasos del onboarding hasta crear hogar
    // ...flujo de onboarding...
  }

  // Si hay un botón de "Crear hogar" directo
  if ($(find.byKey(const Key('create_home_button'))).exists) {
    await $.tester.tap(find.byKey(const Key('create_home_button')));
    // ...
  }
}
```

---

## Archivos afectados

### Correcciones (modificar):
- `lib/features/tasks/presentation/create_edit_task_screen.dart` — bug 1 (cargar miembros) + bug 2 (mostrar error de recurrencia)

### Tests nuevos (crear):
- `integration_test/flows/home_management_flow_test.dart`
- `integration_test/flows/profile_flow_test.dart`
- `integration_test/flows/history_flow_test.dart`
- `integration_test/flows/onboarding_registration_flow_test.dart`
- `integration_test/test_bundle.dart` (actualizar imports)

### Tests expandidos (modificar):
- `integration_test/flows/task_completion_flow_test.dart`
- `integration_test/flows/auth_onboarding_flow_test.dart`
- `integration_test/helpers/test_setup.dart`
- `test/unit/features/tasks/task_validator_test.dart`
- `test/unit/features/tasks/create_edit_task_view_model_test.dart`
- `test/unit/features/homes/home_settings_view_model_test.dart`
- `test/unit/features/homes/my_homes_view_model_test.dart`
- `test/unit/features/profile/edit_profile_view_model_test.dart` (nuevo)
- `test/unit/features/profile/own_profile_view_model_test.dart` (nuevo)
- `test/unit/features/profile/review_validation_test.dart`
- `test/unit/features/history/history_view_model_test.dart`
- `test/ui/features/tasks/create_task_screen_test.dart`
- `test/ui/features/profile/radar_chart_widget_test.dart`

---

## Criterios de éxito

- `flutter test test/unit/` pasa al 100%
- `flutter test test/ui/` pasa al 100%
- Todos los Patrol E2E que no dependan de estado externo imposible de preparar pasan
- Los tests dependientes de estado (rescue banner, suscripción activa) se marcan `skip` con razón clara si el estado no existe, en vez de fallar
- La pantalla de creación de tareas muestra los miembros del hogar y navega correctamente al guardar
