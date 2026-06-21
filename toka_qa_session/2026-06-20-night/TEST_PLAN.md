# Plan de QA exhaustivo — Noche 2026-06-20

> Análisis propio e independiente (no basado en informes previos). Entorno: **producción** toka-dd241.
> Dispositivos: **MI_9** (físico USB, serial `43340fd2`, 1080x2340) · **emulator-5554** (1080x2400).
> Tooling: `ui.sh` (dump/find/tap por semántica Flutter), `shot.sh` (captura+resize), `type.sh` (char-a-char),
> Admin SDK en `secrets/*.js`. **Todo cambio de fecha/estado vía Admin SDK queda registrado en FINDINGS.md.**

## Mapa de cuentas (uid · nickname · password TokaQA2024!)
| Email | uid | Nick | Posee | Miembro de |
|---|---|---|---|---|
| toka.sync.luna@tokatest.dev | Q7CgeIUPoAcHhnyPBlioLlBJXDo1 | Luna | Hogar Sync QA (purged) | Hogar Real QA (admin) |
| toka.sync.sol@tokatest.dev | WAqQyA1aeYZjd9oY3wnZVRo6u8s2 | Sol | **Hogar Real QA** (free) | — |
| toka.sync.tres@tokatest.dev | yJHLdSojcDcqAHGKZftx2eZdnl82 | Tres | — | Hogar Real QA (member) |
| toka.qa.owner@gmail.com | m9K1hwXkB1hLGtE2ZddBy2UfIEb2 | Owner | QA_Post_Fix (expiredFree) | Hogar (admin) |
| toka.qa.member@gmail.com | Ko7pGuGLfVXow7kSduSv33cBT7h1 | Sebas | Casa (free) | V4w8(left), YBGW(left), Casa |
| toka.qa.admin@gmail.com | WAS3FTcW3fOR4pP85pNSDI9vZ6s2 | Admin | **Hogar** (premium ACTIVE) | QA-Hogar-1 (member) |
| qaa20260420@tokatest.dev | vSHMdZXcroZV7b8Ac6pkGm3ZhDy1 | QA-A | QA-Hogar-1 (free) | — |
| qab20260420@tokatest.dev | rC4bRHPULQa4rtgq1epc0tQ1XVs2 | QA-B | — | QA-Hogar-1 (member) |
| toka.qa.n1/n2/n3@tokatest.dev | (n1=8xwbsrsZ...) | — | — | — (sin hogar: onboarding/límites) |

## Home IDs
- Hogar Real QA = `mAJXlAhwRV1kdy4O05hG` (free, 3 miembros)
- Hogar (premium) = `YBGWBKJWaNjQhChCSZGE`
- QA_Post_Fix = `V4w8IDaA6FsALLdSip0S`
- QA-Hogar-1 = `PomTlPWhrJbpg3GNDtpL`
- Casa = `m2GqwgNQ2dgy5V39Ifi7`

## Campañas
1. **Onboarding & cuentas desde cero** (emu): idioma, registro, crear 1er hogar, "Empezar", límites de hogares/plazas.
2. **Pantalla Hoy**: Hecho, Pasar (motivos + preview penalización), orden Hora→Día→Semana→Mes→Año, Por hacer/Hechas, sync en vivo entre dispositivos, timezone.
3. **Tareas CRUD**: crear con TODAS las configs (iconos, recurrencias, dificultad, modo asignación, onMiss), congelar/descongelar, editar, eliminar; ver en historial y puntuaciones.
4. **Historial & filtros**.
5. **Miembros**: invitar, expulsar, reincorporar, hacer admin, acciones admin, valoraciones, equilibrio (radar), notas privadas propias y de otros.
6. **Premium** (Admin SDK): gating (smart distribution, vacaciones, reviews, sin ads), cancelar→cancelledPendingEnd→pantalla degradado en premiumEndsAt, ventana rescate (3d antes), restauración (30d después), permanencia de créditos de plaza, pagador no expulsable. Forzar fechas vía Admin SDK (documentado).
7. **Perfil/Ajustes**: editar perfil, foto (galería), idioma, notificaciones, ajustes hogar; ver foto reflejada en Hoy/Historial/Miembros.
8. **Salir del hogar / Eliminar cuenta**.

## Convención de hallazgos (FINDINGS.md)
`[OK] / [BUG] / [UX] / [MEJORA] / [VISUAL]` + descripción + evidencia (captura/uid/SDK) + severidad.
