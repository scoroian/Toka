# Toka Quick Wins — Security, AdMob & Code Quality

**Fecha:** 2026-04-18
**Estado:** Draft — pendiente de review

## Contexto

Auditoría completa de Toka detectó 20+ hallazgos. Esta tanda cubre los arreglos que no requieren decisiones de arquitectura externas ni migraciones (p. ej. validación IAP real, cierre de `/users/{uid}` y rate limiting quedan para tanda posterior). Se aborda un bug visible (no se muestran anuncios de prueba en free) y las mitigaciones de seguridad más accionables en backend.

## Alcance

### Bloque 1 — Seguridad backend (Cloud Functions)

#### 1.1 Gate `debugSetPremiumStatus` por emulador
- **Archivo:** `functions/src/homes/index.ts` (bloque `debugSetPremiumStatus`, ~L789-895)
- **Cambio:** al inicio del handler, tras validar `request.auth`, comprobar `process.env.FUNCTIONS_EMULATOR === 'true'`. Si no lo es → `throw new HttpsError('permission-denied', 'Debug operations only available in emulator')`.
- **Justificación:** `FUNCTIONS_EMULATOR` lo setea firebase-tools automáticamente; `NODE_ENV` no es fiable en Firebase Functions.

#### 1.2 Transacción única en `syncEntitlement` + `unlockSlotIfEligible`
- **Archivos:** `functions/src/entitlement/sync_entitlement.ts` (L40-95), `functions/src/entitlement/slot_ledger.ts`.
- **Problema actual:** `chargeRef.set` y `unlockSlotIfEligible` se ejecutan en operaciones separadas. Dos requests paralelos con mismo `chargeId` → doble incremento de `lifetimeUnlockedHomeSlots`.
- **Cambio:**
  - Envolver `chargeRef` check + escritura + desbloqueo de slot en un único `db.runTransaction`.
  - Dentro: `tx.get(chargeRef)` → si existe, abort silencioso (ya procesado). Si no, `tx.set(chargeRef, ...)` y si `status === 'active'`, leer `userRef`, comprobar `lifetimeUnlockedHomeSlots < 3` y `tx.update(userRef, { lifetimeUnlockedHomeSlots: FieldValue.increment(1), homeSlotCap: FieldValue.increment(1) })`.
  - `unlockSlotIfEligible` queda como helper interno que acepta la `tx` existente (no abre nueva).
- **Tests:** añadir test de idempotencia con dos invocaciones del mismo `chargeId` — `lifetimeUnlockedHomeSlots` debe incrementar solo una vez.

#### 1.3 Proteger al `currentPayerUid` de expulsión/salida
- **Archivos:** `functions/src/homes/index.ts` — handlers `removeMember` (~L545-600) y `leaveHome` (~L340-400).
- **Regla:** si `targetUid === home.currentPayerUid` y `home.premiumStatus ∈ {'active', 'cancelledPendingEnd', 'rescue'}` → `throw new HttpsError('failed-precondition', 'payer-cannot-leave-or-be-removed-while-premium-active')`.
- **Comportamiento:** error duro. No se intenta degradar el premium automáticamente. El owner debe esperar a expiración o pasar la suscripción (fuera de alcance).
- **UI:** traducir el código de error en el cliente con un mensaje claro. Clave de localización nueva: `members_error_payer_locked` (ES/EN/RO).

#### 1.4 Validar `newAssigneeUid` en `manualReassign`
- **Archivo:** `functions/src/tasks/manual_reassign.ts` (L10-75).
- **Cambio:** dentro de la transacción existente, añadir `tx.get(homes/{homeId}/members/{newAssigneeUid})`. Si no existe → `HttpsError('not-found', 'new-assignee-not-in-home')`. Si `status !== 'active'` → `HttpsError('failed-precondition', 'new-assignee-not-active')`.

### Bloque 2 — AdMob real en 4 pantallas

#### 2.1 Inicialización del SDK
- **Archivo:** `lib/main.dart` (tras `Firebase.initializeApp`).
- **Cambio:** añadir `await MobileAds.instance.initialize();` antes de `runApp(...)`.
- **Import:** `package:google_mobile_ads/google_mobile_ads.dart`.

#### 2.2 Configuración iOS
- **Archivo:** `ios/Runner/Info.plist`.
- **Cambio:** añadir entrada
  ```xml
  <key>GADApplicationIdentifier</key>
  <string>ca-app-pub-3940256099942544~1458002511</string>
  ```
  (App ID de test de AdMob para iOS.)
- **SKAdNetwork identifiers:** no se incluyen en esta tanda — aparecerá warning en consola pero no bloquea test ads.

#### 2.3 Widget compartido `AdBanner`
- **Archivo nuevo:** `lib/shared/widgets/ad_banner.dart`.
- **Contrato:**
  ```dart
  class AdBanner extends StatefulWidget {
    const AdBanner({super.key, required this.unitId, required this.show});
    final String unitId;
    final bool show;
  }
  ```
