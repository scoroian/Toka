# §4 — 🔴 Teléfono y visibilidad no se propagan al doc de miembro

Estado: **RESUELTO** · Desplegado en prod (`toka-dd241`) y verificado end-to-end en 2 dispositivos · Fecha: 2026-06-17

## Bug

Un usuario que en onboarding/perfil pone teléfono y activa "Mostrar mi teléfono a
miembros del hogar" (queda en `users/{uid}.phone` y
`users/{uid}.phoneVisibility="sameHomeMembers"`), al **unirse** a un hogar
generaba un doc de miembro `homes/{homeId}/members/{uid}` con `phone:null` y
`phoneVisibility:"hidden"`. El nickname y la foto SÍ se propagaban; el teléfono y
su visibilidad NO → otros miembros nunca veían el teléfono aunque el usuario
hubiera optado por compartirlo.

## Causa raíz (bug real, confirmado en producción)

El síntoma "otros miembros no ven el teléfono" tenía **dos causas independientes**,
ambas reales. La sesión QA solo detectó la primera; la segunda apareció al
verificar el fix en dispositivo.

### Causa 1 — Backend: el teléfono no se denormalizaba en el doc de miembro

`users/{uid}` es **privado** (las reglas solo permiten leerlo al propio usuario);
los demás miembros leen el perfil desde `homes/{homeId}/members/{uid}`. Por tanto
el teléfono y su visibilidad deben **denormalizarse** (snapshot) en el doc de
miembro. Pero todos los puntos de creación del doc lo hardcodeaban:

- `functions/src/homes/member_factory.ts` → `buildNewMemberDoc` ponía
  `phoneVisibility: "hidden"` fijo (ignorando el parámetro) y solo recibía `phone`.
- `joinHome`, `joinHomeByCode`, `createHome` (owner) y `repairMemberDocument` en
  `functions/src/homes/index.ts` leían solo `nickname` y `photoUrl` de
  `users/{uid}`, nunca `phone`/`phoneVisibility`.
- El trigger `syncMemberProfile` (al editar el perfil) solo re-sincronizaba
  `nickname` y `photoUrl`, así que cambiar la visibilidad después **tampoco**
  llegaba al doc de miembro.

**Semántica decidida:** `phoneVisibility` es una preferencia **global del usuario**
(hay un único toggle en onboarding/perfil). Se snapshotea por hogar en cada doc de
miembro. El cliente lee `member.phoneVisibility` y `Member.phoneForViewer` decide:
`isSelf` o `phoneVisibility=="sameHomeMembers"` ⇒ devuelve el número; en otro caso
`null`. Coherente con cómo `MemberProfileViewData.visiblePhone` ya resolvía el permiso.

### Causa 2 — Cliente: la pantalla de perfil NUNCA pintaba el teléfono

`MemberProfileViewData.visiblePhone` se calculaba en el view model pero **no se
usaba en ninguna pantalla**: no había ningún widget de teléfono en
`lib/features/members/presentation/`. Así que aunque el dato llegara al doc de
miembro (causa 1 arreglada), la UI seguía sin mostrarlo. Comprobado:
`grep -rn "visiblePhone\|phone\|tel:" lib/features/members/presentation/` → 0 resultados.

## Fix

### Backend (`functions/src/homes/`)
- `member_factory.ts`:
  - `buildNewMemberDoc` ahora acepta `phoneVisibility` y usa `p.phoneVisibility ?? "hidden"`.
  - Nuevo helper `readMemberProfileFields(userData)` que centraliza la lectura de
    `nickname`/`photoUrl`/`phone`/`phoneVisibility` de `users/{uid}` con defaults
    coherentes (usado por los 4 puntos de creación + el trigger).
- `index.ts`:
  - `createHome`, `joinHome`, `joinHomeByCode`, `repairMemberDocument` propagan
    `phone` y `phoneVisibility` al crear el doc (y al re-unirse, en la rama
    `existingMember.update`).
  - `syncMemberProfile` detecta cambios en `phone`/`phoneVisibility` (además de
    nickname/photo) y los re-sincroniza a todos los docs de miembro → editar el
    perfil después actualiza la visibilidad en todos los hogares en vivo.

