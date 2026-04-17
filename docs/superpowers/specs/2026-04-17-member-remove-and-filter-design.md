# Spec: Expulsar miembro + filtrar miembros con status "left" (Bugs #40 y #41)

**Fecha:** 2026-04-17
**Estado:** Aprobado
**Bugs:** #40 (owner no puede expulsar miembros), #41 (lista de miembros incluye los que abandonaron el hogar)

---

## Contexto

### Bug #40 — Sin botón de expulsión

`MemberProfileViewData` solo expone `canManageRoles` para controlar la visibilidad del botón de promover/degradar. No existe ningún campo `canRemoveMember` ni método `removeMember()` en la interfaz `MemberProfileViewModel`. La función `removeMember` del repositorio existe y está implementada en `MembersRepositoryImpl` (llama a la CF `removeMember`), pero nunca se invoca desde la UI.

**Archivo clave:** `lib/features/members/application/member_profile_view_model.dart`
- `canManageRoles = isOwner && !isSelf` (línea 137)
- Interfaz `MemberProfileViewModel` solo tiene `promoteToAdmin` y `demoteFromAdmin` (líneas 60–63)

### Bug #41 — Miembros "left" visibles en la lista

`watchHomeMembers` consulta toda la subcolección `homes/{homeId}/members` sin filtrar por status:

```dart
// members_repository_impl.dart línea 22-28
return _firestore
    .collection('homes').doc(homeId).collection('members')
    .snapshots()  // ← sin filtro de status
    .map(...);
```

Los documentos de miembros que abandonaron el hogar tienen `status: 'left'` pero siguen apareciendo en el stream.

---

## Solución

### Bug #41 — Filtrar status "left" en el stream

**Archivo:** `lib/features/members/data/members_repository_impl.dart`

Añadir `.where('status', isNotEqualTo: 'left')` al query de `watchHomeMembers`:

```dart
@override
Stream<List<Member>> watchHomeMembers(String homeId) {
  return _firestore
      .collection('homes')
      .doc(homeId)
      .collection('members')
      .where('status', isNotEqualTo: 'left')
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => MemberModel.fromFirestore(d, homeId)).toList());
}
```

> **Índice Firestore:** Verificar en `firestore.indexes.json` si se necesita un índice compuesto para `homes/{homeId}/members` con `status` (isNotEqualTo puede requerir índice de colección simple con ese campo).

### Bug #40 — Añadir botón de expulsión

#### Paso 1: Añadir `canRemoveMember` a `MemberProfileViewData`

```dart
class MemberProfileViewData {
  const MemberProfileViewData({
    // ...campos existentes...
    required this.canManageRoles,
    required this.canRemoveMember,  // ← nuevo
    // ...
  });
  final bool canManageRoles;
  final bool canRemoveMember;  // ← nuevo
}
```

**Regla:** `canRemoveMember = isOwner && !isSelf && member.role != MemberRole.owner`

El owner no puede expulsarse a sí mismo ni a otro owner. Solo puede expulsar a admins y miembros normales.

#### Paso 2: Añadir `removeMember()` a la interfaz y al impl

```dart
abstract class MemberProfileViewModel {
  AsyncValue<MemberProfileViewData?> get viewData;
  Future<void> promoteToAdmin(String homeId, String uid);
  Future<void> demoteFromAdmin(String homeId, String uid);
  Future<void> removeMember(String homeId, String uid);  // ← nuevo
}

class _MemberProfileViewModelImpl implements MemberProfileViewModel {
  // ...
  @override
  Future<void> removeMember(String homeId, String uid) =>
      ref.read(membersRepositoryProvider).removeMember(homeId, uid);
}
```

#### Paso 3: Actualizar el factory del provider

En la función `memberProfileViewModel`, calcular `canRemoveMember` y pasarlo al constructor:

