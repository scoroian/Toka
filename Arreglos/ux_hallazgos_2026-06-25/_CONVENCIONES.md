# Convenciones de ejecución y pruebas — Lote "UX Hallazgos 2026-06-25"

> **Léeme antes de ejecutar cualquier prompt de este lote.** Cada prompt asume que sigues estas convenciones. No las repitas en el código; aplícalas.

## 0. Regla de oro de este lote: **SIEMPRE Firebase real**

Toda verificación en dispositivo y todo test de integración de este lote apunta al proyecto **real `toka-dd241`**, NO a los emuladores de Firebase.

- Compila y ejecuta con el entry point de producción **`lib/main.dart`**, **nunca** `lib/main_dev.dart` (este último cablea Auth/Firestore/Functions/Storage a los emuladores).
- Tras lanzar la app, confirma en `logcat` que **NO** aparece la línea `Mapping Auth Emulator host` (si aparece, estás contra emuladores → reconstruye con `main.dart`).
- Síntoma típico de APK obsoleto apuntando a emuladores: "no user record"/timeout al hacer login. Verifica el timestamp del APK recién instalado.

## 1. Entorno de build

- **WSL no compila Android.** Usa el Flutter de **Windows** vía interop + `adb.exe`.
- Antes de `flutter build`/`run` en Windows: ejecuta `flutter pub get` **en Windows**.
- `pub get` de Windows deja `package_config.json` con rutas `/C:/...` que rompen `flutter test` en WSL → **corre los tests ANTES del build**, o restaura con `flutter pub get` en WSL después.
- Si tocas `freezed`/`riverpod`/`json_serializable`: `dart run build_runner build --delete-conflicting-outputs`.

## 2. Dispositivos (dos perfiles, no la misma prueba)

- **MI_9 físico** (USB, 1080×2340) + **emulador Android Studio** (`emulator-5554`, 1080×2400). Ambos contra Firebase real.
- Usa **cuentas distintas en cada dispositivo** para validar sincronización en vivo entre miembros (no clones la misma cuenta).
- Cuentas QA (`toka_qa_session/QA_SESSION.md`): Owner `toka.qa.owner@gmail.com`, Member `toka.qa.member@gmail.com`, Admin `toka.qa.admin@gmail.com` — todas `TokaQA2024!`.

## 3. Login por adb (sin Google) — procedimiento verificado

**Nunca** uses sugerencias de Google. Escribe email completo y luego salta a contraseña:
```bash
adb shell input tap 540 1053          # campo email
adb shell input text "toka.qa.owner@gmail.com"
adb shell input tap 540 1242          # campo contraseña (sin KEYCODE_TAB)
adb shell input text "TokaQA2024!"
adb shell input tap 540 1441          # Iniciar sesión
```

## 4. Entrada de texto sensible (código de invitación)

`adb shell input text` **corrompe** campos de código (pegado). Para el código de invitación de 6 chars escribe **carácter a carácter** (`type.sh`) o tecléalo con keyevents. No pegues.

## 5. Localizar elementos y capturar

- Localiza por `content-desc` (Flutter expone semántica): `uiautomator dump` + leer el XML; tap por etiqueta.
- `keyevent 111`/`4` **descartan** sheets/diálogos — no los uses para "cerrar teclado" dentro de un bottom sheet; tapea el botón directo.
- Capturas: `adb exec-out screencap -p > /tmp/x.png` → copia a `C:\tmp\` con `magick.exe`. **Redimensiona a ≤1900px** en el lado mayor antes de leer la imagen con Read (límite de la API).
- SnackBars transitorios: captura inmediatamente tras la acción (duran 10 s con `persist:false`).

## 6. App Check (solo tareas que tocan callables con `enforceAppCheck`)

Las callables con `enforceAppCheck` (p. ej. `syncEntitlement`, `supportDiagnoseHome`) rechazan los APK debug de QA con `403 App attestation failed` hasta registrar el **debug token** (UUID que sale en `logcat`) en la consola de Firebase. **No lo registres tú** (lo bloquea el clasificador): pide al usuario que lo registre y continúa cuando confirme.

## 7. Gates obligatorios antes de dar por cerrada una tarea

1. `flutter analyze` → **sin errores**.
2. `flutter test test/unit/` + tests nuevos del hallazgo → **verde**. (Ojo: hay ~6 fallos golden preexistentes del WIP no relacionados; documenta cuáles y por qué no son tuyos.)
3. Si tocas backend: `npm test` en `functions/` → verde. Trocea batches >450 ops (`shared/batch_utils.ts`); `collectionGroup().where()` exige índice `COLLECTION_GROUP` declarado para prod (el emulador no lo exige).
4. Verificación en **ambos dispositivos** contra Firebase real, con capturas.

## 8. Deploy

- Antes de **cualquier** deploy, ejecuta el runbook `DEPLOY.md` (raíz) en orden (gates + paridad dev↔prod de secretos/config).
- Prefija `FUNCTIONS_DISCOVERY_TIMEOUT=120` en `firebase deploy --only functions` (si no, "Timeout after 10000").
- `firebase deploy` despliega el **working tree** (sin commitear): cuidado con WIP.
- El usuario **autoriza** desplegar a `toka-dd241` (dev) mientras la app no esté publicada. Deploy a producción real requiere **OK explícito**.

## 9. i18n y estilo

- **Nada de texto UI hardcodeado.** Todas las strings van en `lib/l10n/app_es.arb`, `app_en.arb`, `app_ro.arb` y se acceden con `l10n.clave`. Regenera localizaciones tras editar ARB.
- SnackBar con acción → `persist: false` y testea que **desaparece** (bug Flutter 3.44: por defecto persiste).
- Las pantallas reales son los `*_v2.dart` (los archivos sin sufijo son wrappers `SkinSwitch`). Edita las V2.

## 10. Cierre de cada tarea (OBLIGATORIO)

Al terminar un prompt:
1. Abre `INDICE.md`, cambia el estado de tu tarea a **✅ Completado**, pon la fecha y una nota de cierre (commit/archivos clave/evidencia).
2. Si descubres que la tarea depende de otra o desbloquea otra, anótalo en el índice.
3. Lista en tu respuesta final los **archivos nuevos/modificados** y enlaza las **capturas** de verificación.
4. **No marques DONE** si algún gate (analyze/tests/device) no está verde.
