# Spec: Empty states "sin hogar" en historial, miembros y tareas

**Fecha:** 2026-04-16
**Estado:** Aprobado

---

## Contexto

Cuando un usuario abandona su hogar (flujo implementado en `leave-home-owner-flow`), las pantallas de Historial, Miembros y Tareas (all-tasks) no detectan ese estado correctamente:

- **Historial**: muestra un spinner infinito (el view model retorna `AsyncValue.loading()` cuando `homeId == null`).
- **Miembros**: muestra `error_generic`.
- **Tareas**: muestra un spinner infinito.

La pantalla de Hoy ya tiene su propio `_NoHomeEmptyState` privado. Este spec añade el mismo patrón a las tres pantallas restantes mediante un widget compartido.

---

## Enfoque elegido

**Widget compartido `NoHomeEmptyState`** en `lib/shared/widgets/`. Las tres pantallas lo usan pasando sus propios `title` y `body`. La pantalla de Hoy mantiene su `_NoHomeEmptyState` privado existente (no se toca).

---

## Widget compartido

**Archivo:** `lib/shared/widgets/no_home_empty_state.dart`

```dart
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
            Text(title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(body,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center),
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

Importa `showCreateHomeSheet` y `showJoinHomeSheet` de `lib/features/homes/presentation/home_selector_widget.dart`.

---

## Detección por pantalla

### Historial (`history_screen_v2.dart`)

El view model retorna `AsyncValue.loading()` cuando no hay hogar, lo que hace imposible distinguirlo de la carga real. Se añade `bool get hasHome` a la interfaz abstracta:

```dart
abstract class HistoryViewModel {
  // ... existentes ...
  bool get hasHome;   // ← nuevo
}

class _HistoryViewModelImpl implements HistoryViewModel {
  // ...
  @override
  bool get hasHome => homeId != null;
}
```

En la pantalla, antes del `vm.items.when(...)`:

```dart
if (!vm.hasHome) {
  return NoHomeEmptyState(
    title: l10n.history_no_home_title,
    body: l10n.history_no_home_body,
  );
}
```

### Miembros (`members_screen.dart`)

`membersViewModelProvider` devuelve `AsyncData(null)` cuando `currentHomeProvider` resuelve a null. El bloque `data: (data) { if (data == null) ... }` ya existe — actualmente muestra `error_generic`. Se reemplaza por:

```dart
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

### Tareas (`all_tasks_screen_v2.dart`)

`allTasksViewModelProvider` devuelve `AsyncData(null)` cuando no hay hogar. El bloque `data: (data) { if (data == null) ... }` actualmente muestra `CircularProgressIndicator`. Se reemplaza por:

```dart
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

---

## Textos ARB (6 claves nuevas)

| Clave | Español | Inglés | Rumano |
|---|---|---|---|
| `history_no_home_title` | `Sin historial` | `No history` | `Fără istoric` |
| `history_no_home_body` | `Crea un hogar o únete a uno para ver tu historial` | `Create or join a home to see your history` | `Creează sau alătură-te unui cămin pentru a-ți vedea istoricul` |
| `tasks_no_home_title` | `Sin tareas` | `No tasks` | `Fără sarcini` |
| `tasks_no_home_body` | `Crea un hogar o únete a uno para gestionar tareas` | `Create or join a home to manage your tasks` | `Creează sau alătură-te unui cămin pentru a gestiona sarcinile` |
| `members_no_home_title` | `Sin miembros` | `No members` | `Fără membri` |
| `members_no_home_body` | `Crea un hogar o únete a uno para ver los miembros` | `Create or join a home to see its members` | `Creează sau alătură-te unui cămin pentru a vedea membrii` |

---

## Archivos afectados

| Archivo | Tipo de cambio |
|---|---|
| `lib/shared/widgets/no_home_empty_state.dart` | **Nuevo** |
| `lib/features/history/application/history_view_model.dart` | Añadir `bool get hasHome` a interfaz + impl |
| `lib/features/history/presentation/skins/history_screen_v2.dart` | Guardia `if (!vm.hasHome)` + `NoHomeEmptyState` |
| `lib/features/members/presentation/members_screen.dart` | `data == null` → `NoHomeEmptyState` |
| `lib/features/tasks/presentation/skins/all_tasks_screen_v2.dart` | `data == null` → `NoHomeEmptyState` |
| `lib/l10n/app_es.arb` | 6 claves nuevas |
| `lib/l10n/app_en.arb` | 6 claves nuevas |
| `lib/l10n/app_ro.arb` | 6 claves nuevas |
| `lib/l10n/app_localizations.dart` | 6 getters abstractos |
| `lib/l10n/app_localizations_es.dart` | 6 implementaciones |
| `lib/l10n/app_localizations_en.dart` | 6 implementaciones |
| `lib/l10n/app_localizations_ro.dart` | 6 implementaciones |

---

## Tests

No se añaden tests nuevos. Los cambios son exclusivamente de presentación:
- El widget `NoHomeEmptyState` es un `ConsumerWidget` simple sin lógica.
- La única lógica nueva es `bool get hasHome` en `HistoryViewModel`, que es trivial.
- Los view models existentes ya tienen sus propios tests.