### Cliente (`lib/features/members/presentation/skins/member_profile_screen_v2.dart`)
- Nuevo `_PhoneChip`: muestra `data.visiblePhone` bajo el badge de rol (icono +
  número, pulsable → `launchUrl(Uri(scheme:'tel'...))` para marcar). Solo se pinta
  si `visiblePhone != null`. Sin texto UI hardcodeado (el número es dato).
  `MemberProfileScreen` es wrapper de skin única → solo aplica a v2.

## Tests

- `functions/src/homes/member_factory.test.ts` (unit): `buildNewMemberDoc` respeta
  `phoneVisibility="sameHomeMembers"` y default `hidden`; `readMemberProfileFields`
  (usuario completo, defaults, `undefined`, opt-out con número+hidden). **10/10 ✓**
- `functions/test/integration/join_home_profile.test.ts` (nuevo, contra emulador,
  invoca los handlers reales): `joinHome` y `joinHomeByCode` heredan
  phone+visibility; usuario sin teléfono → defaults; `syncMemberProfile` re-sincroniza
  al activar **y** al ocultar. **5/5 ✓**
- `test/ui/features/members/member_profile_screen_v2_test.dart` (widget): el chip
  (`Key('member_phone_chip')`) se muestra con `visiblePhone` y el número aparece;
  no se muestra con `visiblePhone=null`. Helper `_data` ya usa `isSelf:false` →
  cubre la vista **cross-member**. **8/8 ✓**
- `flutter analyze` del archivo cambiado: sin errores. `tsc` estricto: OK (corrió en
  el predeploy).

## Verificación en 2 dispositivos (contra prod `toka-dd241`)

Deploy **dirigido** de las 5 functions tocadas (`joinHome`, `joinHomeByCode`,
`syncMemberProfile`, `createHome`, `repairMemberDocument`) — backward-compatible y
aditivo. APK debug con el cambio de cliente instalado en ambos dispositivos.

Preparación `[ADMIN SDK]`: `toka.qa.n3@tokatest.dev` (uid `aBne0aSLzbNaM7ZyACmibbVkPN62`)
onboardeado con `phone:+34655443322`, `phoneVisibility:sameHomeMembers`; código de
invitación `QAPH01` en el hogar `SMQRtCjrA09gPIr1wazD` ("Hogar QA Noche").

1. **Emulador (`emulator-5554`)** — n3 hace login y se une por código `QAPH01`
   (ejecuta el `joinHomeByCode` desplegado). `[ADMIN SDK]` confirma
   `members/n3.phone=+34655443322` y `phoneVisibility=sameHomeMembers` (antes:
   `null`/`hidden`). El perfil de n3 muestra el chip "📞 +34655443322".
2. **MI_9 físico (`43340fd2`)** — login como `toka.qa.n2` (owner, **otro** miembro)
   → Miembros → QA Tel N3: el perfil muestra "📞 +34655443322". **Prueba
   cross-member definitiva.**
3. **Caso negativo (MI_9)** — `[ADMIN SDK]` pone `users/n3.phoneVisibility=hidden`;
   el trigger desplegado `syncMemberProfile` actualiza `members/n3` a `hidden` en
   ~1.5s; al reabrir el perfil como n2, el teléfono **desaparece** → la privacidad
   se respeta.
4. **Trigger ambos sentidos (`[ADMIN SDK]`)** — hidden→members hidden (~4.5s),
   sameHomeMembers→members sameHomeMembers (~3s).

Capturas analizadas y **borradas** al terminar. Estado restaurado: n3
`phoneVisibility=sameHomeMembers`, invitación `qa-phone-inv` borrada. n3 queda como
miembro de prueba legítimo del hogar QA (join limpio vía función desplegada; el
dashboard se actualizó correctamente, no es un fantasma).

## Mejoras / hallazgos colaterales

- **Causa 2 (UI sin pintar el teléfono)** no estaba en el prompt: el hint asumía
  que la pantalla ya leía `visiblePhone`. No era así. Sin este añadido, el fix de
  backend no habría sido visible para el usuario.
- `readMemberProfileFields` elimina la duplicación de los reads inline de
  `users/{uid}` en 4 sitios + el trigger; futuros campos de perfil a denormalizar
  se añaden en un solo lugar.
- Observado de paso (no tocado, ver §6): los errores de validación del login no se
  limpian al corregir el campo (artefacto visible durante el login QA).
