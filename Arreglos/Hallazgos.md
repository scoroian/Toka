# Hallazgos nuevos — Toka

Registro de **errores o mejoras descubiertos mientras se implementan los arreglos** de `premortem.md`. No arregles aquí cosas fuera del alcance del prompt en curso (salvo que sean triviales y directamente relacionadas); anótalas para priorizarlas después.

## Cómo anotar

Añade una entrada por hallazgo con esta plantilla:

```
### H-NNN — <título corto>
- **Fecha:** AAAA-MM-DD
- **Descubierto durante:** Prompt NN (premortem.md)
- **Tipo:** bug | mejora | deuda técnica | falso positivo del premortem
- **Severidad:** 🔴 crítica | 🟠 alta | 🟡 media | 🟢 baja
- **Evidencia:** `archivo:línea` + 1 frase de qué ocurre
- **Cómo reproducir / verificar:** pasos (incluye dispositivo y cuenta si aplica)
- **Impacto:** por qué importa (negocio / usuario / técnico)
- **Sugerencia:** dirección de arreglo (sin implementarla aún)
- **Estado:** ⬜ sin abordar | 🔁 convertido en prompt | ✅ resuelto de paso
```

## Reglas
- Si el hallazgo invalida o matiza un prompt del premortem, enlázalo (p. ej. "afecta a Prompt 08").
- Si al verificar resulta que **un prompt del premortem era un falso positivo**, regístralo aquí como `Tipo: falso positivo del premortem` y marca el estado en `premortem.md` como 🟦.
- Numera correlativamente: H-001, H-002, …

---

<!-- Las entradas van debajo de esta línea -->

### H-001 — Test de reglas `homes.test.ts` "admin puede crear tareas" sembraba una tarea inválida
- **Fecha:** 2026-06-21
- **Descubierto durante:** Prompt 01 (premortem.md)
- **Tipo:** falso positivo del premortem (no) → deuda técnica (test obsoleto)
- **Severidad:** 🟢 baja
- **Evidencia:** `functions/test/rules/homes.test.ts` creaba `{title, status:'pending'}`; las reglas endurecidas de creación (`taskCreateKeysAllowed`/`taskCreateValuesAllowed`, ya en HEAD) exigen `status=='active'` + campos mínimos → el test fallaba con `PERMISSION_DENIED` **antes** de tocar nada (confirmado: la regla existe en `git show HEAD:firestore.rules`).
- **Cómo reproducir / verificar:** `firebase emulators:exec --only firestore "cd functions && npx jest test/rules/homes"` sobre HEAD → 1 test en rojo.
- **Impacto:** ruido en la suite de reglas; oculta regresiones reales. No es un bug de producto.
- **Sugerencia:** ya corregido de paso (payload válido `validTask()`), pues el fichero se tocaba en este prompt y debía quedar verde.
- **Estado:** ✅ resuelto de paso

### H-002 — Test `notification_prefs_repository_impl_test.dart` "savePrefs funciona aunque el documento no exista" contradecía el diseño
- **Fecha:** 2026-06-21
- **Descubierto durante:** Prompt 01 (premortem.md)
- **Tipo:** deuda técnica (test obsoleto)
- **Severidad:** 🟢 baja
- **Evidencia:** el test esperaba que `savePrefs` completara sin doc previo, pero `savePrefs` usa `.update()` **a propósito** (comentario en `notification_prefs_repository_impl.dart`: "Usa update() para evitar crear el documento... members/{uid} solo lo crea una Cloud Function"). `fake_cloud_firestore` lanza `not-found` → el test estaba en rojo **antes** de este prompt (savePrefs sin cambios respecto a HEAD).
- **Cómo reproducir / verificar:** `flutter test test/integration/features/notifications/notification_prefs_repository_impl_test.dart` sobre HEAD → 1 test en rojo.
- **Impacto:** ruido; el test afirmaba un comportamiento que viola las reglas (crear member doc desde cliente).
- **Sugerencia:** ya corregido de paso (ahora afirma que `savePrefs` falla sin doc, acorde al diseño).
- **Estado:** ✅ resuelto de paso

### H-003 — Orden de despliegue: las reglas restrictivas de invitations rompen el onboarding del cliente ANTIGUO
- **Fecha:** 2026-06-21
- **Descubierto durante:** Prompt 01 (premortem.md)
- **Tipo:** deuda técnica / riesgo de despliegue
- **Severidad:** 🟠 alta (si se despliega mal)
- **Evidencia:** el onboarding del cliente antiguo (`home_creation_repository_impl.dart`) hacía `collectionGroup('invitations')` para unirse por código. La nueva regla `allow list: if false` lo deniega. El cliente nuevo ya usa la callable `joinHomeByCode` (corregido en este prompt), pero **un usuario con la app vieja no podrá unirse por código en el onboarding** si se despliegan las reglas antes de la actualización de la app.
- **Cómo reproducir / verificar:** con la app actual en prod + reglas nuevas → onboarding "Unirse por código" devolvería permission-denied en el `collectionGroup`.
- **Impacto:** bloquea altas por código a usuarios no actualizados durante la ventana de rollout.
- **Sugerencia:** **orden de despliegue**: (1) desplegar functions (cambio compatible: `joinHomeByCode` ahora devuelve `{homeId}`, el resto igual), (2) publicar la app nueva y dar tiempo de adopción, (3) desplegar `firestore.rules`. Alternativa: forzar actualización mínima de la app. La otra ruta de unión (`HomesRepositoryImpl.joinHome` desde el selector de hogar) ya iba por callable y no se ve afectada.
- **Estado:** ⚠️ **LIVE en prod (2026-06-21)** — se desplegaron functions + reglas + app (en los 2 dispositivos de prueba) en el orden recomendado. **OJO:** las reglas restrictivas de invitations YA están en producción; si hay una **app publicada antigua** en la tienda, su onboarding "unirse por código" está roto hasta publicar la app nueva. Si Toka es pre-lanzamiento, sin impacto. Acción: **publicar la app nueva cuanto antes** o (si urge mantener compatibilidad) revertir temporalmente solo la regla de invitations a la versión previa (reabre la fuga (c)).

### H-004 — Deploy obligatorio para activar Premium de pago + secrets de store por configurar
- **Fecha:** 2026-06-21
- **Descubierto durante:** Prompt 02 (premortem.md)
- **Tipo:** deuda técnica / riesgo de despliegue
- **Severidad:** 🔴 crítica (monetización: sin esto no se cobra)
- **Evidencia:** tras el arreglo del #02, `syncEntitlement` opera por la ruta segura (verificación server-to-store) **solo si hay un verificador configurado** (`hasConfiguredVerifier`). En prod, sin los secrets `GOOGLE_PLAY_*` / `APP_STORE_*` y con `STRICT_RECEIPT_VALIDATION=true`, la callable se bloquea (`failed-precondition: store-receipt-validation-not-enabled`) → **nadie puede activar Premium**. La versión vieja sigue desplegada en `toka-dd241` hasta que se autorice el deploy.
- **Cómo reproducir / verificar:** llamar a `syncEntitlement` en prod sin secrets configurados → `failed-precondition`. En emulador (sin secrets) cae a inferencia (`storeVerified=false`) y activa Premium temporal pero sin plaza permanente.
- **Impacto:** la corrección **no cierra el #02 en producción** hasta (1) crear los secrets, (2) deploy autorizado de functions, (3) prueba sandbox en 2 dispositivos. Sin ello el #02 queda 🟧.
- **Sugerencia:** ver el bloque de cierre del Prompt 02 (lista de secrets + orden). Service account de Google Play con scope `androidpublisher`; clave .p8 de App Store Connect (issuer/key id). Considerar `defineSecret` de firebase-functions v2 en vez de env planas.
- **Estado:** 🔁 bloqueado esperando autorización de deploy a prod (parte del cierre del Prompt 02)

### H-005 — JWS de App Store: falta verificar la cadena x5c contra la raíz de Apple
- **Fecha:** 2026-06-21
- **Descubierto durante:** Prompt 02 (premortem.md)
- **Tipo:** deuda técnica (endurecimiento)
- **Severidad:** 🟡 media
- **Evidencia:** `store_verifiers.ts` `defaultAppStoreApiClient` decodifica los JWS de transacción/renovación con `decodeJwt` (solo payload) confiando en el canal TLS autenticado a `api.storekit.itunes.apple.com`, sin verificar la firma ES256 ni la cadena `x5c` contra la CA raíz de Apple.
- **Cómo reproducir / verificar:** revisión de código; la respuesta de Apple llega firmada (JWS) pero no se valida la firma localmente.
- **Impacto:** bajo en la práctica (la fuente es la API autenticada de Apple sobre TLS), pero best-practice exige verificar la cadena x5c para defensa en profundidad / cumplir la guía de Apple.
- **Sugerencia:** verificar la firma con la clave pública del leaf de `x5c` (`jose.compactVerify` + `importX509`) y validar la cadena hasta `Apple Root CA - G3`. Equivalente a usar `@apple/app-store-server-library`.
- **Estado:** ⬜ sin abordar

### H-006 — "Test espejo" en el cliente: `test/integration/features/subscription/sync_entitlement_test.dart`
- **Fecha:** 2026-06-21
- **Descubierto durante:** Prompt 02 (premortem.md)
- **Tipo:** deuda técnica (test que da confianza falsa)
- **Severidad:** 🟢 baja
- **Evidencia:** el test reimplementa la lógica de entitlement en una función local `simulateSyncEntitlement` contra `FakeFirebaseFirestore` (no ejercita la callable real ni el cliente). Su lista `isPremium = ['active','cancelled_pending_end','rescue']` está además desfasada respecto al valor canónico `cancelledPendingEnd`.
- **Cómo reproducir / verificar:** abrir el archivo; los tests pasan sin tocar `SubscriptionRepository` real.
- **Impacto:** cobertura ilusoria de la capa de ingresos en el cliente. No bloquea (la lógica real ya está cubierta por los tests de integración de functions contra el emulador).
- **Sugerencia:** sustituir por un test que mockee `FirebaseFunctions.httpsCallable('syncEntitlement')` y verifique que el repositorio envía el payload correcto (sin `chargeId`), o eliminarlo y confiar en la cobertura backend. No se tocó en este prompt para no salir de alcance.
- **Estado:** ⬜ sin abordar

