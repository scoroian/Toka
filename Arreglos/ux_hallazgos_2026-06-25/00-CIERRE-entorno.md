# 00 · Nota de cierre — Entorno listo (2026-06-25)

Entorno preparado para el lote. **Firebase real `toka-dd241`** en ambos dispositivos. APK real (`lib/main.dart`) confirmado en runtime (sin `Mapping Auth Emulator host`).

## Dispositivos y cuentas (perfiles distintos)

| Dispositivo | Serial | Resolución | Cuenta | Rol |
|-------------|--------|-----------|--------|-----|
| Emulador Android Studio | `emulator-5554` | 1080×2400 | `toka.real.ana@tokatest.dev` | **owner** de Casa |
| MI 9 físico (USB) | `43340fd2` | 1080×2340 | `toka.real.beto@tokatest.dev` | **member** de Casa |

> Decisión del usuario: **mantener Ana/Beto** (no re-loguear a las QA gmail). Son cuentas distintas y ya comparten hogar. Confirmado en runtime: en el emulador las tareas de Ana muestran Hecho/Pasar (es Ana); en MI_9, CasaDos muestra "Sacar al perro"→Beto con Hecho/Pasar (es Beto).

UIDs: Ana=`jFNBvm25nWS2Ag4j35yFqrBHkWm1` · Beto=`3E1RQwmE1JgT0ZntGUHc6zfOjx23` · QA-owner=`m9K1hwXkB1hLGtE2ZddBy2UfIEb2` · QA-member=`Ko7pGuGLfVXow7kSduSv33cBT7h1` · QA-admin=`WAS3FTcW3fOR4pP85pNSDI9vZ6s2`.

## Estado de datos (Firestore real, tras purga)

19 hogares → **purgados a 8** (decisión del usuario). Scripts: `secrets/qa_seed_lote_20260625.js` (seed) y `secrets/qa_purge_lote_20260625.js` (purga, dry-run por defecto, `EXECUTE=1` para borrar).

| Hogar | id | Estado | Para |
|-------|----|--------|------|
| **Casa** | `xBjacg2JdYhHTpX6NsI1` | Free, Ana+Beto, **8 tareas activas** todas vencen hoy | Hogar representativo (recurrencias + reparto) |
| **CasaDos** | `VFYGj84mhZc6S7LOR5no` | **Premium (familia)**, Ana(payer)+Beto, 2 tareas | Monetización / multi-hogar |
| QA Cap A–E | `qa-cap5-home-0..4` | Free, owner cap5 | Prompt 01 (cuenta al límite) |
| QA Cap Target | `qa-cap-target` | Free, owner QA-owner, invitación `CAP6TG` | Prompt 01 (unirse a 6º) |

- **Casa "Hoy"** (reconstruido por el trigger `onTaskWriteUpdateDashboard`): Puntual `Montar la estantería`→Beto · Hora `Revisar caldera`→Beto · Día `Fregar platos`/`Limpiar bano`→Ana, `Sacar basura`→Beto · Semana `Compra semanal`→Ana · Mes `Pagar alquiler`→Beto · Año `Renovar el seguro`→Ana. Stats de miembro desequilibradas (Ana por delante) para "equilibrio del hogar".
- **Cuenta al límite (prompt 01):** `toka.qa.cap5@tokatest.dev` / `TokaQA2024!` (verificada). `homeSlotCap=5` y **5 memberships activas** = AL LÍMITE. UID `nPPIFokG7jV7kauXSbdBEGqHtYQ2`.
- **Premium/Free a mano:** CasaDos (Premium) + Casa (Free). Los prompts de monetización pueden flipear estados con `secrets/qa_set_tier.js`.

## App Check — ✅ resuelto

Los dos debug tokens **registrados** vía la API REST de App Check (`firebaseappcheck.googleapis.com`, no la consola) con el service account `toka-sa.json` → `secrets/qa_register_appcheck_tokens.js`:

- **Emulador:** `4d683969-226c-41c6-bc1a-948bfb990c62` ✓
- **MI_9:** `0078e727-d3aa-404b-8503-d5948157dcfe` ✓

Verificado end-to-end: tras relanzar, logcat ya NO da `403 App attestation failed`; ambos obtienen JWT válido (`🔑 APP CHECK DEBUG TOKEN: eyJ…`, aud `projects/toka-dd241`, provider `debug`). Las callables con `enforceAppCheck` (`syncEntitlement`, `supportDiagnoseHome`) ya funcionan en device.

## Baseline de tests (antes de tocar nada)

**Backend** (`functions/`, runners canónicos):
- unit/colocados (`jest`, sin emulador): **424/424 ✓**
- `test:rules` (con emuladores): **171/171 ✓**
- `test:integration` (con emuladores): **332/333** — 1 fallo: `cleanup_user.test.ts` › "borra el objeto de la foto en Cloud Storage" (espera 404, el objeto sigue). **Dependiente del emulador de Storage / entorno, NO del lote.**
- ⚠️ `npm test` plano mezcla configs (no carga el setup de integración) → da falsos fallos; usar los runners separados.

**Flutter:**
- `flutter test test/unit/`: **916/916 ✓**
- golden (`test/ui` `--plain-name "golden:"`): **36/40**, **4 fallos** por `google_fonts` no pudiendo descargar PlusJakartaSans (sin red en el entorno de test). **Ambientales, no regresiones.** Son: `members_packs_limit` (banner Toka Business tope abs. / banner tope dinámico Grupo), `paywall_packs` (sección packs Grupo es), `tiered_paywall` (paywall tiers anual).
- ⚠️ `flutter test test/ui/` completo: el test `member_profile_screen_v2_test.dart` › "Hacer admin dispara promoteToAdmin" **se cuelga** en WSL (flakiness del harness, no regresión). Correr UI por archivos o usar `--plain-name`.

## Notas de entorno

- WSL no compila Android → build con Flutter de **Windows**; tests en **WSL**. `package_config.json` restaurado a rutas WSL con `flutter pub get` (WSL). **No se reconstruyó APK** (el instalado ya era real).
- adb.exe ve ambos: `43340fd2` (MI 9) + `emulator-5554`.
