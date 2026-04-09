# Diseño: Cobertura de Tests Exhaustiva — Toka

**Fecha:** 2026-04-09  
**Área:** Testing — Firestore Rules + Functions Integration + Patrol E2E  
**Enfoque elegido:** Secuencial por área (A → B → C)

---

## Contexto

El proyecto ya cuenta con ~126 archivos de test en `test/` (unit + UI + integration para Flutter) y 10 archivos `.test.ts` en Functions (helpers + rules). Sin embargo, se han identificado tres áreas con gaps significativos de cobertura.

---

## Área 1: Firestore Rules Tests (Cobertura Máxima)

### Objetivo
Cubrir todas las rutas de `firestore.rules` que actualmente no tienen tests. Las reglas existentes cubren 12 rutas; solo 4 tienen tests (`homes`, `languages`, `reviews`, `users`).

### Ubicación
`functions/test/rules/`

### Framework
Igual al existente: Jest + `@firebase/rules-unit-testing`, `initializeTestEnvironment`, `withSecurityRulesDisabled` para seed, `assertSucceeds`/`assertFails`.

### Archivos a crear

#### `tasks.test.ts`
Colección: `homes/{homeId}/tasks`

**Read:**
- ✅ owner puede leer
- ✅ admin puede leer
- ✅ member activo puede leer
- ✅ member frozen puede leer
- ❌ usuario autenticado no-miembro no puede leer
- ❌ usuario no autenticado no puede leer

**Create:**
- ✅ owner activo puede crear
- ✅ admin activo puede crear
- ❌ member raso activo no puede crear
- ❌ member frozen no puede crear (aunque sea admin)
- ❌ no-miembro autenticado no puede crear
- ❌ no autenticado no puede crear

**Update:**
- ✅ owner activo puede actualizar
- ✅ admin activo puede actualizar
- ❌ member raso activo no puede actualizar
- ❌ member frozen no puede actualizar
- ❌ no-miembro autenticado no puede actualizar
- ❌ no autenticado no puede actualizar

**Delete (soft delete — denegado para todos):**
- ❌ owner no puede borrar físicamente
- ❌ admin no puede borrar físicamente
- ❌ member no puede borrar físicamente
- ❌ no-miembro no puede borrar físicamente
- ❌ no autenticado no puede borrar físicamente

---

#### `task_events.test.ts`
Colección: `homes/{homeId}/taskEvents`

**Read:**
- ✅ owner puede leer
- ✅ admin puede leer
- ✅ member activo puede leer
- ✅ member frozen puede leer
- ❌ no-miembro autenticado no puede leer
- ❌ no autenticado no puede leer

**Write (create/update/delete — todos denegados):**
- ❌ owner no puede escribir directamente
- ❌ admin no puede escribir directamente
- ❌ member no puede escribir directamente
- ❌ no-miembro no puede escribir directamente
- ❌ no autenticado no puede escribir directamente

---

#### `members.test.ts`
Colección: `homes/{homeId}/members/{uid}`

**Read:**
- ✅ owner puede leer cualquier miembro
- ✅ admin puede leer cualquier miembro
- ✅ member puede leer cualquier miembro del hogar
- ❌ no-miembro autenticado no puede leer
- ❌ no autenticado no puede leer

**Update propio (uid == request.auth.uid):**
- ✅ actualizar solo `notificationPrefs`
- ✅ actualizar solo `vacation`
- ✅ actualizar `notificationPrefs` + `vacation` juntos
- ❌ actualizar `role` (campo prohibido)
- ❌ actualizar `status` (campo prohibido)
- ❌ actualizar `uid` (campo prohibido)
- ❌ actualizar `billingState` (campo prohibido)
- ❌ actualizar `notificationPrefs` + campo extra prohibido
- ❌ actualizar `vacation` + campo extra prohibido

**Update de otro miembro:**
- ❌ owner no puede actualizar `notificationPrefs` de otro miembro via cliente
- ❌ admin no puede actualizar `notificationPrefs` de otro miembro via cliente
- ❌ member no puede actualizar datos de otro miembro

**Create / Delete:**
- ❌ ningún rol puede crear miembros directamente (solo Functions)
- ❌ ningún rol puede eliminar miembros directamente (solo Functions)