### H-007 — El verificador deriva el plan del productId (`includes("annual")`); validar con el rediseño de monetización
- **Fecha:** 2026-06-21
- **Descubierto durante:** Prompt 02 (premortem.md)
- **Tipo:** deuda técnica / coordinación
- **Severidad:** 🟡 media
- **Evidencia:** `store_verifiers.ts` `planFromProductId` mapea a `annual`/`monthly` por substring del productId. El [rediseño de monetización 2026-06-21](../Monetizacion/) introduce tiers por tamaño + packs de miembros + Toka Plus, con nuevos productIds/planes que este mapeo no contempla.
- **Cómo reproducir / verificar:** revisión cruzada con los docs de `Monetizacion/` y `Arreglos/` del rediseño.
- **Impacto:** cuando aterricen los nuevos SKUs, `planFromProductId` (y el modelo de plan en el hogar) habrá que ampliarlos; afecta también al #14 (trial) y #06 (RTDN).
- **Sugerencia:** centralizar el catálogo de productIds→plan en una constante compartida cliente/backend y derivar de ahí; alinear con el rediseño antes de fijar SKUs en las consolas.
- **Estado:** ⬜ sin abordar

### H-008 — El guardrail `check-debug-premium.js` no protegía el flujo de deploy real
- **Fecha:** 2026-06-21
- **Descubierto durante:** Prompt 03 (premortem.md)
- **Tipo:** mejora / riesgo de despliegue
- **Severidad:** 🟠 alta
- **Evidencia:** `functions/package.json` tenía `"deploy": "firebase deploy --only functions"` **sin** el check; el guardrail `check:release-safety` solo estaba en `deploy:release`. El flujo realmente usado (`FUNCTIONS_DISCOVERY_TIMEOUT=120 firebase deploy --only functions`, ver memoria `deploy-functions-discovery-timeout`) saltaba el guard → la función `debugSetPremiumStatus` **y** la allowlist poblada llegaron a `toka-dd241`.
- **Cómo reproducir / verificar:** antes del fix, `npm run deploy` no ejecutaba `node scripts/check-debug-premium.js`.
- **Impacto:** el control que debía impedir que el bypass de Premium llegara a prod era inefectivo (control de seguridad cosmético).
- **Sugerencia:** ya aplicado de paso — `deploy` ahora encadena `check:release-safety && build && deploy`. Mejora futura: que el guardrail también escanee el bundle compilado `lib/` y/o un hook de CI/pre-push; `firebase deploy` directo (sin `npm`) lo sigue saltando, así que el control fuerte es que el código ya no exista.
- **Estado:** ✅ resuelto de paso

### H-009 — `debugSetPremiumStatus` sigue VIVA en prod hasta el deploy autorizado (env horneada)
- **Fecha:** 2026-06-21
- **Descubierto durante:** Prompt 03 (premortem.md)
- **Tipo:** riesgo de despliegue
- **Severidad:** 🔴 crítica (mientras siga desplegada)
- **Evidencia:** `firebase functions:list --project toka-dd241` muestra `debugSetPremiumStatus` (callable v2) desplegada. El código ya se eliminó en el working tree, pero el deploy a prod requiere autorización explícita (protocolo). **Matiz crítico:** vaciar `DEBUG_PREMIUM_ALLOWED_UIDS` en `.env.toka-dd241` **no** cambia la función ya desplegada — las env vars se hornean en cada deploy — así que el uid `lJp9DG6dUObxcPkGzxil7AXhSMt2` **puede forzar Premium en prod AHORA mismo** (sin App Check) hasta que se haga un nuevo deploy.
- **Cómo reproducir / verificar:** `firebase functions:list --project toka-dd241`; la función aparece. Tras el deploy autorizado debe desaparecer.
- **Impacto:** el camino de bypass de Premium sigue activo en producción hasta el deploy. Eleva la urgencia: el fix no cierra el #03 en prod sin desplegar.
- **Sugerencia:** deploy autorizado de functions (la build ya no incluye la función → se retira) + `firebase functions:list` para confirmar. Mientras tanto, si urge mitigar sin deploy completo, se puede re-desplegar para hornear la allowlist vacía, pero lo correcto es retirar la función.
- **Estado:** ✅ resuelto (2026-06-21) — el usuario autorizó deploys en desarrollo; se retiró con `firebase functions:delete debugSetPremiumStatus --region us-central1 --project toka-dd241 --force`. Verificado: `firebase functions:list` ya no la muestra y `POST` al endpoint devuelve **404** (vs `createHome` → 401). Se usó borrado quirúrgico (no `deploy` completo) porque los secrets del #02 no existen en prod (habría bloqueado `syncEntitlement`).

### H-010 — Los `*.test.ts` se compilan a `lib/` y entran en el bundle desplegado
- **Fecha:** 2026-06-21
- **Descubierto durante:** Prompt 03 (premortem.md)
- **Tipo:** deuda técnica (higiene de bundle)
- **Severidad:** 🟢 baja
- **Evidencia:** `tsc` compila también los `*.test.ts` → `lib/**/*.test.js` (p. ej. `lib/homes/homes_callables.test.js`, `lib/homes/debug_premium_removed.test.js`). `firebase deploy` sube `lib/` entero. Los `.test.js` no se registran como funciones (no los `require` `index.js`), pero engordan el bundle y suben código de test a producción.
- **Cómo reproducir / verificar:** `ls functions/lib/**/*.test.js` tras `tsc`.
- **Impacto:** bajo (no son endpoints); higiene/peso del bundle y superficie innecesaria en prod.
- **Sugerencia:** excluir tests de la compilación de despliegue (`tsconfig.build.json` con `"exclude": ["**/*.test.ts"]`) o ignorarlos en el deploy (`firebase.json` → `functions.ignore: ["**/*.test.js"]` / `.gcloudignore`).
- **Estado:** ⬜ sin abordar

### H-011 — Fotos huérfanas en Storage de cuentas borradas ANTES del fix #04 (token de descarga salta las rules)
- **Fecha:** 2026-06-21
- **Descubierto durante:** Prompt 04 (premortem.md)
- **Tipo:** privacidad / backfill pendiente
- **Severidad:** 🟠 alta
- **Evidencia:** hasta el #04, `cleanupDeletedUser` nunca borraba el objeto `users/{uid}/profile.jpg` de Cloud Storage. El `photoUrl` denormalizado en `homes/{h}/members/{uid}` es una *download URL tokenizada* (`getDownloadURL()`), y esos tokens **saltan las Storage rules** (`allow read: if request.auth.uid == uid` no protege a quien ya tiene la URL). Por tanto, cualquier co-miembro con un snapshot antiguo puede seguir viendo la foto de un usuario ya borrado **indefinidamente**.
- **Cómo reproducir / verificar:** para un `uid` con cuenta Auth inexistente, comprobar si existe `users/{uid}/profile.jpg` en el bucket y si su download URL (en algún member doc) sigue devolviendo 200.
- **Impacto:** PII (foto de rostro) accesible tras el borrado para cuentas eliminadas antes del fix. El fix #04 lo cierra **de aquí en adelante**, no retroactivamente.
- **Sugerencia:** backfill — barrer `users/*/` en Storage y borrar los prefijos cuyo `uid` ya no exista en Firebase Auth (análogo a `qa_scrub_member_pii.js` pero sobre Storage). Requiere autorización para prod.
- **Estado:** ⬜ sin abordar (backfill); el fix de borrado en caliente ya está implementado y testeado.

