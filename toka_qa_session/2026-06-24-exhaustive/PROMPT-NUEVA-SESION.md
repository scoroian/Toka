# Prompt para la nueva sesión de Claude Code

Copia y pega lo que hay dentro del bloque siguiente como primer mensaje de la nueva sesión.

---

Continúa la sesión de QA exhaustiva + corrección de hallazgos de la app Flutter "Toka" (gestión de tareas del hogar) sobre Firebase de PRODUCCIÓN (toka-dd241). Responde siempre en español.

LO PRIMERO QUE DEBES HACER: lee estos dos documentos enteros antes de tocar nada:
- `toka_qa_session/2026-06-24-exhaustive/HANDOFF-FIXES.md` (estado exacto de los 6 fixes, detalle técnico archivo:línea de cada uno, entorno, cuentas, gotchas y qué falta por probar).
- `toka_qa_session/2026-06-24-exhaustive/HALLAZGOS.md` (informe de la QA original).

OBJETIVO (en este orden):
1. Termina los 6 fixes de los hallazgos: el #1 ya está hecho y verificado; el #4 está implementado y compilado pero FALTA verificarlo visualmente; el #5, #3, #2 y #6 están analizados con plan técnico exacto en el handoff pero SIN implementar. Implementa cada uno, escribe/actualiza su test unitario, compila y verifica.
2. Cuando los 6 estén cerrados, CONTINÚA las pruebas exhaustivas de los flujos/pantallas que quedaron sin probar (lista en la sección 7 del handoff: vacaciones de miembro, soporte/diagnóstico, login social, IAP real, tope de 3er hogar, edición de avatar/foto, pestaña Congeladas, toggle de tema Claro/Oscuro, escaneo QR, etc.). Apunta hallazgos nuevos en HALLAZGOS.md.

FUENTE DE VERDAD: el código, no los documentos previos (que pueden quedar obsoletos). Haz tus propios análisis.

ENTORNO Y DISPOSITIVOS:
- Hay un MI_9 físico (serial 43340fd2) conectado por USB, contra Firebase prod. El emulador estaba MUY inestable: úsalo solo si arranca bien; si no, trabaja con el MI_9.
- adb: `C:\Users\sebas\AppData\Local\Android\Sdk\platform-tools\adb.exe`. Flutter (Windows): `C:\Users\sebas\flutter\flutter\bin\flutter.bat`. Compila con flutter.bat (no WSL); si tocas .arb haz `flutter gen-l10n` antes. APK en `build/app/outputs/flutter-apk/app-debug.apk`.
- Cuentas (Firebase prod): Ana `toka.real.ana@tokatest.dev` / `TokaReal2024` (owner de Casa homeId `xBjacg2JdYhHTpX6NsI1` y CasaDos `VFYGj84mhZc6S7LOR5no`); Beto `toka.real.beto@tokatest.dev` / `TokaReal2024` (member de Casa). Crea usuarios nuevos por el formulario si necesitas más (dominio `@tokatest.dev`, no requiere verificación de email).
- IMPORTANTE: Casa quedó en premium `active` por error de la sesión anterior; revierte a free al empezar si no la necesitas premium: `node secrets/qa_set_state_for.js xBjacg2JdYhHTpX6NsI1 free`.
- Admin SDK (`secrets/toka-sa.json`) AUTORIZADO ÚNICAMENTE para modificar premium/free/tier/Plus de los hogares de prueba (para verificar gating). Scripts: `qa_set_state_for.js <homeId> <free|active|rescue|cancelledPendingEnd|expiredFree|restorable>`, `qa_plus.js <email> <on|off>`, `qa_inspect_email.js <email>`.

GOTCHAS CRÍTICOS (para no atascarte como la sesión anterior):
- En MIUI (MI_9) `adb input text` CORROMPE textos largos (emails). Escribe carácter a carácter: un `input text "X"` por carácter con `sleep 0.12` entre cada uno.
- Los test-ads de AdMob (banner e intersticial) son CLICKABLES: un tap a ciegas los abre en Chrome → ANR. NUNCA tappees a ciegas cerca de un ad; localiza siempre el botón con `uiautomator dump` y tappea su centro exacto.
- Para evitar intersticiales mientras navegas, pon el hogar en premium (con premium nadie ve intersticial). Para verificar el BANNER (fix #4) necesitas free o un miembro no-pagador. El FAB de crear tarea solo lo tienen owner/admin.
- Capturas: usa un helper que capture con adb exec-out screencap y redimensione con magick.exe a ≤1900px antes de leerla con Read; bórrala tras analizarla. (La sesión anterior dejó `cap.sh` en el scratchpad).

VERIFICACIÓN (preferencia por robustez):
- Para la LÓGICA (#5, #3, #2, #6) la verificación PRIMARIA son TESTS unitarios (`flutter.bat test test/...`). Si `flutter test` en WSL falla por rutas, corre los tests con flutter.bat (Windows) o haz `flutter pub get` en WSL antes.
- Para lo VISUAL (#4 y el QA de pantallas) verifica en el MI_9 con capturas. Verifica en los dos dispositivos solo cuando el emulador coopere; si no, deja constancia.
- `flutter analyze` debe pasar sin errores. No hagas commit ni despliegues sin OK explícito del usuario.

Trabaja como un usuario real, apunta cada hallazgo en HALLAZGOS.md con severidad, y mantén actualizado el handoff. Empieza leyendo el HANDOFF-FIXES.md y dime tu plan antes de implementar.
