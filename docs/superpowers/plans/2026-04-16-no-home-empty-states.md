# No-Home Empty States Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mostrar un empty state con botones "Crear hogar / Unirse a hogar" en las pantallas de Historial, Miembros y Tareas cuando el usuario no pertenece a ningún hogar.

**Architecture:** Un `ConsumerWidget` compartido (`NoHomeEmptyState`) con parámetros `title` y `body` se crea en `shared/widgets/`. Cada pantalla detecta la ausencia de hogar mediante sus contratos de view model existentes, más un nuevo getter `hasHome` en `HistoryViewModel`.

**Tech Stack:** Flutter 3.x / Dart 3.x, Riverpod (ConsumerWidget), flutter_localizations (ARB), go_router (no usado aquí directamente).

---

## Estructura de archivos

| Archivo | Acción |
|---|---|
| `lib/shared/widgets/no_home_empty_state.dart` | **Crear** — widget compartido |
| `lib/features/history/application/history_view_model.dart` | **Modificar** — añadir `bool get hasHome` (interfaz + impl) |
| `lib/features/history/presentation/skins/history_screen_v2.dart` | **Modificar** — guardia + import |
| `lib/features/members/presentation/members_screen.dart` | **Modificar** — reemplazar error null con `NoHomeEmptyState` + import |
| `lib/features/tasks/presentation/skins/all_tasks_screen_v2.dart` | **Modificar** — reemplazar spinner null con `NoHomeEmptyState` + import |
| `lib/l10n/app_es.arb` | **Modificar** — 6 claves nuevas |
| `lib/l10n/app_en.arb` | **Modificar** — 6 claves nuevas |
| `lib/l10n/app_ro.arb` | **Modificar** — 6 claves nuevas |
| `lib/l10n/app_localizations.dart` | **Modificar** — 6 getters abstractos |
| `lib/l10n/app_localizations_es.dart` | **Modificar** — 6 implementaciones |
| `lib/l10n/app_localizations_en.dart` | **Modificar** — 6 implementaciones |
| `lib/l10n/app_localizations_ro.dart` | **Modificar** — 6 implementaciones |

---

### Task 1: ARB strings y localizations generadas

**Files:**
- Modify: `lib/l10n/app_es.arb:357`
- Modify: `lib/l10n/app_en.arb:357`
- Modify: `lib/l10n/app_ro.arb:357`
- Modify: `lib/l10n/app_localizations.dart:1067`
- Modify: `lib/l10n/app_localizations_es.dart:538`
- Modify: `lib/l10n/app_localizations_en.dart:532`
- Modify: `lib/l10n/app_localizations_ro.dart:537`

- [ ] **Paso 1: Añadir 6 claves en `app_es.arb`**

Busca la línea que contiene `"today_no_home_body": "Crea un hogar...` e inserta inmediatamente después (antes de `"complete_task_dialog_body"`):

```json
  "history_no_home_title": "Sin historial",
  "@history_no_home_title": { "description": "No home empty state title in history screen" },
  "history_no_home_body": "Crea un hogar o únete a uno para ver tu historial",
  "@history_no_home_body": { "description": "No home empty state body in history screen" },
  "tasks_no_home_title": "Sin tareas",
  "@tasks_no_home_title": { "description": "No home empty state title in all-tasks screen" },
  "tasks_no_home_body": "Crea un hogar o únete a uno para gestionar tareas",
  "@tasks_no_home_body": { "description": "No home empty state body in all-tasks screen" },
  "members_no_home_title": "Sin miembros",
  "@members_no_home_title": { "description": "No home empty state title in members screen" },
  "members_no_home_body": "Crea un hogar o únete a uno para ver los miembros",
  "@members_no_home_body": { "description": "No home empty state body in members screen" },
```

- [ ] **Paso 2: Añadir 6 claves en `app_en.arb`**

Mismo punto de inserción (después de `"today_no_home_body": "Create a home...`):

