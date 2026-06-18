# §12 — 🟡 Payer-lock bloquea pero sin mensaje claro

Estado: **RESUELTO** · Cliente only (backend ya rechazaba correctamente) · Verificado end-to-end en 2 dispositivos contra prod (`toka-dd241`) · Fecha: 2026-06-18

## Bug reportado

El "payer-lock" funciona (el pagador no puede transferir propiedad / abandonar / ser
expulsado mientras hay Premium activo: el backend rechaza con `failed-precondition`),
pero el usuario **no recibía un mensaje claro** de por qué la acción no surtía efecto.
En el camino de transferir desde "Abandonar hogar" no se veía nada útil (o un error
genérico), y desde el tile "Transferir propiedad" se mostraba incluso un **falso
"éxito"**.

REPRO: N2 es owner+pagador de `SMQRtCjrA09gPIr1wazD` en premium `active`; Ajustes →
Abandonar hogar → seleccionar a otro miembro → Transferir → no pasa nada claro (el
owner sigue siendo N2).

## Diagnóstico — causa raíz (eran 2 bugs cliente, no 1)

El backend (`functions/src/homes/index.ts`) es **correcto**: lanza `failed-precondition`
con `payer-cannot-transfer-ownership-while-premium-active` (en `transferOwnership`,
~L1114) y `payer-cannot-leave-or-be-removed-while-premium-active` (en `leaveHome` ~L488
y `removeMember` ~L585). El problema estaba 100% en el cliente, y había **dos** fallos
distintos en los caminos de transferencia:

1. **`MemberActions.transferOwnership` se tragaba la excepción.** Usaba
   `AsyncValue.guard`, que captura el error y lo guarda en `state` **sin relanzarlo**.
   El `try/catch` de `transfer_ownership_sheet.dart` (tile "Transferir propiedad" en
   *Ajustes del hogar*) nunca veía la excepción → seguía por el camino de éxito,
   mostrando un **SnackBar de "propiedad transferida"** falso y cerrando el sheet.
   (Contraste: `generateInviteCode` en el mismo provider ya hacía `try/catch + rethrow`
   correctamente; el resto de acciones quedaron con `guard` por copy-paste.)

2. **`MembersRepositoryImpl.transferOwnership` no mapeaba el error.** A diferencia de
   `removeMember`/`leaveHome` (que mapean a `PayerLockedException`), la transferencia
   dejaba subir la `FirebaseFunctionsException` cruda. En el camino de *Ajustes* (pestaña)
   → "Abandonar hogar" → `_transferAndLeave` (settings_screen.dart), que llama al **repo
   directo**, el error caía en un `catch (_)` genérico y mostraba `error_generic` (no el
   mensaje específico de payer-lock).

Caminos que **ya funcionaban** y se confirmaron:
- **Expulsar** al pagador (`member_profile_screen_v2._confirmRemoveMember`): el repo
  `removeMember` ya lanza `PayerLockedException` y la pantalla ya mostraba
  `members_error_payer_locked`. ✔ (se le añadió test de regresión).
- **Abandonar** desde *Ajustes del hogar* (`home_settings_screen_v2._confirmLeave`): ya
  captura `PayerLockedException`. ✔

## Cambios (cliente; sin tocar backend / reglas / ARB)

Las claves i18n **ya existían** en `app_es/en/ro.arb` — no hizo falta crear ninguna:
- `members_error_payer_locked` — "No puedes expulsar ni salir del hogar mientras seas
  el pagador de la suscripción Premium activa. Cancela la suscripción primero o espera
  a que expire."
- `homes_transfer_error_payer_locked` — "No puedes transferir la propiedad mientras
  pagues el Premium del hogar. Cancela la renovación o transfiere al final del periodo."

1. **`lib/features/members/data/members_repository_impl.dart`** — `transferOwnership`
   ahora envuelve la llamada en `try/catch` y mapea `failed-precondition` +
   `payer-cannot-transfer-ownership-while-premium-active` → `PayerLockedException`
   (coherente con `removeMember`/`leaveHome`); cualquier otro error se relanza.

2. **`lib/features/members/application/member_actions_provider.dart`** —
   `transferOwnership` deja de usar `AsyncValue.guard`: guarda el error en `state` y lo
   **relanza** (patrón idéntico a `generateInviteCode`), para que la UI pueda reaccionar.

3. **`lib/features/homes/presentation/widgets/transfer_ownership_sheet.dart`** — el
   `catch` pasa a `on PayerLockedException` → `homes_transfer_error_payer_locked`; resto
   → `error_generic`. Se eliminó el frágil `errMsg.contains('payer-cannot-transfer-...')`
   (ya no llega el string crudo porque el repo lo mapea). Además se cierra el sheet
   (`navigator.maybePop()`) **antes** de mostrar el SnackBar en todos los caminos: si no,
   el aviso queda tapado por el propio bottom sheet y es invisible (ver "Fallo secundario"
   en la verificación). Este punto se descubrió probando en dispositivo.

4. **`lib/features/settings/presentation/settings_screen.dart`** — `_transferAndLeave`
   (Casos B y D de "Abandonar hogar") añade `on PayerLockedException` →
   `members_error_payer_locked` antes del `catch (_)` genérico. Además, el **Caso A**
   (abandonar siendo no-owner) se envolvió en `try/catch` (antes no tenía manejo de
   error): cubre el edge case de un miembro no-owner que sigue siendo el pagador.

5. **`lib/features/members/domain/members_repository.dart`** — docstring de
   `transferOwnership` documenta que puede lanzar `PayerLockedException`.

`flutter analyze` de los 9 ficheros (fuente + tests): **No issues found**.

