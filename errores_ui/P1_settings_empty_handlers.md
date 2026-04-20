# P1 — Handlers vacíos en Settings y HomeSettings

## Bugs que corrige
- **Bug #3** — Multiple `onTap: () {}` vacíos en Settings: Cambiar contraseña, Eliminar cuenta, Idioma, Visibilidad del teléfono, Código de invitación, Abandonar hogar, Términos de uso, Política de privacidad.
- **Bug #5** — Botón "Generar código" en HomeSettings tiene `onPressed: () {}` vacío.
- **Bug #23** — Item "Código de invitación" en Settings (sección Hogar) tiene `onTap: () {}` vacío. No abre ningún sheet ni pantalla.

## Archivos a modificar

| Archivo | Items |
|---------|-------|
| `lib/features/settings/presentation/settings_screen.dart` | Todos los `onTap: () {}` |
| `lib/features/homes/presentation/home_settings_screen.dart` | Botón "Generar código" |

## Cambios requeridos por item

### 1. Cambiar contraseña

Solo aplica a usuarios registrados con email/password (no OAuth):

```dart
onTap: () async {
  final user = FirebaseAuth.instance.currentUser;
  if (user?.email != null) {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.passwordResetEmailSent)),
      );
    }
  }
},
```

### 2. Idioma

Navegar a la pantalla/bottom sheet de selección de idioma:

```dart
onTap: () => context.push('/settings/language'),
// o si es un BottomSheet:
onTap: () => showModalBottomSheet(
  context: context,
  builder: (_) => const LanguageSelectorSheet(),
),
```

### 3. Código de invitación (en Settings → sección Hogar)

Abrir `InviteMemberSheet` o navegar a la pantalla de invitación:

```dart
onTap: () => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (_) => const InviteMemberSheet(),
),
```

### 4. Abandonar hogar

Mostrar diálogo de confirmación antes de ejecutar:

```dart
onTap: () async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(l10n.leaveHomeTitle),
      content: Text(l10n.leaveHomeConfirm),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
        TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.confirm)),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    await ref.read(homeRepositoryProvider).leaveHome();
    context.go('/onboarding');
  }
},
```

### 5. Términos de uso y Política de privacidad

Abrir URL externa (usar `url_launcher`):

```dart
onTap: () => launchUrl(Uri.parse('https://toka.app/terms')),
// y
onTap: () => launchUrl(Uri.parse('https://toka.app/privacy')),
```

### 6. Eliminar cuenta

Requiere re-autenticación. Mostrar diálogo de confirmación + re-auth:

```dart
onTap: () async {
  final confirmed = await showDialog<bool>(...);
  if (confirmed == true) {
    // Flujo de re-autenticación y eliminación de cuenta
    await ref.read(authRepositoryProvider).deleteAccount();
    if (context.mounted) context.go('/login');
  }
},
```

### 7. Visibilidad del teléfono

Navegar a ajustes de privacidad o toggle inline:

```dart
onTap: () => context.push('/settings/privacy'),
```

### 8. Generar código en HomeSettings

Llamar a la Cloud Function o repositorio para generar un nuevo código:

```dart
onPressed: () async {
  final code = await ref.read(homeRepositoryProvider).generateInviteCode();
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.inviteCodeGenerated(code))),
    );
  }
},
```

## Claves ARB requeridas

Añadir en `l10n/app_es.arb` (y equivalentes en en/ro):
```json
"passwordResetEmailSent": "Te hemos enviado un email para restablecer tu contraseña.",
"leaveHomeTitle": "Abandonar hogar",
"leaveHomeConfirm": "¿Seguro que quieres abandonar este hogar? Esta acción no se puede deshacer.",
"inviteCodeGenerated": "Código generado: {code}"
```

## Criterios de aceptación

- [ ] "Cambiar contraseña" envía email de reset y muestra snackbar de confirmación.
- [ ] "Idioma" abre selector de idioma funcional.
- [ ] "Código de invitación" en Settings abre el sheet de invitación.
- [ ] "Abandonar hogar" muestra diálogo de confirmación y redirige a onboarding si confirma.
- [ ] "Términos de uso" y "Política de privacidad" abren URLs correctas.
- [ ] "Generar código" en HomeSettings genera un nuevo código y lo muestra.
- [ ] Todos los items de Settings tienen feedback visual al pulsarlos (ripple + acción).

## Tests requeridos

- Test de widget: pulsar "Abandonar hogar" → muestra diálogo de confirmación.
- Test de widget: pulsar "Generar código" → llama a `generateInviteCode()` del repositorio mock.
- Test de integración: abandonar hogar → usuario removido de `members/{uid}` en Firestore.
