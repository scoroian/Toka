# Hallazgos QA exhaustiva (2026-06-18/19) — issues accionables

Documento de issues/observaciones encontrados durante la QA en 2 dispositivos (emulador `emulator-5554` + MI_9 `43340fd2`), producción `toka-dd241`. El log completo de todo lo probado (incl. lo que pasó OK) está en `REPORT.md`.

Severidad: 🔴 alta · 🟠 media · 🟡 baja/UX · ⚠️ observación.

## Abiertos

### ✅ 🔴-6 [ARREGLADO] Recuperar contraseña: nunca muestra la confirmación de envío
- **Repro (device MI_9):** login → "¿Olvidaste tu contraseña?" → escribir email válido → "Enviar enlace". El email se envía (Firebase), pero la pantalla **se queda en el formulario**; nunca aparece la vista de confirmación ("Te hemos enviado un correo…" + check verde). El usuario no sabe si funcionó.
- **Causa raíz:** `forgotPasswordViewModelProvider` (provider derivado `@riverpod`) hace `return ref.read(notifier.notifier)` → devuelve SIEMPRE la misma instancia del notifier. La pantalla hacía `ref.watch(forgotPasswordViewModelProvider)`; al cambiar el state (`resetSent:true`) Riverpod compara el valor con `==` (misma instancia) y NO notifica → no hay rebuild. A diferencia de login/register (que usan `ref.listen` para reaccionar), la pantalla de forgot dependía SOLO de `ref.watch` para mostrar la confirmación.
- **Fix:** `forgot_password_screen.dart` ahora observa el STATE del notifier: `ref.watch(forgotPasswordViewModelNotifierProvider)` y usa `state.resetSent`/`state.isLoading`. Test nuevo (provider real + fake auth) en `forgot_password_screen_test.dart`: "tras enviar con éxito muestra la confirmación (rebuild)". **✅ VERIFICADO EN DEVICE (MI_9):** tras "Enviar enlace" aparece el check verde + "Te hemos enviado un correo para restablecer tu contraseña".

### ✅ FALSO POSITIVO (resuelto) — "Crear 2º hogar falla" era artefacto de automatización
**CONCLUSIÓN: NO es un bug.** Crear hogar desde el selector y desde el estado vacío FUNCIONA. El fallo lo causaba mi automatización: usaba `adb shell input keyevent KEYCODE_BACK` para cerrar el teclado tras escribir el nombre, y eso **cerraba el bottom sheet** del formulario; el "Crear" posterior caía en vacío → no se llamaba a la CF. Pista decisiva: `users/{luna}.lastSelectedHomeId` quedaba `undefined` (la ruta de éxito de `_submitCreate` nunca corría). Re-test SIN el BACK (tapeando "Crear" directamente, encima del teclado): hogar creado y cambiado correctamente; BD confirma Luna con 2 hogares (Hogar Sync QA + Hogar Real QA). El onboarding no se veía afectado porque su "crear hogar" es pantalla completa (BACK solo cierra teclado), no bottom sheet.

<details><summary>Descripción original (incorrecta) del supuesto bug</summary>

### 🔴-0 ~~Crear un 2º hogar desde el selector falla en silencio~~ (FALSO POSITIVO)
- **Repro (emulador, Luna, owner de "Hogar Sync QA" premium activo, 1 hogar):** cabecera Hoy → selector → "Añadir hogar" → "Crear un hogar" → nombre "Hogar Dos QA" → "Crear". El sheet se cierra y vuelve a Hoy SIN error, pero:
  - No cambia al hogar nuevo (sigue en "Hogar Sync QA").
  - El hogar nuevo NO aparece en el selector.
  - **Persiste tras reiniciar la app** → no es refresco en vivo: el hogar no quedó creado/asociado server-side.
  - Reproducido 2 veces. Había slots disponibles (apareció el formulario, no el banner de límite).