- **Comportamiento:**
  - Si `!show` o `unitId.isEmpty` → `SizedBox.shrink()`.
  - Si `kDebugMode` → ignora `unitId` y usa `BannerAd.testAdUnitId` fijo (`ca-app-pub-3940256099942544/6300978111` Android, equivalente iOS). Evita servir anuncios reales en dev por accidente.
  - Crea `BannerAd(size: AdSize.banner, adUnitId: effectiveUnitId, request: AdRequest(), listener: ...)`.
  - `load()` en `initState`, `dispose()` en `dispose()`.
  - Si `LoadAdError` → `SizedBox.shrink()` (falla silenciosa, no rompe UI).

#### 2.4 Integración en las 4 pantallas

**Patrón común:** `Column(children: [contenido_scrolleable_en_Expanded, AdBanner(...)])`. Esto hace el banner siempre visible al pie y el `Expanded` limita naturalmente el área scrollable, de modo que el último item del `ListView` queda por encima del banner (no oculto).

- **Today** — `lib/features/tasks/presentation/today_screen.dart`: reemplazar `_AdBannerPlaceholder` (L139-154) por `AdBanner` real. El `Column` ya existe.
- **All Tasks** — `lib/features/tasks/presentation/all_tasks_screen.dart` y variante `skins/all_tasks_screen_v2.dart`: envolver `ListView` en `Expanded` dentro de un `Column` y añadir `AdBanner` al pie.
- **Historial** — `lib/features/history/presentation/history_screen.dart`: sacar el `AdBanner` fuera del `ListView.builder` (antes estaba intercalado como item). Pasar a `Column(Expanded(ListView), AdBanner)`.
- **Miembros** — pantallas principales de miembros (`lib/features/members/presentation/...`): misma estructura.

El `AdBanner` lee `show` y `unitId` de un provider compartido que envuelve el dashboard:

```dart
@riverpod
({bool show, String unitId}) adBannerConfig(AdBannerConfigRef ref) {
  final dashboard = ref.watch(dashboardProvider).valueOrNull;
  return (
    show: dashboard?.adFlags.showBanner ?? false,
    unitId: dashboard?.adFlags.bannerUnit ?? '',
  );
}
```

#### 2.5 Sincronización de `adFlags` en backend
- **Archivos:** `functions/src/entitlement/sync_entitlement.ts`, `functions/src/entitlement/apply_downgrade_plan.ts`, `functions/src/jobs/restore_premium_state.ts`.
- **Cambio:** cada vez que se escriba `premiumFlags.isPremium`, escribir en el mismo update también:
  ```typescript
  adFlags: {
    showBanner: !isPremium,
    bannerUnit: isPremium ? '' : TEST_BANNER_UNIT_ID,
  }
  ```
- **Constantes compartidas:** `functions/src/shared/ad_constants.ts`:
  ```typescript
  export const TEST_BANNER_UNIT_ID_ANDROID = 'ca-app-pub-3940256099942544/6300978111';
  export const TEST_BANNER_UNIT_ID_IOS = 'ca-app-pub-3940256099942544/2934735716';
  // TODO producción: reemplazar con unit IDs reales por plataforma antes de release.
  ```
- **Consideración:** el dashboard actualmente guarda un único `bannerUnit`. Se mantiene así y se usa el Android test ID por defecto; el cliente hace override por plataforma con `Platform.isIOS` antes de crear el `BannerAd` (el flag `kDebugMode` ya fuerza los test IDs). Se documenta en el widget.

#### 2.6 Regla especial del upsell en Historial (coexiste con AdBanner)

**Requisito:** el `_PremiumBanner` promocional (upsell a Premium) debe:
1. Mostrarse **solo si** hay ≥5 items por debajo del viewport visible (es decir, el usuario necesita scrollear para ver ≥5 items más).
2. Aparecer siempre al **final** de la lista, como item N+1 (si hay 15 items, upsell es el item 16; si hay 30, es el 31).
3. Visible solo para usuarios free (comportamiento actual).

**Implementación:**
- `LayoutBuilder` alrededor del `ListView` para obtener `constraints.maxHeight`.
- Altura aproximada de item: `kHistoryItemApproxHeight = 88.0` (constante en el archivo).
- `visibleCount = (constraints.maxHeight / kHistoryItemApproxHeight).floor()`
- `hiddenCount = items.length - visibleCount`
- `showUpsell = !isPremium && hiddenCount >= 5`
- Si `showUpsell`, `ListView.builder` construye `items.length + 1` elementos donde el último es `_PremiumBanner`.
- El `AdBanner` queda **fuera** del `ListView`, en el `Column` padre, siempre visible al pie.

Resultado: en free con lista larga, usuario ve arriba los eventos, al scrollear final encuentra el upsell promocional, y el banner AdMob permanece anclado abajo todo el tiempo.

