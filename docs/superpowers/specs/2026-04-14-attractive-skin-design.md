# Attractive Skin V2 para Toka — Spec de implementación

> **Para el agente implementador:** FLUJO OBLIGATORIO en dos fases.
> **Fase 0** (antes de escribir una sola línea de Flutter): usa `superpowers:brainstorming`
> con el **visual companion** para presentar al usuario 3 propuestas de diseño en localhost.
> **Fase 1**: implementa la propuesta elegida siguiendo esta spec al pie de la letra.
> No hay `writing-plans` hasta que el usuario haya elegido un diseño en Fase 0.

---

## Objetivo

Añadir una segunda skin visual a Toka (`AppSkin.v2`) que sea más atractiva que la skin
Material actual, con animaciones modernas y diseño memorable. La lógica de negocio no
cambia en absoluto: todas las pantallas nuevas deben consumir los contratos ViewModel
existentes, exactamente igual que la skin actual.

---

## Fase 0 — Selección de diseño visual (OBLIGATORIA ANTES DE IMPLEMENTAR)

### Qué hacer

1. Invoca `superpowers:brainstorming` al iniciar la sesión.
2. Ofrece el **visual companion** al usuario (mensaje independiente, sin mezclar).
3. Usando el visual companion (o HTML estático servido con `python -m http.server`),
   muestra **3 propuestas de diseño distintas** para la pantalla Hoy (`TodayScreen`).
   Cada propuesta debe mostrar:
   - La tarjeta de tarea pendiente (`TodayTaskCardTodo`)
   - La cabecera de contadores (`TodayHeaderCounters`)
   - La sección con título de recurrencia (`TodayTaskSection`)
4. Pregunta al usuario **una cosa a la vez**: paleta de color, tipografía, nivel de
   animaciones, estilo de tarjetas, estilo de barra de navegación.
5. Documenta las decisiones en `docs/superpowers/specs/2026-04-14-attractive-skin-choices.md`
   (este archivo lo creas tú en la otra sesión, no existe aún).
6. Solo cuando el usuario apruebe el diseño, invoca `superpowers:writing-plans` para
   crear el plan de implementación (Fase 1).

### Preguntas mínimas a responder antes de implementar

- **Dirección estética**: (soft & cozy / dark & sleek / playful & colorful / minimal & editorial / otra)
- **Modo oscuro**: ¿La V2 es siempre oscura, siempre clara, o sigue el sistema?
- **Tipografía**: ¿Cambiar la fuente (actualmente Inter) o mantenerla?
- **Animaciones**: nivel de intensidad (sutil / medio / expresivo)
- **Tarjeta de tarea**: ¿card elevada, flat con borde, glassmorphism, otro?
- **Barra de navegación**: ¿NavigationBar estándar, barra flotante con blur, otra?
- **Animación de completar tarea**: ¿confetti, checkmark animado, ripple, ninguna?

---

## Arquitectura de skins (ya existe, solo extenderla)

### Ficheros existentes

```
lib/core/theme/app_skin.dart          ← enum AppSkin + SkinConfig
lib/core/theme/app_theme.dart         ← ThemeData light/dark (skin material)
lib/core/theme/app_colors.dart        ← paleta material
```

### Ficheros a crear en Fase 1

```
lib/core/theme/app_colors_v2.dart          ← paleta elegida en Fase 0
lib/core/theme/app_theme_v2.dart           ← ThemeData light y/o dark para V2

lib/features/tasks/presentation/skins/
  today_screen_v2.dart                     ← TodayScreen V2
  all_tasks_screen_v2.dart                 ← AllTasksScreen V2
  task_detail_screen_v2.dart               ← TaskDetailScreen V2
  create_edit_task_screen_v2.dart          ← CreateEditTaskScreen V2

lib/features/history/presentation/skins/
  history_screen_v2.dart

lib/features/members/presentation/skins/
  member_profile_screen_v2.dart

lib/shared/widgets/skins/
  main_shell_v2.dart                       ← NavigationBar / barra alternativa V2
```

### Modificar `app_skin.dart`

```dart
enum AppSkin { material, v2 }

class SkinConfig {
  SkinConfig._();
  static AppSkin current = AppSkin.v2; // ← cambiar a v2 para activar la nueva skin
}
```

---

## Selector de skin en el router (`lib/app.dart`)

El router elige la clase de pantalla según `SkinConfig.current`. Patrón a seguir:

```dart
// Dentro del ShellRoute builder:
builder: (context, state, child) => SkinConfig.current == AppSkin.v2
    ? MainShellV2(child: child)
    : MainShell(child: child),

// Dentro de cada GoRoute:
GoRoute(
  path: AppRoutes.home,
  builder: (_, __) => SkinConfig.current == AppSkin.v2
      ? const TodayScreenV2()
      : const TodayScreen(),
),
```