---

#### `invitations.test.ts`
Colección: `homes/{homeId}/invitations/{inviteId}`

**Read por admin/owner:**
- ✅ owner puede leer invitaciones
- ✅ admin puede leer invitaciones
- ❌ member raso no puede leer invitaciones
- ❌ no-miembro autenticado no puede leer (sin código)
- ❌ no autenticado no puede leer

**Read público (resource.data.code != null):**
- ✅ usuario autenticado no-miembro puede leer si el documento tiene `code`
- ❌ usuario autenticado no-miembro no puede leer si el documento no tiene `code`

**Create:**
- ✅ owner puede crear invitación
- ✅ admin puede crear invitación
- ❌ member raso no puede crear invitación
- ❌ member frozen no puede crear invitación
- ❌ no-miembro no puede crear invitación
- ❌ no autenticado no puede crear invitación

**Update:**
- ✅ owner puede actualizar invitación
- ✅ admin puede actualizar invitación
- ❌ member raso no puede actualizar
- ❌ no-miembro no puede actualizar

**Delete:**
- ✅ owner puede eliminar invitación
- ✅ admin puede eliminar invitación
- ❌ member raso no puede eliminar
- ❌ no-miembro no puede eliminar
- ❌ no autenticado no puede eliminar

---

#### `member_task_stats.test.ts`
Colección: `homes/{homeId}/memberTaskStats/{statId}`

**Read:**
- ✅ owner puede leer stats
- ✅ admin puede leer stats
- ✅ member activo puede leer stats
- ✅ member frozen puede leer stats
- ❌ no-miembro autenticado no puede leer
- ❌ no autenticado no puede leer

**Write (todos denegados):**
- ❌ owner no puede escribir directamente
- ❌ admin no puede escribir directamente
- ❌ member no puede escribir directamente
- ❌ no autenticado no puede escribir directamente

---

#### `downgrade.test.ts`
Documento: `homes/{homeId}/downgrade/current`

**Read:**
- ✅ owner puede leer el plan de downgrade
- ❌ admin no puede leer el plan de downgrade
- ❌ member raso no puede leer el plan de downgrade
- ❌ no-miembro autenticado no puede leer
- ❌ no autenticado no puede leer

**Write:**
- ✅ owner puede escribir el plan de downgrade manual
- ❌ admin no puede escribir el plan de downgrade
- ❌ member raso no puede escribir
- ❌ no-miembro no puede escribir
- ❌ no autenticado no puede escribir

---

#### `subscriptions.test.ts`
Colección: `homes/{homeId}/subscriptions/history/{chargeId}`

**Read con billingState válido:**
- ✅ miembro con billingState `currentPayer` puede leer
- ✅ miembro con billingState `formerPayer` puede leer

**Read con billingState no autorizado:**
- ❌ miembro con billingState `none` no puede leer
- ❌ miembro con billingState `invited` no puede leer
- ❌ member raso (sin billingState de pago) no puede leer
- ❌ no-miembro autenticado no puede leer
- ❌ no autenticado no puede leer

**Write (todos denegados):**
- ❌ currentPayer no puede escribir directamente
- ❌ owner no puede escribir directamente
- ❌ no autenticado no puede escribir directamente

---

#### `dashboard.test.ts`
Documento: `homes/{homeId}/views/dashboard`

**Read:**
- ✅ owner puede leer el dashboard
- ✅ admin puede leer el dashboard
- ✅ member activo puede leer el dashboard
- ✅ member frozen puede leer el dashboard
- ❌ no-miembro autenticado no puede leer
- ❌ no autenticado no puede leer

**Write (todos denegados):**
- ❌ owner no puede escribir directamente
- ❌ admin no puede escribir directamente
- ❌ member no puede escribir directamente
- ❌ no autenticado no puede escribir directamente

---

### Estimación
~160-200 tests en total para Área 1.

---

## Área 2: Functions Integration Tests con Emulador

### Objetivo
Probar los callables de Cloud Functions contra el Firebase Emulator real (Auth + Firestore + Functions), verificando efectos secundarios en Firestore tras cada llamada.

### Ubicación
`functions/test/integration/`

