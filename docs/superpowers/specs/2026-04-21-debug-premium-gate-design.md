# Spec: Gating del toggle debug de premium a builds de desarrollo

**Fecha:** 2026-04-21
**Estado:** Propuesto
**Prioridad:** Crítica (BUG-25, filtración de debug en release)

---

## Contexto

La spec del 2026-04-18 (`2026-04-18-debug-premium-toggle-design.md`) añadió:

1. El tile **🧪 DEBUG: Estado premium** en *Ajustes del hogar*, con la intención de envolverlo en marcadores para eliminar a mano antes del release.
2. La Cloud Function `debugSetPremiumStatus`.

Durante la QA del 2026-04-20 (BUG-25) se confirmó que:

- El tile aparece en el build ejecutado en el emulador aunque no sea un build `--debug`.
- La Cloud Function está deployada en el proyecto por defecto (sin gating de entorno) y respondería también en producción.

El enfoque "lo borramos a mano antes de release" no es suficiente: la spec 2026-04-18 lo reconoce explícitamente en su sección *"Fuera de alcance"* y renuncia a gating por flag de build. Esta spec cierra esa puerta con un gating **real y automático**, sin eliminar el toggle (sigue siendo útil en dev).

---

## Decisiones clave

- **Cliente:** gating doble — `kDebugMode` **y** un flag de Remote Config `debug_tools_enabled`. El flag permite rehabilitarlo para un build interno (staging) sin recompilar.
- **Backend:** la Cloud Function sólo responde si `process.env.TOKA_ENV !== "prod"`. En el proyecto de producción la variable vale `"prod"`; en dev/staging vale `"dev"` o `"staging"`.
- **Ninguna función de debug** se despliega al proyecto de producción. Se condiciona el `export` en `functions/src/index.ts`.

Con este enfoque:

1. Un usuario que descompile la APK no ve el toggle (condicional `kDebugMode` en Dart).
2. Aun si alguien parchea el cliente, el callable rechaza la petición en `prod` con `permission-denied`.
3. Aun si alguien consigue invocar el callable en dev, seguimos exigiendo que sea owner del hogar (ya cubierto en spec previa).

---

## Cambios en cliente

### 1. Flag de Remote Config

Añadir al provider de Remote Config un nuevo valor `bool debugToolsEnabled` con **default `false`**. Se lee en [lib/features/homes/application/home_settings_view_model.dart](lib/features/homes/application/home_settings_view_model.dart).

### 2. `HomeSettingsViewData.showDebugPremiumToggle`

Cambiar la condición:

```dart
// ANTES (spec 2026-04-18)
showDebugPremiumToggle: isOwner

// DESPUÉS
showDebugPremiumToggle: isOwner && (kDebugMode || remoteConfig.debugToolsEnabled)
```

Importar `package:flutter/foundation.dart` en el ViewModel si no estaba ya.

### 3. `HomeSettingsScreen`

No cambia el tile en sí: sigue envuelto en sus marcadores `// DEBUG PREMIUM — REMOVE BEFORE PRODUCTION` y condicionado a `data.showDebugPremiumToggle`. El cambio es únicamente en la fuente de ese booleano.

### 4. Defensa extra en Release

El `HomesRepositoryImpl.debugSetPremiumStatus` envuelve la llamada:

```dart
Future<void> debugSetPremiumStatus(String homeId, String status) async {
  if (kReleaseMode) {
    throw StateError("debugSetPremiumStatus no disponible en release");
  }
  // ...existing callable invocation...
}
```

Esto garantiza que aunque un futuro refactor se olvide del gating de UI, el intento desde el cliente release falla sin tocar red.

---

## Cambios en backend

### 1. Variable de entorno

Añadir a la configuración Firebase del proyecto de producción:

```
firebase functions:config:set toka.env="prod"
```

Y en dev/staging respectivamente `"dev"` / `"staging"`. Se expone como `process.env.TOKA_ENV` en el runtime (Node.js 20 lee `functions.config()` de forma retrocompatible, o se usa `process.env.TOKA_ENV` directo si se pasa con `--set-env-vars`).

### 2. Gating del callable

En [functions/src/homes/index.ts](functions/src/homes/index.ts), al inicio de `debugSetPremiumStatus`:

```ts
// DEBUG PREMIUM — REMOVE BEFORE PRODUCTION
export const debugSetPremiumStatus = onCall(async (request) => {
  const env = process.env.TOKA_ENV ?? "dev";
  if (env === "prod") {
    throw new HttpsError("permission-denied", "debug_tools_disabled_in_prod");
  }
  // ... resto de la lógica ...
});
// END DEBUG PREMIUM
```

### 3. Condición de export

En [functions/src/index.ts](functions/src/index.ts):

```ts
// DEBUG PREMIUM — REMOVE BEFORE PRODUCTION
if ((process.env.TOKA_ENV ?? "dev") !== "prod") {
  export { debugSetPremiumStatus } from "./homes";
}
// END DEBUG PREMIUM
```

(Si el build TS no admite `export` condicional a nivel top-level con la configuración actual, se usa re-export explícito detrás de un `if` con `require` en `index.ts` — equivalente funcional.)

---

## Tests

- `home_settings_view_model_test.dart`: nuevo caso que verifica que `showDebugPremiumToggle=false` cuando `kDebugMode=false` y `debugToolsEnabled=false`, y `true` en el resto de combinaciones razonables.
- `functions/src/homes/index.test.ts` (nuevo o ampliando el existente): llamada al callable con `process.env.TOKA_ENV="prod"` devuelve `permission-denied`.

No se añaden tests UI específicos — el test del ViewModel es suficiente porque el widget sólo lee el booleano.

---

## Plan de despliegue

1. Merge de esta spec en develop.
2. En Firebase del proyecto de producción: `firebase functions:config:set toka.env="prod"` + redeploy.
3. En Remote Config de producción: crear la key `debug_tools_enabled` con default `false` y **sin condiciones**.
4. Verificar en un build release que el tile ya no aparece.
5. Re-ejecutar la regresión BUG-25 de la sesión QA 2026-04-20.

---

## Fuera de alcance

- Renombrar el tile o moverlo a otra pantalla (ya está en su sitio lógico).
- Sustituir Remote Config por Firebase App Check (planteable a futuro si crece la lista de herramientas debug).
- Auditoría de otras Cloud Functions potencialmente "debug-only" — se cubrirá en una pasada aparte si aparecen en el registro.