```json
  "history_no_home_title": "No history",
  "@history_no_home_title": { "description": "No home empty state title in history screen" },
  "history_no_home_body": "Create or join a home to see your history",
  "@history_no_home_body": { "description": "No home empty state body in history screen" },
  "tasks_no_home_title": "No tasks",
  "@tasks_no_home_title": { "description": "No home empty state title in all-tasks screen" },
  "tasks_no_home_body": "Create or join a home to manage your tasks",
  "@tasks_no_home_body": { "description": "No home empty state body in all-tasks screen" },
  "members_no_home_title": "No members",
  "@members_no_home_title": { "description": "No home empty state title in members screen" },
  "members_no_home_body": "Create or join a home to see its members",
  "@members_no_home_body": { "description": "No home empty state body in members screen" },
```

- [ ] **Paso 3: Añadir 6 claves en `app_ro.arb`**

Mismo punto de inserción (después de `"today_no_home_body": "Creează o locuință...`):

```json
  "history_no_home_title": "Fără istoric",
  "@history_no_home_title": { "description": "No home empty state title in history screen" },
  "history_no_home_body": "Creează sau alătură-te unui cămin pentru a-ți vedea istoricul",
  "@history_no_home_body": { "description": "No home empty state body in history screen" },
  "tasks_no_home_title": "Fără sarcini",
  "@tasks_no_home_title": { "description": "No home empty state title in all-tasks screen" },
  "tasks_no_home_body": "Creează sau alătură-te unui cămin pentru a gestiona sarcinile",
  "@tasks_no_home_body": { "description": "No home empty state body in all-tasks screen" },
  "members_no_home_title": "Fără membri",
  "@members_no_home_title": { "description": "No home empty state title in members screen" },
  "members_no_home_body": "Creează sau alătură-te unui cămin pentru a vedea membrii",
  "@members_no_home_body": { "description": "No home empty state body in members screen" },
```

- [ ] **Paso 4: Añadir 6 getters abstractos en `app_localizations.dart`**

Busca el getter `String get today_no_home_body;` (línea ~1067) e inserta inmediatamente después:

```dart
  /// No home empty state title in history screen
  ///
  /// In es, this message translates to:
  /// **'Sin historial'**
  String get history_no_home_title;

  /// No home empty state body in history screen
  ///
  /// In es, this message translates to:
  /// **'Crea un hogar o únete a uno para ver tu historial'**
  String get history_no_home_body;

  /// No home empty state title in all-tasks screen
  ///
  /// In es, this message translates to:
  /// **'Sin tareas'**
  String get tasks_no_home_title;

  /// No home empty state body in all-tasks screen
  ///
  /// In es, this message translates to:
  /// **'Crea un hogar o únete a uno para gestionar tareas'**
  String get tasks_no_home_body;

  /// No home empty state title in members screen
  ///
  /// In es, this message translates to:
  /// **'Sin miembros'**
  String get members_no_home_title;

  /// No home empty state body in members screen
  ///
  /// In es, this message translates to:
  /// **'Crea un hogar o únete a uno para ver los miembros'**
  String get members_no_home_body;
```

- [ ] **Paso 5: Añadir 6 implementaciones en `app_localizations_es.dart`**

Busca `String get today_no_home_body =>` (línea ~537) e inserta después del cierre de esa expresión (línea ~538, antes de `String get complete_task_dialog_body`):

```dart
  @override
  String get history_no_home_title => 'Sin historial';

  @override
  String get history_no_home_body =>
      'Crea un hogar o únete a uno para ver tu historial';

  @override
  String get tasks_no_home_title => 'Sin tareas';

  @override
  String get tasks_no_home_body =>
      'Crea un hogar o únete a uno para gestionar tareas';

  @override
  String get members_no_home_title => 'Sin miembros';

  @override
  String get members_no_home_body =>
      'Crea un hogar o únete a uno para ver los miembros';
```

- [ ] **Paso 6: Añadir 6 implementaciones en `app_localizations_en.dart`**

Busca `String get today_no_home_body =>` (línea ~531) e inserta después del cierre:

