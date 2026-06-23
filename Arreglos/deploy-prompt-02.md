# Runbook de despliegue — Prompt 02 (verificación real de recibos IAP)

> **Requiere autorización explícita de deploy a producción (`toka-dd241`).**
> Hasta entonces, la corrección está demostrada en emulador (functions unit 262/262,
> integración 13/13). Este runbook es lo que hay que ejecutar **cuando se autorice**.

## 0. Estado seguro por defecto
Sin los secrets/config rellenos, `syncEntitlement` se **bloquea** en prod
(`failed-precondition: store-receipt-validation-not-enabled`) — no activa Premium
de forma insegura. El deploy puede hacerse "en seguro" y activarse al rellenar la config.

## 1. Credenciales a obtener (fuera de Toka)
- **Google Play**: service account (GCP) con acceso en Play Console → API access, con
  permiso para ver compras/suscripciones (scope `androidpublisher`). Descargar su JSON.
  Anotar el **package name** (ej. `com.toka.app`).
- **App Store Connect**: clave de App Store Server API (Users and Access → Integrations →
  In-App Purchase / Keys). Descargar el `.p8`. Anotar **Issuer ID**, **Key ID**, **Bundle ID**.

## 2. Secrets (Secret Manager) — material sensible
Enlazados en `secrets:[...]` de la callable; aparecen en `process.env` en runtime.
```bash
cd functions
# JSON del service account de Google Play (pega el contenido del .json):
firebase functions:secrets:set GOOGLE_PLAY_SA_JSON --project toka-dd241
# Clave .p8 de App Store (pega el contenido del .p8, con sus líneas BEGIN/END):
firebase functions:secrets:set APP_STORE_PRIVATE_KEY --project toka-dd241
```

## 3. Config NO sensible — `functions/.env.toka-dd241` (gitignored)
Rellenar los valores ya presentes (vacíos) en el fichero:
```dotenv
GOOGLE_PLAY_PACKAGE_NAME=com.toka.app
APP_STORE_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
APP_STORE_KEY_ID=ABCDE12345
APP_STORE_BUNDLE_ID=com.toka.app
APP_STORE_ENV=Production        # o Sandbox para pruebas de sandbox
STRICT_RECEIPT_VALIDATION=true
```
> Importante: deja los 4 primeros **vacíos** si aún no tienes valores reales — un valor
> a medias hace que la callable intente verificar y falle en red. Vacío = bloqueo seguro.

## 4. Build + deploy (autorizado)
```bash
cd functions && npm run build            # tsc
# Deploy SOLO de syncEntitlement (evita tocar el resto):
FUNCTIONS_DISCOVERY_TIMEOUT=120 firebase deploy \
  --only functions:syncEntitlement --project toka-dd241
```
> `firebase deploy` usa el **working tree** (ver memoria `deploy-functions-discovery-timeout`).
> Confirma que `firebase functions:secrets:get GOOGLE_PLAY_SA_JSON` y `APP_STORE_PRIVATE_KEY`
> existen antes; si faltan, el deploy avisa de secrets no resueltos.

## 5. Verificación PASO 4 (sandbox, 2 dispositivos)
Con `APP_STORE_ENV=Sandbox` (iOS) / cuenta de prueba de Play:
1. **Owner (físico)** compra Premium en el paywall.
2. **Member (emulador, mismo hogar)** debe ver el hogar pasar a Premium: en "Hoy" desaparece
   el banner de ads; `adFlags.showBanner=false`, `premiumFlags.isPremium=true`.
   Inspeccionar BD: `node secrets/qa_premium.js <homeId>` (o `qa_inspect_home.js`).
3. **Compra/sync duplicada** (reabrir paywall / restore): confirmar que `premiumEndsAt`
   **no salta** y `lifetimeUnlockedHomeSlots` no se incrementa de nuevo.
4. Confirmar `subscriptions/history/charges/{chargeId}` con `storeVerified:true`,
   `validForUnlock:true`, y `chargeId` = purchaseToken/originalTransactionId (no el del cliente).
5. Capturar, analizar, borrar las capturas.

## 6. Cierre
Si el sandbox confirma activación + idempotencia + sincronización → marcar el Prompt 02
como ✅ en `premortem.md`. Si algo falla → 🟧 con el detalle.

## Rollback
`firebase deploy --only functions:syncEntitlement` desde el commit anterior, o
desactivar la ruta segura vaciando la config (vuelve al bloqueo seguro).
