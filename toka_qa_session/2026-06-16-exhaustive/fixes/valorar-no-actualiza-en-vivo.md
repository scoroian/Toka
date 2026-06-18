# §11 — 🟡 Botón "Valorar" no se actualiza en vivo tras valorar

Estado: **RESUELTO** (causa raíz: latencia del listener de Firestore; fix: marca optimista) · Cliente only (sin backend/reglas/ARB) · Verificado end-to-end en 2 dispositivos contra prod (`toka-dd241`) · Fecha: 2026-06-18

## Bug reportado

En Historial, tras enviar una valoración de un evento completado, el botón/estrella
"Valorar" del evento NO cambia a estado "valorado" en vivo (sigue mostrando el icono
de "Valorar" `star_border`); solo se actualiza al salir y reentrar (al reentrar el
tile muestra la estrella ámbar y, al tocarlo, el detalle ya trae la valoración
existente — eso sí era correcto).

REPRO: premium; Historial; valorar un evento "completado" de otro miembro; observar
que el botón no cambia hasta reentrar.

## Diagnóstico (bug real, no falso positivo)

El estado "valorado" del tile se calcula en `historyViewModel` a partir de
`item.isRated`, que sale de fusionar el `TaskEvent` con el conjunto `ratedIds`.
Ese conjunto se leía **solo** de `ratedEventIdsProvider`, un `StreamProvider` que
escucha en vivo `homes/{homeId}/memberReviews/{currentUid}.ratedEventIds`
(`lib/features/history/application/rated_events_provider.dart`).

Flujo de valoración (única vía activa, skin v2):
`HistoryScreenV2._buildTile` → `showRateSheet` → `RateEventSheet` →
`vm.rateEvent(eventId, score, note)` → `membersRepository.submitReview(...)` →
CF `submitReview` (`functions/src/tasks/submit_review.ts`), que dentro de una
transacción hace `tx.set(memberReviews/{reviewerUid}, {ratedEventIds: arrayUnion(eventId)}, {merge:true})`.

La cadena de providers es correcta en sí: cuando el `snapshots()` de
`memberReviews/{uid}` emite el nuevo set, `historyViewModel` se reconstruye e
`item.isRated` pasa a `true`. **Por eso al reentrar (suscripción fresca) el botón ya
aparece valorado.** El problema es el **desfase temporal**: entre que la callable
`submitReview` retorna y que el listener del cliente recibe el documento actualizado
(round-trip callable → commit de la transacción → propagación del snapshot) pasan
desde ~1 s hasta varios segundos. Durante esa ventana el botón sigue mostrando
"Valorar". Como `RateEventSheet` hace `Navigator.pop()` inmediatamente (la llamada a
`onSubmit` es fire-and-forget), el usuario vuelve al listado y ve el botón sin
cambiar — percibido como "no se actualiza en vivo". (Además, en ese hueco un segundo
toque dispararía la CF de nuevo y devolvería `already-exists`.)

Regla de negocio: la valoración debe reflejarse de inmediato; no tiene sentido
depender del latido del listener para el feedback de UI del propio autor.

Casos relacionados revisados:
- El `ReviewDialog` de `history_event_tile.dart` (rama `_canReview`, `onSubmitted: () {}`)
  es **código muerto** en Historial: `HistoryScreenV2` siempre pasa `trailing`, por lo
  que `_CompletedTile.effectiveTrailing` nunca cae en esa rama (además `homeId`/`currentUid`
  no se pasan al tile desde la pantalla, así que `_canReview` sería false igualmente).
  La única vía real es `vm.rateEvent`.
- El detalle del evento (`historyEventDetailProvider`) lee sus reviews con `.get()`
  cada vez que se abre, así que ahí no había desfase (de ahí que "reentrar al detalle"
  mostrara siempre la valoración).

## Causa raíz

Feedback de UI acoplado exclusivamente a la propagación asíncrona del `snapshots()`
de Firestore, que tiene latencia tras la escritura server-side de la CF.

## Fix (cliente)

Actualización **optimista**: tras un `submitReview` exitoso se marca el evento como
valorado en un conjunto local que se fusiona con el del stream, de modo que el botón
cambia al instante sin esperar al round-trip. El set optimista es siempre un
subconjunto de lo que acabará confirmando Firestore, así que no introduce
incoherencias (ni entre dispositivos).

1. **`lib/features/history/application/rated_events_provider.dart`** — nuevo notifier
   `OptimisticRatedEventIds` (familia por `homeId`, `Set<String>`) con `markRated(eventId)`.
   Documentado el porqué (latencia del listener).
2. **`lib/features/history/application/history_view_model.dart`**:
   - En `historyViewModel`: se fusiona el set del stream (`ratedEventIdsProvider`) con
     `optimisticRatedEventIdsProvider(homeId)` para calcular `ratedIds` (y por tanto
     `isRated`/`canRate`).
   - En `rateEvent`: tras `await submitReview(...)` (solo si no lanzó) se llama a
     `optimisticRatedEventIdsProvider(homeId).notifier.markRated(eventId)`.
3. Regenerados los `.g.dart` con `dart run build_runner build` (filtrado a los dos
   ficheros para no ensuciar el resto del árbol).

`flutter analyze lib/features/history/` → **No issues found**.

## Tests

