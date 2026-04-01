# Spec-08: Miembros, perfiles y privacidad

**Dependencias previas:** Spec-00 → Spec-07  
**Oleada:** Oleada 2

---

## Objetivo

Pantalla de miembros del hogar, perfil propio con estadísticas, perfil ajeno con alcance restringido, invitaciones, privacidad del teléfono y gestión de roles.

---

## Reglas de negocio

1. Perfil ajeno: foto, apodo, bio corta, teléfono (si visible), estadísticas del **hogar compartido** únicamente. Nunca notas textuales ni datos de otros hogares.
2. Perfil propio: todo lo anterior + notas recibidas, facturación histórica, vista global entre hogares.
3. Teléfono: `sameHomeMembers` (visible a miembros del hogar compartido) u `hidden`.
4. Solo `owner` puede designar/retirar admins y transferir propiedad.
5. Solo `owner` y admins pueden invitar o quitar miembros normales.
6. Admins no pueden quitar al propietario ni al pagador actual durante periodo Premium vigente.
7. En Free: máximo 3 miembros activos, 1 admin (el owner).
8. En Premium: hasta 10 miembros activos, hasta 4 admins.
9. Miembro congelado puede ver el tablero pero no recibe asignaciones ni puede actuar.

---

## Archivos a crear

```
lib/features/members/
├── data/
│   └── members_repository_impl.dart
├── domain/
│   ├── members_repository.dart
│   └── member.dart                (modelo freezed)
├── application/
│   ├── members_provider.dart
│   └── member_actions_provider.dart
└── presentation/
    ├── members_screen.dart
    ├── member_profile_screen.dart  (perfil ajeno)
    └── widgets/
        ├── member_card.dart
        ├── member_role_badge.dart
        └── invite_member_sheet.dart

lib/features/profile/
├── data/
│   └── profile_repository_impl.dart
├── domain/
│   ├── profile_repository.dart
│   └── user_profile.dart          (modelo freezed)
├── application/
│   └── profile_provider.dart
└── presentation/
    ├── own_profile_screen.dart
    ├── edit_profile_screen.dart
    └── widgets/
        ├── stats_section.dart
        ├── compliance_chart.dart
        └── access_management_section.dart
```

---

## Implementación clave

### MembersRepository

```dart
abstract interface class MembersRepository {
  Stream<List<Member>> watchHomeMembers(String homeId);
  Future<Member> fetchMember(String homeId, String uid);
  Future<void> inviteMember(String homeId, String? email);
  Future<String> generateInviteCode(String homeId);
  Future<void> removeMember(String homeId, String uid);
  Future<void> promoteToAdmin(String homeId, String uid);
  Future<void> demoteFromAdmin(String homeId, String uid);
  Future<void> transferOwnership(String homeId, String newOwnerUid); // via Function
}
```

### Pantalla Miembros

- Lista de miembros activos con avatar, nombre, rol badge, compliance rate.
- Indicador de "N tareas pendientes" por miembro.
- Sección de miembros congelados (colapsada).
- FAB "Invitar" (solo owner/admin).
- Al tocar un miembro → `MemberProfileScreen`.

### Pantalla Perfil ajeno (MemberProfileScreen)

```
Avatar | Nombre | Bio
[Teléfono si es visible]
─────────────────────
Estadísticas del hogar compartido:
• Tareas completadas: 42
• Compliance: 87%
• Racha actual: 5 tareas
• Puntuación media: 8.2/10
[Radar — solo Premium]
─────────────────────
Historial en este hogar (últimos 30/90 días)
```

### Pantalla Perfil propio

```
Avatar (editable) | Nombre | Bio (editable)
[Teléfono] + [Toggle de visibilidad]
─────────────────────
Mis estadísticas globales (todos mis hogares)
Estadísticas por hogar (acordeón)
─────────────────────
Gestionar acceso:
• Proveedores vinculados
• Cambiar contraseña (si email/password)
• Cerrar sesión
─────────────────────
[Historial como pagador — si aplica]
```

### Invite flow

1. Admin/Owner toca "Invitar".
2. Sheet: opción "Compartir código" o "Invitar por email".
3. Código: genera 6 chars alfanumérico único, guardado en `invitations/{inviteId}` con TTL de 48h.
4. Email: guarda la invitación con `targetEmail`.
5. Al unirse, se valida el código y se crea la membresía.

---

## Tests requeridos

### Unitarios

- `Member.fromFirestore` mapea roles y estados correctamente.
- `membersRepository.inviteMember` lanza error si el hogar ya tiene máximo de miembros.
- `membersRepository.promoteToAdmin` lanza error en Free (solo 1 admin permitido).
- `membersRepository.removeMember` lanza error si intenta quitar al owner.
- Privacidad de teléfono: `phoneVisibility = 'hidden'` → el campo se omite en perfil ajeno.

### De integración

- Invitar miembro con código → membresía creada correctamente.
- Código expirado → error `ExpiredInviteCodeException`.
- Free con 3 miembros activos → invitar 4º → error de límite.
- Transferir propiedad → owner anterior pasa a `admin`, nuevo uid es `owner`.

### UI

- Pantalla Miembros: lista con roles y badges correctos.
- Admin no ve botón "Cerrar hogar" (solo owner lo ve).
- Perfil ajeno: NO muestra las notas textuales.
- Perfil ajeno: muestra teléfono solo si `phoneVisibility = 'sameHomeMembers'`.
- Golden tests de pantallas de miembros y perfil.

---

## Pruebas manuales requeridas al terminar esta spec

1. **Invitar miembro:** Generar código desde admin → usar código en otra cuenta → aparece como miembro.
2. **Perfil ajeno restringido:** Ver perfil de otro miembro → no deben aparecer sus notas privadas ni stats de otros hogares.
3. **Teléfono oculto:** Usuario A pone teléfono como "oculto" → usuario B (mismo hogar) no ve el teléfono.
4. **Teléfono visible:** Usuario A pone teléfono como "visible" → usuario B (mismo hogar) lo ve.
5. **Promover a admin:** Owner promueve a un miembro → el miembro pasa a ver opciones de admin.
6. **Quitar miembro:** Admin quita a un miembro → el miembro ya no aparece en la lista.
7. **Límite de admins (Free):** Intentar promover un segundo admin en plan Free → error.
8. **Editar perfil:** Cambiar foto, apodo y bio → cambios reflejados inmediatamente.
