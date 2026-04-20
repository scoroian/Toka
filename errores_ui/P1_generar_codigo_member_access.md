# P1 — Botón "Generar código" visible para Member sin permisos

## Bugs que corrige
- **Bug #30** — El botón "Generar código" en HomeSettings es visible para usuarios con rol **Member**, aunque no tienen permisos para generarlo.
- **Bug #33** — Cuando Member pulsa "Generar código", la operación falla silenciosamente en Firestore (permisos denegados) sin ningún mensaje de error visible al usuario.

## Causa raíz

El widget de "Generar código" en `HomeSettingsScreen` no verifica el rol del usuario actual antes de renderizar el botón. Además, el handler del botón (aunque está vacío — Bug #5) no tiene lógica de guard de permisos ni manejo de errores.

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `lib/features/homes/presentation/home_settings_screen.dart` | Ocultar botón para Member; añadir manejo de error |

## Cambios requeridos

### 1. Ocultar el botón "Generar código" para Members

En `HomeSettingsScreen`, obtener el rol del usuario actual y mostrar el botón solo para Owner y Admin:

```dart
// Obtener rol actual
final currentRole = ref.watch(currentMemberRoleProvider);
final canGenerateCode = currentRole == MemberRole.owner || currentRole == MemberRole.admin;

// Renderizar condicionalmente
if (canGenerateCode)
  ElevatedButton(
    onPressed: _generateInviteCode,
    child: Text(l10n.generateCode),
  ),
```

### 2. Alternativa: mostrar el botón pero deshabilitado con tooltip explicativo

Si se prefiere mostrar el botón a todos pero deshabilitado para Members:

```dart
Tooltip(
  message: canGenerateCode ? '' : l10n.onlyAdminsCanGenerateCode,
  child: ElevatedButton(
    onPressed: canGenerateCode ? _generateInviteCode : null,
    child: Text(l10n.generateCode),
  ),
),
```

> **Recomendación**: ocultar el botón (opción 1) es más limpio y consistente con el patrón usado en otras partes de la app (FAB de tareas, FAB de invitar).

### 3. Manejo de error en caso de fallo de permisos Firestore

En el handler `_generateInviteCode`, capturar `FirebaseException` y mostrar snackbar:

```dart
Future<void> _generateInviteCode() async {
  try {
    final code = await ref.read(homeRepositoryProvider).generateInviteCode();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.inviteCodeGenerated(code))),
      );
    }
  } on FirebaseException catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.code == 'permission-denied'
              ? l10n.noPermissionToGenerateCode
              : l10n.errorGeneratingCode),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
```

### 4. Claves ARB requeridas

```json
"onlyAdminsCanGenerateCode": "Solo los administradores pueden generar códigos de invitación.",
"noPermissionToGenerateCode": "No tienes permisos para generar códigos de invitación.",
"errorGeneratingCode": "Error al generar el código. Inténtalo de nuevo.",
"inviteCodeGenerated": "Código generado: {code}"
```

## Criterios de aceptación

- [ ] Member NO ve el botón "Generar código" en HomeSettings.
- [ ] Owner ve el botón y puede generar el código.
- [ ] Admin ve el botón y puede generar el código.
- [ ] Si (por cualquier motivo) el botón es visible para Member y se pulsa, se muestra un mensaje de error claro.

## Tests requeridos

- Test de widget: `HomeSettingsScreen` con rol Member → botón "Generar código" ausente.
- Test de widget: `HomeSettingsScreen` con rol Owner → botón "Generar código" presente y habilitado.
- Test de widget: handler de generación con error `permission-denied` → muestra snackbar de error.
