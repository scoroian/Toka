# DEPLOY.md — Runbook de despliegue de Toka (ejecutar EN ORDEN)

> **Para Claude (y para humanos):** este documento es el **procedimiento canónico**
> de despliegue. Cada vez que haya que desplegar (functions, reglas, o app), recórrelo
> **de arriba abajo sin saltarte gates**. El objetivo es que **lo que funciona en
> desarrollo (emulador) se replique idéntico en producción** (`toka-dd241`): mismos
> tests en verde, misma config, mismos secretos.
>
> **Regla de oro:** desplegar a producción (`toka-dd241`) **requiere autorización
> explícita del usuario**. No despliegues por tu cuenta. `firebase deploy` usa el
> **working tree** (despliega lo que hay sin commitear) — revisa el árbol antes.

Leyenda de gates: 🚦 **GATE** = si falla, PARA y arregla antes de seguir.

---

## 0. Pre-flight
- [ ] Rama y `git status` revisados (sabes qué se va a desplegar; el deploy usa el working tree).
- [ ] Ruido CRLF separado del cambio real: `git diff --ignore-cr-at-eol --numstat`.
- [ ] Sabes el alcance: ¿solo functions? ¿reglas? ¿app? ¿solo una función concreta?
- [ ] Si tocas reglas/functions y vas a probar en móviles → **pide autorización de deploy** y espera el OK (ver §4).

---

## 1. 🚦 GATE de tests — TODO en verde (igual que en desa)

### 1a. Backend (functions) — desde `functions/`
```bash
cd functions
npx tsc --noEmit -p tsconfig.json          # build/typecheck: 0 errores
npx jest src/                              # UNIT (no usa emulador)
```
> Nota: `npm test` (jest a secas) intenta correr TAMBIÉN rules+integration sin emulador y
> falla; el unit canónico es `npx jest src/`.

Rules + integración **necesitan el emulador de Firestore**. Desde la **raíz**:
```bash
FUNCTIONS_DISCOVERY_TIMEOUT=120 firebase emulators:exec --only firestore \
  --project demo-toka-integration \
  "cd functions && npm run test:rules && npm run test:integration"
```
- [ ] 🚦 tsc 0 errores
- [ ] 🚦 unit verde (`npx jest src/`)
- [ ] 🚦 rules verde (`test:rules`)
- [ ] 🚦 integración verde (`test:integration`)

### 1b. Cliente (Flutter)
> WSL **no** resuelve bien los paquetes (`package_config` es de Windows). Usa el
> **Flutter de Windows** vía interop para `analyze`/`test` (ver memoria
> `clean-apk-build-broken-cfe-exhaustiveness`).
```bash
# analyze (Windows) — debe dar "No issues found"
cmd.exe /c "cd /d C:\Users\sebas\OneDrive\Escritorio\Proyectos\Toka && flutter analyze"
# tests afectados (unit/integration/ui)
cmd.exe /c "cd /d C:\Users\sebas\OneDrive\Escritorio\Proyectos\Toka && flutter test test\unit test\integration"
```
- [ ] 🚦 `flutter analyze` sin issues (al menos en los archivos tocados)
- [ ] 🚦 tests Dart afectados en verde (si tocan goldens, regenerarlos — ver `toka-ui-test-harness-gotchas`)

---

## 2. 🚦 GATE de seguridad de release
- [ ] 🚦 `cd functions && npm run check:release-safety` (verifica que no se cuela `debugSetPremiumStatus` ni allowlist de debug a prod — Prompt 03).
- [ ] 🚦 `DEBUG_PREMIUM_ALLOWED_UIDS` en `.env.toka-dd241`: que sea lo esperado (idealmente vacío en release).
- [ ] 🚦 `TOKA_ALLOW_UNVERIFIED_RECEIPTS` **NO** está a `true` en prod (activaría Premium sin verificar).

---

## 3. 🚦 GATE de PARIDAD dev → prod (config + secretos)

**Principio:** *toda* variable de entorno o secreto que el **código** usa debe existir en
producción. Si está en desa pero falta en prod, la función fallará o quedará bloqueada.

### 3a. Enumera lo que el código necesita (se autogenera del código → nunca se queda obsoleto)
```bash
cd functions
echo "── Secretos (Secret Manager) ──"
grep -rhoE 'defineSecret\("([A-Z_]+)"\)' src --include=*.ts | grep -oE '"[A-Z_]+"' | tr -d '"' | sort -u
echo "── Variables process.env usadas (sin tests) ──"
grep -rhoE 'process\.env\.[A-Z_]+' src --include=*.ts | grep -v test | sed 's/process\.env\.//' | sort -u
```
Clasifica cada clave en una de estas categorías:

| Clave | Categoría | Dónde vive en PROD | Notas |
|---|---|---|---|
| `GOOGLE_PLAY_SA_JSON` | 🔐 secreto | Secret Manager (`functions:secrets:set`) | JSON service account (scope androidpublisher) |
| `APP_STORE_PRIVATE_KEY` | 🔐 secreto | Secret Manager | contenido del `.p8` |
| `GOOGLE_PLAY_PACKAGE_NAME` | ⚙️ env | `functions/.env.toka-dd241` | |
| `APP_STORE_ISSUER_ID` / `APP_STORE_KEY_ID` / `APP_STORE_BUNDLE_ID` | ⚙️ env | `functions/.env.toka-dd241` | |
| `APP_STORE_ENV` | ⚙️ env | `functions/.env.toka-dd241` | `Production` (o `Sandbox` para probar) |
| `STRICT_RECEIPT_VALIDATION` | ⚙️ env | `functions/.env.toka-dd241` | `true` en prod |
| `DEBUG_PREMIUM_ALLOWED_UIDS` | ⚙️ env | `functions/.env.toka-dd241` | vacío en release |
| `FUNCTIONS_EMULATOR` | 🤖 runtime | (lo pone el emulador) | NO setear en prod |
| `TOKA_ALLOW_UNVERIFIED_RECEIPTS` | 🚫 nunca-prod | — | dejar sin definir / false |