```dart
  @override
  String get history_no_home_title => 'No history';

  @override
  String get history_no_home_body =>
      'Create or join a home to see your history';

  @override
  String get tasks_no_home_title => 'No tasks';

  @override
  String get tasks_no_home_body =>
      'Create or join a home to manage your tasks';

  @override
  String get members_no_home_title => 'No members';

  @override
  String get members_no_home_body =>
      'Create or join a home to see its members';
```

- [ ] **Paso 7: Añadir 6 implementaciones en `app_localizations_ro.dart`**

Busca `String get today_no_home_body =>` (línea ~536) e inserta después del cierre:

```dart
  @override
  String get history_no_home_title => 'Fără istoric';

  @override
  String get history_no_home_body =>
      'Creează sau alătură-te unui cămin pentru a-ți vedea istoricul';

  @override
  String get tasks_no_home_title => 'Fără sarcini';

  @override
  String get tasks_no_home_body =>
      'Creează sau alătură-te unui cămin pentru a gestiona sarcinile';

  @override
  String get members_no_home_title => 'Fără membri';

  @override
  String get members_no_home_body =>
      'Creează sau alătură-te unui cămin pentru a vedea membrii';
```

- [ ] **Paso 8: Verificar que compila**

```bash
flutter analyze 2>&1 | grep "^error" | head -20
```

Esperado: sin líneas de error.

- [ ] **Paso 9: Commit**

```bash
git add lib/l10n/app_es.arb lib/l10n/app_en.arb lib/l10n/app_ro.arb \
        lib/l10n/app_localizations.dart \
        lib/l10n/app_localizations_es.dart \
        lib/l10n/app_localizations_en.dart \
        lib/l10n/app_localizations_ro.dart
git commit -m "feat(i18n): claves ARB no-home para historial, miembros y tareas"
```

---

### Task 2: Widget compartido `NoHomeEmptyState`

**Files:**
- Create: `lib/shared/widgets/no_home_empty_state.dart`

**Contexto:** `showCreateHomeSheet` y `showJoinHomeSheet` están en `lib/features/homes/presentation/home_selector_widget.dart`. El widget necesita `WidgetRef` porque llama a esas funciones (pasan `ref` para Riverpod). Los botones tienen keys fijas para poder encontrarlos en tests.

- [ ] **Paso 1: Crear el archivo**

Crea `lib/shared/widgets/no_home_empty_state.dart` con este contenido completo:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/homes/presentation/home_selector_widget.dart';
import '../../l10n/app_localizations.dart';

