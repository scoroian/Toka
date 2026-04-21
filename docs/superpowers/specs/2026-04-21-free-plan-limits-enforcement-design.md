# Spec: Cumplimiento de límites del plan Free + tarea puntual + gating de valoraciones

**Fecha:** 2026-04-21
**Estado:** Propuesto
**Prioridad:** Crítica (monetización + privacidad)

---

## Contexto

El documento maestro define en el **punto 6.1** qué puede hacer un hogar Free frente a uno Premium. La sesión de QA del 2026-04-20 detectó que varios de esos límites no se aplican en la app actual:

| Recurso                                | Free (según 6.1)                | Estado actual en código                        |
| -------------------------------------- | ------------------------------- | ---------------------------------------------- |
| Miembros activos                       | Hasta 3                         | Sin límite (se aceptan más de 3 `addMember`)    |
| Tareas activas                         | 4                               | Sin límite                                     |
| Administradores                        | 1 total (solo el propietario)   | Se puede `grantAdmin` a cualquier miembro      |
| Tareas recurrentes automáticas         | Hasta 3                         | Sin límite (se ignora el tipo de `RecurrenceRule`) |
| Valoraciones y notas                   | No                              | **El cliente las permite y el backend las acepta** |

Además, QA confirmó dos huecos funcionales:

1. **No se puede crear una tarea puntual sin recurrencia.** `RecurrenceRule` es un sealed class con siete variantes recurrentes y ninguna `oneTime`, por lo que tanto la UI como el validador obligan a elegir una recurrencia.
2. **Los hogares Free pueden enviar valoraciones** (`submitReview`) sin que el backend compruebe el plan.

Esta spec resuelve los cinco límites del 6.1, añade la variante puntual y bloquea las valoraciones en Free con defensa en profundidad (cliente + Cloud Function + reglas Firestore).

---

## Restricciones actuales

- El estado premium se lee SIEMPRE del servidor en `homes/{homeId}.premiumStatus`. La UI lo consume vía `homes/{homeId}/views/dashboard.premiumFlags`.
- Las mutaciones importantes ya pasan por Callable Functions (`createTask`, `updateTask`, `addMember`, `grantAdmin`, `submitReview`, `applyTaskCompletion`, `passTaskTurn`). Las reglas Firestore deniegan la escritura directa de estos campos al cliente.
- `TaskValidator` en [lib/features/tasks/domain/task_validator.dart](lib/features/tasks/domain/task_validator.dart) valida inputs de cliente pero no conoce el plan.
- El dashboard ya expone `premiumFlags.canUseReviews`; se usa sólo como hint UI y no se revalida en backend.

---

## Límites numéricos y fuentes de verdad

Se centralizan los números en un módulo compartido TS y en un archivo de constantes Dart, para evitar deriva:

- **Nuevo TS:** `functions/src/shared/free_limits.ts`
  ```ts
  export const FREE_LIMITS = {
    maxActiveMembers: 3,
    maxActiveTasks: 4,
    maxAdminsTotal: 1, // solo el owner
    maxAutomaticRecurringTasks: 3,
  } as const;
  ```
- **Nuevo Dart:** `lib/core/constants/free_limits.dart`
  ```dart
  class FreeLimits {
    static const maxActiveMembers = 3;
    static const maxActiveTasks = 4;
    static const maxAdminsTotal = 1;
    static const maxAutomaticRecurringTasks = 3;
  }
  ```

Tareas **recurrentes automáticas** = cualquier `RecurrenceRule` que no sea `oneTime`. La nueva `oneTime` (añadida en esta spec) nunca computa para el límite de 3.

---

## Tarea puntual: `RecurrenceRule.oneTime`

### Dominio

Modificar [lib/features/tasks/domain/recurrence_rule.dart](lib/features/tasks/domain/recurrence_rule.dart) para añadir la variante:

```dart
const factory RecurrenceRule.oneTime({
  required String date,      // "YYYY-MM-DD"
  required String time,      // "HH:mm"
  required String timezone,
}) = OneTimeRule;
```

### Serialización Firestore

Se codifica como `{"kind":"oneTime","date":"2026-04-25","time":"09:00","timezone":"Europe/Madrid"}` en el campo `recurrenceRule` del documento `tasks/{taskId}`. Actualizar `TasksRepositoryImpl._fromFirestore/_toFirestore` y el equivalente TS en `functions/src/tasks/task_assignment_helpers.ts` (`computeNextDueAt`, `advanceNextDueAt`).

### Ciclo de vida

- Al completar (`applyTaskCompletion`) o pasar turno (`passTaskTurn`) una tarea `oneTime`, la lógica existente ya calcula `nextDueAt` vía `advanceNextDueAt`; para `oneTime` devuelve `null` y el callable marca la tarea como `status = "archived"` (nuevo estado opcional) o mantiene `status = "active"` con `nextDueAt = null` y la oculta del panel Hoy.
- **Decisión:** introducir `TaskStatus.completedOneTime` en [lib/features/tasks/domain/task_status.dart](lib/features/tasks/domain/task_status.dart) y que `applyTaskCompletion` lo fije en la última transición. El dashboard filtra `status != completedOneTime` para la cuenta de tareas activas.