> Si el grep saca una clave **nueva** que no está en esta tabla → actualízala AQUÍ y decide
> su categoría ANTES de desplegar. Una clave usada por el código y no provista en prod = bug.

### 3b. Verifica los SECRETOS en prod
```bash
cd functions
# ¿Existen en producción? (metadata)
firebase functions:secrets:get GOOGLE_PLAY_SA_JSON   --project toka-dd241
firebase functions:secrets:get APP_STORE_PRIVATE_KEY --project toka-dd241
# Si NO existen y se necesitan, crearlos (pega el contenido):
# firebase functions:secrets:set GOOGLE_PLAY_SA_JSON   --project toka-dd241
# firebase functions:secrets:set APP_STORE_PRIVATE_KEY --project toka-dd241
```
- [ ] 🚦 Cada `defineSecret` del código existe en Secret Manager de `toka-dd241` **o** se ha
  decidido conscientemente dejarlo sin setear (→ la función queda en "bloqueo seguro", no rota).
- [ ] Los mismos secretos están disponibles en **desa** para probar: emulador usa
  `functions/.secret.local` (no commiteado) o inyección en tests; QA local con `.env.local`.

### 3c. Verifica la CONFIG `.env` (paridad de claves desa↔prod)
```bash
cd functions
# Claves presentes en cada entorno (compara que no falte ninguna en prod):
echo "── .env.local (desa) ──"      ; grep -oE '^[A-Z_]+=' .env.local      | sort -u
echo "── .env.toka-dd241 (prod) ──" ; grep -oE '^[A-Z_]+=' .env.toka-dd241 | sort -u
```
- [ ] 🚦 Toda clave ⚙️env que el código usa está en `.env.toka-dd241` con valor real
  (o vacío **a propósito** = bloqueo seguro). Ningún valor "a medias".
- [ ] 🚦 No hay en prod claves de debug/desa que no toquen (revisa diffs de `.env.toka-dd241`).

### 3d. Reglas / índices (si aplica)
- [ ] `firestore.rules` y `firestore.indexes.json` del working tree son los que quieres en prod.
- [ ] Compatibilidad de rollout cliente↔reglas revisada (ver `Arreglos/Hallazgos.md` H-003:
  orden functions → app → reglas para no romper apps antiguas).

---

## 4. Despliegue (SOLO con autorización explícita)

**Orden recomendado** (minimiza ventanas de incompatibilidad, ver H-003):
**1) functions → 2) publicar app → 3) reglas.**

```bash
# Functions (todas o selectivo). Prefijo de timeout SIEMPRE (ver memoria
# deploy-functions-discovery-timeout).
cd functions && npm run build
FUNCTIONS_DISCOVERY_TIMEOUT=120 firebase deploy --only functions --project toka-dd241
# …o una sola función:
FUNCTIONS_DISCOVERY_TIMEOUT=120 firebase deploy --only functions:syncEntitlement --project toka-dd241

# Reglas / índices (cuando toque y tras adoptar la app nueva):
firebase deploy --only firestore:rules --project toka-dd241
firebase deploy --only firestore:indexes --project toka-dd241
```
- [ ] 🚦 Tienes **OK explícito** del usuario para tocar prod.
- [ ] 🚦 §1, §2 y §3 en verde.
- [ ] `Deploy complete!` sin errores; revisar warnings de secrets no resueltos.

---

## 5. Post-deploy — verificación de que prod == desa
- [ ] `firebase functions:list --project toka-dd241` — están las funciones esperadas y
  **no** aparecen funciones de debug que no deban estar en prod.
- [ ] Verificación funcional en **2 dispositivos / 2 cuentas distintas** (físico MI_9 +
  emulador, mismo hogar): el comportamiento nuevo se reproduce y **sincroniza**; ninguna
  cuenta ve lo que no le toca (ver memoria `two-devices-different-profiles`).
- [ ] Inspección de BD con los helpers de `secrets/` (`qa_inspect_home.js`, `qa_premium.js`,
  `qa_dump_tasks.js`, …) para confirmar el estado real en `toka-dd241`.
- [ ] Capturas: analizar y **borrar** (no dejar PNG en el repo).

---

## 6. Rollback
- Functions: `firebase deploy --only functions:<fn>` desde el commit anterior.
- Reglas: re-desplegar la versión previa de `firestore.rules`.
- Config sensible: vaciar la `.env`/secreto vuelve al "bloqueo seguro" donde aplique
  (ej. `syncEntitlement` sin verificadores → rechaza, no activa Premium inseguro).

---

## 7. Registro
- [ ] Actualiza el estado del prompt afectado en `Arreglos/premortem.md`
  (✅ / 🟧 / 🟦) con qué se desplegó y el resultado de la verificación dual.
- [ ] Anota cualquier hallazgo nuevo en `Arreglos/Hallazgos.md`.

---

### Runbooks específicos
- IAP / `syncEntitlement` (Prompt 02): ver `Arreglos/deploy-prompt-02.md` para el detalle
  de credenciales de Google Play / App Store y la prueba sandbox.
