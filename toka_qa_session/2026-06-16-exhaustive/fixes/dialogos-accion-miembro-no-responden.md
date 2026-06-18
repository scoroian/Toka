# 🔴 §1 — Diálogos de acción de miembro no responden a toques

**Estado:** ✅ Resuelto · bug **real** (alta severidad) · fix de cliente, sin cambios de backend/reglas.

## ¿Falso positivo? No — bug real

No era artefacto de automatización. La causa es un error de navegación determinista, reproducible al 100 % en un test de widget que recrea el navigator anidado del `ShellRoute` (falla antes del fix, pasa después). La hipótesis del QA ("overlay/scrim por encima del diálogo capturando los toques de la mitad inferior") describe el **síntoma**, no la causa: lo que el usuario percibe como "los botones no responden" es que el diálogo nunca se cierra al pulsarlos.

## Causa raíz

La pantalla de perfil de miembro (`/members/:uid`) vive **dentro del `ShellRoute`** de go_router (`lib/app.dart`), por lo que su `BuildContext` pertenece al **navigator del shell**, no al raíz.

`showDialog(...)` usa `useRootNavigator: true` por defecto → la ruta del diálogo se empuja en el **navigator raíz** (`_rootNavigatorKey`), por encima del shell.

Los botones del diálogo cerraban con el **context de la pantalla** (porque el `builder` ignoraba su propio context con `builder: (_)`):

```dart
// ANTES (buggy)
builder: (_) => AlertDialog(
  actions: [
    TextButton(onPressed: () => Navigator.pop(context, false), ...), // context = pantalla
    FilledButton(onPressed: () => Navigator.pop(context, true), ...),
  ],
),
```

`Navigator.pop(context, ...)` con el context de pantalla resuelve a `Navigator.of(context)` = **navigator del shell**, así que al pulsar un botón se hacía pop de **la ruta del perfil**, no del diálogo. Resultado:

- El diálogo (en el navigator raíz) sigue abierto → "el botón no responde".
- El `Future` de `showDialog` nunca resuelve a `true`/`false` → la acción (promover/degradar/expulsar) **nunca se ejecuta**.
- El **barrier** sí cierra el diálogo porque lo gestiona el modal-barrier del propio navigator raíz → "tocar arriba (barrier) sí cierra".

Por qué otros diálogos de la app sí funcionan: usan el **context del builder** (`Navigator.of(ctx).pop(...)`), que resuelve correctamente al navigator raíz donde vive el diálogo. Ejemplos: `task_detail_screen_v2.dart` (`Navigator.of(c).pop(...)`), `settings_screen.dart` (`Navigator.of(ctx).pop(...)`). El perfil de miembro era el **único** sitio con el antipatrón `builder: (_)` + `Navigator.pop(context, ...)` (verificado con grep en todo `lib/`).

## Fix

`lib/features/members/presentation/skins/member_profile_screen_v2.dart` — en los dos `showDialog` (el de `_toggleAdminRole`, que cubre **promover** y **degradar**, y el de `_confirmRemoveMember`, que cubre **expulsar**): nombrar el context del builder y cerrar con él.

```dart
// DESPUÉS (fix)
builder: (dialogContext) => AlertDialog(
  actions: [
    TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), ...),
    FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), ...),
  ],
),
```

`Navigator.of(context).pop()` de la línea posterior a `removeMember` (cerrar el perfil tras expulsar con éxito) se mantiene: ahí **sí** queremos el context de pantalla para hacer pop de la ruta del perfil en el shell.

Sin hardcodear texto (todo via ARB, sin cambios de i18n). Backend (`promoteToAdmin`/`demoteFromAdmin`/`removeMember` en `functions/src/homes/index.ts`) ya era correcto y no se toca.

## Tests

`test/ui/features/members/member_profile_screen_v2_test.dart` — nuevo grupo con un harness `_wrapNested` que monta la pantalla en un **`Navigator` anidado** bajo el navigator raíz del `MaterialApp` (reproduce el `ShellRoute`). 4 tests nuevos:

1. Confirmar "Hacer admin" → cierra el diálogo, llama `promoteToAdmin` 1 vez y **conserva** la ruta del perfil.
2. Cancelar → cierra el diálogo, **no** llama a la acción y conserva el perfil.
3. Confirmar "Quitar admin" → cierra el diálogo y llama `demoteFromAdmin` 1 vez.
4. Confirmar "Expulsar" → cierra el diálogo y llama `removeMember` 1 vez.

Verificación fail-before/pass-after: con el código buggy (revertido temporalmente) los 4 fallan (`AlertDialog` sigue presente, las acciones no se invocan); con el fix pasan los 6 del archivo. `flutter analyze` del lib + test: **sin issues**.

> Nota de entorno: `flutter test test/ui/features/members/` muestra 4 fallos **pre-existentes** en `members_screen_test.dart` (golden con 99.78 % de diff = render de otra máquina + churn CRLF/LF de builds Windows). No importan `member_profile_screen_v2.dart` y son ajenos a este fix (documentado en memoria del proyecto).

## Verificación en los 2 dispositivos

Estado preparado **[ADMIN SDK]**: `node secrets/qa_premium.js SMQRtCjrA09gPIr1wazD wwL0OTdrNeMZs2wTt6QtRDT1nb53 active` (premium para que la opción admin aparezca). Hogar con owner N2 (`wwL0OTdrNeMZs2wTt6QtRDT1nb53`) y miembro N1 "Sebas N1" (`role=admin`). Login como N2 (owner) → Miembros → "Sebas N1".

APK compilado en Windows (`flutter.bat pub get && flutter.bat build apk --debug`) e instalado con `adb install -r -g` en ambos. Interacción con `input tap` real sobre el centro exacto de cada botón (coords del `ui.sh`); estado leído por dump de UI y `[ADMIN SDK]`.

**Emulador `emulator-5554`** (1080x2400):
- Degradar → **Cancelar**: el diálogo se cierra y permanece en el perfil (N1 sigue Admin). ✅
- Degradar → **Confirmar**: el diálogo se cierra y N1 pasa a **Miembro** en vivo (badge + botón cambian a "Hacer administrador"). ✅
- Promover → **Confirmar**: N1 vuelve a **Admin** en vivo. ✅
- Expulsar → **Cancelar**: el diálogo se cierra y permanece en el perfil. ✅

**MI_9 físico `43340fd2`** (1080x2340) — login N2 por adb char-a-char (`type.sh`), sin Google:
- Degradar → **Confirmar**: el diálogo se cierra y N1 pasa a **Miembro** en vivo. ✅
- Promover → **Confirmar**: N1 vuelve a **Admin** en vivo. ✅
- Expulsar → **Cancelar**: el diálogo se cierra y permanece en el perfil. ✅

En ambos dispositivos los botones (la "mitad inferior" del diálogo que antes no respondía) ahora reaccionan al primer toque, cierran el diálogo y ejecutan la acción. El camino "Confirmar Expulsar" no se ejecutó en dispositivo a propósito para conservar al miembro huérfano N1 (§3); queda cubierto por el test de widget. Estado final verificado **[ADMIN SDK]**: N1 `role=admin status=active`, N2 `role=owner` (sin cambios netos). Capturas tomadas durante la verificación y **borradas** al terminar.

## Mejoras / otros fallos detectados

- Antipatrón aislado: solo el perfil de miembro tenía el `builder: (_)` + pop con context de pantalla. El resto de la app ya usaba el context del builder. No se detectaron otros diálogos afectados.
- (Relacionado, fuera de alcance de este fix) El miembro N1 del hogar de pruebas es el **huérfano** del §3 (cuenta borrada, `status=active`). Útil para ese hallazgo; no se expulsó durante esta verificación para conservarlo.
