Eres Claude Code trabajando en la app Flutter "Toka" (proyecto Firebase: toka-dd241, rama: main).

Tu tarea es implementar y verificar la spec:
  docs/superpowers/specs/2026-04-17-member-remove-and-filter-design.md

**Bug #40:** El owner no puede expulsar miembros. No existe botón de expulsión en el perfil de miembro ni método `removeMember()` en el view model, aunque la Cloud Function `removeMember` y el repositorio ya están implementados.

**Bug #41:** La lista de miembros muestra a personas que ya abandonaron el hogar (`status: 'left'`). El stream `watchHomeMembers` no filtra por status.

---

## Flujo de trabajo obligatorio (repite hasta que la spec esté resuelta)

### Fase 1 — Bug #41: Filtrar miembros "left"

1. Leer `lib/features/members/data/members_repository_impl.dart`.
2. En `watchHomeMembers()`, añadir `.where('status', isNotEqualTo: 'left')` antes de `.snapshots()`.
3. Verificar `firestore.indexes.json` — el filtro `isNotEqualTo` sobre un único campo no requiere índice compuesto en Firestore, pero confirmar que no hay conflicto.

### Fase 2 — Bug #40: Botón de expulsión

4. Leer `lib/features/members/application/member_profile_view_model.dart` completo.
5. Añadir `canRemoveMember` a `MemberProfileViewData`:
   - Regla: `isOwner && !isSelf && member.role != MemberRole.owner`
6. Añadir `Future<void> removeMember(String homeId, String uid)` a la interfaz `MemberProfileViewModel` y al impl:
   ```dart
   Future<void> removeMember(String homeId, String uid) =>
       ref.read(membersRepositoryProvider).removeMember(homeId, uid);
   ```
7. Calcular `canRemoveMember` en la función factory del provider y pasarlo al constructor de `MemberProfileViewData`.
8. Leer `lib/features/members/presentation/skins/member_profile_screen_v2.dart` completo.
9. Añadir después del botón de gestión de roles (`toggle_admin_button`):
   - `OutlinedButton` con `key: const Key('remove_member_button')`, estilo rojo, visible solo si `data.canRemoveMember`.
   - Método `_confirmRemoveMember(...)` que muestra `AlertDialog` de confirmación, llama `vm.removeMember`, navega atrás con `Navigator.of(context).pop()` en éxito, maneja `CannotRemoveOwnerException`.
10. Añadir claves i18n en `lib/l10n/app_es.arb`, `app_en.arb`, `app_ro.arb`:
    ```json
    "member_profile_remove_member": "Expulsar del hogar",
    "member_profile_remove_member_confirm": "¿Expulsar a {name} del hogar? Esta acción no se puede deshacer.",
    "@member_profile_remove_member_confirm": {
      "placeholders": { "name": { "type": "String" } }
    },
    "error_cannot_remove_owner": "No se puede expulsar al propietario del hogar."
    ```
11. Ejecutar `dart run build_runner build --delete-conflicting-outputs`.
12. Ejecutar `flutter analyze` — debe pasar sin errores.
13. Ejecutar `flutter run -d emulator-5554`.

### Fase 3 — Verificación

14. Login como owner → tab Miembros → verificar que no aparecen miembros con status "left".
15. Capturar la lista de miembros:
    ```bash
    adb exec-out screencap -p > /tmp/screen_raw.png
    python3 -c "
    from PIL import Image
    img = Image.open('/tmp/screen_raw.png')
    if max(img.size) > 1900:
        img.thumbnail((1500, 1500), Image.LANCZOS)
    img.save('/tmp/screen.png')
    " 2>/dev/null || cp /tmp/screen_raw.png /tmp/screen.png
    ```
16. Leer `/tmp/screen.png` y confirmar la lista.
17. Tap sobre un miembro que no sea el owner (ej. el member QA) → verificar que aparece el botón **"Expulsar del hogar"** en rojo.
18. Capturar el perfil con el botón visible.
19. Tap sobre el botón → verificar que aparece el diálogo de confirmación.
20. Capturar el diálogo.
21. Confirmar la expulsión → verificar que vuelve a la lista y el miembro desaparece.
22. Cuando esté resuelto, marcar **Bug #40** y **Bug #41** como CORREGIDOS en `toka_qa_session/QA_SESSION.md`.

---

## Cuentas de prueba

| Rol | Email | Contraseña |
|-----|-------|------------|
| Owner | toka.qa.owner@gmail.com | TokaQA2024! |
| Member | toka.qa.member@gmail.com | TokaQA2024! |

## Procedimiento de login como owner
```bash
adb shell input tap 540 1053
adb shell input text "toka.qa.owner@gmail.com"
adb shell input tap 540 1242
adb shell input text "TokaQA2024!"
adb shell input tap 540 1441
```

Responde siempre en español.
