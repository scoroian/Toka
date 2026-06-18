# §2 — 🔴 "Pasar turno" desinforma (sin candidato / sin penalización)

Estado: **RESUELTO** · Fecha: 2026-06-17 · Verificado en 2 dispositivos.

## Bug

El diálogo "¿Pasar turno?" SIEMPRE mostraba "No hay otro miembro disponible,
seguirás siendo el responsable" aunque existiera un siguiente responsable
válido, y NUNCA mostraba ni el siguiente responsable ni el aviso de
penalización de cumplimiento. El backend, en cambio, sí pasaba el turno
correctamente. Violaba la regla de negocio #7 ("Pasar turno genera penalización
estadística VISIBLE antes de confirmar").

## Causa raíz (era bug real, no falso positivo)

Dos defectos del **cliente**, ambos en la pantalla Hoy:

1. **Siguiente responsable hardcodeado a `null`.**
   `lib/features/tasks/presentation/skins/today_screen_v2.dart` (`_onPass`)
   construía el `PassTurnDialog` con `nextAssigneeName: null` **literal**. El
   cliente NUNCA calculaba el siguiente elegible, por eso el diálogo siempre
   caía en la rama `pass_turn_no_candidate`. El widget `PassTurnDialog` estaba
   bien: mostraba el nombre cuando se le pasaba; simplemente nunca lo recibía.

2. **Compliance leída de un campo legacy ya borrado.**
   `today_view_model.dart` (`fetchPassStats`) leía `completedCount`. El backend
   migró ese contador a `tasksCompleted` y **borra** `completedCount` con
   `FieldValue.delete()` en la primera operación (`pass_task_turn.ts`). Tras la
   primera vez, el cliente leía `completedCount` inexistente → `completed = 0`
   → `before = after = 0%` → `diff = 0` → el banner de penalización
   (`if (diff >= 1.0)`) nunca se mostraba.

## Fix

Se replica en cliente la lógica exacta del backend
(`functions/src/tasks/pass_turn_helpers.ts` → `getNextEligibleMember`):

- **Nuevo helper puro** `lib/features/tasks/domain/pass_turn_logic.dart` →
  `getNextEligibleMember(order, currentUid, frozenUids)`, espejo 1:1 del TS
  (avanza en `assignmentOrder`, salta `frozen`/`absent`, devuelve `currentUid`
  si no hay candidato).
- **Nueva función testeable** `fetchPassTurnInfo(db, homeId, taskId, currentUid)`
  en `today_view_model.dart`: lee el doc de la tarea (para `assignmentOrder`) y
  la colección de miembros (para congelados/ausentes, nombres y contadores del
  propio usuario), y devuelve `(complianceBefore, estimatedAfter,
  nextAssigneeName)`. Usa `tasksCompleted` con fallback a `completedCount`
  (igual que el backend) y `complianceBefore = completed / max(completed+passed, 1)`.
- `TodayViewModel.fetchPassStats(uid)` → reemplazado por
  `fetchPassInfo(taskId, uid)` que delega en `fetchPassTurnInfo`.
- `today_screen_v2.dart` (`_onPass`) ahora pasa
  `nextAssigneeName: info.nextAssigneeName` (ya no `null`).

Sin texto hardcodeado: se reutilizan las claves ARB existentes
(`pass_turn_next_assignee`, `pass_turn_compliance_warning`,
`pass_turn_no_candidate`).

### Archivos

- Nuevo: `lib/features/tasks/domain/pass_turn_logic.dart`
- Modificado: `lib/features/tasks/application/today_view_model.dart`
- Modificado: `lib/features/tasks/presentation/skins/today_screen_v2.dart`
- Nuevo test: `test/unit/features/tasks/pass_turn_logic_test.dart` (8 casos)
- Nuevo test: `test/integration/features/tasks/pass_turn_info_test.dart` (7 casos)

## Tests

- `flutter analyze` sobre los archivos tocados: **sin issues**.
- `pass_turn_logic_test.dart` (unit): orden vacío, 1 miembro, alternancia A↔B,
  3 miembros, salto de congelado, todos congelados, currentUid fuera del orden.
- `pass_turn_info_test.dart` (integración, `fake_cloud_firestore`): siguiente =
  nombre de B; 1 miembro → null; congelado se salta; **ausente (vacaciones) se
  salta como el backend**; todos congelados → null; **usa `tasksCompleted`
  sobre legacy** (before=0.8, after=8/11); fallback a `completedCount`
  (before=1.0, after=5/6).
- Los tests fallan antes del fix (cálculo inexistente / campo legacy) y pasan
  después. **15/15 verdes.**
- Nota: el golden `pass_turn_dialog.png` falla con diff 0.26% por renderizado de
  fuentes de esta máquina (uno de los ~68 fallos de entorno documentados); el
  widget del diálogo no se tocó. No es regresión.

## Verificación en dispositivo (2/2)

Sin mutar producción (la preparación vía Admin SDK quedó denegada por el
clasificador; se verificó con datos reales existentes y se cancelaron los
diálogos sin confirmar el paso).

Estado usado: hogar **QA-Hogar-1** (`PomTlPWhrJbpg3GNDtpL`), tarea **"frigoricoo"**
(`de97fcac`), `assignmentOrder=["WAS"(Admin), "rC4b"(QA-B)]`, ambos activos,
responsable actual = Admin. Login: `toka.qa.admin@gmail.com`.

- **Emulador `emulator-5554`**: Hoy → frigoricoo → "↻ Pasar" → el diálogo muestra
  **"El siguiente responsable será: QA-B"** (antes: "No hay otro miembro
  disponible"). ✅
- **MI_9 `43340fd2`**: mismo flujo → **"El siguiente responsable será: QA-B"**. ✅

Capturas analizadas y borradas al terminar (`C:\tmp\toka`).

La penalización de cumplimiento (banner rojo) no aparece en este caso concreto
porque el usuario Admin tiene `tasksCompleted=0` → `before = after = 0%`
(comportamiento correcto: 0% no baja). El arreglo de la penalización
(`tasksCompleted` migrado + render del banner) queda cubierto de forma
determinista por `pass_turn_info_test.dart` ("usa tasksCompleted sobre legacy")
y por el test UI existente `pass_turn_dialog_test.dart` ("muestra banner rojo
cuando diff >= 1%"). La misma vía de wiring (`fetchPassInfo` → diálogo) que
entrega el nombre del siguiente responsable —ya verificada en dispositivo—
entrega también los valores de compliance.

## Otros hallazgos durante el trabajo

- **Membresía espejo `users/{uid}/memberships` desincronizada.** Con
  `toka.qa.owner` (m9K) el selector de hogares solo listaba "QA_Post_Fix", pese
  a que m9K es admin activo de "Hogar" (`YBGWBKJWaNjQhChCSZGE`) en
  `homes/.../members`. El selector lee la colección espejo `users/{uid}/memberships`,
  que no contenía "Hogar". Relacionado con §3 (membresías fantasma/limpieza
  incompleta). Mini-repro: login m9K → selector de hogares → falta "Hogar".
- **Miembros `left` permanecen en `assignmentOrder`.** En "Hogar", la tarea
  "Barrer" tiene `order=["Ko7p"(left), "m9K"]`. Tanto el backend como el cliente
  solo saltan `frozen`/`absent` (no `left`), así que pasar turno elegiría a un
  ex-miembro. Es coherente cliente↔backend (no es regresión de este fix), pero
  conviene que `removeMember`/`leaveHome` purguen el uid de los `assignmentOrder`
  de las tareas. Fuera del alcance de §2.