Nuevo: **`test/unit/features/history/rated_events_optimistic_test.dart`** — ejercita el
`historyViewModelProvider` real (con `OptimisticRatedEventIds` y la fusión reales);
overridea `auth/currentHome/dashboard(premium)/homeMembers/historyRepository/
membersRepository` y, **clave**, `ratedEventIdsProvider` con un `StreamController` que
**nunca llega a emitir** el id valorado (simula el retardo del listener de Firestore):

- `rateEvent marca isRated en vivo aunque el stream de Firestore no emita`: antes de
  valorar `isRated=false`/`canRate=true`; tras `await vm.rateEvent('evt1', 8.0)` —
  sin que el stream emita el id— `isRated=true`/`canRate=false`. Se comprueba además
  que el `ratedEventIdsProvider` sigue **sin** el id (prueba que el cambio vino de la
  marca optimista).
- `la marca optimista se fusiona con los ids confirmados por Firestore`: con el stream
  confirmando `{'evt_previo'}` y `markRated('evt1')`, el item de `evt1` queda valorado
  (fusión correcta, no se pisa lo confirmado).

Prueba de que el test captura la regresión: deshabilitando temporalmente la línea
`markRated` en `rateEvent`, el primer test **falla** (`isRated` se queda en `false`);
con el fix **pasa**. Restaurado el fix.

Resultados:
- `flutter test test/unit/features/history/rated_events_optimistic_test.dart` → **2/2**.
- `flutter test test/unit/features/history/history_view_model_test.dart` → **15/15**
  (sin regresión en la cobertura existente de `TaskEventItem.canRate`/`HistoryNotifier`).
- `flutter test test/integration/features/history/` → en verde.
- `flutter test test/ui/features/history/` → único fallo
  `history_screen_v2_test.dart::muestra lista de eventos`, que es **pre-existente**
  (el mock `_MockHistoryViewModel` no stubea `vm.hasHome`, leído en
  `history_screen_v2.dart:55` → `Null is not a subtype of bool`); está listado en
  `PREEXISTING_TEST_FAILURES.md` (categoría layout/widget). No lo toca este fix.

## Verificación en 2 dispositivos (prod `toka-dd241`)

APK debug recompilado en Windows (`flutter build apk --debug`) e instalado en ambos
dispositivos. Hogar `SMQRtCjrA09gPIr1wazD` "Hogar QA Noche" en **premium active**
(confirmado por Admin SDK, solo lectura). Helper de lectura creado para la sesión:
`secrets/qa_inspect_reviews.js <homeId>` lista eventos `completed` + `ratedEventIds`
por miembro y calcula qué eventos puede valorar cada uno.

Estado del hogar [ADMIN SDK, lectura]: los 3 eventos `completed` los realizó **N2**
(`wwL0…`), así que **solo N3** (`aBne0…`, miembro) tenía eventos valorables (no se
valora el evento propio). Reviewer = **N3** en ambos dispositivos, valorando un evento
**distinto** en cada uno.

- **emulador `emulator-5554`** (N3, tema claro): Historial → "Sebas N2 completó · Tarea"
  con botón ☆ "Valorar" → sheet "Valorar tarea" (slider 5.0 + nota) → "Enviar
  valoración". Captura a **1 s** (sheet recién cerrado): el botón seguía ☆. Captura a
  **~4 s** (sin tocar nada, misma pantalla): el botón pasó a **★ ámbar (valorado)** —
  el flip en vivo que faltaba. `ui.sh` confirmó que ese tile dejó de exponer el
  content-desc "Valorar". Admin SDK: `memberReviews/N3.ratedEventIds=[dmQDOdM4…]`. ✔
- **MI_9 `43340fd2`** (re-logueado como N3, MIUI, tema oscuro): el otro evento de N2
  (`hPCYXNZF…`) con ☆ → sheet → "Enviar valoración" → el botón pasó a **★ ámbar en
  vivo** sin salir de Historial (`ui.sh`: el tile dejó de tener "Valorar"; quedaron 2
  estrellas llenas y los demás eventos con ☆). Admin SDK:
  `ratedEventIds=[dmQDOdM4…, hPCYXNZF…]`. ✔
- **Cross-device de paso**: el evento valorado en el emulador apareció como **★** en la
  vista recién abierta de Historial de MI_9 (la fuente de verdad de Firestore es
  coherente entre dispositivos; el set optimista es solo un atajo local de feedback).

La progresión 1 s (☆) → 4 s (★) sin reentrar reproduce el bug original (antes se
quedaba en ☆ hasta salir/reentrar) y demuestra el arreglo: el flip ocurre al volver
`submitReview`, vía la marca optimista, sin esperar al `snapshots()`.

Cuentas tras la verificación: **MI_9 = N2 (owner)**, **emulador = N3 (member)** —
config documentada de sesiones previas (re-logueé MI_9 a N2 al terminar). No se
modificó ningún dato del hogar salvo las 2 valoraciones reales creadas por N3 (que es
justo lo que prueba el fix). Capturas analizadas y **borradas** al terminar.

## Notas / hallazgos

- No se tocó backend ni reglas: la CF `submitReview` ya escribía `ratedEventIds`
  correctamente; el bug era de feedback de UI por latencia, no de datos.
- Mejora de robustez colateral: el set optimista también cubre el caso (improbable)
  de que el listener tarde mucho o se reabra; el botón nunca se queda "atascado" en
  "Valorar" tras un envío exitoso mientras la pantalla siga viva.
