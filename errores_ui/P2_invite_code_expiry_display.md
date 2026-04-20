# P2 — Código de invitación: sin fecha de expiración visible y sin posibilidad de regenerar

## Bug + Mejora que aborda
- **Bug #18** — Los códigos de invitación expiran rápidamente sin indicación de cuándo. El código V5W5X9 generado el 2026-04-15 ya era inválido en la misma sesión. No hay UI que muestre la fecha de expiración ni permita revocar/regenerar fácilmente.
- **Mejora #8** — Mostrar fecha de expiración del código en `InviteMemberSheet` y en `HomeSettingsScreen`. Permitir revocar/regenerar código sin crear uno nuevo siempre.

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `lib/features/members/presentation/widgets/invite_member_sheet.dart` | Mostrar fecha de expiración |
| `lib/features/homes/presentation/home_settings_screen.dart` | Mostrar fecha de expiración + botón regenerar |
| `functions/src/homes/index.ts` | Asegurar que `expiresAt` se escribe al generar código |

## Cambios requeridos

### 1. Asegurar que el código tiene `expiresAt` en Firestore

En la Cloud Function que genera el código de invitación:

```typescript
const expiresAt = new Date();
expiresAt.setDate(expiresAt.getDate() + 7); // 7 días de validez

await inviteRef.set({
  code: generatedCode,
  homeId,
  createdBy: uid,
  createdAt: FieldValue.serverTimestamp(),
  expiresAt: Timestamp.fromDate(expiresAt),
  used: false,
});
```

### 2. Mostrar la fecha de expiración en InviteMemberSheet

```dart
// En el widget del código de invitación
if (inviteCode != null) ...[
  Text(inviteCode.code, style: Theme.of(context).textTheme.headlineMedium),
  const SizedBox(height: 8),
  Text(
    l10n.inviteCodeExpiresAt(
      DateFormat('dd MMM yyyy · HH:mm').format(inviteCode.expiresAt.toLocal()),
    ),
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      color: _isExpiringSoon(inviteCode.expiresAt)
          ? Theme.of(context).colorScheme.error
          : Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  ),
],
```

Helper para indicar si expira pronto (< 24h):

```dart
bool _isExpiringSoon(DateTime expiresAt) {
  return expiresAt.difference(DateTime.now()).inHours < 24;
}
```

### 3. Botón "Regenerar código" en HomeSettings

```dart
// Junto al código actual
Row(
  children: [
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(currentCode, style: Theme.of(context).textTheme.titleLarge),
          Text(l10n.expiresAt(formattedDate)),
        ],
      ),
    ),
    IconButton(
      icon: const Icon(Icons.refresh),
      tooltip: l10n.regenerateCode,
      onPressed: _regenerateInviteCode,
    ),
    IconButton(
      icon: const Icon(Icons.copy),
      tooltip: l10n.copyCode,
      onPressed: () => Clipboard.setData(ClipboardData(text: currentCode)),
    ),
  ],
),
```

### 4. Revocación de código anterior al regenerar

En la CF de generación de código, revocar/marcar como usado el código anterior:

```typescript
// Buscar códigos activos del hogar y marcarlos como revocados
const oldCodes = await db.collection('invitations')
  .where('homeId', '==', homeId)
  .where('used', '==', false)
  .where('expiresAt', '>', Timestamp.now())
  .get();

const batch = db.batch();
for (const doc of oldCodes.docs) {
  batch.update(doc.ref, { revoked: true });
}
// Crear nuevo código
batch.set(newInviteRef, { ...newCodeData });
await batch.commit();
```

### 5. Claves ARB requeridas

```json
"inviteCodeExpiresAt": "Expira el {date}",
"regenerateCode": "Regenerar código",
"copyCode": "Copiar código",
"inviteCodeExpiredError": "Este código ha caducado. El propietario debe generar uno nuevo."
```

## Criterios de aceptación

- [ ] El código de invitación muestra la fecha y hora de expiración al mostrarse en `InviteMemberSheet`.
- [ ] Si el código expira en menos de 24h, la fecha se muestra en rojo.
- [ ] El botón "Regenerar código" (o "Generar código") revoca el anterior y crea uno nuevo.
- [ ] Al intentar usar un código expirado en onboarding, el error es específico: "El código ha caducado".

## Tests requeridos

- Test de widget: `InviteMemberSheet` con `expiresAt` = ahora + 2h → fecha en rojo.
- Test de widget: `InviteMemberSheet` con `expiresAt` = ahora + 5d → fecha en gris/subtexto.
- Test de integración: regenerar código → código anterior marcado como revocado → nuevo código activo.
