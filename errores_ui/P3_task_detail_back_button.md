# P3 — Sin botón Back explícito en AppBar de TaskDetail

## Bug que corrige
- **Bug #28** — `TaskDetailScreen` no muestra ningún botón "Atrás" explícito en la AppBar. Solo funciona el botón de sistema Android. Es inconsistente con otras pantallas que sí tienen flecha de vuelta.

## Nota
Este bug es relacionado pero independiente del **Bug #32** (BACK cierra la app). Incluso si Bug #32 se corrige, la ausencia de botón Back en la AppBar es una inconsistencia de UX que debe resolverse.

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `lib/features/tasks/presentation/skins/task_detail_screen_v2.dart` | Añadir `leading: BackButton()` en AppBar |

## Cambio requerido

En `TaskDetailScreenV2`, asegurar que la AppBar tiene un botón de vuelta:

```dart
AppBar(
  leading: const BackButton(), // ← añadir esto
  // O con acción personalizada:
  leading: IconButton(
    icon: const Icon(Icons.arrow_back),
    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    onPressed: () => context.pop(),
  ),
  title: Text(task.title),
  actions: [
    // botones de editar, más opciones...
  ],
),
```

Si la AppBar tiene `automaticallyImplyLeading: false`, eliminar esa propiedad o setearla a `true`.

### Verificar la consistencia en otras pantallas de detalle

```bash
# Verificar qué pantallas de detalle tienen/no tienen BackButton
grep -rn "AppBar\|automaticallyImplyLeading" lib/features/tasks/presentation/
grep -rn "AppBar\|automaticallyImplyLeading" lib/features/members/presentation/
```

## Criterios de aceptación

- [ ] La AppBar de `TaskDetailScreen` muestra una flecha de vuelta (BackButton).
- [ ] Pulsar el BackButton vuelve a la pantalla anterior (coherente con Bug #32 fix).
- [ ] El botón de vuelta tiene el tooltip de accesibilidad correcto ("Atrás" / "Back" según el locale).

## Tests requeridos

- Test de widget: `TaskDetailScreenV2` → `find.byType(BackButton)` o `find.byIcon(Icons.arrow_back)` devuelve 1 elemento.
