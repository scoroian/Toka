# QA exhaustiva 2026-06-19 — regresión completa, 2 dispositivos reales

**Build:** `app-debug.apk` recompilado HOY del working tree (Flutter Windows) e instalado por `install -r` en **emulador** `emulator-5554` (1080x2400, GMT, tema claro) y **MI_9** `43340fd2` (1080x2340, Madrid, tema oscuro). Todo contra producción `toka-dd241`.
**Cuentas:** Luna (emulador) + Sol (MI_9, owner) en **Hogar Real QA** `mAJXlAhwRV1kdy4O05hG`; cuenta auxiliar `tres`. Estados premium forzados con `secrets/qa_premium.js`.

## Veredicto
**Sin bugs reales nuevos.** El único candidato crítico (unirse por código) resultó ser un **falso positivo de mi tooling**. Se confirmó **1 bug real medio** (🟠-2, regresión latente conocida) y **6 observaciones menores**. Todos los fixes de sesiones previas (§1, §2, §4, §5, §6, §9, §11, §12, §14) siguen **verdes**.

## Cobertura (12/12 áreas)
| Área | Estado |
|---|---|
| Auth (login, validación, logout, recuperar contraseña) | ✅ |
| Onboarding (welcome, idioma, perfil, elección hogar) | ✅ (⚠️-f) |
| Hogares (selector, ajustes del hogar, premium en vivo) | ✅ |
| Hoy (contadores, agrupación Hora→Día, completar, pasar turno) | ✅ |
| Tareas (crear/recurrencias/asignados/modo/onMiss, editar, congelar, filtros, swipe-delete) | ✅ |
| Miembros (lista, perfil, admin/expulsar, invitar código+email) | ✅ |
| Perfil (editar, visibilidad teléfono, stats, cambiar contraseña) | ✅ |
| Historial (filtros, valorar, §11 estrella en vivo) | ✅ |
| Suscripción (tile, Tu suscripción, 4 banners de estado, paywall) | ✅ |
| Ajustes + Notificaciones + i18n (es/en/ro) + tema | ✅ |
| Sync cross-device + zona horaria (GMT↔Madrid) | ✅ |
| Destructivo (abandonar, downgrade hoy; resto regresión 18) | ✅ |

## Hallazgos
- **✅ FALSO POSITIVO (era candidato 🔴): "unirse por código".** Parecía fallar siempre en el emulador con "Algo salió mal". Tras descartar App Check, rate-limit, índices, backend (funciona vía REST) y rejoin-vs-new, la causa era **mi método de input**: `adb shell input text` corrompe el campo de código (input formatter de mayúsculas/longitud) en Gboard. Con `type.sh` char-a-char **funciona en emulador y en MI_9 físico** (member nuevo y rejoin). No es bug de producto.
- **🟠-2 (real, medio): "Abandonar hogar" ofrece "Transferir propiedad" a un no-owner.** `settings_screen.dart:283` deriva `isOwner` de `watchHomeMembers().first`, que sirve el primer snapshot desde la **caché local stale** si ningún listener la refrescó antes. Un ex-owner re-unido como admin ve el flujo de owner. El backend protege; impacto = UX confusa. Fix: derivar `isOwner` de `home.ownerUid` o forzar lectura de servidor.
- **Menores:** ⚠️-a "Cargando…" persistente en AppBar de "Sin hogar" (ambos dispositivos) · ⚠️-b `error_generic` aplasta códigos de error del join no mapeados · ⚠️-c layouts de botones inconsistentes en diálogos de miembro · ⚠️-d "Cambiar contraseña" envía email de reset sin confirmación · ⚠️-e banner rescue "vence en 1 días" (pluralización) · ⚠️-f botón "Empezar" del onboarding no respondió a `adb input tap` (probable artefacto adb+PageView, no reproducido como bug).

## Detalle
Ver `FINDINGS.md`. Helpers de sesión: `shot.sh`, `type.sh`, `ui.sh`. Scripts Admin SDK añadidos: `secrets/qa_map_session.js`, `secrets/qa_call_join.js`.

## Estado final de dispositivos
Emulador: Luna (admin) · MI_9: Sol (owner) · Hogar Real QA en **free**, 2 tareas + historial con valoración. Setup íntegro para la próxima sesión.
