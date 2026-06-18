# §8 — 🟡 "Distribución inteligente" habilitada por flag pero sin UI

Estado: **RESUELTO** · Punto de entrada en UI añadido (cliente) + gate Premium server-side (reglas, defensa en profundidad) · Verificado end-to-end en los **2 dispositivos** (MI_9 físico `43340fd2` + emulador `emulator-5554`) contra producción (toka-dd241) + cobertura de tests (UI, reglas, helper) · Fecha: 2026-06-18

## Bug / gap

Con premium, `dashboard.premiumFlags.canUseSmartDistribution=true`, pero el
formulario de crear/editar tarea **no ofrecía ningún selector** de modo de
asignación. El campo `assignmentMode` (`basicRotation` | `smartDistribution`)
estaba **completamente cableado** de extremo a extremo —dominio (`Task`,
`TaskInput`), estado (`TaskFormState`), serialización (`TaskModel.toFirestore`/
`toUpdateMap`), backend (`applyTaskCompletion` lee `assignmentMode` y elige entre
`getNextAssigneeRoundRobin` y `getNextAssigneeSmart`)— **pero nadie llamaba a
`setAssignmentMode` desde la UI**, así que toda tarea quedaba siempre en
`basicRotation`. Feature implementada en backend, sin punto de entrada.

No es falso positivo: la feature existe y funciona en backend (con sus tests),
pero era **inalcanzable** para el usuario.

## Decisión: añadir el toggle (no retirar)

El backend de smart distribution funciona y tiene cobertura (`getNextAssigneeSmart`
+ `apply_task_completion.ts`). Retirarlo sería tirar una feature Premium operativa.
Se añade el **punto de entrada en UI** con **gate Premium** (candado/paywall si
Free), y un **gate server-side en reglas** para que el flag no sea puenteable solo
desde cliente.

## Fix

1. **Cliente — selector en el formulario**
   (`lib/features/tasks/presentation/skins/create_edit_task_screen_v2.dart`):
   nuevo widget privado `_AssignmentModeSelector` (mismo patrón que
   `_OnMissAssignSelector`), insertado tras "Miembros asignados". Comportamiento:
   - Oculto con 0 miembros asignados; visible con ≥1, **habilitado con ≥2** (el
     reparto solo importa con 2+ miembros; con 1 muestra el aviso reutilizado
     `tasks_rotation_requires_two_members`).
   - `SegmentedButton` con "Rotación básica" (icono `repeat`) y "Distribución
     inteligente". El icono de la opción smart es `auto_awesome` (✨) si Premium o
     **`lock_outline` (🔒) si Free**.
   - **Gate Premium**: `canUseSmart = dashboard.premiumFlags.canUseSmartDistribution`
     (pesimista —`?? false`— mientras el dashboard no ha llegado, para que un hogar
     Free nunca vea smart como disponible). Si Free y se pulsa smart → se abre el
     **paywall** (`AppRoutes.paywall`) y **no** se cambia el modo. Si Premium →
     `vm.setAssignmentMode('smartDistribution')`, que ya se persiste.
   - Hint bajo el selector: `tasks_assignment_smart_hint` (Premium, describe la
     feature) o `tasks_assignment_premium_locked` "Disponible con Premium" (Free).

2. **i18n** (`lib/l10n/app_{es,en,ro}.arb` + `flutter gen-l10n`): claves nuevas
   `tasks_assignment_smart_hint` y `tasks_assignment_premium_locked` en los 3
   idiomas. (Las etiquetas `tasks_field_assignment_mode`,
   `tasks_assignment_basic_rotation`, `tasks_assignment_smart` ya existían.)

3. **Reglas Firestore (defensa en profundidad)** (`firestore.rules`): las tareas
   se escriben **directo a Firestore** (no por callable), y las reglas **no**
   gateaban `smartDistribution`. Añadidos `taskCreateSmartAllowed(homeId)` y
   `taskUpdateSmartAllowed(homeId)`:
   - **CREATE** con `smartDistribution` solo si `isHomePremium(homeId)`.
   - **UPDATE**: cambiar **a** smart requiere Premium, pero **conservar** un smart
     ya existente (`resource.data.assignmentMode == 'smartDistribution'`) o pasar a
     básico **siempre** se permite → no rompe la edición de una tarea tras un
     downgrade del hogar.

   El backend de completado (`apply_task_completion.ts`) ya respeta
   `assignmentMode`; **no requiere cambios**.

## Tests (fallan antes / pasan después)

- **UI Dart** `test/ui/features/tasks/assignment_mode_selector_test.dart` (nuevo, 3 casos, harness con `GoRouter` para verificar navegación al paywall):
  - `<2` miembros asignados → selector deshabilitado con aviso "requiere 2 miembros"; pulsar smart no cambia modo ni navega.
  - **Premium + 2 miembros** → seleccionar smart persiste `assignmentMode=smartDistribution`, sin navegar.
  - **Free + 2 miembros** → aviso "Disponible con Premium"; pulsar smart **abre el paywall** y el modo **sigue** `basicRotation`.
