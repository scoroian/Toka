# §14 — 💄 Limpieza visual/UX menor (agrupado)

Estado: **RESUELTO** · 4 ítems en un solo PR · Cliente + reglas Firestore + Cloud Functions · Reglas y functions **desplegadas a producción (toka-dd241)** con autorización explícita del usuario · Verificado end-to-end en los **2 dispositivos** (MI_9 físico `43340fd2` + emulador `emulator-5554`) + cobertura de tests · Fecha: 2026-06-18

Los 4 ítems eran retoques menores. Resumen rápido:

| # | Ítem | Resultado |
|---|------|-----------|
| 1 | Subform "Crear hogar" conserva título "¿Qué quieres hacer?" + espacio vacío arriba | Título dinámico por sub-paso + contenido alineado arriba |
| 2 | No se puede eliminar tarea desde el detalle | **Ya estaba implementado** (hallazgo QA obsoleto); solo faltaba `tooltip` |
| 3 | Borrado lógico no guarda `deletedAt` | `deletedAt: serverTimestamp()` + whitelist de reglas |
| 4 | Desfase ~10s del rebuild del dashboard tras completar/pasar | `await` del rebuild (fire-and-forget en gen2 quedaba estrangulado) |

---

## Ítem 1 — Título del subformulario "Crear hogar" + distribución vertical

### Bug
En el onboarding, el paso de elección mostraba **siempre** el título
`onboarding_home_choice_title` ("¿Qué quieres hacer?") aunque ya estuvieras
dentro del subformulario de crear o de unirte. Además, el contenido quedaba
**centrado verticalmente** dejando mucho espacio vacío arriba.

### Causa raíz
- **Título:** `home_choice_step_v2.dart` renderizaba un único `Text` con la clave
  fija por encima del `if/else` de `_choice`, sin variar con el sub-paso.
- **Espacio vertical:** la skin envuelve cada paso en un `AnimatedSwitcher`
  (`lib/core/theme/skin_switcher.dart` → `SkinSwitch`), cuyo `alignment` por
  defecto es `center`. El `SingleChildScrollView` del paso encoge a su contenido
  y el `AnimatedSwitcher` lo centra verticalmente → hueco arriba. Comportamiento
  **pre-existente** (no introducido por este cambio), reproducible en cualquier
  paso que use ese patrón.

### Fix (`lib/features/onboarding/presentation/steps/skins/home_choice_step_v2.dart`)
- Título dinámico:
  ```dart
  final title = switch (_choice) {
    _HomeChoice.none => l10n.onboarding_home_choice_title,
    _HomeChoice.create => l10n.onboarding_create_home_title,   // "Crea tu hogar"
    _HomeChoice.join => l10n.onboarding_join_home_title,       // "Únete a un hogar"
  };
  ```
- Contenido alineado arriba: `LayoutBuilder` + `ConstrainedBox(minHeight: constraints.maxHeight)`
  para rellenar el alto disponible, neutralizando el centrado del `AnimatedSwitcher`.
- Nuevas claves ARB en es/en/ro: `onboarding_create_home_title`, `onboarding_join_home_title`.

### Sheet "Añadir hogar" (desde el selector de hogares)
Revisado: `lib/features/homes/presentation/home_selector_widget.dart` → `_buildCreate`
**ya tenía título propio** ("Crear un hogar" en un `Row` con botón atrás). El bug del
título heredado era exclusivo del onboarding. No requería cambios.

---

## Ítem 2 — Eliminar tarea desde el detalle

### Diagnóstico: hallazgo QA OBSOLETO (ya implementado)
`lib/features/tasks/presentation/skins/task_detail_screen_v2.dart` **ya tenía** la
acción de borrar: `IconButton(Icons.delete_outline)` en el `AppBar` (gated por
`data.canManage`) con diálogo de confirmación `_confirmDelete` (`tasks_delete_confirm_title`
/ `tasks_delete_confirm_body` / `cancel` / `delete`) y navegación segura previa al
`await` (comentario BUG-08). Se añadió en el commit de hardening posterior a la
sesión QA del 2026-06-16, por eso el hallazgo quedó obsoleto.

### Único cambio
Faltaba el `tooltip` (los botones Editar y Congelar sí lo tenían). Añadido
`tooltip: l10n.tasks_action_delete`.

---

## Ítem 3 — `deletedAt` en el borrado lógico

### Causa raíz
`lib/features/tasks/data/tasks_repository_impl.dart` → `deleteTask` escribía
`status: 'deleted'` + `updatedAt` pero **no** `deletedAt`. El borrado es directo
cliente→Firestore (no callable).

### Fix
- Cliente: añadido `'deletedAt': FieldValue.serverTimestamp()` al `update`.
- **Reglas (`firestore.rules`):** el whitelist `taskUpdateFieldsAllowed()` usa
  `hasOnly([...])`. Sin añadir `'deletedAt'`, el write se **rechazaría** y el
  borrado quedaría roto en producción. Añadido `'deletedAt'` al whitelist.
  → **Desplegado a prod** (`firebase deploy --only firestore:rules`).

> ⚠️ Orden de despliegue: las reglas deben ir **antes o junto** a la app. Si la
> app con `deletedAt` llega a prod sin las reglas desplegadas, el borrado se rompe.
> (En este trabajo las reglas ya se desplegaron a toka-dd241.)

---

## Ítem 4 — Desfase ~10s del rebuild del dashboard

### Causa raíz
`applyTaskCompletion` (`functions/src/tasks/apply_task_completion.ts:175`) y
`passTaskTurn` (`functions/src/tasks/pass_task_turn.ts:121`) llamaban a
`updateHomeDashboard(homeId).catch(...)` **sin `await`** (fire-and-forget). En
**Cloud Functions gen2 (Cloud Run)** el CPU se estrangula en cuanto se envía la
respuesta, así que el rebuild en segundo plano quedaba sin CPU hasta la siguiente
petición → la pantalla Hoy tardaba ~10s en reflejar el cambio (el cliente escucha
`views/dashboard`).