- **Esperado:** crear el hogar, asociarlo a Luna y cambiar a él (como en el onboarding, que sí funciona).
- **Impacto:** ALTO — un usuario no puede crear su 2º hogar desde la app (función central del modelo multi-hogar). El onboarding (primer hogar) sí funciona.
- **Pistas de código:** `lib/features/homes/presentation/home_selector_widget.dart` `_AddHomeSheetState._submitCreate` (hace `homesRepositoryProvider.createHome` → CF `createHome` → `updateLastSelectedHome` → `switchHome`; hace `Navigator.pop()` solo en éxito, así que la CF no lanzó excepción). `lib/features/homes/data/homes_repository_impl.dart:52` `createHome` (callable `createHome`). Backend `functions/src/homes/index.ts` `createHome`. Comparar con la ruta del onboarding `home_creation_repository_impl` que sí crea+asocia. Falta confirmar server-side si crea el doc home sin la membership (huérfano) o no crea nada.
- **Bloquea:** prueba de selector con 2 hogares (flecha + cambio) — no verificable hasta arreglar esto.
- **AMPLIADO (2026-06-19):** NO es solo el selector. Tras eliminar el hogar (Luna queda "Sin hogar"), el botón **"Crear hogar" del estado vacío del Home** (misma `_AddHomeSheet`) TAMBIÉN falla: el hogar no se crea (sigue "Sin hogar" tras reiniciar). Probado con Luna a 0 y a 1 hogar. **Solo funciona el create del onboarding (primer hogar) — `home_creation_repository_impl.createHome`.** Ambas rutas rotas usan `homes_repository_impl.createHome`; ambas llaman a la MISMA CF `createHome`, así que la diferencia está en el cliente (manejo del resultado/switchHome) o en una precondición de la CF dependiente de estado. Severidad efectiva: un usuario solo puede tener el hogar del onboarding; no puede crear más ni recrear uno tras abandonar/eliminar, desde dentro de la app. **Bloquea además la recreación del setup de QA por la app.**

(↑ Todo lo anterior quedó INVALIDADO: era el artefacto del BACK. Ver conclusión arriba.)
</details>

### ✅ ⚠️-4 [POR DISEÑO] "Eliminar hogar" deja el home doc (soft-delete "purged")
**CONCLUSIÓN: intencional, no es bug.** `closeHome` (CF `functions/src/homes/index.ts:614`) hace soft-delete: `home.premiumStatus="purged"` + borra la membresía del owner. NO hace hard-delete del home doc (es un tombstone). Todo el procesamiento excluye los "purged" (`update_dashboard.ts where premiumStatus != "purged"`, restore bloqueado para "purged"). Mismo patrón que `cleanup_user.ts` para hogares que quedan huérfanos. Para el usuario el hogar desaparece (sin membresía, no visible, no recuperable), que es lo que promete el diálogo. (Observación menor de higiene: `closeHome` no borra el sub-doc `homes/{id}/members/{owner}` ni tasks/dashboard del tombstone; no es user-facing.)

<details><summary>repro/observación original</summary>

### ⚠️-4 ~~"Eliminar hogar" (Caso C) deja huérfano~~ (POR DISEÑO)
- **Repro:** Luna, miembro único de "Hogar Sync QA" → Ajustes → Abandonar hogar → diálogo "Eliminar hogar (eres el único miembro… se eliminará permanentemente)" → confirmar. UI: pasa a "Sin hogar" (✅ la membresía se quita y la app no muestra el hogar).
- **Observado en BD (lectura puntual autorizada):** el documento `homes/{id}` de "Hogar Sync QA" **seguía existiendo** con `ownerUid=Luna` pero Luna con **0 membresías** a él (hogar huérfano: poseído pero sin miembros).
- **Pendiente de confirmar:** si es un bug (el borrado solo quita la membresía y no elimina el home doc) o si hay una limpieza async (trigger) que lo borra más tarde. No reconfirmé por no abusar del Admin SDK.
- **Pista:** flujo de leave/delete en `settings_screen.dart` (`_transferAndLeave`/delete sole-member) + backend `functions/src/homes/index.ts` (leaveHome/deleteHome). Verificar que el caso sole-member borre el home doc (y subcolecciones).
</details>

### ✅ 🟠-5 [ARREGLADO] Errores de auth (login/registro) rebotan a un login vacío sin mensaje claro
**FIX:** `lib/app.dart` redirect — **`loading` Y `error`** ahora se comportan como `unauthenticated` (se quedan si `authScreens.contains(location)`), en vez de forzar `/splash`→`/login`. La causa raíz real (revelada en device) era doble: durante el intento, `loading` mandaba `/register → /splash`, y luego `error` desde `/splash` → `/login`. Test: `test/unit/app_router_redirect_test.dart` (8 casos, loading+error). **✅ VERIFICADO EN DEVICE (MI_9), ambas rutas:** (1) registro con email duplicado → se queda en /register con email+contraseñas intactos; (2) login con contraseña incorrecta → se queda en /login con el formulario intacto. Ambas pantallas muestran el error vía SnackBar (`register_screen`/`login_screen` líneas ~25-31).

