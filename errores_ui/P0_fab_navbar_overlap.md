# P0 — FAB y BottomSheet tapados por la NavigationBar

## Bugs que corrige
- **Bug #1** — FAB "Invitar" (Members) y FAB "Crear tarea" (Tasks) se superponen con la NavigationBar; los toques navegan al tab de Settings en lugar de abrir el FAB.
- **Bug #2** — InviteMemberSheet: el botón de confirmación queda detrás de la NavigationBar porque el sheet no aplica `viewPadding.bottom`.
- **Bug #25** — BottomSheet de valoración: botón "Enviar valoración" renderiza a y≈2211, detrás de NavBar (y≈2161+). Completamente inaccesible.

## Causa raíz

La NavigationBar de Flutter ocupa los últimos ~142 px del viewport (1080×2400 en el emulador de pruebas). Los FABs se posicionan a y≈2222 (superpuestos), y los BottomSheets calculan su padding inferior solo con `MediaQuery.of(context).viewInsets.bottom` (altura del teclado), ignorando `MediaQuery.of(context).viewPadding.bottom` (zona de sistema + NavBar).

## Archivos a modificar

| Archivo | Sección |
|---------|---------|
| `lib/features/members/presentation/skins/members_screen_v2.dart` | FAB de invitación |
| `lib/features/tasks/presentation/skins/tasks_screen_v2.dart` | FAB de crear tarea |
| `lib/features/members/presentation/widgets/invite_member_sheet.dart` | Padding inferior del sheet |
| `lib/features/tasks/presentation/widgets/task_rating_sheet.dart` | Padding inferior del sheet (valoración) |

## Cambios requeridos

### 1. FABs — Scaffold padding

En cada Scaffold que contenga un FAB, añadir `floatingActionButtonLocation` con offset correcto o envolver el contenido con `SafeArea`:

```dart
// Opción A: SafeArea en el FAB mismo
floatingActionButton: SafeArea(
  child: FloatingActionButton(
    onPressed: _openInviteSheet,
    child: const Icon(Icons.person_add),
  ),
),
```

```dart
// Opción B: padding explícito con MediaQuery
floatingActionButton: Padding(
  padding: EdgeInsets.only(
    bottom: MediaQuery.of(context).padding.bottom,
  ),
  child: FloatingActionButton(...),
),
```

### 2. BottomSheets — padding inferior correcto

En todos los BottomSheets (InviteMemberSheet, TaskRatingSheet, y cualquier otro), reemplazar:

```dart
// MAL — solo cuenta la altura del teclado
padding: EdgeInsets.only(
  bottom: MediaQuery.of(context).viewInsets.bottom,
),
```

por:

```dart
// BIEN — suma teclado + zona de sistema (NavBar, gesture bar)
final mq = MediaQuery.of(context);
final bottomPadding = mq.viewInsets.bottom + mq.viewPadding.bottom;
// ...
padding: EdgeInsets.only(bottom: bottomPadding + 16),
```

### 3. Verificar todos los BottomSheets de la app

Buscar todos los usos de `viewInsets.bottom` en `lib/` y verificar que añaden `viewPadding.bottom`:

```bash
grep -rn "viewInsets.bottom" lib/
```

## Criterios de aceptación

- [ ] El FAB de invitación en Members es tappable sin activar el tab de Settings.
- [ ] El FAB de crear tarea en Tasks es tappable sin activar el tab de Settings.
- [ ] El botón del BottomSheet de invitación es visible y tappable sin abrir el teclado.
- [ ] El botón "Enviar valoración" del BottomSheet es visible y tappable sin abrir el teclado.
- [ ] Verificado en emulador `emulator-5554` (1080×2400, Android 14).
- [ ] Sin regresiones en otros BottomSheets.

## Tests requeridos

- Test de widget: `InviteMemberSheet` — el botón de confirmación tiene posición por encima de `viewPadding.bottom`.
- Test de widget: `TaskRatingSheet` — mismo criterio.
- Golden test: FABs en Members y Tasks con NavBar visible.