Aplicar el mismo patrón a: `home`, `history`, `tasks`, `createTask`, `editTask`,
`taskDetail`, `memberProfile`. Las pantallas de auth, onboarding, settings,
subscription, y my_homes no requieren skin V2 en esta iteración.

---

## Contratos ViewModel — reglas de implementación (NO NEGOCIABLE)

Cada pantalla V2 **debe** declarar el tipo abstracto explícitamente:

```dart
// ✅ CORRECTO
final TodayViewModel vm = ref.watch(todayViewModelProvider);
final AllTasksViewModel vm = ref.watch(allTasksViewModelProvider);
final TaskDetailViewModel vm = ref.watch(taskDetailViewModelProvider(...));
final HistoryViewModel vm = ref.watch(historyViewModelProvider);
final MemberProfileViewModel vm = ref.watch(memberProfileViewModelProvider(...));
final CreateEditTaskViewModel vm = ref.watch(createEditTaskViewModelProvider(...));

// ❌ INCORRECTO — no usar var/final sin tipo
final vm = ref.watch(todayViewModelProvider);
```

Si la anotación de tipo no compila porque el provider retorna el tipo concreto en lugar
del abstracto, añadir el tipo explícito es la solución correcta. NO cambiar los providers.

### Inventario de contratos

| Pantalla              | Contrato abstracto          | Provider                              |
|-----------------------|-----------------------------|---------------------------------------|
| TodayScreenV2         | `TodayViewModel`            | `todayViewModelProvider`              |
| AllTasksScreenV2      | `AllTasksViewModel`         | `allTasksViewModelProvider`           |
| TaskDetailScreenV2    | `TaskDetailViewModel`       | `taskDetailViewModelProvider(taskId)` |
| CreateEditTaskScreenV2| `CreateEditTaskViewModel`   | `createEditTaskViewModelProvider(id)` |
| HistoryScreenV2       | `HistoryViewModel`          | `historyViewModelProvider`            |
| MemberProfileScreenV2 | `MemberProfileViewModel`    | `memberProfileViewModelProvider(...)`  |

### Datos disponibles en cada contrato

**TodayViewModel** expone:
- `viewData` → `AsyncValue<TodayViewData?>` con `grouped`, `counters`, `showAdBanner`,
  `currentUid`, `homeId`, `recurrenceOrder`
- `homes` → `List<HomeDropdownItem>` para el selector de hogar
- `selectHome(homeId)`, `completeTask(taskId)`, `passTurn(taskId, {reason})`,
  `fetchPassStats(uid)`, `retry()`

**AllTasksViewModel** expone:
- `viewData` → `AsyncValue<AllTasksViewData?>` con `tasks`, `filter`, `canManage`, `uid`, `homeId`
- `selectedIds`, `isSelectionMode`
- `setStatusFilter`, `setAssigneeFilter`, `toggleSelection`, `clearSelection`,
  `toggleFreeze`, `deleteTask`, `bulkDelete`, `bulkFreeze`

**TaskDetailViewModel** expone:
- `viewData` → `AsyncValue<TaskDetailViewData?>` con `task`, `canManage`,
  `currentAssigneeName`, `upcomingOccurrences` (lista de `UpcomingOccurrence` con
  `.date` y `.assigneeName`), `difficultyWeight`, `isFrozen`
- `toggleFreeze(task)`, `deleteTask(task)`

**HistoryViewModel** expone:
- `viewData` → `AsyncValue<HistoryViewData?>` con `events` (lista de `TaskEventItem`),
  `hasMore`, `filter`
- `loadMore()`, `setFilter(filter)`

**MemberProfileViewModel** expone:
- `viewData` → `AsyncValue<MemberProfileViewData?>` con `member`, `completedCount`,
  `streakCount`, `averageScore`, `showRadar`, `overflowEntries`, `isOwner`, `canManage`,
  `isCurrentUser`
- `removeMember()`, `changeMemberRole(role)`

**CreateEditTaskViewModel** expone:
- `state` → `AsyncValue<CreateEditTaskState>` con `title`, `visualKind`, `visualValue`,
  `recurrenceRule`, `members` (lista de `MemberOrderItem`), `fixedTime`, `difficultyWeight`
- `setTitle`, `setVisual`, `setRecurrenceRule`, `setFixedTime`, `setDifficultyWeight`,
  `toggleMemberAssignment`, `reorderMembers`, `save()`, `isEditing`

---

## Requisitos de animación

Los detalles (duración, curva, intensidad) se confirman en Fase 0. Las siguientes
animaciones son **obligatorias** independientemente del diseño elegido:

| Elemento                        | Tipo de animación                              |
|---------------------------------|------------------------------------------------|
| Lista de tareas en TodayScreen  | Staggered slide-in al cargar (entrada escalonada) |
| Completar tarea                 | Animación de confirmación visible (>0.3s)      |
| Skeleton loaders                | Shimmer (no spinner estático)                  |
| Transición entre pestañas       | Fade o slide suave (no corte abrupto)          |
| FAB en AllTasksScreen           | Scale-in al aparecer                           |

Las siguientes son **opcionales** y se deciden en Fase 0:
- Confetti / partículas al completar tarea
- Glassmorphism en tarjetas o barra de navegación
- Hero animation entre AllTasksScreen y TaskDetailScreen
- Pull-to-refresh personalizado

### Librería de animaciones recomendada

Preferir `AnimatedList`, `AnimationController` con `CurvedAnimation`, y
`TweenAnimationBuilder` nativos de Flutter antes de añadir dependencias externas.
Si se necesita confetti o efectos complejos, usar `confetti: ^0.7.0` (ya popular
en pub.dev). No añadir más de una dependencia de animaciones nueva.

---

## ThemeData V2

Crear `AppThemeV2` en `lib/core/theme/app_theme_v2.dart` siguiendo la misma
estructura que `AppTheme`:

```dart
abstract class AppThemeV2 {
  static ThemeData get light { ... }
  static ThemeData get dark { ... }  // solo si el usuario pidió modo oscuro
}
```

En `lib/app.dart`, seleccionar el tema según la skin activa:

```dart
MaterialApp(
  theme: SkinConfig.current == AppSkin.v2
      ? AppThemeV2.light
      : AppTheme.light,
  darkTheme: SkinConfig.current == AppSkin.v2
      ? AppThemeV2.dark
      : AppTheme.dark,
  ...
)
```

---

## Tests requeridos

### Por cada pantalla V2 (mínimo)

```
test/ui/features/tasks/today_screen_v2_test.dart
test/ui/features/tasks/all_tasks_screen_v2_test.dart
test/ui/features/tasks/task_detail_screen_v2_test.dart
test/ui/features/history/history_screen_v2_test.dart
test/ui/features/members/member_profile_screen_v2_test.dart
```

Cada test de UI debe:
1. Mockear el ViewModel con `mocktail` (implementar el contrato abstracto)
2. Verificar que los datos del ViewModel se renderizan en pantalla
3. Verificar que las acciones (completar, pasar turno, etc.) llaman al método correcto
4. Verificar que el widget compila con tipo abstracto explícito

### Test del selector de skin

```dart
// test/unit/core/theme/skin_selector_test.dart
// Verificar que SkinConfig.current == AppSkin.v2 hace que el router
// construya TodayScreenV2, no TodayScreen.
```

---

## Criterios de aceptación

- [ ] `SkinConfig.current = AppSkin.v2` activa la nueva skin en toda la app
- [ ] `SkinConfig.current = AppSkin.material` restaura la skin actual sin cambios
- [ ] Cada pantalla V2 usa tipo abstracto explícito (verificable con `grep`)
- [ ] Si se añade un método al contrato abstracto y no se implementa en V2, error de compilación
- [ ] Todos los tests unitarios y de UI pasan (`flutter test`)
- [ ] `flutter analyze` sin errores
- [ ] La app funciona en modo material y en modo v2 sin crashes

---

## Qué NO hacer

- No modificar los ViewModels existentes ni sus contratos
- No modificar las pantallas `material` existentes
- No cambiar la lógica de negocio en domain o data
- No añadir campos nuevos al router salvo los condicionales de skin
- No crear abstracciones intermedias (ej. `BaseTodayScreen`) — cada skin es independiente
- No usar `var` al declarar el ViewModel en las pantallas V2

---

## Referencia rápida de archivos relevantes

| Archivo                                                          | Qué hace                          |
|------------------------------------------------------------------|-----------------------------------|
| `lib/core/theme/app_skin.dart`                                   | Enum + SkinConfig (modificar)     |
| `lib/app.dart`                                                   | Router — añadir condicionales     |
| `lib/shared/widgets/main_shell.dart`                             | Barra nav actual (no tocar)       |
| `lib/features/tasks/application/today_view_model.dart`           | Contrato TodayViewModel           |
| `lib/features/tasks/application/all_tasks_view_model.dart`       | Contrato AllTasksViewModel        |
| `lib/features/tasks/application/task_detail_view_model.dart`     | Contrato TaskDetailViewModel      |
| `lib/features/tasks/application/create_edit_task_view_model.dart`| Contrato CreateEditTaskViewModel  |
| `lib/features/history/application/history_view_model.dart`       | Contrato HistoryViewModel         |
| `lib/features/members/application/member_profile_view_model.dart`| Contrato MemberProfileViewModel   |
| `lib/features/tasks/presentation/today_screen.dart`              | Skin material — referencia        |
| `lib/features/tasks/presentation/all_tasks_screen.dart`          | Skin material — referencia        |