<details><summary>descripción original</summary>

- **Repro login:** login con email real + contraseña incorrecta → el formulario se **vacía** y NO se ve un mensaje de error claro (no se pudo capturar SnackBar; varios intentos).
- **Repro registro:** registro con email YA EXISTENTE (toka.sync.luna@…) + contraseñas coincidentes → la app **salta a la pantalla de login vacía** en lugar de quedarse en registro mostrando "email ya en uso".
- **Causa probable:** `app.dart` redirect `error: (_) => location==login ? null : login` → cualquier `AuthState.error` redirige a login; al reconstruir la pantalla se pierde el formulario y el SnackBar del view-model (atado a la pantalla anterior). Para registro es claramente incorrecto: el error de email-duplicado debería mostrarse inline en la pantalla de registro, no expulsar a login.
- **Impacto:** medio (UX): el usuario no entiende por qué falló (¿contraseña mal? ¿email en uso?) y pierde lo escrito.
- **Pistas:** `lib/app.dart` redirect del estado `error`; `register_view_model.dart`/`login_view_model.dart` (manejo de error → SnackBar) vs el redirect. Considerar NO redirigir en error y mostrar el error inline en la misma pantalla.
- **Nota:** la validación CLIENTE sí funciona bien (email mal formado → "Introduce un email válido"; y §6: el error se limpia al corregir).
</details>

### ✅ ⚠️-1 [ARREGLADO] La descripción de la tarea no se muestra en el detalle
**FIX:** `task_detail_screen_v2.dart` — añadido bloque `Key('detail_description')` bajo el título que muestra `task.description` si no está vacía. Tests en `task_detail_screen_v2_test.dart` (muestra / no-muestra). **✅ VERIFICADO EN DEVICE (emulador):** tarea creada con descripción → el detalle la muestra bajo el título, encima de la tarjeta Responsable/Próxima/Dificultad.

<details><summary>original</summary>
- **Repro:** crear/editar una tarea con descripción (p. ej. "QA editado desc") → abrir su detalle. El detalle muestra Responsable/Próxima vez/Dificultad/Próximas fechas, pero NO la descripción.
- **Esperado:** mostrar la descripción si existe.
- **Impacto:** bajo; el dato se guarda (se ve al reeditar) pero no se consulta.
- **Pista:** `lib/features/tasks/presentation/skins/task_detail_screen_v2.dart`.
</details>

### ✅ 🟡-2 [NO ES BUG] "Pasar turno" no mostraba penalización (era 0% de cumplimiento)
**CONCLUSIÓN: comportamiento correcto.** El aviso de penalización se muestra solo `if (diff >= 1.0)` (caída ≥1 punto). Lo probé con Luna a 0% (0 completadas/0 pasadas) → estimada = 0/(0+0+1) = 0 → diff = 0 → no hay penalización real que mostrar. Con un usuario con historial SÍ se muestra. Cubierto por los tests existentes `test/ui/features/tasks/pass_turn_dialog_test.dart` ("muestra banner rojo cuando diff >= 1%", 87→81 / 90→80). No requiere fix.

### ✅ ⚠️-3 [MEJORADO] Valoración: 2,5★ junto a "5.0" → ahora "5.0 / 10"
**Por diseño** (escala 1–10 mostrada como 5 estrellas vía `score/2`), pero **apliqué el tweak de claridad** para que el número no parezca máximo de 5: ahora muestra **"X.X / 10"** junto a las estrellas (`_ScoreStars`) y en el slider del rate sheet ("Puntuación: X.X / 10"). Nueva clave l10n `review_score_value` en es/en/ro + `history_rate_score_label` actualizada. Test: `history_event_detail_screen_test.dart` asegura `find.text('9.0 / 10')`. (Las estrellas siguen siendo `score/2`, correcto.)

<details><summary>repro original</summary>
- **Repro:** valorar una tarea con la "Puntuación 5.0" del slider → detalle del evento muestra 2,5 estrellas (de 5) y el número "5.0".
</details>
- **Impacto:** UX menor.
- **Pista:** widget de estrellas en el detalle de evento / `review` widgets.

## Cerrados / verificados OK
Ver `REPORT.md`. Fixes confirmados en vivo: §1, §2, §5, §9, §11, §14 + fix de registro→onboarding.
</content>