### Fix
`await updateHomeDashboard(homeId)` envuelto en `try/catch` (un fallo del rebuild
**no** revierte la completación/pase ya confirmados en la transacción; el cron lo
reconstruirá). En `passTaskTurn` también se espera `sendPassNotification` (mismo
estrangulamiento afectaba al push). → **Desplegado a prod**
(`firebase deploy --only functions:applyTaskCompletion,functions:passTaskTurn`).

Nota: se valoró feedback optimista en el cliente; se descartó para este PR de
"retoques menores" por su complejidad (reconciliación/rollback). La aceleración
backend es el fix de menor riesgo. Queda como posible mejora futura.

---

## Tests añadidos / actualizados

- **Ítem 1** (`test/ui/features/onboarding/onboarding_flow_test.dart`): 2 tests de
  widget que verifican el título dinámico ("Crea tu hogar" al crear, "Únete a un
  hogar" al unirse) y que "¿Qué quieres hacer?" desaparece. Se testea
  `HomeChoiceStepV2` **aislado** (patrón ya usado para `ProfileStepV2`) para no
  depender del `PageView`/`GoRouter` del flow completo. ✅ pasan.
- **Ítem 3** integración (`test/integration/features/tasks/tasks_crud_test.dart`):
  el test de `deleteTask` ahora también verifica `deletedAt != null`. ✅ 8/8.
- **Ítem 3** reglas (`functions/test/rules/tasks.test.ts`): nuevo test "soft-delete
  incluyendo deletedAt". ✅ 43/43 (emulador Firestore).
- **Ítem 4** integración (`functions/test/integration/apply_task_completion.test.ts`):
  nuevo test "reconstruye el dashboard dentro de la llamada (no fire-and-forget)"
  que lee `views/dashboard.counters.tasksDoneToday >= 1` tras la llamada (antes
  era racy, ahora determinista). ✅ 9/9 (emuladores).
- `flutter analyze` sin errores; `tsc --noEmit` (functions) exit 0.

---

## Verificación en los 2 dispositivos (producción toka-dd241)

Hogar de pruebas `SMQRtCjrA09gPIr1wazD` "Hogar QA Noche".

- **Ítem 4** (MI_9, owner Sebas N2): completar "Reparar grifo URGENTE" (vencida) →
  el dashboard refleja el cambio en **~3-5s** (antes ~10s), la tarea pasa a
  "Hechas" y el contador "completadas hoy" sube 2→3→4. La 1ª llamada incluyó cold
  start del deploy reciente; la 2ª (warm) también ~3-5s (coste real del rebuild +
  round-trips). El emulador (miembro del mismo hogar) reflejó las 4 completaciones
  **sincronizadas en vivo** desde el MI_9.
- **Ítem 2** (MI_9, owner): detalle de "Compra semanal" muestra los 3 iconos del
  AppBar (editar/congelar/**eliminar** con tooltip "Eliminar"). En el **emulador**
  (miembro raso, `canManage=false`) el detalle muestra solo el botón atrás → gating
  correcto.
- **Ítem 3** (MI_9, owner): borrado de "Compra semanal" desde el detalle →
  confirmación "¿Eliminar tarea?" → tras confirmar, Admin SDK muestra el doc
  `id b0b8d746-… status: deleted, deletedAt: 2026-06-18T14:13:57Z` (antes
  `active, deletedAt: null`). Confirma a la vez que el deploy de reglas funciona
  (el write con `deletedAt` no fue rechazado) y que `deletedAt` se persiste. La
  tarea desapareció de la lista.
- **Ítem 1** (emulador, cuenta nueva `toka.qa.onb@tokatest.dev` en onboarding):
  paso de elección muestra "¿Qué quieres hacer?"; al tocar "Crear un hogar" el
  título pasa a **"Crea tu hogar"** y el contenido se alinea arriba (sin el hueco
  vacío previo).

Capturas tomadas durante la verificación y **borradas al terminar** (protocolo).

---

## Otros hallazgos / mejoras durante el trabajo

1. **Test de integración roto (corregido):** `apply_task_completion.test.ts` →
   "completar tarea actualiza stats del member" verificaba `data['completedCount']`,
   pero la función (desde el hardening) escribe `tasksCompleted` y **borra**
   `completedCount` con `FieldValue.delete()`. El test fallaba siempre con emuladores.
   Corregida la aserción a `tasksCompleted`.
2. **Tests UI del flow de onboarding fallan en WSL (pre-existente):** los tests que
   renderizan `OnboardingFlowScreen` completo (`step 3 shows create and join
   options`, goldens, `progress bar…`) fallan con `pumpAndSettle timed out` por el
   `GoRouter`/`PageView` en este entorno (coincide con los fallos pre-existentes de
   `PREEXISTING_TEST_FAILURES.md`). Por eso los tests nuevos se hicieron sobre el
   widget aislado.
3. **Golden `onboarding_step3_home_choice.png`:** el cambio de espaciado +
   alineación lo modifica. Ya estaba entre los 45 golden mismatch pre-existentes
   (imágenes de otra máquina). Debe **regenerarse en la máquina golden canónica**.
4. **Trampa de entorno WSL/Windows:** `flutter build apk` (Windows) reescribe
   `.dart_tool/package_config.json` con rutas Windows → el `flutter analyze`/`test`
   de WSL deja de resolver `package:flutter`. Hay que correr `flutter pub get` en
   WSL para restaurar (ya documentado en memoria).