### H-012 — `data-model.md`: el doc de reseña usa `byUid`, pero el código escribe `reviewerUid`/`performerUid`
- **Fecha:** 2026-06-21
- **Descubierto durante:** Prompt 04 (premortem.md)
- **Tipo:** deriva de documentación
- **Severidad:** 🟢 baja
- **Evidencia:** `architecture/data-model.md` (`homes/{h}/taskEvents/{ev}/reviews/{uid}`) declara el campo `byUid`, pero `functions/src/tasks/submit_review.ts` escribe `{ reviewerUid, performerUid, score, note, createdAt }` (sin `byUid`). El código manda: el export del #04 filtra por `reviewerUid`. Una doc desactualizada podría inducir a futuras queries a usar `byUid` (que no existe) y devolver vacío.
- **Cómo reproducir / verificar:** comparar `data-model.md:209-217` con `submit_review.ts:94-100`.
- **Impacto:** bajo; riesgo de queries erróneas basadas en la doc.
- **Sugerencia:** actualizar `data-model.md` a `reviewerUid`/`performerUid` (no lo toco fuera de alcance del #04).
- **Estado:** ⬜ sin abordar

### H-013 — `collectionGroup` de igualdad sobre un solo campo exige índice COLLECTION_GROUP explícito en prod (no auto-creado)
- **Fecha:** 2026-06-21
- **Descubierto durante:** Prompt 04 (premortem.md), PASO 4 de verificación en prod
- **Tipo:** bug (encontrado y corregido) / nota de plataforma
- **Severidad:** 🟠 alta (rompía la callable en prod)
- **Evidencia:** la 1ª invocación de `exportUserData` en `toka-dd241` devolvió `functions/internal`. Los logs (`firebase functions:log`) mostraron `code 9: The query requires a COLLECTION_GROUP_ASC index for collection reviews and field reviewerUid`. Mi supuesto de que "un `collectionGroup().where('campo','==',x)` lo sirve el índice de campo único automático" es **falso**: el scope COLLECTION_GROUP de campo único NO se auto-crea; hay que declararlo (los índices automáticos son COLLECTION). El emulador no lo exige, así que pasó los tests de integración y solo se vio en prod.
- **Cómo reproducir / verificar:** una callable/función con `db.collectionGroup('X').where('f','==',v)` sin el `fieldOverride` correspondiente → `FAILED_PRECONDITION` en prod (no en emulador).
- **Impacto:** cualquier query collectionGroup nueva puede romper SOLO en producción aunque los tests de emulador estén verdes. Lección: validar collectionGroup contra prod (o declarar el índice por adelantado).
- **Sugerencia / arreglo aplicado:** (a) `fieldOverride` para `reviews.reviewerUid` con `queryScope: COLLECTION_GROUP` en `firestore.indexes.json` (desplegado); (b) defensa en profundidad: la query va en try/catch en `export_user_data.ts` (`reviewsAuthoredError`) para que un índice ausente/en construcción no tumbe todo el export. Regla general para el futuro: declarar el índice COLLECTION_GROUP en el mismo PR que introduce la query.
- **Estado:** ✅ resuelto (2026-06-21)

### H-014 — Cierre del #05 bloqueado por ausencia de unit IDs reales de AdMob (pre-release)
- **Fecha:** 2026-06-21
- **Descubierto durante:** Prompt 05 (premortem.md), PASO 4
- **Tipo:** prerrequisito de release / bloqueo de verificación
- **Severidad:** 🟠 alta (impide pasar el #05 a ✅)
- **Evidencia:** el mecanismo de inyección de unit IDs reales por plataforma está implementado y probado (unit + integración en emulador 2/2 + guardrail), pero **no existe todavía una cuenta AdMob real ni unit IDs reales** (la app es pre-lanzamiento). Por eso `.env.toka-dd241` deja `ADMOB_BANNER_UNIT_*` vacíos (fallback a test, seguro en dev) y la afirmación del PASO 4 "adFlags.bannerUnit es el real" es **inalcanzable** hoy. Además, en build debug el cliente sirve SIEMPRE los test IDs (rama `kDebugMode` en `ad_banner.dart`), y una build release serviría anuncios reales (que no se deben clicar), así que **no hay configuración de dispositivo que demuestre el unit real por plataforma de forma segura** ahora mismo. La validación correcta del backend (escritura del dashboard) se hizo en el **emulador Firestore**.
- **Cómo reproducir / verificar:** `secrets/qa_inspect_home.js` sobre un hogar Free en prod muestra `adFlags.bannerUnit` = test ID (prod corre el código viejo y, tras desplegar, seguiría siendo test mientras `ADMOB_BANNER_UNIT_*` estén vacíos).
- **Impacto:** el #05 queda 🟧 hasta tener IDs reales. El riesgo de ingresos cero persiste en una hipotética release hasta configurar los IDs.
- **Checklist de release para cerrar en ✅:** (1) crear cuenta/app AdMob y obtener los banner unit IDs reales de Android e iOS; (2) en el `.env.<proyectoProd>` poner `ADMOB_BANNER_UNIT_ANDROID`, `ADMOB_BANNER_UNIT_IOS` y `TOKA_REQUIRE_REAL_AD_UNITS=true` (el guardrail `check-ad-units.js` bloqueará el deploy si faltan o son de prueba); (3) deploy autorizado de functions; (4) verificación dual en físico+emulador (cuentas distintas, mismo hogar Free) de que el banner aparece y `adFlags.bannerUnit{Android,Ios}` son los reales (extender `qa_inspect_home.js` para volcar `views/dashboard.adFlags`), y que un hogar Premium NO muestra banner. Build release de verificación: confirmar el unit servido **sin clicar** el anuncio.
- **Estado:** 🟧 mecanismo hecho y testeado; cierre pendiente de IDs reales + deploy autorizado.

### H-015 — `RemoteConfigService` cliente tiene claves `ad_banner_unit_android/ios` pero están MUERTAS (no se leen)
- **Fecha:** 2026-06-21
- **Descubierto durante:** Prompt 05 (premortem.md), PASO 1
- **Tipo:** código muerto / decisión de arquitectura pendiente
- **Severidad:** 🟢 baja
- **Evidencia:** `lib/shared/services/remote_config_service.dart` define defaults y getters `adBannerUnitAndroid`/`adBannerUnitIos` (claves RC `ad_banner_unit_android`/`ios`), y `init()` se llama en `main.dart`/`main_dev.dart`, pero **ningún consumidor lee esos getters** (grep). El banner real se sirve por el **dashboard** (`adFlags.bannerUnit*`), que es la vía que parametrizó el #05. La de Remote Config quedó como scaffold dormido.
- **Impacto:** confusión (dos mecanismos posibles para lo mismo); riesgo de que alguien cablee RC y entre en conflicto con la vía del dashboard.
- **Resolución (2026-06-21, a petición del usuario):** se **cableó Remote Config** como fuente del unit ID para poder cambiar el id del anuncio **sin redesplegar**. Nuevo `remoteBannerAdUnitsProvider` (en `ad_banner_config_provider.dart`) que lee `RemoteConfigService.adBannerUnitAndroid/Ios` (claves RC `ad_banner_unit_android`/`ios`) — esos getters dejan de estar muertos. `adBannerConfigProvider` aplica esta **precedencia** del unit: (1) **Remote Config** (consola, sin redeploy) → (2) `dashboard.adFlags.bannerUnit{Android,Ios}` (inyectado por backend desde env, con guardrail `check-ad-units.js`) → (3) test IDs (debug/vacío, en `ad_banner.dart`). El show/hide sigue siendo server-authoritative (`premiumFlags.showAds` + `adFlags.showBanner`). Tests: `ad_banner_config_provider_test.dart` añade casos de precedencia RC→dashboard (11/11). **Para cambiar el id en producción:** crear/editar los parámetros `ad_banner_unit_android` / `ad_banner_unit_ios` en la consola de Firebase Remote Config (defaults en código = `''` → fallback seguro). **Propagación INSTANTÁNEA (2026-06-21):** se cableó Remote Config **en tiempo real** — `RemoteConfigService.onConfigUpdated` + `activate()`, y el provider hace `ref.invalidateSelf()` al recibir un cambio, así que con la app abierta el banner recarga el nuevo unit **sin reiniciar**. Además `minimumFetchInterval` bajó de 1h a **1 min** (refresco rápido en el siguiente arranque/fetch). Caveat: el tiempo real requiere la app en primer plano y con conexión; si no, el cambio entra en el siguiente fetch/arranque.
- **Estado:** ✅ resuelto (2026-06-21) — RC en tiempo real como fuente primaria con fallback al dashboard.

### H-016 — `full_user_flow.test.ts` (integración) está stale: espera `completedCount`, el código migró a `completedCount90d`
- **Fecha:** 2026-06-21
- **Descubierto durante:** Prompt 05 (premortem.md), al correr la suite de integración (regresión)
- **Tipo:** test desactualizado (pre-existente, ajeno al #05)
- **Severidad:** 🟡 media (3 tests rojos en la suite de integración)
- **Evidencia:** `apply_task_completion.ts` ahora incrementa `completedCount90d` y hace `completedCount: FieldValue.delete()` (línea ~165), pero `test/integration/full_user_flow.test.ts` (pasos 6/10/12) asserta `members/{uid}.completedCount === 1` → `undefined`. `apply_task_completion.ts` **no** está en el diff del #05; el fallo ya existía en esta rama WIP.
- **Cómo reproducir / verificar:** `npm run test:integration -- full_user_flow` con el emulador → 3 fallos en `completedCount`.
- **Impacto:** ruido en CI/local; no es un bug de producto (el campo se migró a propósito).
- **Sugerencia:** actualizar el test a `completedCount90d` (y/o leer la métrica de compliance que sí persiste). Fuera de alcance del #05.
- **Estado:** ✅ resuelto en el #10 (2026-06-22). El campo canónico real es **`tasksCompleted`** (no `completedCount90d`, que es el contador de 90 días): `apply_task_completion.ts` escribe `tasksCompleted` y borra `completedCount`. Los pasos 6/10/12 de `full_user_flow.test.ts` se actualizaron a `tasksCompleted`; suite de integración **146/146** en verde.

### H-017 — Cierre del #06 bloqueado por infra de stores (RTDN/ASSN no verificables en prod aún)
- **Fecha:** 2026-06-21
- **Descubierto durante:** Prompt 06 (premortem.md), PASO 4
- **Tipo:** prerrequisito de release / bloqueo de verificación
- **Severidad:** 🟠 alta (impide pasar el #06 a ✅)
- **Evidencia:** la reconciliación con stores (handlers RTDN/ASSN + revoke de plaza + downgrade de `active` vencido) está implementada y probada (unit 299/299 + integración de emulador de reconciliación + verificación dual en dispositivos del resultado Free/ads/sync). Pero los **nuevos handlers no se pueden verificar end-to-end en prod**: (i) `googlePlayRtdnHandler` enlaza el secret `GOOGLE_PLAY_SA_JSON` para re-verificar el recibo, y ese secret —junto con `APP_STORE_PRIVATE_KEY`— **no existe en `toka-dd241`** (es el mismo bloqueo del #02, ver H-009); (ii) no hay **topic Pub/Sub de RTDN** configurado en Google Play Console; (iii) no hay **URL de webhook ASSN** configurada en App Store Connect; (iv) la app es **pre-lanzamiento**, sin suscripciones reales que reembolsar/renovar.
- **Cómo reproducir / verificar:** un `firebase deploy --only functions:googlePlayRtdnHandler` fallaría/bloquearía igual que `syncEntitlement` por el `defineSecret("GOOGLE_PLAY_SA_JSON")` ausente en prod (mismo escollo que H-009).
- **Impacto:** el #06 queda 🟧 hasta tener la infra de stores. Mientras tanto, el **cron de downgrade ampliado** (captura `active` vencido) SÍ es desplegable sin secretos de store y es la red de seguridad principal contra el "Premium gratis perpetuo".
- **Checklist de cierre en ✅:** (1) cerrar el #02 (subir `GOOGLE_PLAY_SA_JSON` y `APP_STORE_PRIVATE_KEY` a Secret Manager de prod); (2) crear el **topic Pub/Sub** y configurarlo en Play Console → Monetization → Real-time developer notifications, con `GOOGLE_RTDN_TOPIC` igual al nombre del topic; (3) desplegar `googlePlayRtdnHandler` + `appStoreServerNotificationsHandler` (+ el cron actualizado); (4) pegar la **URL del webhook** que imprime `firebase deploy` para `appStoreServerNotificationsHandler` en App Store Connect → App Information → App Store Server Notifications (Sandbox primero); (5) con **sandbox de la store**, comprar→renovar→reembolsar y verificar dual (físico + emulador) que el hogar pasa a Premium, se extiende en renovación, y en refund baja a Free + se revoca la plaza (`lifetimeUnlockedHomeSlots` decrementa); confirmar con `qa_premium.js`/`qa_inspect_home.js`.
- **Estado:** 🟧 implementado y probado (emulador + dispositivos); cierre pendiente de infra de stores + deploy autorizado.

### H-018 — App Store Server Notifications v2 son webhook HTTPS, no Pub/Sub (desviación deliberada del prompt #06)
- **Fecha:** 2026-06-21
- **Descubierto durante:** Prompt 06 (premortem.md), PASO 2
- **Tipo:** decisión de arquitectura / aclaración de mecanismo
- **Severidad:** 🟢 baja
- **Evidencia:** el prompt #06 pedía "Endpoint Pub/Sub (onMessagePublished) para RTDN de Google **y otro** para App Store Server Notifications v2". Pero Apple **no** entrega las ASSN v2 por Cloud Pub/Sub: las envía como **POST HTTPS** de un `signedPayload` (JWS firmado por Apple) a una URL que configuras en App Store Connect. Implementarlo como `onMessagePublished` crearía una función escuchando un topic al que Apple nunca publica → muerta. Por eso `appStoreServerNotificationsHandler` es `onRequest` (webhook HTTPS), que es el mecanismo correcto. Google RTDN sí es Pub/Sub (`googlePlayRtdnHandler` = `onMessagePublished`), conforme al prompt. La **lógica de reconciliación es idéntica** para ambos (módulo `reconcile_entitlement`); solo cambia el adaptador de entrada.
- **Impacto:** ninguno negativo; es la implementación correcta. Documentado en el header de `app_store_notifications.ts`.
- **SEGURIDAD (corregido tras review automático):** el webhook ASN es un endpoint HTTPS **público** (cualquiera puede hacer POST). La primera versión del handler **confiaba en el cuerpo JWS** (lo decodificaba y aplicaba el estado), lo que abría un vector: un `DID_RENEW` forjado podía **extender Premium gratis**, y un `REFUND` forjado podía quitárselo a un tercero (griefing). **Arreglo:** el handler ya **NUNCA confía en el cuerpo** — lo usa solo como disparador y **re-verifica el estado real contra la App Store Server API** (`verifyAppStore`), igual que el path de Google RTDN re-verifica contra Google Play. Un POST forjado dispara una re-verificación que devuelve la verdad de Apple → no puede conceder ni revocar Premium. Sin verificador configurado, ignora el cuerpo (no cambia nada). Tests de regresión de seguridad en `entitlement_reconciliation.test.ts` (REFUND forjado pero Apple activo → no revoca; sin verificador → no extiende).
- **Endurecimiento pendiente (menor):** verificar además la **firma x5c** del JWS contra la raíz de Apple (mismo criterio diferido que `store_verifiers.ts`) para descartar payloads no firmados antes incluso de re-verificar; defensa en profundidad sobre el filtro de `bundleId` (la corrección de re-verificación ya neutraliza el impacto de un payload forjado). Recomendado antes de producción real.
- **Estado:** ✅ resuelto (mecanismo correcto + re-verificación que cierra el vector de Premium gratis/griefing) — x5c pendiente como endurecimiento menor.

### H-019 — Faltaba el índice compuesto `homes(premiumStatus, premiumEndsAt)`: el cron de downgrade Y el de rescate fallaban en CADA ejecución en prod
- **Fecha:** 2026-06-21
- **Descubierto durante:** Prompt 06 (premortem.md), PASO 4 / despliegue del cron
- **Tipo:** bug de producción (pre-existente) — índice ausente
- **Severidad:** 🟠 alta (rompía el downgrade automático en prod → causa raíz adicional del "Premium gratis perpetuo")
- **Evidencia:** al desplegar `applyDowngradeJob` y consultar prod con el Admin SDK, la query del cron `homes.where('premiumStatus','in',[...]).where('premiumEndsAt','<=',now)` devolvió `9 FAILED_PRECONDITION: The query requires an index`. Los logs de prod confirmaron que **`applyDowngradeJob` (cada 30 min) y `openRescueWindow` (diario 09:00) llevaban fallando en TODAS sus ejecuciones** con ese error (ej. `applydowngradejob` 15:30/16:00 y `openrescuewindow` 2026-06-17 09:00). El índice compuesto `homes(premiumStatus ASC, premiumEndsAt ASC)` **no estaba en `firestore.indexes.json`**. El **emulador NO exige índices compuestos**, así que los tests de integración pasaban en verde y el fallo solo existía en prod (mismo patrón que [[collectiongroup-index-prod-only]] H-013, pero con índice compuesto de colección normal, no collectionGroup).
- **Impacto:** **el downgrade automático NUNCA ocurría en producción** desde que existe el cron → hogares cancelados/rescate/`active` vencidos se quedaban en Premium efectivo (refuerza el síntoma central del #06); además la ventana de rescate (`openRescueWindow`) tampoco se abría. Silencioso: el error se logueaba pero no alertaba ni afectaba a la UI.
- **Cómo reproducir / verificar:** cualquier query con `in` sobre un campo + rango (`<=`/`<`/`>`) sobre otro exige índice compuesto; el emulador lo ignora. `firebase functions:log --only applyDowngradeJob` mostraba el `FAILED_PRECONDITION` recurrente.
- **Arreglo aplicado:** añadido el índice `homes(premiumStatus, premiumEndsAt)` a `firestore.indexes.json` y desplegado (`firebase deploy --only firestore:indexes --project toka-dd241`). Tras construirse, la query del cron pasó de error a `0 elegibles`. **Verificación funcional en prod:** un hogar desechable `active`+vencido fue degradado a `restorable` (+ Free limits + ads ON + tareas excedentes congeladas) por el cron en su siguiente ejecución programada (18:30 UTC). El mismo índice arregla `openRescueWindow` (misma forma de query).
- **Lección (general):** declarar el índice compuesto en `firestore.indexes.json` **en el mismo PR** que introduce una query `in`+rango (o cualquier compuesta). Validar contra prod o revisar logs de funciones programadas tras desplegar, porque el emulador da falsos verdes.
- **Estado:** ✅ resuelto (2026-06-21) — índice desplegado y cron verificado en prod.

### H-020 — `pass_task_turn.test.ts` (integración) "miembro absent excluido del siguiente turno" en rojo (pre-existente, ligado al #09)
- **Fecha:** 2026-06-21
- **Descubierto durante:** Prompt 07 (premortem.md), al correr la suite de integración completa (regresión)
- **Tipo:** test/lógica desactualizada (pre-existente, ajeno al #07)
- **Severidad:** 🟡 media (1 test rojo en la suite de integración)
- **Evidencia:** `test/integration/pass_task_turn.test.ts` "miembro absent excluido del siguiente turno" espera `result.noCandidate === true` (el siguiente del orden `[MEMBER_A, 'member-absent']` debería saltarse al ausente y volver a MEMBER_A) pero recibe `false`. `pass_task_turn.ts`, `pass_turn_helpers.ts` y `shared/vacation.ts` **no** están en mi diff del #07 (git status limpio para esos archivos). El fallo es de la lógica de exclusión de miembros ausentes al pasar turno, que es exactamente el ámbito del **Prompt 09 (Vacaciones penaliza a los ausentes, ⬜ pendiente)**.
- **Cómo reproducir / verificar:** `npm run test:integration -- pass_task_turn` con el emulador → 1 fallo en "absent excluido".
- **Impacto:** ruido en CI/local; será abordado y verificado al ejecutar el #09 (donde encaja). No es regresión del #07.
- **Resolución (2026-06-22, en el #09):** era un **FALSO POSITIVO de producción / fixture de test incorrecto**. El test fijaba al ausente con `addMemberToHome(..., 'absent')` (campo `status:'absent'`), pero `isMemberCurrentlyAbsent` **ignora `status:'absent'` a propósito** (las Firestore rules no dejan denormalizar ese estado) y solo lee el campo `vacation`. El `pass_task_turn.ts` de producción ya excluía bien a los ausentes. Arreglado el fixture para usar un objeto `vacation` activo (`isActive:true`, `startDate` ayer, sin fin) + `import admin`; ahora el test pasa. Verificado: suite `pass_task_turn` 100% verde.
- **Estado:** ✅ resuelto (fixture corregido en el #09; no había bug de producción)

### H-021 — `recurrence_order_test.dart` desactualizado: espera 5 elementos sin `oneTime`, el código ya tiene 6 con `oneTime`
- **Fecha:** 2026-06-21
- **Descubierto durante:** Prompt 07 (premortem.md), al correr `flutter test test/unit/features/tasks` (regresión)
- **Tipo:** test desactualizado (pre-existente, ajeno al #07)
- **Severidad:** 🟢 baja (2 tests rojos, el CÓDIGO es el correcto)
- **Evidencia:** `lib/features/tasks/domain/recurrence_order.dart` define `RecurrenceOrder.all = ['oneTime','hourly','daily','weekly','monthly','yearly']` (6 elementos; el comentario explica que sin `'oneTime'` las tareas Puntuales se agrupaban pero NUNCA se renderizaban en Hoy → fix legítimo). Pero `test/unit/features/tasks/recurrence_order_test.dart` aún asserta `length === 5` y la lista sin `oneTime`. `recurrence_order.dart` y su test **no** están en mi diff del #07.
- **Cómo reproducir / verificar:** `flutter test test/unit/features/tasks/recurrence_order_test.dart` (con el Flutter de Windows; el de WSL no resuelve el package_config de Windows) → 2 fallos.
- **Impacto:** ruido en CI/local; el test miente, el código es correcto. Arreglo trivial: actualizar el test a 6 elementos con `'oneTime'` primero. Fuera de alcance del #07.
- **Estado:** ⬜ sin abordar

### Nota de entorno (Prompt 07) — la suite de integración necesita el emulador de **Storage** además de Firestore
- `cleanup_user.test.ts` (#04, GDPR) borra la foto en Cloud Storage; si se arranca el emulador con `--only firestore` sus 4 tests fallan por entorno (no es regresión). Arrancar siempre `firebase emulators:start --only firestore,auth,storage` para la suite de integración. Verificado en el #07: con Storage activo `cleanup_user` pasa 100%.

### H-022 — Matices de diseño de vacaciones (#09): vacación con inicio FUTURO no dispara reasignación eager + el cron no deja rastro en historial
- **Fecha:** 2026-06-22
- **Descubierto durante:** Prompt 09 (premortem.md), al diseñar las dos capas del arreglo.
- **Tipo:** límite de cobertura conocido + posible mejora de UX (no es bug).
- **Evidencia / detalle:**
  1. **Vacación con `startDate` futura:** el trigger `onMemberVacationStart` actúa en la transición presente→ausente, que detecta vía un *write* del doc de miembro. Si el miembro programa una vacación que empieza dentro de unos días, en ese momento `isMemberCurrentlyAbsent(after)` es `false` (aún no cubre hoy) → el trigger NO reasigna. Cuando llega la fecha de inicio **no hay write** del doc de miembro, así que el trigger tampoco salta. **Mitigación ya implementada:** la **capa B** (cron `processExpiredTasks`) cubre exactamente ese caso — cuando una tarea del ausente vence durante la ausencia, la rueda hacia un presente y NO penaliza. Así que la propiedad "no penalizado / no conserva tareas que vencen" se mantiene, pero la reasignación de esas tareas es *lazy* (al vencer) en lugar de *eager* (al activar). Mejora futura: un cron ligero que al cruzar `startDate` reasigne, o reasignar al programar.
  2. **El cron, al saltar la penalización del ausente, NO emite ningún `taskEvent`** (ni `missed` ni otro). Es lo correcto (no fue un incumplimiento), pero deja el historial sin rastro de "esta tarea se reasignó porque X estaba de vacaciones". Mejora futura opcional: un tipo de evento `auto_reassigned_vacation` (penaltyApplied:false) para transparencia en Historial. El cliente (`task_event.dart`) hoy solo mapea `completed`/`passed`/`missed`.
- **Impacto:** ninguno funcional (las dos propiedades del objetivo se cumplen); solo UX/observabilidad.
- **Estado:** ⬜ anotado (fuera de alcance del #09; candidato a backlog).

### H-023 — La hora mostrada de una tarea usa la zona del DISPOSITIVO, no la de la regla (`recurrenceRule.timezone`)
- **Fecha:** 2026-06-22
- **Descubierto durante:** Prompt 10 (premortem.md), PASO 4 (verificación dual).
- **Tipo:** presentación del cliente (no es bug de cálculo).
- **Evidencia:** la misma tarea "09:00 Europe/Madrid" (instante `nextDueAt=…T07:00Z` en CEST) se mostró como **"Hoy 09:00"** en el físico (zona Madrid) y como **"Hoy 07:00"** en el emulador (reloj en UTC); el sello "Completada por Sol" salía "08:44" vs "06:44". El **cálculo backend es correcto** (el instante es idéntico en ambos dispositivos, derivado tz-aware de la regla); lo que varía es que el cliente **formatea el instante en la zona local del dispositivo**, no en `recurrenceRule.timezone`. Para un hogar cuyos miembros están en husos distintos, una tarea definida "a las 09:00 de Madrid" se verá a otra hora para quien esté en otro huso.
- **Impacto:** posible confusión cross-zona; sin efecto en el reparto ni en cuándo vence realmente la tarea. Para hogares mono-huso (el caso común) no se nota.
- **Sugerencia:** decidir el contrato de producto: (a) mostrar siempre la hora en la zona de la regla (coherente con cómo se definió), o (b) mostrar la hora local del dispositivo (coherente con el reloj del usuario) e indicar la zona cuando difiera. Fuera de alcance del #10 (que es el cálculo backend).
- **Estado:** ⬜ anotado (candidato a backlog de UX i18n).

### H-024 — `passTaskTurn` penaliza (`passedCount++`, `penaltyApplied=true`) incluso cuando `noCandidate=true` (no hay a quién pasar)
- **Fecha:** 2026-06-22
- **Descubierto durante:** Prompt 11 (premortem.md), PASO 1 (verificación).
- **Tipo:** regla de negocio cuestionable (no es un bug de cálculo).
- **Evidencia:** `functions/src/tasks/pass_task_turn.ts` crea SIEMPRE el evento `passed` con `penaltyApplied:true` e incrementa `passedCount` del actor, también cuando `getNextEligibleMember` devuelve el propio uid (`noCandidate=true`: único miembro, o todos los demás `frozen`/ausentes/`left`). Es decir, si un usuario "pasa turno" pero **se queda con la tarea** (nadie a quien pasársela), igualmente se lleva la penalización estadística. El test de integración `pass_task_turn.test.ts` confirma `noCandidate=true` + `toUid=actor`, y el evento se marca penalizado.
- **Impacto:** percepción de injusticia (justo el tema del #11): penalizar por intentar pasar cuando el sistema no ofrece alternativa puede sentirse arbitrario. Tras el arreglo del #11(a), el diálogo ahora muestra el aviso de penalización JUNTO al texto "No hay otro miembro disponible, seguirás siendo el responsable", lo que hace el caso más visible (el usuario ve que se penalizará aunque no pase a nadie) — bueno para la transparencia, pero expone la pregunta de producto.
- **Sugerencia:** decidir si en `noCandidate` se debe (a) no penalizar (no crear evento `passed` ni incrementar `passedCount`, solo informar de que no hay candidato), o (b) seguir penalizando como acción explícita. Si se opta por (a), el cliente debería ocultar el botón "Pasar" o el aviso cuando no hay candidato. **Fuera de alcance del #11**, que solo cubre la VISIBILIDAD de la penalización y el no-reinicio de la rotación al editar.
- **Estado:** ⬜ anotado (candidato a decisión de producto).

### H-025 — `MemberActions.demoteFromAdmin`/`revokeInvitation` aún tragan errores con `AsyncValue.guard` (sin feedback)
- **Fecha:** 2026-06-22
- **Descubierto durante:** Prompt 12 (premortem.md), al arreglar el feedback del tope de admins.
- **Tipo:** gap menor de UX (no es bug funcional).
- **Evidencia:** en `member_actions_provider.dart`, `transferOwnership` y `promoteToAdmin` ya NO usan `AsyncValue.guard` (relanzan, para que la UI muestre payer-lock / tope de admins). Pero `demoteFromAdmin` y `revokeInvitation` siguen con `guard`, que captura la excepción en `state` y **no la relanza**: si la callable falla (permisos, red), la UI no recibe excepción y no muestra snackbar. Mismo patrón que causó el "falso éxito" del payer-lock (regresión #12 QA 2026-06-16) y el botón de invitar muerto.
- **Impacto:** bajo — degradar/revocar fallido pasa desapercibido para el usuario; ambos son acciones de owner/admin poco frecuentes y normalmente exitosas.
- **Sugerencia:** unificar el patrón (rethrow + try/catch en la UI con snackbar) en `demoteFromAdmin` y `revokeInvitation`, como ya se hizo con transferOwnership/promoteToAdmin. Trivial pero fuera de alcance del #12 (que solo necesitaba el feedback del tope en promote).
- **Nota relacionada:** existen DOS superficies para "salir del hogar" — `home_settings_screen_v2.dart` (arreglada en el #12) y la pestaña Ajustes `settings_screen.dart` (que ya enrutaba al owner a "transferir y salir" vía `_transferAndLeave`, QA previa 🟠-2). Ambas tratan ahora correctamente al owner. Además, `toka_qa_session/QA_SESSION.md` está DESFASADO sobre qué cuentas pertenecen a qué hogar (el hogar de QA real verificado es `mAJXlAhwRV1kdy4O05hG` "Hogar Real QA": Sol owner, Luna admin, Tres member; las cuentas `toka.sync.*`, no `toka.qa.*`).
- **Estado:** ⬜ anotado (candidato a backlog trivial).

### H-026 — `lib/core/utils/smart_assignment_calculator.dart` es código MUERTO (sin usos) y duplica la lógica vieja del reparto
- **Fecha:** 2026-06-22
- **Descubierto durante:** Prompt 13 (premortem.md), PASO 1 (verificación).
- **Tipo:** deuda técnica (código muerto) + riesgo de divergencia.
- **Evidencia:** `SmartAssignmentCalculator.selectNextAssignee` y su `MemberLoadData` replican `task_assignment_helpers.ts` (`scoreOf` = `completionsRecent*difficultyWeight + daysSinceLastExecution*-0.1`). Un grep en `lib/` no encuentra **ningún** uso de `SmartAssignmentCalculator`/`selectNextAssignee` ni quién construya su `MemberLoadData` (el reparto inteligente es server-authoritative: se calcula en `applyTaskCompletion`). No tiene tests que lo "claven".
- **Cómo reproducir / verificar:** `grep -rn "SmartAssignmentCalculator\|selectNextAssignee" lib` → solo la definición.
- **Impacto:** bajo hoy (no se ejecuta), pero si algún día se cablea, su peso `completionsRecent` arrastraría el MISMO bug del #13 (acumulado de por vida) salvo que se alimente desde la ventana real. Riesgo de que diverja de la lógica de servidor.
- **Sugerencia:** borrarlo (es código muerto), o —si se prevé un preview cliente— documentar que `completionsRecent` debe venir de la ventana de 60 días (eventos `taskEvents`), no de un contador acumulado. Fuera de alcance del #13 (que cierra el camino real de servidor).
- **Estado:** ⬜ anotado (candidato a limpieza).

### H-027 — `autoSelectForDowngrade` desempata por `completions60d` (acumulado de por vida), mismo "smell" que el #13 en el dominio de entitlement
- **Fecha:** 2026-06-22
- **Descubierto durante:** Prompt 13 (premortem.md), PASO 1 (verificación).
- **Tipo:** mejora (consistencia de criterio "actividad reciente").
- **Evidencia:** `functions/src/entitlement/downgrade_helpers.ts:64` ordena a los miembros a conservar en un downgrade por `b.completions60d - a.completions60d` (los "más activos" se quedan). Ese campo es, pese al nombre, un **acumulado de por vida** (solo `FieldValue.increment(1)` en `apply_task_completion.ts`, nunca decae). Por eso el #13 **mantiene** el incremento de `completions60d` (no lo elimina): lo necesita el downgrade. Pero el criterio "más activo" del downgrade sufre el mismo sesgo que sufría el reparto: prioriza al cumplidor histórico aunque lleve meses inactivo.
- **Cómo reproducir / verificar:** revisar `downgrade_helpers.ts:56-71`; un miembro con mucho histórico pero 0 actividad reciente se conserva antes que uno recientemente activo.
- **Impacto:** medio-bajo; afecta a a quién se conserva Premium al degradar (no es seguridad ni dinero perdido, pero sí "justicia" del criterio). El nombre `completions60d` es además **engañoso** (no es de 60 días).
- **Sugerencia:** unificar con el #13 — calcular también aquí la actividad reciente desde `taskEvents` (ventana real), o renombrar el campo a `completionsLifetime` para no engañar. Fuera de alcance del #13 (que se limita al reparto inteligente de tareas).
- **Estado:** ⬜ anotado (candidato a backlog).

### H-028 — Segundo vector de elusión del límite Free de tareas: ciclo congelar→crear→descongelar
- **Fecha:** 2026-06-22
- **Descubierto durante:** Prompt 14 (premortem.md), PASO 1/2 (al cerrar la create-race).
- **Tipo:** bug (eludibilidad residual del límite Free).
- **Evidencia:** el límite Free cuenta solo `status == 'active'` (tanto el dashboard `planCounters.activeTasks = tasksSnap(where status==active).size` como ahora la callable `createTask`). Congelar una tarea es un UPDATE cliente (`tasks_repository_impl.freezeTask` → `status: 'frozen'`) permitido por reglas a admin/owner de un hogar Free; baja el conteo de activas. Secuencia: con 4 activas → congelar 1 (quedan 3 activas) → `createTask` permite la 4ª → descongelar la congelada (`unfreezeTask`, UPDATE `frozen→active`, NO pasa por la callable ni re-chequea el límite) → 5 activas. Repetible (congelar 4, crear 4, descongelar 4 → 8 activas), así que es elusión efectivamente ilimitada.
- **Cómo reproducir / verificar:** en un hogar Free a tope, congelar una tarea desde la app, crear otra (la callable lo permite porque cuenta 3 activas), descongelar la primera → quedan 5 activas pese al tope de 4.
- **Impacto:** medio — el #14 cierra el vector que el prompt describe (ráfaga de altas, ya **no eludible**, probado), pero este camino alternativo sigue abierto. No es dinero perdido directo (Free no paga), pero erosiona la presión de conversión.
- **Sugerencia:** enrutar el descongelado por una callable `unfreezeTask` transaccional que re-aplique el mismo conteo de activas (reutilizando la lógica de `createTask`), y denegar en reglas la transición `frozen→active` desde cliente (`taskUpdateValuesAllowed`). Alternativa más simple pero con cambio de semántica/UX: que el límite cuente `active + frozen` (congelar no liberaría cupo); requiere alinear el dashboard/banner para no confundir al usuario.
- **Estado:** ⬜ anotado (seguimiento del #14; candidato a cerrar en la misma línea de trabajo).

### H-029 — Cierre del free trial (#14) bloqueado por configuración de stores (mismo patrón que #05/#02)
- **Fecha:** 2026-06-22
- **Descubierto durante:** Prompt 14 (premortem.md), PASO 2/4.
- **Tipo:** bloqueo de infraestructura externa (no de código).
- **Evidencia:** el cliente ya lee la oferta introductoria de la store (`intro_offer_parser.dart` cubre Google Play `subscriptionOfferDetails`/pricingPhases y App Store `SKProductDiscount.freeTrail`) y el paywall muestra el copy de trial solo cuando la store la reporta (`annualIntroOfferProvider` + `paywall_screen_v2`). Pero la **oferta NO existe todavía en las stores**: hay que crear en Google Play Console un base plan del producto `toka_premium_annual` con una **oferta de prueba gratuita de 14 días**, y en App Store Connect una **introductory offer de tipo Free Trial (14 días)** para el mismo plan anual. Decisión de producto registrada: **14 días, solo plan anual** (el mensual sin trial). Como en H-014 (#05, faltan unit IDs reales de AdMob) y H-009/H-017 (#02/#06, faltan secrets/infra de stores), el código está cableado y testeado pero la verificación en sandbox queda pendiente de esa config + app no-pre-release.
- **Cómo reproducir / verificar:** en un build con la store conectada, `InAppPurchase.queryProductDetails({'toka_premium_annual'})` hoy NO devuelve fase de trial → el paywall muestra el CTA normal ("Empezar Premium Anual"), no "Empezar 14 días gratis".
- **Checklist de release para cerrar en ✅:** (1) crear el base plan + oferta free-trial 14d en Play Console (anual); (2) crear la introductory offer free-trial 14d en App Store Connect (anual); (3) build sandbox + cuenta de prueba elegible → confirmar que el paywall muestra "14 días gratis" y que la compra inicia el trial sin cobro; (4) confirmar que el mensual NO ofrece trial.
- **Estado:** 🟧 código hecho + testeado; pendiente config de stores + verificación sandbox.

### H-030 — `resetDashboardsDaily`: el filtro `premiumStatus != 'purged'` excluye hogares SIN el campo (semántica de `!=` en Firestore)
- **Fecha:** 2026-06-22
- **Descubierto durante:** Prompt 15 (premortem.md), PASO 2 (fan-out del reset diario).
- **Tipo:** bug latente (cobertura incompleta del cron), pre-existente; se preservó la semántica al refactorizar para no ampliar el alcance.
- **Evidencia:** tanto el código anterior como `enqueueDashboardRebuilds` usan `db.collection("homes").where("premiumStatus","!=","purged")`. En Firestore, un filtro `!=` (igual que `not-in`) **sólo devuelve documentos en los que el campo EXISTE** y es distinto del valor; los hogares sin `premiumStatus` quedan **excluidos** del barrido → nunca reciben el reset diario de dashboard (contadores de "hoy"/"hecho hoy" no se ponen a cero a medianoche). Los hogares creados por el flujo normal sí escriben `premiumStatus` (p. ej. `'free'`), así que el impacto real depende de si existen docs antiguos/parciales sin ese campo.
- **Cómo reproducir / verificar:** crear un home sin `premiumStatus` y comprobar que no aparece en el resultado de la query del cron (`enqueueDashboardRebuilds` no lo encola). En el emulador el test `reset_dashboards_fanout` no lo cubre porque todos los homes sembrados tienen `premiumStatus`.
- **Impacto:** bajo — el dashboard también se reconstruye por el trigger `onTaskWriteUpdateDashboard` y por completar/pasar turno; sólo se perdería el reset de medianoche de los contadores diarios en hogares sin el campo.
- **Sugerencia:** filtrar por estados vivos de forma positiva (p. ej. `where("premiumStatus","in",[lista de estados no-purged])`) o no filtrar y saltar los `purged` en el handler por hogar; alinear con cómo se modela el estado de hogar purgado. Verificar de paso que TODOS los homes de prod tienen `premiumStatus`.
- **Estado:** ⬜ anotado (fuera de alcance del #15; candidato a cerrar junto con la limpieza de estados de hogar).

### H-031 — `closeHome` NO trocea un batch grande (era falso positivo); pero los hogares `purged` nunca borran sus subcolecciones (fuga de almacenamiento)
- **Fecha:** 2026-06-22
- **Descubierto durante:** Prompt 16 (premortem.md), PASO 1 (verificación).
- **Tipo:** falso positivo (el batch-size) + bug latente real (retención/almacenamiento).
- **Evidencia:** el premortem listaba `closeHome` como "`db.batch()` sin trocear (riesgo con >500 ops)". El código real (`homes/index.ts`, y TODO su historial vía `git log -S`) solo hace un batch de ≤2 ops: marca `premiumStatus:'purged'` en el home y borra la membership del PROPIO owner. **Nunca** itera `members`/`tasks`/`taskEvents`. Así que el riesgo de batch >500 en `closeHome` es **falso positivo**. PERO: cerrar un hogar (y `purgeExpiredFrozen`, y el owner huérfano en `cleanup_user.ts`) solo deja un **tombstone** `purged`; **no existe NINGÚN job que borre las subcolecciones** (`tasks`, `taskEvents`, `members`, `views`, `subscriptions`) de un hogar `purged` (grep: solo se escribe `purged`, jamás `recursiveDelete` de un home). → los datos de hogares cerrados viven **para siempre** en Firestore.
- **Cómo reproducir / verificar:** cerrar un hogar con tareas/eventos y comprobar que `homes/{id}/tasks` y `homes/{id}/taskEvents` siguen existiendo indefinidamente; `grep -rn "recursiveDelete" functions/src` → solo `users/{uid}`, nunca homes.
- **Impacto:** medio-bajo — coste de almacenamiento que crece con los hogares cerrados (no se libera), y posible residuo de PII en snapshots de miembros de hogares muertos (GDPR, relacionado con #04). No es contención ni rotura de batch.
- **Sugerencia:** un job programado (o un paso en `closeHome`) que haga `recursiveDelete(homes/{id})` de los hogares `purged` tras una ventana de gracia (p. ej. 30-90 días), usando `BulkWriter`/`recursiveDelete` (que ya trocea). Fuera de alcance del #16 (que es contención/batch-size), pero del mismo dominio de fiabilidad.
- **Estado:** ⬜ anotado (candidato a backlog: purga real de hogares cerrados).

### H-032 — El emulador Firestore NO aplica el límite de 500 escrituras/batch (falso verde en tests)
- **Fecha:** 2026-06-22
- **Descubierto durante:** Prompt 16 (premortem.md), PASO 3 (al testear el batching grande).
- **Tipo:** trampa de testing (paridad emulador↔prod), análoga a H-019/`collectiongroup-index-prod-only`.
- **Evidencia:** un test de integración que sembraba 510 tareas y llamaba a `restorePremiumState`/`reassignTasksFromDeletedUser` con el código VIEJO (batch único, sin trocear) **pasaba en verde** en el emulador. Producción impone un límite DURO de 500 ops por `WriteBatch`/transacción (`INVALID_ARGUMENT: cannot write more than 500 entities ...`); el emulador no lo aplica. Por eso el bug del #16 era invisible en tests de integración.
- **Cómo reproducir / verificar:** sembrar >500 docs y commitear un único `db.batch()` contra el emulador (pasa) vs contra prod (falla).
- **Impacto:** alto para la confianza de los tests — un batch sin trocear puede llegar a prod "verde". 
- **Sugerencia (aplicada en #16):** testear la MECÁNICA de troceo con un unit test (`functions/src/shared/batch_utils.ts` → `chunked`, `MAX_BATCH_OPS=450`), no fiarse de la integración para este límite. Auditar el resto del código en busca de `db.batch()`/transacciones que iteren colecciones sin trocear. Registrado también en la memoria `emulator-no-batch-500-limit`.
- **Estado:** ✅ mitigado en el #16 (restore + reassign troceados); auditoría del resto = candidato a backlog.

### H-033 — Gate por custom claim con token cacheado: el claim recién concedido no se refleja hasta expirar el token (~1h)
- **Fecha:** 2026-06-22
- **Descubierto durante:** Prompt 17 (premortem.md), PASO 4 (verificación en dispositivo de la pantalla de soporte).
- **Tipo:** bug real (corregido en el #17).
- **Evidencia:** `isSupportAgent` (`lib/features/support/application/support_providers.dart`) leía el claim con `user.getIdTokenResult()` (sin forzar refresh), que devuelve el ID token CACHEADO. Tras conceder el claim `support` server-side (`setCustomUserClaims`), la entrada de soporte en Ajustes **no aparecía** aunque el claim estaba presente en el backend (`qa_grant_support_claim.js show` → `{"support":true}`). Un agente de soporte ya logueado no vería la entrada hasta que el token expirase (~1h) o re-logueara. Confirmado en dispositivo: con `getIdTokenResult(true)` (force-refresh) el log del cliente mostró `claims={support: true, ...}` y la entrada apareció.
- **Cómo reproducir / verificar:** conceder un custom claim a una cuenta ya autenticada y comprobar que un gate que lee `getIdTokenResult()` (sin force) no lo ve hasta el refresh.
- **Impacto:** medio para cualquier feature gateada por custom claims que se conceden en caliente. Patrón a vigilar si se añaden más claims (roles, flags).
- **Sugerencia (aplicada):** `getIdTokenResult(true)` en gates de claim raramente abiertos (coste de un refresh puntual asumible) + try/catch que oculta la entrada si el refresh falla. El backend reverifica el claim de todas formas (defensa en profundidad).
- **Estado:** ✅ corregido en el #17.

### H-034 — Las funciones con `enforceAppCheck:true` no se pueden verificar en builds debug de QA: el debug token de App Check no está registrado en la consola
- **Fecha:** 2026-06-22
- **Descubierto durante:** Prompt 17 (premortem.md), PASO 4 (al intentar invocar `supportDiagnoseHome` desde el APK debug).
- **Tipo:** gap de infraestructura/QA (no es bug de código).
- **Evidencia:** el APK debug usa `AndroidProvider.debug` de App Check (`lib/main.dart:35-51`), que genera un debug secret local impreso en logcat (`DebugAppCheckProvider: Enter this debug secret into the allow list ...`). Como ese token NO está registrado en Firebase Console → App Check, `getToken` devuelve `403 App attestation failed` y las llamadas llevan un placeholder. Cualquier callable con `enforceAppCheck:true` (`syncEntitlement` del #02, y ahora `supportDiagnoseHome` del #17) **rechaza** la petición → en la pantalla de soporte se ve "Acceso denegado" en vez de los datos. La enforcement FUNCIONA (es la prueba de que el control está activo), pero impide la verificación funcional en vivo desde un dispositivo de QA.
- **Cómo reproducir / verificar:** instalar el APK debug, abrir la pantalla de soporte con una cuenta con claim `support`, diagnosticar un hogar → "Acceso denegado"; logcat muestra `403 App attestation failed`.
- **Impacto:** medio para QA — bloquea probar en dispositivo TODA función con App Check (incluye el #02). No afecta a release builds con Play Integrity (firma + SHA registrados).
- **Sugerencia:** registrar el debug token de cada dispositivo/emulador QA en Firebase Console → App Check → app `com.toka.toka` → "Administrar tokens de depuración" (paso manual, lo decide el dueño porque añade un token que pasa App Check para esa app). Documentar el flujo en `QA_SESSION.md`. Alternativamente, exponer la callable de soporte también vía una consola interna server-side (sin App Check de cliente) si el soporte no se hará desde la app.
- **Resuelto (2026-06-22, autorizado por el usuario):** se registró el debug token del emulador vía la API de gestión de App Check (`debugTokens`, con la SA admin) → `getToken` pasó a devolver un JWT válido (provider `debug`) y la callable `supportDiagnoseHome` devolvió los datos en vivo del hogar real, redactados (sin PII). El proyecto ya tenía otros debug tokens de QA registrados. Token añadido: `displayName=qa-emulator-h17` (borrable con `node /tmp/reg_appcheck_h17.js del <name>` o desde la consola).
- **Estado:** ✅ desbloqueado para el #17 (verificación en vivo completada); el mismo flujo aplica para verificar el #02 en dispositivo.

### H-035 — Una query Firestore offline-sin-caché NO lanza: devuelve snapshot vacío `isFromCache=true` (y el SDK no reconecta el canal "en caliente")
- **Fecha:** 2026-06-22
- **Descubierto durante:** Prompt 18 (premortem.md), PASO 4 (verificación en dispositivo del onboarding sin red).
- **Tipo:** matiz de comportamiento del SDK de Firestore (motivó un refinamiento del fix del #18; no es bug de código).
- **Evidencia:** el plan del #18 asumía que sin red la lectura "falla" (excepción). En la práctica, una **query** (`collection().where().orderBy().get()`) en modo avión se resuelve distinto según la caché:
  - **con `languages` cacheada** (cacheada en el login previo con red) → devuelve los docs reales `isFromCache=true` → la pantalla muestra los idiomas reales sin banner (objetivo cumplido, pero no se ejercita el fallback).
  - **sin caché** (borrando `databases/firestore.*` vía `run-as`, sesión Auth intacta) → la query **NO lanza**: resuelve a un `QuerySnapshot` **vacío con `metadata.isFromCache=true`**. La implementación inicial del #18 lo trataba como "colección remota vacía" → `isFallback=false` → **sin banner** justo en el escenario del hallazgo.
- **Refinamiento aplicado (#18):** distinguir vacío-desde-caché de vacío-desde-servidor con `snapshot.metadata.isFromCache`: vacío+caché → `isFallback=true` (banner+Reintentar); vacío+servidor → defaults sin retry (despliegue inicial legítimo). Verificado en dispositivo: con la caché borrada y modo avión, el banner "Sin conexión" + "Reintentar" aparece correctamente.
- **Sub-matiz (reconexión en caliente):** tras desactivar el modo avión **con la app abierta**, el canal gRPC del SDK queda en offline un tiempo y `get()` sigue sirviendo de caché; el botón **Reintentar** re-ejecuta el fetch (tap verificado) pero la lista remota no llega hasta que el SDK reconecta. Un **relanzado con red** (SDK inicializado online) la trae de inmediato. Es comportamiento del SDK, no del fix.
- **Cómo reproducir / verificar:** loguear cuenta nueva sin hogar (con red) → onboarding; `am force-stop`; activar modo avión; `run-as com.toka.toka rm -f 'databases/firestore.%5BDEFAULT%5D.toka-dd241.%28default%29'*`; relanzar → step de idioma con banner + Reintentar.
- **Impacto:** bajo, pero a vigilar en cualquier feature que lea Firestore offline y asuma "error = excepción": las **queries** vacías offline no lanzan (sí lanzan los `doc().get()` de un documento concreto sin caché). Conviene mirar `metadata.isFromCache` cuando una query vacía deba distinguirse de "sin datos".
- **Estado:** ✅ contemplado en el fix del #18 (tests unit: vacío-caché→fallback, vacío-servidor→no-fallback; verificado en dispositivo).

### H-036 — `recurrence_order_test.dart` está obsoleto: `RecurrenceOrder.all` ganó un 6º tipo (`oneTime`) pero el test sigue esperando 5
- **Fecha:** 2026-06-22
- **Descubierto durante:** Prompt 19 (premortem.md), PASO 3 (suite unitaria completa antes del build).
- **Tipo:** deuda de test (no es bug de código; ajeno a accesibilidad).
- **Evidencia:** `lib/features/tasks/domain/recurrence_order.dart` declara `all = ['oneTime','hourly','daily','weekly','monthly','yearly']` (6 elementos; las tareas **puntuales** se añadieron después). `test/unit/features/tasks/recurrence_order_test.dart` aún asume `all.length == 5` y `all == ['hourly','daily','weekly','monthly','yearly']` → **2 tests fallan** (`flutter test test/unit`: 692 verde, estos 2 rojos). No lo toqué en el #19.
- **Impacto:** bajo — solo cobertura desactualizada; la app ordena bien (incluye `oneTime`). Ensucia el verde de la suite unitaria.
- **Sugerencia:** actualizar el test a 6 elementos con `oneTime` en cabeza (orden actual del enum), o fijar el contrato de orden deseado si `oneTime` debe ir en otra posición.
- **Estado:** ⬜ pendiente (fuera de alcance del #19; anotado).

### H-037 — Los golden tests fallan en el entorno WSL por diferencias de renderizado de fuente (no de layout); los goldens commiteados son de otro entorno
- **Fecha:** 2026-06-22
- **Descubierto durante:** Prompt 19 (premortem.md), PASO 3 (al correr `test/ui/features/tasks` y `.../members`).
- **Tipo:** fragilidad del harness de goldens (no es regresión de código).
- **Evidencia:** varios goldens del proyecto fallan en WSL (`members_screen`, `complete_task_dialog`, `pass_turn_dialog`, `today_card_done`, `today_card_todo_*`, `home_settings_owner`…), TAMBIÉN en widgets que NO se tocaron en el #19. Comparando master vs render actual con ImageMagick, el golden **no tocado** `today_card_todo_with_buttons` (card legacy no-v2) difiere **~0.93 %** de píxeles y su `isolatedDiff` muestra que la diferencia está solo en los **bordes de glifos/contornos** (antialiasing), no en posiciones → los goldens se generaron en otro entorno (otra versión de fuente/AA) y no casan con este WSL. El mismo `git stash` confirmó que estos fallos ya existían en HEAD (sin mis cambios). Coincide con la memoria `toka-ui-test-harness-gotchas` ("regenerar goldens").
- **Matiz relacionado (no-v2):** la card **legacy** `lib/features/tasks/presentation/widgets/today_task_card_todo.dart` (+ `today_task_section.dart`) conserva el patrón viejo (`GestureDetector` + glifo `✓/↻` en el `Text`), pero **no está en el árbol vivo** (la app usa `TodayScreenV2 → TodayTaskSectionV2 → TodayTaskCardTodoV2`, ya corregido). No se tocó para no romper más goldens; si se elimina el código muerto, eliminar también sus tests/goldens.
- **Impacto:** medio para CI/QA — un `flutter test` en WSL nunca sale 100 % verde por estos goldens; enmascara regresiones reales de pixel. Los tests NO-golden sí son fiables.
- **Sugerencia:** regenerar todos los goldens en el entorno canónico con `flutter test --update-goldens` y commitearlos juntos, o fijar fuentes embebidas + `GoogleFonts.config.allowRuntimeFetching=false` en un `flutter_test_config.dart` global para hacerlos deterministas entre entornos. Para el #19 la garantía de "sin overflow" se aseguró con tests de aserción (sin excepción de RenderFlex), no con el golden.
- **Estado:** ⬜ pendiente (fuera de alcance del #19; anotado).

### H-038 — El hueco de tests del #20 era parcialmente FALSO POSITIVO; código/tests muertos residuales
- **Fecha:** 2026-06-23
- **Descubierto durante:** Prompt 20 (premortem.md), PASO 1.
- **Tipo:** premortem desactualizado (escrito antes de #12/#15/#17) + código muerto.
- **Evidencia:** el #20 afirmaba "tests ausentes: `sendRescueAlerts`, `sendPassNotification`, `resetDashboardsDaily`" y "tests espejo en `homes_callables.test.ts`". Real: (1) las dos funciones de notificación ya tenían tests de **purga de token** (#17, `fcm_token_purge.test.ts`), faltaba solo su **lógica núcleo** (destinatarios/contenido) → añadida en `notification_dispatch.test.ts`. (2) `resetDashboardsDaily` ya tenía su fan-out (`enqueueDashboardRebuilds`/`rebuildDashboardForHome`) testeado en `reset_dashboards_fanout.test.ts` (#15); el wrapper `onSchedule` es un one-liner sobre esa lógica → no se añadió test del wrapper. (3) Las callables de gobernanza **reales** (`removeMember`/`transferOwnership`/`leaveHome`/`promoteToAdmin`) YA se ejercitaban contra el emulador en `homes_governance.test.ts` (#12); los espejos eran redundancia → se reforzó governance con 11 edge-cases y se borraron los 6 espejos de esas 3 callables.
- **Residual:** (a) `lib/features/tasks/presentation/widgets/complete_task_dialog.dart` queda **sin uso** tras quitar el diálogo del flujo de completar (solo lo referencia su propio test+golden) → candidato a borrar junto con `complete_task_dialog_test.dart`. (b) En `homes_callables.test.ts` **permanecen los espejos de `createHome`/`joinHome`** (validación de nombre/slots/longitud, rate-limit, expiración de invitación): fuera del alcance nombrado del #20 (que citaba transferOwnership/leaveHome/removeMember); candidatos a sustituir por tests de callable real. (c) El test pre-existente `complete_task_dialog_test.dart › "muestra nombre e icono"` espera `find.text('🧹 Barrer')` pero el diálogo renderiza emoji+título como widgets separados → **ya fallaba en HEAD** (confirmado por `git stash`), no es regresión del #20 (mismo cubo que H-037).
- **Impacto:** bajo — solo deuda de tests/código muerto.
- **Estado:** 🟧 parcial (lo nombrado por el #20 cerrado; createHome/joinHome y el código muerto anotados como seguimiento).

### H-039 — Varios `.g.dart` commiteados están DESACTUALIZADOS respecto a su source; revertirlos en bloque rompe el build de Android
- **Fecha:** 2026-06-23
- **Descubierto durante:** Prompt 20 (premortem.md), PASO 4 (build del APK con Flutter de Windows).
- **Tipo:** higiene de repo (generados no committeados tras cambiar el source) + trampa de `build_runner`.
- **Evidencia:** al generar el `.g.dart` del provider nuevo, `build_runner` reescribió ~10 `.g.dart` ajenos; los revertí a HEAD creyéndolos "ruido de hash". Pero **el source `.dart` de varios estaba modificado en el working tree** (sesión QA previa, sin commitear su `.g.dart`): `language_provider.dart` (+`remoteBannerAdUnits` en `ad_banner_config_provider.dart`, `subscription_dashboard_provider.dart`, etc.). Revertir su `.g.dart` a la versión vieja de HEAD dejó el generado **sin los símbolos del source** → el build Android falló en `:app:compileFlutterBuildDebug` con `Type 'Language' not found` / `RemoteBannerAdUnitsRef isn't a type` (el `flutter analyze` por-archivo NO lo detecta; el error solo sale en la compilación kernel de toda la app).
- **Trampa de `build_runner`:** tras revertir el `.g.dart`, `build_runner build` (incluso con `--delete-conflicting-outputs`) lo **SALTA** ("wrote 0 outputs") porque su grafo de assets cree que el output está al día (compara digests de input, no el contenido en disco). Hay que **borrar el `.g.dart` en disco** para forzar la regeneración, o `build_runner clean` + build.
- **Impacto:** medio — un build limpio del HEAD actual fallaría si esos `.g.dart` se commitean stale; y es una trampa fácil al "limpiar" diffs de generados.
- **Sugerencia:** NO revertir a mano archivos generados; regenerarlos. Antes de commitear, correr `dart run build_runner build --delete-conflicting-outputs` (con los `.g.dart` borrados o tras `clean`) y verificar que `git diff` de los `.g.dart` casa con sus sources. Idealmente añadir un check en el runbook de deploy.
- **Estado:** ✅ resuelto en esta sesión (los 10 `.g.dart` regenerados y consistentes; build del APK verde). El patrón queda anotado para evitar reincidir.

### H-040 — Un `SnackBar` con acción NO se auto-cierra por defecto en Flutter 3.44 (`persist = action != null`)
- **Fecha:** 2026-06-23
- **Descubierto durante:** Prompt 20 (premortem.md), PASO 4 — el USUARIO lo vio en el MI_9 ("hay un mensaje que no se va de tarea completada"). Yo lo había entrevisto en una captura del PASO 4 y NO lo investigué (fallo de proceso).
- **Tipo:** bug real introducido por el #20 (regresión de comportamiento de UX).
- **Root cause (confirmado en la fuente del SDK):** `snack_bar.dart:303` hace `persist = persist ?? action != null`, y `scaffold.dart:622` en el callback del timer de duración hace `if (snackBar.persist) return;`. Es decir, **un `SnackBar` que lleva `SnackBarAction` y no fija `persist` explícitamente tiene `persist=true` → el timer de `duration` se programa pero NO lo cierra**; queda fijo hasta que se pulse la acción, se navegue, o lo desplace otro SnackBar. El SnackBar de "Tarea completada · Deshacer" del #20 caía justo en ese caso.
- **Cómo se aisló:** test de SnackBar suelto con 4 variantes (default / 10s fixed / 10s floating / 10s floating+**action**): solo la que llevaba acción NO se cerraba. (El harness de `flutter_test` SÍ dispara el timer con `pump(Duration)`, así que reproduce el bug — pero ojo: un SnackBar **con acción y persist por defecto** también "se queda" en test, lo que puede enmascararse si el test solo asierta que el SnackBar aparece y no que DESAPARECE.)
- **Fix:** `persist: false` explícito en el `SnackBar` de `today_screen_v2.dart:_onDone`. Regresión cubierta con un test que asierta que el SnackBar **desaparece** tras la ventana (antes solo se asertaba que aparecía).
- **Lección de testing:** para SnackBars temporizados, asertar SIEMPRE la **desaparición** (`findsNothing` tras `pump(duración+margen)`), no solo la aparición. Y al ver algo raro en una captura de verificación, **investigarlo en el momento** (no diferirlo).
- **Estado:** ✅ resuelto, testeado (test de regresión verde) y **verificado en el MI_9** (el SnackBar ahora se auto-cierra a los ~10s y el completado sincroniza correctamente).
