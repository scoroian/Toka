# 00 · 🟦 Arranque — Preparar el entorno (dos dispositivos, Firebase real)

> **Ejecuta este prompt ANTES que cualquier otro del lote.** No es un arreglo: deja el entorno listo y verificado para que el resto de tareas puedan probar en MI_9 físico **y** emulador Android Studio contra **Firebase real**. Lee también `_CONVENCIONES.md`. Marca 🔄 En progreso en `INDICE.md` y ✅ al cerrar.

## Objetivo
Tener, al terminar: ambos dispositivos con el APK de **producción real** instalado y logueados con **cuentas distintas**, un hogar de prueba con datos representativos, un snapshot del estado de tests de partida, y la confirmación de que App Check no bloquea lo que se vaya a probar.

## Checklist de preparación

### 1. Toolchain
- [ ] Flutter de **Windows** operativo vía interop (WSL no compila Android). `flutter doctor` sin bloqueos.
- [ ] `adb.exe` ve **ambos** dispositivos: `adb devices` muestra MI_9 (USB) y `emulator-5554`.
- [ ] `magick.exe` disponible para capturas/resize (≤1900px antes de Read).

### 2. Firebase real
- [ ] Proyecto activo = `toka-dd241` (real), no emuladores. `firebase use` correcto.
- [ ] Admin SDK disponible (`toka-sa.json`) para sembrar/inspeccionar datos.
- [ ] Cuentas QA existen y son válidas (Owner/Member/Admin, ver `toka_qa_session/QA_SESSION.md`).

### 3. Build e instalación (APK real en ambos)
- [ ] `flutter pub get` en **Windows**; build con `lib/main.dart` (NO `main_dev.dart`).
- [ ] Instala el APK en MI_9 y en el emulador. **Verifica el timestamp** del APK recién instalado (evita el bug del APK obsoleto cableado a emuladores).
- [ ] En `logcat` de ambos: **NO** aparece `Mapping Auth Emulator host` (si aparece → reconstruir con `main.dart`).

### 4. Login (cuentas DISTINTAS por dispositivo)
- [ ] MI_9: login por adb (sin Google) con una cuenta (p. ej. Owner). Coordenadas y procedimiento en `_CONVENCIONES.md §3`.
- [ ] Emulador: login con una cuenta **diferente** (p. ej. Member) para validar sync en vivo entre miembros.

### 5. Datos de prueba (semilla)
- [ ] Con Admin SDK / scripts de `scripts/` o `toka_qa_session/`, deja un hogar compartido por ambas cuentas con:
  - tareas de **varias recurrencias** (puntual, diaria, semanal, mensual…) y con responsables repartidos,
  - al menos una tarea propia de cada cuenta para "hoy",
  - estado de miembros suficiente para ver stats/equilibrio.
- [ ] (Para tareas de monetización) ten a mano una cuenta con hogar Premium y otra Free, y una con 5 hogares (para el prompt 01).

### 6. App Check
- [ ] Lanza la app y revisa `logcat`: si alguna callable a probar usa `enforceAppCheck` (p. ej. `syncEntitlement`, `supportDiagnoseHome`), localiza el **debug token** (UUID) y **pide al usuario** que lo registre en consola (no lo registres tú). Anota el token en la nota de cierre.

### 7. Snapshot de tests de partida
- [ ] Corre `flutter test test/unit/` y `npm test` en `functions/` **antes** de tocar nada. Anota el resultado y, en concreto, los **~6 fallos golden preexistentes del WIP** que no son de este lote, para que las sesiones siguientes no los confundan con regresiones suyas.
- [ ] Recuerda: tras un build en Windows, restaura `flutter pub get` en WSL para poder correr tests (rutas `package_config.json`).

## Criterios de aceptación
- [ ] `adb devices` lista los dos dispositivos; ambos con APK real y logueados con cuentas distintas.
- [ ] Confirmado que apuntan a Firebase real (sin línea de emulador en logcat).
- [ ] Hogar de prueba con datos representativos creado y visible en ambos.
- [ ] Snapshot de tests documentado (verde + lista de golden preexistentes).
- [ ] Estado de App Check anotado (token pendiente de registrar, si aplica).

## Al terminar
Actualiza `INDICE.md` (✅ + fecha + nota: cuentas usadas en cada dispositivo, hogar de prueba, baseline de tests, token App Check). Este prompt habilita al resto.