**Nota de escalabilidad:** esta regla aplica solo a Historial en esta tanda. Today, All Tasks y Miembros no tienen upsell interno hoy — no se añade.

### Bloque 3 — Code quality

#### 3.1 `new Date()` → `Timestamp.now().toDate()` en functions
- **Archivos:**
  - `functions/src/homes/index.ts` (L192, L269): validación de expiración de invitaciones.
  - `functions/src/jobs/process_expired_tasks.ts` (L49).
  - `functions/src/notifications/dispatch_due_reminders.ts` (L16).
  - `functions/src/tasks/apply_task_completion.ts` (L78, L115).
  - `functions/src/tasks/update_dashboard.ts` (L60).
- **Cambio:** reemplazar `new Date()` por `admin.firestore.Timestamp.now().toDate()` en comparaciones. Consistencia con servidor Firebase.

#### 3.2 Rutas hardcodeadas → `AppRoutes`
- **Archivos y cambios:**
  - `lib/features/tasks/presentation/task_detail_screen.dart:91` — `context.push('/task/$taskId/edit')` → `context.push(AppRoutes.editTask.replaceAll(':id', taskId))`
  - `lib/features/tasks/presentation/all_tasks_screen.dart:174` — `context.go('/task/${task.id}')` → `context.go(AppRoutes.taskDetail.replaceAll(':id', task.id))`
  - `lib/features/tasks/presentation/skins/all_tasks_screen_v2.dart:151` — `context.push('/tasks/${task.id}')` → idem con `AppRoutes.taskDetail`
  - `lib/features/tasks/presentation/skins/task_detail_screen_v2.dart:78` — `context.push('/tasks/${task.id}/edit')` → idem con `AppRoutes.editTask`
- **Nota:** los endpoints singulares (`/task/`) son bugs; ruta canónica es plural (`/tasks/`). Todos deben apuntar a las rutas registradas en `routes.dart`.

#### 3.3 Extraer `createMemberData` helper
- **Archivo nuevo:** `functions/src/homes/member_factory.ts`.
- **Firma:**
  ```typescript
  export function buildNewMemberDoc(params: {
    uid: string;
    nickname: string;
    role: 'owner' | 'admin' | 'member';
    photoUrl?: string;
    phone?: string;
    bio?: string;
  }): Record<string, unknown>
  ```
- **Retorna:** el objeto con todos los campos default (`tasksCompleted: 0`, `passedCount: 0`, `complianceRate: 1.0`, `currentStreak: 0`, `averageScore: 0`, `status: 'active'`, `joinedAt: FieldValue.serverTimestamp()`, `phoneVisibility: 'hidden'`, etc.).
- **Reemplazos:** `createHome` (L79-93), `joinHome` (L215-233), `joinHomeByCode` (L308-326) en `functions/src/homes/index.ts`.
- **Alcance:** refactor puro sin cambios funcionales. No se añaden ni eliminan campos.

## Pruebas a añadir

- `functions/src/homes/homes_callables.test.ts`: test de que `debugSetPremiumStatus` falla fuera del emulador (mock de `process.env.FUNCTIONS_EMULATOR`).
- Test nuevo en `functions/src/entitlement/`: idempotencia de `syncEntitlement` frente a doble invocación con mismo `chargeId`.
- Test nuevo en `functions/src/homes/`: `removeMember` y `leaveHome` con `currentPayerUid` y `premiumStatus: active` fallan con el código esperado.
- Test nuevo en `functions/src/tasks/`: `manualReassign` rechaza UID no-miembro y miembro frozen.

## Out of scope (tanda posterior)

- Validación real de recibos IAP contra App Store Connect / Google Play Developer API.
- Cerrar `allow read: if isAuth()` sobre `/users/{uid}`; crear subdocumento `public/profile` y migrar.
- Rate limiting en callables.
- Whitelist de campos (`hasOnly([...])`) en rules Firestore.
- Deprecar skins v1 o elegir única versión.
- Eliminar `_buildReceiptData` del cliente (depende de 1).
- Unit IDs de producción AdMob.

## Riesgos

- **AdMob en 4 pantallas:** altura del banner (50px) ocupa viewport. En pantallas densas podría reducir items visibles. Mitigado por `SizedBox.shrink()` cuando `!show`.
- **Protección del payer:** bloquea flujos de salida legítimos si el pagador quiere irse. El owner puede cancelar la suscripción primero (estado pasa a `cancelledPendingEnd`, sigue bloqueado hasta `premiumEndsAt`). **Aceptado por diseño** — alinea con la regla de negocio en CLAUDE.md.
- **Heurística de altura de item en Historial:** si el diseño cambia radicalmente, `kHistoryItemApproxHeight` queda desalineado y el umbral de 5 items se mide mal. Mitigación: constante bien documentada cerca del widget.