```dart
final member = /* miembro objetivo */;
final canRemoveMember = isOwner && !isSelf && member.role != MemberRole.owner;

return MemberProfileViewData(
  // ...
  canManageRoles: canManageRoles,
  canRemoveMember: canRemoveMember,
  // ...
);
```

#### Paso 4: Añadir botón en `MemberProfileScreenV2`

**Archivo:** `lib/features/members/presentation/skins/member_profile_screen_v2.dart`

Añadir un botón destructivo después del botón de gestión de roles (después del bloque `if (data.canManageRoles && !data.isSelf)`):

```dart
if (data.canRemoveMember) ...[
  const SizedBox(height: 12),
  SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      key: const Key('remove_member_button'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red),
      ),
      onPressed: _isLoading
          ? null
          : () => _confirmRemoveMember(context, vm, data, l10n),
      child: Text(l10n.member_profile_remove_member),
    ),
  ),
],
```

Añadir el método de confirmación en `_MemberProfileScreenV2State`:

```dart
Future<void> _confirmRemoveMember(
  BuildContext context,
  MemberProfileViewModel vm,
  MemberProfileViewData data,
  AppLocalizations l10n,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(l10n.member_profile_remove_member),
      content: Text(l10n.member_profile_remove_member_confirm(data.member.nickname)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.member_profile_remove_member),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;

  setState(() => _isLoading = true);
  try {
    await vm.removeMember(widget.homeId, widget.memberUid);
    if (context.mounted) Navigator.of(context).pop(); // Volver a la lista
  } on CannotRemoveOwnerException {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.error_cannot_remove_owner)));
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.error_generic)));
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
```

#### Paso 5: Añadir claves i18n

Añadir en `app_es.arb`, `app_en.arb` y `app_ro.arb`:

```json
"member_profile_remove_member": "Expulsar del hogar",
"member_profile_remove_member_confirm": "¿Expulsar a {name} del hogar? Esta acción no se puede deshacer.",
"@member_profile_remove_member_confirm": {
  "placeholders": { "name": { "type": "String" } }
},
"error_cannot_remove_owner": "No se puede expulsar al propietario del hogar."
```

---

## Archivos afectados

| Archivo | Acción |
|---|---|
| `lib/features/members/data/members_repository_impl.dart` | Añadir `.where('status', isNotEqualTo: 'left')` en `watchHomeMembers` |
| `lib/features/members/application/member_profile_view_model.dart` | Añadir `canRemoveMember` + `removeMember()` |
| `lib/features/members/presentation/skins/member_profile_screen_v2.dart` | Añadir botón de expulsión + método de confirmación |
| `lib/l10n/app_es.arb` | Añadir claves i18n |
| `lib/l10n/app_en.arb` | Añadir claves i18n |
| `lib/l10n/app_ro.arb` | Añadir claves i18n |
| `firestore.indexes.json` | Verificar/añadir índice para `status != 'left'` si requerido |

---

## Tests requeridos

### Unitarios
- `watchHomeMembers` filtra documentos con `status == 'left'`: solo devuelve los que tienen otro status.
- `canRemoveMember` es `false` para `isSelf == true`.
- `canRemoveMember` es `false` cuando `member.role == MemberRole.owner`.
- `canRemoveMember` es `true` para owner viendo a un admin o member normal.

### Widget
- `MemberProfileScreenV2` con owner viendo a un member: muestra `remove_member_button`.
- `MemberProfileScreenV2` con owner viendo a otro owner: no muestra `remove_member_button`.
- `MemberProfileScreenV2` con member viendo a otro member: no muestra `remove_member_button`.
- Tap en `remove_member_button` → muestra diálogo de confirmación.
- Confirmación → llama `vm.removeMember` y navega hacia atrás.
- Rechazo del diálogo → no llama `vm.removeMember`.

### CF (integración)
- Test de integración contra el emulador: owner llama `removeMember` CF → el documento de miembro tiene `status: 'left'` y desaparece de `watchHomeMembers`.
