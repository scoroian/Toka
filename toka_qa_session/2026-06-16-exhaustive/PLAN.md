# Plan de pruebas exhaustivas Toka — 2026-06-16

Sesión QA E2E contra producción `toka-dd241`. Dos dispositivos reales:
- **MI_9** físico USB (`43340fd2`, 1080x2340) — rol principal/owner/pagador.
- **Emulador** (`emulator-5554`, 1080x2400) — segundo miembro/admin.

Capturas: `./shot.sh <serial> <nombre>` → redimensiona y devuelve ruta para Read.
Admin SDK: `secrets/qa_*.js` (firebase-admin en functions/node_modules). Toda manipulación
de fechas/estado premium vía Admin SDK queda anotada en RESULTS.md con `[ADMIN SDK]`.

## Cuentas
| Alias | Email | uid | Notas |
|---|---|---|---|
| N1 | toka.qa.n1@tokatest.dev | ZynuqUTlbtb1R1qBv74Wi7iEmuN2 | NUEVA, sin hogares (emailVerified vía Admin SDK) |
| N2 | toka.qa.n2@tokatest.dev | wwL0OTdrNeMZs2wTt6QtRDT1nb53 | NUEVA, sin hogares |
| N3 | toka.qa.n3@tokatest.dev | aBne0aSLzbNaM7ZyACmibbVkPN62 | NUEVA, sin hogares |
| OWNER | toka.qa.owner@gmail.com | m9K1hwXkB1hLGtE2ZddBy2UfIEb2 | existente, con hogares |
| MEMBER | toka.qa.member@gmail.com | Ko7pGuGLfVXow7kSduSv33cBT7h1 | existente |
| ADMIN | toka.qa.admin@gmail.com | WAS3FTcW3fOR4pP85pNSDI9vZ6s2 | existente |

Password de todas: `TokaQA2024!`

## Fases y checklist

### F1 — Auth & Onboarding
- [ ] Validaciones login (email inválido, password corta, credenciales incorrectas)
- [ ] Link "¿Olvidaste tu contraseña?" (envío reset)
- [ ] "Crear cuenta" (registro + verify email) — validaciones (passwords no coinciden, email en uso)
- [ ] Login OK con N1 en emulador
- [ ] Onboarding: welcome → idioma → perfil (nickname, teléfono, foto) → crear/unirse hogar
- [ ] Cambiar idioma en onboarding (es/en/ro) y verificar textos
- [ ] Foto de perfil desde galería en onboarding
- [ ] Rationale de notificaciones tras onboarding

### F2 — Homes & límites de plazas
- [ ] Crear hogar (nombre, emoji/icono)
- [ ] Crear 2º hogar base
- [ ] Intentar 3º hogar con cuenta free → debe bloquear (slot cap = 2) `[ADMIN SDK verif]`
- [ ] Unirse a hogar por código (validaciones: <6 chars, código inválido, expirado)
- [ ] Cambiar entre hogares (My Homes)
- [ ] Ajustes del hogar: editar nombre, avatar (galería/cámara/quitar)
- [ ] Verificar reflejo de avatar en Hoy / Historial / Miembros

### F3 — Tareas (todas las configuraciones)
- [ ] Crear tarea con cada tipo de recurrencia: oneTime, hourly, daily(every=1 y >1), weekly, monthlyFixed, monthlyNth, yearlyFixed, yearlyNth
- [ ] Probar los 24 emojis y 12 iconos (muestreo representativo + edge)
- [ ] Asignación: 1 miembro, varios miembros, reordenar, basicRotation vs smartDistribution (premium)
- [ ] onMissAssign: sameAssignee vs nextRotation (requiere ≥2 miembros)
- [ ] Dificultad: 0.5, 1.0, 3.0 + fuera de rango
- [ ] Hora fija + "crear ocurrencia para hoy"
- [ ] Validaciones: título vacío, >60 chars, sin asignados
- [ ] Límite free: 4 tareas activas, 3 recurrentes automáticas → banners de bloqueo
- [ ] Acción "Hecho": confirmación, efecto en stats/rotación/dashboard, botón no-actionable
- [ ] Acción "Pasar turno": motivos, aviso de penalización compliance, siguiente responsable, sin candidato
- [ ] Congelar / descongelar (swipe y detalle); bloqueo al descongelar si free lleno
- [ ] Editar tarea (todos los campos)
- [ ] Eliminar tarea (individual y bulk) → reflejo en historial y puntuaciones
- [ ] Orden en Hoy: hora→día→semana→mes→año, subgrupos por hacer/hechas

