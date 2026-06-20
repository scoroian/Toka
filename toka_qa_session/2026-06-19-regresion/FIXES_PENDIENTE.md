# Fixes QA 2026-06-19 — estado y lo que falta

## ✅ Hecho (código + tests, listo en el working tree)

Los 6 hallazgos accionables de la sesión están **implementados** y `flutter analyze` pasa limpio en el código de producción.

| # | Fix | Archivos |
|---|-----|----------|
| 🟠-2 | "Abandonar hogar" ya NO ofrece transferir a un no-owner. `isOwner` se deriva de `home.ownerUid` (vía view model), no de `members.first` (caché stale). | `lib/features/settings/application/settings_view_model.dart` (campo `ownerUid`), `lib/features/settings/presentation/settings_screen.dart` |
| ⚠️-b | Mapeo de errores del join: `failed-precondition`→`MaxMembersReachedException` (hogar Free lleno) + refactor del manejo en el selector a catch tipado (antes `toString().contains('invalid')` ni siquiera casaba). | `lib/features/homes/data/homes_repository_impl.dart`, `lib/features/homes/presentation/home_selector_widget.dart` |
| ⚠️-d | "Cambiar contraseña" ahora pide confirmación antes de enviar el email. | `lib/features/settings/presentation/settings_screen.dart` + ARB |
| ⚠️-e | Pluralización "1 día" / "N días" (ICU plural) en banners rescue + historial, es/en/ro. | `lib/l10n/app_es.arb`, `app_en.arb`, `app_ro.arb` |
| ⚠️-a | "Cargando…" persistente: la pantalla "Sin hogar" muestra el nombre de la app, no "Cargando…". | `lib/features/homes/presentation/home_selector_widget.dart` |
| ⚠️-c | Diálogos de miembro (Quitar admin/Expulsar): botón de acción corto ("Confirmar") para evitar el apilado/overflow inconsistente de Material. | `lib/features/members/presentation/skins/member_profile_screen_v2.dart` |

**Strings nuevas** (es/en/ro): `settings_change_password_confirm_title`, `settings_change_password_confirm_body`.

**Tests añadidos / actualizados:**
- `test/ui/features/settings/settings_screen_test.dart`: `_wrapWithHome` acepta `ownerUid`; nuevo test de regresión "members stale lo marca owner pero ownerUid != uid → flujo no-owner". (10+1 tests verdes.)
- `test/integration/features/homes/home_creation_integration_test.dart`: grupo `joinHome` (not-found→Invalid, deadline→Expired, failed-precondition→MaxMembers). Verdes.
- Tests afectados re-verificados verdes: `member_profile_screen_v2_test`, `member_profile_overflow_test`, `home_selector_widget_test`, `leave_home_navigation_test`, `settings_view_model_test`.

## ✅ CIERRE (2026-06-20) — todo verificado

1. **Suite completa de tests** — `flutter test` → **+976 -4**. Los 4 fallos son **PRE-EXISTENTES y de entorno**, confirmado con `git stash push -- lib/` (siguen fallando con el código de los fixes fuera del árbol; ninguno toca archivos de los fixes):
   - `home_creation_integration_test › getAvailableSlots … baseSlots+lifetimeUnlocked-currentCount` (Expected `<3>` Actual `<5>`) — el documentado.
   - `notification_prefs_repository_impl_test › savePrefs … doc no existe` y `› updateFcmToken` — `[FakeFirestore/not-found]` en `.update()` (versión de `fake_cloud_firestore` de esta máquina).
   - `profile_save_test › phoneVisible=true stores members visibility` (Expected `'members'` Actual `'sameHomeMembers'`) — test obsoleto vs código.
   - `flutter analyze` limpio en los archivos de los fixes (2 issues pre-existentes ajenos: `task_visual_utils.dart`, `assignment_form.dart`).

2. **APK compilado e instalado** — `flutter.bat build apk --debug` (Windows) → `app-debug.apk` (223 MB) instalado con `install -r [-g]` en emulator-5554 **y** 43340fd2 (MI_9). Smoke test OK en ambos.

3. **Verificación en dispositivo — 6/6 OK** (capturas en `screenshots/verif-*.png`):
   | Fix | Dispositivo | Resultado | Captura |
   |-----|-------------|-----------|---------|
   | ⚠️-d | emulador (Luna) | Diálogo "¿Cambiar contraseña?" + cuerpo + Cancelar/Confirmar antes del email | `verif-d-confirmar-contrasena.png` |
   | 🟠-2 | emulador (Luna, no-owner) | "¿Abandonar hogar?" — **no** "Transferir propiedad" | `verif-2-abandonar-hogar-noowner.png` |
   | ⚠️-c | MI_9 (Sol, owner) | Quitar admin **y** Expulsar → "Cancelar"/"Confirmar" en una fila | `verif-c-dialogo-quitaradmin.png`, `verif-c-dialogo-expulsar.png` |
   | ⚠️-e | MI_9 | Banner "Tu Premium vence en **1 día** — renueva…" (singular). Forzado con `qa_premium.js … rescue 24` (ventana 23-24h: `days=1 && hours>=24`) | `verif-e-plural-1dia.png` |
   | ⚠️-a | emulador (Tres, sin hogar) | Pantalla "Sin hogar" con AppBar **"Toka"** (no "Cargando…") | `verif-a-sinhogar-toka.png` |
   | ⚠️-b | emulador (Tres → join a QA-Hogar-1 Free lleno) | "Tu plan Free permite hasta 3 miembros. Hazte Premium para añadir más." | `verif-b-free-limite-miembros.png` |

4. **Goldens** — ningún test de golden/`test/ui/` falló en la suite → no hubo que regenerar.

5. **Commit** — **pendiente por decisión del usuario** (no commitear todavía). Rama `hardening/qa-2026-06-16-spec14-and-wip`. NO desplegar functions (fixes solo cliente).
   - ⚠️ El working tree contiene además WIP extra no listado arriba: `lib/app.dart`, `forgot_password_screen.dart`, `history_event_detail_screen_v2.dart`, `task_detail_screen_v2.dart` y strings de escala `/10` (`history_rate_score_label`, `review_score_value`). Decidir alcance al commitear.

## Notas
- `flutter gen-l10n` ya ejecutado (l10n regenerado con plural + strings nuevas).
- Estado de los 2 dispositivos restaurado al cerrar: Luna (emulador) / Sol (owner, MI_9) en "Hogar Real QA" **free**, sin banner rescue.
- **Efectos colaterales en producción** (verificación ⚠️-a/⚠️-b): pass de `toka.sync.tres@tokatest.dev` reseteada a `TokaQA2024!`; código de invitación `QAFULL` creado en QA-Hogar-1 y luego **revocado** (`used=true`); Hogar Real QA pasó por `rescue` y se restauró a `free`.
- Scripts Admin SDK de la sesión (en `secrets/`, gitignored): `qa_map_session.js`, `qa_premium.js`, `qa_make_invite.js` (nuevo), `qa_revoke_invite.js` (nuevo).
- Verificación visual con `shot.sh`/`ui.sh`/`type.sh` (esta carpeta). Códigos de invitación SIEMPRE con `type.sh` char-a-char.