- **Reglas** `functions/test/rules/tasks.test.ts` (+7 casos, suite **42/42**):
  - Free **NO** crea smart; Free **SÍ** crea básica; Premium **SÍ** crea smart.
  - Free **NO** cambia básica→smart; Free **SÍ** edita conservando smart (tras downgrade); Free **SÍ** pasa smart→básica; Premium **SÍ** cambia básica→smart.
- **Helper** `functions/src/tasks/task_assignment_helpers.test.ts` (+3 casos, suite **18/18**): smart favorece a quien lleva más días sin ejecutar (recencia), la dificultad acumulada pesa en el score, y usa carga 0 por defecto para miembros sin datos.
- `flutter analyze` limpio en los archivos tocados. `tsc --noEmit` (strict) sin errores.

## Evidencia de verificación (2 dispositivos, producción toka-dd241, hogar `SMQRtCjrA09gPIr1wazD`)

Helper de QA nuevo `secrets/qa_smart_verify.js` (`list|setmode|order|load|due`) para
preparar estado `[ADMIN SDK]`.

**Emulador — Premium (UI + persistencia):** Crear tarea → asignar 2 miembros →
aparece "Modo de asignación" con "Distribución inteligente" + icono ✨ y hint
"Asigna cada turno al miembro con menos carga reciente." → seleccionar smart →
Guardar. Admin SDK confirma la tarea creada con
`mode=smartDistribution`, `order=[N3,N2]`, `current=N3`. ✓

**Emulador — Premium (rotación smart real, ≥2 miembros, cargas distintas):**
tarea smart, `order=[N2,N3]`, `current=N2`:

| Escenario | Carga N2 (`completions60d`) | Carga N3 | Tras completar N2 → `currentAssigneeUid` | Round-robin habría dado |
|---|---|---|---|---|
| 1 | **0** (menos) | 10 | **N2** (se queda) | N3 |
| 2 | 10 | **0** (menos) | **N3** (se mueve) | N3 |

→ El escenario **1 es el discriminante**: smart **mantiene** al responsable porque
es el de menos carga, donde la rotación básica habría pasado el turno. El 2 muestra
que el turno **se mueve** al miembro menos cargado al invertir la carga. Smart
reparte por carga reciente. ✓

**Emulador — Free (gate):** hogar forzado a `free`, app reiniciada. Crear tarea →
asignar 2 miembros → "Distribución inteligente" con **candado 🔒** + hint
"Disponible con Premium" → pulsar smart **abre el paywall** ("Haz tu hogar
Premium"), el modo no cambia. ✓ Hogar restaurado a `active`.

**MI_9 físico — Premium:** mismo hogar (tema oscuro). Crear tarea → asignar 2
miembros → selector con "Distribución inteligente" + ✨ (sin candado) → seleccionar
smart funciona sin paywall. ✓

Capturas tomadas, analizadas y **borradas** al terminar. Tarea de prueba creada
durante la verificación marcada `status=deleted` `[ADMIN SDK]`. Hogar restaurado a
premium `active`.

## Otros hallazgos / notas durante el trabajo

- **Tie-break de `getNextAssigneeSmart`** (no es bug): con `scoreOf` empatado, el
  `reduce` devuelve el acumulador (primer elegible), así que un empate de carga
  **mantiene** al responsable actual; al siguiente completado su `completions60d`
  ya difiere y alterna. La `MemberLoadData.difficultyWeight` la pasa
  `apply_task_completion.ts` como `1.0` constante (la dificultad es **por tarea**,
  no acumulada por miembro); el reparto smart balancea por **`completions60d` +
  recencia**, que es el contrato documentado y testeado. Se dejó como está.
- **Preexistente, ajeno a §8 — `test/ui/features/tasks/create_task_screen_test.dart`
  falla por timezones:** su `build` invoca `upcomingDates` → `tz.getLocation()`, y
  el test no inicializa la base de datos de timezones (`tzdata.initializeTimeZones()`
  en `setUpAll`), lanzando `LocationNotFoundException`. Es un fallo de **setup**
  preexistente (causa: timezone), **distinto** del cubo "shader+goldens" de §0:
  son **4** de los 57 fallos verificados hoy (ver `../PREEXISTING_TEST_FAILURES.md`).
  Mi test nuevo sí la inicializa. **No** lo arreglé ahí para no mezclar un fix
  parcial de un fichero ya roto fuera del alcance de §8 (al inicializar timezones
  afloran además otros 2 fallos preexistentes suyos: falta `GoRouter` en su harness
  y checkbox fuera de viewport). Queda anotado por si se
  aborda en una limpieza de la suite UI.