### Infraestructura
- Helper compartido: `functions/test/integration/helpers/setup.ts`
  - Inicializa conexión al emulador (Auth puerto 9099, Firestore puerto 8080, Functions puerto 5001)
  - Factory `createTestUser(email, password)` → uid
  - Factory `createTestHome(ownerUid, options?)` → homeId
  - Factory `createTestTask(homeId, options?)` → taskId
  - Factory `addMemberToHome(homeId, uid, role)` → membership
  - `cleanupAll()` — limpia Firestore entre tests

### Archivos a crear

#### `apply_task_completion.test.ts`
- ✅ owner completa su propia tarea → evento creado, stats actualizadas, dashboard actualizado
- ✅ member completa tarea asignada a él → ídem
- ❌ member intenta completar tarea asignada a otro → error autorización
- ❌ tarea ya completada → error estado inválido
- ❌ miembro frozen intenta completar → error
- ❌ llamada sin autenticación → error auth
- ❌ homeId inexistente → error not-found
- ❌ taskId inexistente → error not-found
- ✅ hogar premium — completar tarea premium → funciona
- ❌ hogar free — completar tarea premium → error entitlement

#### `pass_task_turn.test.ts`
- ✅ pasa turno con miembros elegibles → siguiente asignado, penalización registrada
- ✅ miembro en vacaciones excluido del siguiente turno
- ❌ último miembro (sin elegibles) → error o se queda asignado a sí mismo
- ✅ evento de penalización creado correctamente en Firestore
- ✅ stats de turn_passed actualizadas
- ❌ no-owner/admin intenta pasar turno → error autorización
- ❌ sin autenticación → error auth
- ❌ tarea no asignada → error estado

#### `open_rescue_window.test.ts`
- ✅ owner abre ventana dentro de los 3 días previos a premiumEndsAt → campo rescueWindowOpen: true
- ❌ fuera de ventana de 3 días → error
- ❌ ventana ya abierta → error o idempotente
- ❌ hogar free sin premiumEndsAt → error
- ❌ no-owner intenta abrir → error autorización
- ❌ sin autenticación → error auth

#### `sync_entitlement.test.ts`
- ✅ receipt válido de iOS → premiumStatus actualizado, premiumEndsAt correcto
- ✅ receipt válido de Android → ídem
- ❌ receipt expirado → premiumStatus = free
- ❌ receipt inválido/malformado → error
- ✅ llamada idempotente (mismo receipt dos veces) → sin error, mismo resultado
- ❌ usuario sin hogar → error
- ❌ sin autenticación → error auth

#### `apply_downgrade_plan.test.ts`
- ✅ downgrade con plan manual guardado → aplica el plan, hogar queda free con configuración del plan
- ✅ sin plan manual → aplica downgrade automático (reduce a 2 hogares base)
- ❌ periodo premium aún vigente → error, no aplica
- ❌ hogar ya free → error o idempotente
- ❌ no-owner intenta aplicar → error autorización
- ✅ verifica documentos de downgrade limpiados tras aplicar
- ✅ verifica slots actualizados en usuario

#### `manual_reassign.test.ts`
- ✅ admin reasigna tarea a miembro activo válido → assignedTo actualizado
- ✅ owner reasigna → ídem
- ❌ reasignar a miembro frozen → error
- ❌ reasignar a uid no-miembro → error
- ❌ member raso intenta reasignar → error autorización
- ❌ sin autenticación → error auth
- ❌ taskId inexistente → error not-found

#### `dispatch_due_reminders.test.ts`
Scheduled job — se invoca directamente sin auth:
- ✅ tareas con reminder pendiente y token FCM → notificación enviada (mock FCM), campo `reminderSentAt` actualizado
- ✅ tareas con reminder ya enviado (`reminderSentAt` presente) → no se reenvía
- ✅ miembro sin token FCM → se omite silenciosamente
- ✅ tarea completada → no se envía reminder
- ✅ múltiples tareas en múltiples hogares → procesa todas correctamente

#### `full_user_flow.test.ts`
Flujo completo encadenado (end-to-end a nivel Functions):