## Tests (fallan antes del fix, pasan después)

- **`test/integration/features/members/transfer_ownership_payer_lock_test.dart`** (nuevo)
  — `MembersRepositoryImpl` con `FirebaseFunctions` mockeado: (a) mapea
  `failed-precondition` payer → `PayerLockedException`; (b) relanza otras
  `FirebaseFunctionsException` sin mapear; (c) caso feliz completa y llama a la CF.
- **`test/unit/features/members/member_actions_provider_test.dart`** (nuevo) — prueba la
  causa raíz: `MemberActions.transferOwnership` **relanza** `PayerLockedException` y deja
  `state.hasError`; caso feliz deja `state.hasValue`. (Antes, con `guard`, no relanzaba.)
- **`test/ui/features/homes/transfer_ownership_sheet_test.dart`** (nuevo) — cableado
  completo UI→provider→SnackBar: con payer-lock muestra `homes_transfer_error_payer_locked`
  y **no** el falso éxito; caso feliz muestra `homes_transfer_success`.
- **`test/ui/features/members/member_profile_screen_v2_test.dart`** (ampliado) — nuevo
  test: expulsar al pagador muestra `members_error_payer_locked`.

Resultado: **16/16 en verde** en los 4 ficheros nuevos/ampliados (3+2+2+9), y
**21/21** incluyendo el `members_repository_test.dart` pre-existente (5). Sin regresiones:
`settings_screen_test.dart` da **`+5 -5` idéntico con y sin mi cambio** (`git stash` del
fuente) — los 5 fallos (4 casos "abandonar hogar" por tap fuera del viewport 800x600 +
1 golden de otra máquina) son pre-existentes de los 57 conocidos. `flutter analyze`
completo del proyecto: 0 errores, 40 issues pre-existentes (ninguno en ficheros tocados).

## Verificación en 2 dispositivos (prod `toka-dd241`)

[ADMIN SDK, solo lectura] Hogar `SMQRtCjrA09gPIr1wazD` "Hogar QA Noche" ya estaba en el
estado exacto del repro: `premiumStatus=active`, `endsAt=2026-07-17`,
`owner=currentPayerUid=wwL0OTdrNeMZs2wTt6QtRDT1nb53` (N2), con un miembro activo
`aBne0aSLzbNaM7ZyACmibbVkPN62` (N3) como candidato. No se forzó premium.

Cuentas durante la verificación: **MI_9 `43340fd2`** = N2 (owner+pagador, tema oscuro);
**emulador `5554`** = re-logueado como N2 (tema claro). Ambos en "Hogar QA Noche", sin
banner de ads (premium activo). Se capturó el SnackBar con ráfaga de `screencap`
(es transitorio ~4s; los `uiautomator dump` son demasiado lentos para atraparlo) y se
localizó el frame por diff de píxeles con ImageMagick.

**Resultados (los 2 caminos de transferencia, en los 2 dispositivos):**

| Camino | MI_9 (oscuro) | Emulador (claro) | Mensaje mostrado |
|---|---|---|---|
| Ajustes → "Abandonar hogar" → Caso B (transferir a N3) → Transferir | ✔ visible | ✔ visible | `members_error_payer_locked` ("No puedes expulsar ni salir del hogar mientras seas el pagador…") |
| Ajustes del hogar → tile "Transferir propiedad" → N3 → Transferir | ✔ visible (sheet cierra) | ✔ visible (sheet cierra) | `homes_transfer_error_payer_locked` ("No puedes transferir la propiedad mientras pagues el Premium…") |

En todos los casos `ownerUid` permaneció en N2 (`wwL0OTdrNeMZs2wTt6QtRDT1nb53`) — el backend
rechazó la transferencia y **nada cambió** en producción (verificado con
`node secrets/qa_inspect_home.js SMQRtCjrA09gPIr1wazD` tras cada intento). [ADMIN SDK, solo lectura]

**Fallo secundario descubierto y corregido durante la verificación en dispositivo:** en el
camino del **sheet** (tile "Transferir propiedad"), aun con el error ya mapeado, el
SnackBar **no era visible**: se pintaba al fondo de la pantalla por debajo del bottom
sheet, que seguía abierto y lo tapaba (confirmado: 0 cambio de píxeles en una ráfaga de
30 frames / ~6s, y el texto tampoco aparecía en 18 dumps). Se corrigió en
`transfer_ownership_sheet.dart` cerrando el sheet (`navigator.maybePop()`) **antes** de
mostrar el SnackBar en todos los caminos (éxito y error), de modo que el aviso se pinta
sobre la pantalla de Ajustes del hogar ya visible. Tras recompilar, el SnackBar de
`homes_transfer_error_payer_locked` aparece correctamente en ambos dispositivos (ver
tabla). Se añadió al widget test la aserción de que el sheet se cierra
(`transfer_candidate_u2` → `findsNothing`).

Capturas analizadas y **borradas** al terminar. APK debug recompilado dos veces (la
segunda con el fix del sheet) e instalado en ambos dispositivos con `-g`.

## Notas / hallazgos

- El mismo anti-patrón (`AsyncValue.guard` que traga el error) sigue presente en
  `MemberActions.removeMember/promoteToAdmin/demoteFromAdmin/inviteMember`, pero **ningún
  caller de UI depende de capturar su excepción** (el perfil de miembro usa
  `MemberProfileViewModel`, que llama al repo directo y sí relanza; las hojas de admins /
  invitación no muestran error específico). Se dejó como está para no ampliar el alcance,
  pero conviene migrarlos a `rethrow` si en el futuro alguna pantalla necesita distinguir
  errores de esas acciones.