class NoHomeEmptyState extends ConsumerWidget {
  const NoHomeEmptyState({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              key: const Key('no_home_create_button'),
              onPressed: () => showCreateHomeSheet(context, ref, 0),
              icon: const Icon(Icons.add),
              label: Text(l10n.onboarding_create_home_button),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const Key('no_home_join_button'),
              onPressed: () => showJoinHomeSheet(context, ref, 0),
              icon: const Icon(Icons.group_add_outlined),
              label: Text(l10n.onboarding_join_home),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Paso 2: Verificar que compila**

```bash
flutter analyze lib/shared/widgets/no_home_empty_state.dart 2>&1 | grep "^error" | head -10
```

Esperado: sin líneas de error.

- [ ] **Paso 3: Commit**

```bash
git add lib/shared/widgets/no_home_empty_state.dart
git commit -m "feat(shared): widget NoHomeEmptyState compartido"
```

---

### Task 3: Historial — `HistoryViewModel.hasHome` + guardia en pantalla

**Files:**
- Modify: `lib/features/history/application/history_view_model.dart:48-102`
- Modify: `lib/features/history/presentation/skins/history_screen_v2.dart:42-56`

**Contexto:** La interfaz abstracta `HistoryViewModel` está en las líneas 48-56. La implementación `_HistoryViewModelImpl` está en líneas 58-102. El campo `homeId` es `String?` y ya existe en el impl. El método `build` de `_HistoryScreenV2State` comienza en línea 42; `final bg = ...` es la última línea antes del `return Scaffold(`.

- [ ] **Paso 1: Añadir `bool get hasHome` a la interfaz abstracta**

En `lib/features/history/application/history_view_model.dart`, en el bloque `abstract class HistoryViewModel` (líneas 48-56), añade el getter después de `bool get isPremium;`:

```dart
abstract class HistoryViewModel {
  AsyncValue<List<TaskEventItem>> get items;
  HistoryFilter get filter;
  bool get hasMore;
  bool get isPremium;
  bool get hasHome;   // ← añadir esta línea
  void loadMore();
  void applyFilter(HistoryFilter newFilter);
  Future<void> rateEvent(String eventId, double rating, {String? note});
}
```

- [ ] **Paso 2: Implementar `hasHome` en `_HistoryViewModelImpl`**

En el mismo archivo, en `_HistoryViewModelImpl` (línea ~77, justo después del campo `homeId`), añade:

```dart
  final String? homeId;
  final String  currentUid;
  final Ref ref;

  @override
  bool get hasHome => homeId != null;   // ← añadir este getter
```

- [ ] **Paso 3: Añadir guardia y `NoHomeEmptyState` en `history_screen_v2.dart`**

En `lib/features/history/presentation/skins/history_screen_v2.dart`:

1. Añade el import del widget compartido después de los imports existentes:

```dart
import '../../../../shared/widgets/no_home_empty_state.dart';
```

2. En el método `build` de `_HistoryScreenV2State`, añade la guardia inmediatamente después de `final bg = ...` y antes del `return Scaffold(`:

```dart
    if (!vm.hasHome) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          title: Text(l10n.history_title,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900)),
        ),
        body: NoHomeEmptyState(
          title: l10n.history_no_home_title,
          body: l10n.history_no_home_body,
        ),
      );
    }
```

El método `build` completo debe quedar así:

```dart
  @override
  Widget build(BuildContext context) {
    final l10n  = AppLocalizations.of(context);
    final HistoryViewModel vm = ref.watch(historyViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg    = isDark ? AppColorsV2.backgroundDark : AppColorsV2.backgroundLight;

    if (!vm.hasHome) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          title: Text(l10n.history_title,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900)),
        ),
        body: NoHomeEmptyState(
          title: l10n.history_no_home_title,
          body: l10n.history_no_home_body,
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text(l10n.history_title,
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900)),
      ),
      body: Column(children: [
        // ... resto sin cambios ...
      ]),
    );
  }
```

- [ ] **Paso 4: Verificar que compila**

```bash
flutter analyze lib/features/history/ 2>&1 | grep "^error" | head -10
```

Esperado: sin líneas de error.

- [ ] **Paso 5: Commit**

```bash
git add lib/features/history/application/history_view_model.dart \
        lib/features/history/presentation/skins/history_screen_v2.dart
git commit -m "feat(history): empty state sin hogar en pantalla de historial"
```

---

### Task 4: Miembros — reemplazar `error_generic` con `NoHomeEmptyState`

**Files:**
- Modify: `lib/features/members/presentation/members_screen.dart:1-38`

**Contexto:** El bloque `data: (data) { if (data == null) ... }` está en líneas 33-38. Actualmente muestra `Center(child: Text(l10n.error_generic))`. La pantalla ya es un `ConsumerWidget`, por lo que `ref` está disponible en el `build`.

- [ ] **Paso 1: Añadir import de `NoHomeEmptyState`**

En `lib/features/members/presentation/members_screen.dart`, añade el import después de los imports existentes de `shared/widgets/`:

```dart
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/no_home_empty_state.dart';   // ← añadir
import '../../../shared/widgets/skins/main_shell_v2.dart';
```

- [ ] **Paso 2: Reemplazar el bloque `data == null` en `members_screen.dart`**

Localiza (líneas 33-38):

```dart
      data: (data) {
        if (data == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.members_title)),
            body: Center(child: Text(l10n.error_generic)),
          );
        }
```

Reemplaza por:

```dart
      data: (data) {
        if (data == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.members_title)),
            body: NoHomeEmptyState(
              title: l10n.members_no_home_title,
              body: l10n.members_no_home_body,
            ),
          );
        }
```

- [ ] **Paso 3: Verificar que compila**

```bash
flutter analyze lib/features/members/presentation/members_screen.dart 2>&1 | grep "^error" | head -10
```

Esperado: sin líneas de error.

- [ ] **Paso 4: Commit**

```bash
git add lib/features/members/presentation/members_screen.dart
git commit -m "feat(members): empty state sin hogar en pantalla de miembros"
```

---

### Task 5: Tareas — reemplazar spinner con `NoHomeEmptyState`

**Files:**
- Modify: `lib/features/tasks/presentation/skins/all_tasks_screen_v2.dart:90-96`

**Contexto:** El bloque `data: (data) { if (data == null) ... }` está en líneas 90-96. Actualmente muestra `const Center(child: CircularProgressIndicator())`. La pantalla es `ConsumerStatefulWidget`, así que `ref` está disponible en el `State`.

- [ ] **Paso 1: Añadir import de `NoHomeEmptyState`**

En `lib/features/tasks/presentation/skins/all_tasks_screen_v2.dart`, añade el import después de los imports existentes de `shared/widgets/`:

```dart
import '../../../../shared/widgets/skins/main_shell_v2.dart';
import '../../../../shared/widgets/no_home_empty_state.dart';   // ← añadir
```

- [ ] **Paso 2: Reemplazar el bloque `data == null` en `all_tasks_screen_v2.dart`**

Localiza (líneas 90-96):

```dart
      data: (data) {
        if (data == null) {
          return Scaffold(
            appBar: _buildAppBar(l10n, vm, isDark),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
```

Reemplaza por:

```dart
      data: (data) {
        if (data == null) {
          return Scaffold(
            appBar: _buildAppBar(l10n, vm, isDark),
            body: NoHomeEmptyState(
              title: l10n.tasks_no_home_title,
              body: l10n.tasks_no_home_body,
            ),
          );
        }
```

- [ ] **Paso 3: Verificar que compila**

```bash
flutter analyze lib/features/tasks/presentation/skins/all_tasks_screen_v2.dart 2>&1 | grep "^error" | head -10
```

Esperado: sin líneas de error.

- [ ] **Paso 4: Commit**

```bash
git add lib/features/tasks/presentation/skins/all_tasks_screen_v2.dart
git commit -m "feat(tasks): empty state sin hogar en pantalla de tareas"
```

---

### Task 6: Verificación final

**Files:** ninguno nuevo.

- [ ] **Paso 1: `flutter analyze` global**

```bash
flutter analyze 2>&1 | grep "^error" | head -20
```

Esperado: sin líneas de error.

- [ ] **Paso 2: Confirmar claves ARB completas**

```bash
grep -c "no_home" lib/l10n/app_es.arb
```

Esperado: `8` (2 de today + 6 nuevas).

- [ ] **Paso 3: Confirmar getters en localizations**

```bash
grep "no_home" lib/l10n/app_localizations.dart | wc -l
```

Esperado: `8` (2 de today + 6 nuevas).

- [ ] **Paso 4: Commit final de docs**

```bash
git add docs/superpowers/plans/2026-04-16-no-home-empty-states.md
git commit -m "docs(plans): plan de implementación no-home empty states"
```

---

## Pruebas manuales requeridas

Tras implementar, el desarrollador debe verificar manualmente:

1. Abandonar el hogar → navegar a Historial → ver "Sin historial" con icon + texto + 2 botones.
2. Ir a Miembros → ver "Sin miembros" con icon + texto + 2 botones.
3. Ir a Tareas (todas) → ver "Sin tareas" con icon + texto + 2 botones.
4. Pulsar "Crear hogar" en cualquiera de esas pantallas → se abre el sheet de creación.
5. Pulsar "Unirse a hogar" → se abre el sheet de unión.
6. Crear/unirse → la pantalla pasa a mostrar el contenido normal.