```
1. Crear usuario A en Auth emulator
2. Llamar callable createHome → verificar hogar creado, ownerUid correcto
3. Verificar hogar vacío (colección tasks vacía)
4. Crear tarea recurrente diaria → verificar en Firestore
5. Crear tarea recurrente semanal → verificar en Firestore
6. Crear tarea puntual → verificar en Firestore
7. Verificar dashboard actualizado con 3 tareas
8. applyTaskCompletion (tarea 1) → verificar evento creado, stats de A actualizadas
9. passTaskTurn (tarea 2) → verificar penalización en evento, stats de A
10. Invitar usuario B → código de invitación creado
11. Crear usuario B y unirse al hogar con código
12. Verificar B aparece en members con role 'member'
13. manualReassign tarea 3 a B → verificar assignedTo = B
14. B completa tarea 3 → verificar evento, stats de B
15. Verificar historial de eventos: 3 eventos para 3 tareas
16. Verificar stats finales: A (1 completada, 1 turn_passed), B (1 completada)
```

---

## Área 3: Patrol E2E Flows

### Objetivo
Ampliar los flujos de integración e2e con Patrol para cubrir gestión de miembros, suscripción premium y ajustes/notificaciones. Se reutiliza el setup existente en `integration_test/helpers/test_setup.dart`.

### Ubicación
`integration_test/flows/`

### Archivos a crear

#### `member_management_flow_test.dart`
```
1. Login con usuario A (owner)
2. Ir a pantalla Miembros → verificar estado vacío
3. Abrir sheet de invitar → código de invitación visible
4. Login con usuario B (sesión paralela) → unirse con código
5. Recargar pantalla Miembros → B aparece en lista
6. Usuario A pone a B en modo vacaciones → badge 'En vacaciones' visible en card
7. Usuario A cancela vacaciones de B → badge desaparece
8. Usuario A expulsa a B → B desaparece de la lista
9. Verificar que B ya no puede acceder al hogar
```

#### `subscription_flow_test.dart`
```
1. Login como owner de hogar free
2. Navegar a Paywall → plan comparison visible, botón de compra activo
3. Simular compra exitosa (mock in_app_purchase)
4. Verificar estado premium activado en UI (badge premium visible)
5. Navegar a Gestión de suscripción → fecha de renovación visible
6. Simular premiumEndsAt próximo (3 días) → rescue banner visible en pantalla principal
7. Abrir pantalla de rescate → opciones de renovar/downgrade visibles
8. Confirmar downgrade → hogar vuelve a free, badge premium desaparece
```

#### `settings_notifications_flow_test.dart`
```
1. Login con usuario
2. Navegar a Ajustes → verificar secciones (Cuenta, Notificaciones, Idioma, etc.)
3. Cambiar idioma a Inglés → UI cambia a inglés, labels actualizados
4. Cambiar idioma de vuelta a Español → UI restaurada
5. Navegar a Notificaciones → todos los toggles visibles
6. Desactivar toggle 'Recordatorios de tarea' → guardado en Firestore verificado
7. Reactivar toggle → estado restaurado
8. Navegar a Editar perfil → cambiar nombre de usuario
9. Guardar → verificar nuevo nombre en pantalla de perfil y en lista de miembros
```

#### Ampliación de `task_completion_flow_test.dart`
Añadir al flujo existente:
```
- Crear tarea desde cero (pantalla create_edit_task) con recurrencia semanal
- Verificar tarea aparece en pantalla Hoy
- Completar tarea → dialog de valoración aparece
- Dar valoración (4 estrellas, nota privada) → confirmación visible
- Pasar turno en otra tarea → dialog de penalización con stats visibles antes de confirmar
- Confirmar paso → turno cambiado, siguiente asignado visible
```

---

## Orden de implementación

1. **Área 1** — Firestore Rules (8 archivos, ~160-200 tests)
2. **Área 2** — Functions Integration (8 archivos, ~60 tests + flujo completo)
3. **Área 3** — Patrol E2E (3 archivos nuevos + 1 ampliación)

---

## Criterios de completitud

- Todos los tests pasan en verde con emuladores activos
- `flutter analyze` sin errores
- `tsc --noEmit` sin errores en Functions
- Cada área se commitea de forma independiente con su propio PR