### F4 — Miembros, admin, expulsión, reincorporación
- [ ] Invitar (generar código, copiar/compartir, QR)
- [ ] Unirse N2 en emulador al hogar de N1
- [ ] Límite free de miembros (3 activos incl. owner) → 4º bloquea
- [ ] Promover a admin / quitar admin (en free bloqueado; en premium permitido)
- [ ] Acciones de admin (invitar, expulsar) vs owner
- [ ] Expulsar miembro → status left
- [ ] Payer lock: pagador no puede abandonar/ser expulsado con premium activo `[ADMIN SDK]`
- [ ] Reincorporación (rejoin con código) conserva rol/stats
- [ ] Abandonar hogar (no owner); owner debe transferir antes
- [ ] Transferir propiedad

### F5 — Premium / suscripción / downgrade
- [ ] Paywall (CTA anual/mensual, restaurar, términos)
- [ ] `active` → gating off (smart, vacaciones, reviews, sin ads) `[ADMIN SDK]`
- [ ] `free` → gates visibles (overlay lock + CTA) `[ADMIN SDK]`
- [ ] `cancelledPendingEnd` → banner ámbar "no se renovará" `[ADMIN SDK]`
- [ ] `rescue` (3 días / <24h / último día) → banner rojo + pantalla rescate + lastBillingError `[ADMIN SDK fechas]`
- [ ] `expiredFree` → banner gris reactivar `[ADMIN SDK]`
- [ ] `restorable` → banner verde restaurar + ventana 30d `[ADMIN SDK]`
- [ ] Pantalla "Planear downgrade": seleccionar 3 miembros / 4 tareas, guardar
- [ ] Downgrade automático: congelado de miembros/tareas excedentes (forzar fecha `[ADMIN SDK]`)
- [ ] Restaurar premium dentro de ventana
- [ ] Slots permanentes tras cancelar (lifetimeUnlockedHomeSlots) `[ADMIN SDK verif]`

### F6 — Valoraciones, equilibrio, radar
- [ ] Valorar tarea completada de otro (slider 1-10 + nota privada) — solo premium
- [ ] No poder valorar tarea propia; no duplicar valoración
- [ ] Ver valoración propia vs de otros (privacidad de notas)
- [ ] Equilibrio del hogar (balance card) bien repartido / desequilibrado
- [ ] Radar de tareas por evaluación en perfil

### F7 — Historial
- [ ] Filtros: Todos / Completadas / Pases / Vencidas
- [ ] Evento pasado muestra motivo y penalización
- [ ] Tarea eliminada queda como snapshot en historial
- [ ] Paginación / cargar más
- [ ] Detalle de evento

### F8 — Perfil, Ajustes, Idioma, Notificaciones, Tema
- [ ] Editar perfil (nickname, teléfono, visibilidad teléfono, foto)
- [ ] Cambiar idioma en Ajustes (es/en/ro)
- [ ] Tema claro/oscuro/sistema + AppearancePicker (skins)
- [ ] Notificaciones: toggles (al vencer, antes-premium, resumen diario), permisos SO
- [ ] Cambiar contraseña (envía reset)
- [ ] Términos / privacidad (abren URL)
- [ ] Cerrar sesión

### F9 — Ciclo de vida de cuenta
- [ ] Abandonar hogar
- [ ] Cerrar hogar (owner único)
- [ ] Eliminar cuenta (requiere reauth reciente)

### F10 — Extremos / forzar fallo
- [ ] Doble tap rápido en Hecho/Pasar (idempotencia)
- [ ] Pérdida de conexión durante acción
- [ ] Strings largos / emoji en nombres
- [ ] Sincronización en tiempo real entre 2 dispositivos
- [ ] Rotación de turnos con miembros congelados
- [ ] Recurrencias con fechas límite (día 31, 29-feb, cambios de mes)

## Convención de veredictos en RESULTS.md
- ✅ OK · ⚠️ Funciona con observación/mejora · ❌ Bug · 💄 Observación visual/UX