### UI

En [lib/features/tasks/presentation/widgets/recurrence_form.dart](lib/features/tasks/presentation/widgets/recurrence_form.dart) añadir el chip **"Puntual"** como primer elemento. Al seleccionarlo, el formulario muestra sólo un `DatePicker` + `TimePicker` y oculta las opciones de repetición. El tipo se persiste vía `recurrence_provider` como `OneTimeRule`.

### Validador

En [lib/features/tasks/domain/task_validator.dart](lib/features/tasks/domain/task_validator.dart) aceptar `OneTimeRule` y validar que `date` no sea pasada en más de 1 día.

---

## Backend: validación por Callable

Cada callable obtiene el documento del hogar y su `premiumStatus`. Un helper centraliza la decisión:

```ts
// functions/src/shared/free_limits.ts
export function isPremium(status: string): boolean {
  return status === "active"
      || status === "cancelledPendingEnd"
      || status === "rescue";
}
```

### 1. `createTask` / `updateTask` (en [functions/src/tasks/index.ts](functions/src/tasks/index.ts))

**Preconditions adicionales si `!isPremium(home.premiumStatus)`:**

1. Contar tareas activas del hogar (`status in ["active","paused"]`, `taskId != thisTaskId` en update). Si **≥ 4** → `HttpsError("failed-precondition", "free_limit_tasks")`.
2. Si la `recurrenceRule` entrante **no** es `oneTime`:
   - Contar tareas activas con `recurrenceRule.kind != "oneTime"` (excluyendo la actual en update). Si **≥ 3** → `HttpsError("failed-precondition", "free_limit_recurring")`.

### 2. `addMember` (en [functions/src/homes/index.ts](functions/src/homes/index.ts))

**Precondition adicional si Free:** contar `members.size` (estado `active`). Si **≥ 3** → `HttpsError("failed-precondition", "free_limit_members")`.

El owner siempre cuenta. Miembros `pending` también cuentan para evitar rebasar el límite con invitaciones abiertas.

### 3. `grantAdmin` (nueva restricción)

Si **Free**: sólo el `ownerUid` puede tener `role = "admin"`. El callable rechaza cualquier intento con `HttpsError("failed-precondition", "free_limit_admins")`. Al hacer **downgrade** (`expiredFree`, transición automática en `jobs/premium_downgrade.ts`), el cron debe **revocar el rol admin** a todos excepto al owner — ya cubierto en la spec 2026-04-15-task-expiry si se amplía ahí; si no, se añade en esta spec como sub-paso.

### 4. `submitReview` (en [functions/src/tasks/submit_review.ts](functions/src/tasks/submit_review.ts))

**Precondition adicional:** si `!isPremium(home.premiumStatus)` → `HttpsError("failed-precondition", "free_no_reviews")`. El cliente además ocultará el botón cuando `dashboard.premiumFlags.canUseReviews == false`.

---

## Defensa en profundidad: `firestore.rules`

Las tareas y miembros no se escriben directamente desde el cliente (ya prohibido en reglas actuales). Para **valoraciones** sí hay un path cliente-escribible (`memberReviews/{uid}`). Endurecer la regla:

```
match /homes/{homeId}/taskEvents/{eventId}/reviews/{reviewerUid} {
  allow create: if request.auth != null
    && request.auth.uid == reviewerUid
    && get(/databases/$(database)/documents/homes/$(homeId)/views/dashboard).data.premiumFlags.canUseReviews == true;
}
```

Coste: 1 get extra por creación de review (~0.00001 USD). Aceptable.

---

## Cliente: gating visible

Todos los accesos a estas acciones deben desaparecer (o quedar deshabilitados con mensaje claro de upgrade) cuando el hogar es Free. Fuente de verdad: `dashboard.premiumFlags` + el nuevo campo `dashboard.planCounters` (añadido abajo).

### 1. Dashboard — nuevos contadores

En [functions/src/tasks/update_dashboard.ts](functions/src/tasks/update_dashboard.ts) y el writer equivalente de miembros, añadir al documento `homes/{homeId}/views/dashboard`:

```ts
planCounters: {
  activeMembers: number,
  activeTasks: number,
  automaticRecurringTasks: number,
  totalAdmins: number,
}
```

Se recomputa cuando cambia la colección de tareas o miembros (ya hay triggers; sólo se amplía el payload).

En el lado Dart: añadir los mismos campos a `HomeDashboard` en [lib/features/tasks/domain/home_dashboard.dart](lib/features/tasks/domain/home_dashboard.dart).

### 2. Tareas

- **[lib/features/tasks/presentation/skins/create_edit_task_screen_v2.dart](lib/features/tasks/presentation/skins/create_edit_task_screen_v2.dart):**
  - Si Free y `activeTasks >= 4` → el formulario muestra un banner no cerrable "Tu hogar Free tiene el máximo de 4 tareas activas" + botón **Hazte Premium** (abre paywall). El botón **Guardar** queda deshabilitado.
  - Si Free, `activeTasks < 4` pero la recurrencia seleccionada no es `oneTime` y ya hay 3 automáticas → banner "Has alcanzado las 3 tareas recurrentes del plan Free. Puedes crear tareas puntuales o hacerte Premium." Botón Guardar deshabilitado sólo si la recurrencia no es puntual.

### 3. Miembros

- **[lib/features/members/presentation/members_screen.dart](lib/features/members/presentation/members_screen.dart):**
  - FAB "Invitar" deshabilitado + snackbar de upgrade si Free y `activeMembers >= 3`.
  - El sheet de confirmación muestra un indicador `"3 / 3 miembros — límite del plan Free"`.
- Toggle **Hacer admin** en el bottom sheet de detalle de miembro: en Free no se renderiza. En su lugar, un `ListTile` informativo "Los roles de admin están disponibles en Premium".

### 4. Valoraciones

- **[lib/features/history/presentation/widgets/rate_event_sheet.dart](lib/features/history/presentation/widgets/rate_event_sheet.dart):** si `!canUseReviews`, el sheet no se muestra. En su lugar, la tarjeta del evento renderiza un mini-banner "Valoraciones disponibles en Premium" con CTA.
- El botón "Valorar" de [lib/features/history/presentation/widgets/history_event_tile.dart](lib/features/history/presentation/widgets/history_event_tile.dart) se oculta si `!canUseReviews`.

---

## Downgrade automático — limpieza coherente

En el cron `jobs/premium_downgrade.ts` (o donde hoy se cambie a `expiredFree`):

1. Revocar rol admin a todos los miembros excepto `ownerUid`.
2. Si `activeMembers > 3` → **no se expulsa a nadie**, pero la UI de Miembros muestra un banner "Has superado el límite Free (3 miembros). Sólo se aceptan nuevas invitaciones cuando vuelvas a estar por debajo."
3. Si `activeTasks > 4` → **no se archivan tareas**, pero la UI permite a cualquier admin/owner archivar manualmente hasta estar por debajo. El `createTask` rechaza hasta volver a la normalidad.
4. Las valoraciones previas no se borran (son datos históricos). Sólo se bloquea crear nuevas.

Este enfoque cumple la regla del documento maestro: "el downgrade nunca destruye datos; sólo bloquea nuevas capacidades".

---

## i18n

Nuevas claves ARB en `lib/l10n/app_es.arb`, `app_en.arb`, `app_ro.arb`:

- `freeLimitMembersReached` — "Tu plan Free permite hasta 3 miembros. Hazte Premium para añadir más."
- `freeLimitTasksReached` — "Tu plan Free permite hasta 4 tareas activas."
- `freeLimitRecurringReached` — "Tu plan Free permite hasta 3 tareas con recurrencia. Crea una puntual o hazte Premium."
- `freeAdminsLockedToOwner` — "Los roles de admin están disponibles en Premium."
- `freeReviewsDisabled` — "Las valoraciones están disponibles en Premium."
- `recurrenceOneTime` — "Puntual".
- `recurrenceOneTimeHelp` — "Se completa una sola vez y desaparece del listado."

---

## Tests

### Unitarios (Dart)

- `recurrence_rule_test.dart`: round-trip JSON para `OneTimeRule`.
- `task_validator_test.dart`: acepta `oneTime` con fecha futura; rechaza fecha pasada > 24h.
- `create_edit_task_view_model_test.dart`: si `activeTasks=4` y Free, `canSave=false` con razón `freeLimitTasks`.

### Unitarios (TS)

- `free_limits.test.ts`: `isPremium` cubre los 6 estados.
- `homes_callables.test.ts`: ampliar con casos `addMember` y `grantAdmin` en Free.
- `submit_review.test.ts`: rechaza con `free_no_reviews` cuando el hogar es Free.
- Nuevo `task_limits.test.ts`: `createTask` rechaza >4 activas y >3 recurrentes en Free.

### Integración (emuladores)

- Flujo Free completo: crear 4 tareas OK → 5ª falla; crear 3 recurrentes + 1 puntual OK → 4ª recurrente falla; invitar 3 miembros OK → 4º falla.

---

## Marcadores de debug del QA

Ninguno. Esta spec introduce comportamiento permanente. Los contadores de `dashboard.planCounters` **se mantienen también para Premium** (valor informativo en Ajustes del hogar).

---

## Fuera de alcance

- Rediseño del paywall (cubierto por spec 5).
- Transiciones automáticas del estado premium (ya cubiertas por el cron existente).
- Migración de datos históricos de valoraciones antiguas en hogares que se queden Free.
- Estrategia de aviso proactivo (push/email) al pagador cuando se acerca al límite.
