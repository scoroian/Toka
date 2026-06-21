# Informe ejecutivo — QA exhaustivo Toka (noche 2026-06-20)

**Análisis independiente** (sin basarse en informes previos). Entorno: **producción** toka-dd241.
Dispositivos: **MI_9** físico (Sol) + **emulador** (Luna), ambos en "Hogar Real QA".
Metodología: pilotaje de la app vía ADB con tap por semántica Flutter (`content-desc`), captura+análisis visual, y verificación cruzada de la verdad en Firestore vía **Admin SDK**. Todos los cambios de estado/fecha por Admin SDK quedan registrados en `FINDINGS.md` con `⚙️ SDK:`.

Cobertura: 8 campañas — Onboarding/cuentas, Pantalla Hoy, Tareas CRUD, Historial, Miembros, Premium, Perfil/Ajustes, Salir/Eliminar. Detalle completo en **FINDINGS.md**.

---

## Veredicto general
La app está **sólida y madura**. Los flujos núcleo (completar, pasar turno con penalización, rotaciones, premium, valoraciones con privacidad real, onboarding, borrado de cuenta) funcionan correctamente y con buena UX. La sincronización en vivo entre dispositivos funciona. No se encontró ningún crash ni pantalla en blanco persistente. Bugs históricos (membresía fantasma al borrar cuenta, teléfono visible pese a hidden, blocker de "Empezar") **NO se reprodujeron** (corregidos).

Se hallaron **1 bug funcional de severidad alta** (tareas puntuales invisibles en Hoy), **1 inconsistencia de datos importante** (contadores stale al expulsar/abandonar) y varias mejoras menores de UX/i18n.

---

## Bugs y mejoras priorizados

### 🟠 Importantes
1. **Tareas "Puntual" (oneTime) no se renderizan en la pantalla Hoy.** Se crean, se guardan, se cuentan en "tareas para hoy" (`tasksDueToday`) y están en `activeTasksPreview`, pero la agrupación de Hoy solo maneja Hora/Día/Semana/Mes/Año y no hay bucket para `oneTime`. Como el detalle de tarea tampoco tiene acción "Hecho", **una tarea puntual es prácticamente imposible de completar desde la UI**. (C3)
2. **Cluster de bookkeeping de miembros (contadores/agregados inconsistentes).** Confirmado a nivel de DATOS en la Ronda 2, con varias facetas:
   - Al pasar un miembro a `status=left` (expulsión/abandono), `planCounters.activeMembers` NO se decrementa (queda en 3). El banner "3/3 — límite del plan Free" persiste con 2 activos y **bloquea invitar un reemplazo** (no aparece "Invitar"). El owner de un hogar free queda atascado.
   - Una **cuenta BORRADA reapareció como miembro ACTIVO** ("?") en la lista, por regeneración inconsistente del `memberPreview` tras operaciones de otros miembros (membresía zombie con `status=active` + `accountDeleted=true`).
   - **Reincorporar quedó bloqueado** mientras el contador stale marcaba 3/3.
   - La cuenta borrada en "Antiguos miembros" muestra su **UID crudo** y ofrece **"Reincorporar"** (que crearía una membresía fantasma de un usuario inexistente).
   El **borrado de cuenta y el join SÍ regeneran** los contadores; el gap está en los triggers de expulsión/abandono/reincorporación. **Recomendación**: reconciliar server-side los agregados de miembros en CUALQUIER cambio de `members/{uid}.status`, excluyendo siempre `accountDeleted=true`. (C5, C8, Ronda 2)

### 🟡 Menores / UX
3. **i18n pluralización**: "Tu Premium vence en **1 días**" → debe ser "1 **día**". (C6)
4. **Guardar nombre del hogar poco descubrible**: sin botón Guardar; solo persiste con "Done/Enter" del teclado; al pulsar "Atrás" se pierde el cambio en silencio. (C7)
5. **Verificación de email no obligatoria**: el registro deja usar la app con `emailVerified=false`. (C1)
6. **Nuevo miembro sin apodo se muestra como "?"** en la lista de miembros. (C1)
7. **Vacaciones**: sin indicador en la lista de Miembros; las "Próximas fechas" de una tarea no respetan las vacaciones (siguen asignando al miembro ausente). (C5)
8. **"✓ Hecho" en tarea no vencida**: deshabilitado (correcto) pero sin feedback al tocarlo (el usuario no entiende por qué "no funciona"). (C2)
9. **Build DEBUG**: botón "🧪 DEBUG: Estado premium" en Ajustes del hogar — asegurar que NO aparece en builds release de producción. (C7)
10. **Checkbox del último miembro en Crear tarea** queda al borde inferior, solapando la NavigationBar (falta padding). (C3)

### 🔵 Mejoras
11. **Sin update optimista en el dispositivo que actúa**: tras Hecho/Pasar, el device que ejecuta espera la regeneración del dashboard (~2-8s) mostrando estado obsoleto con botones ya inválidos. (C2)
12. **Banner de anuncio solapa** la parte inferior del formulario Crear tarea. (C3)
13. **Estrella "ya valorado"** no refresca al instante tras enviar una valoración. (C5)

---

## Qué funciona bien (✅ verificado)
- **Pantalla Hoy**: completar (con confirmación, avanza recurrencia), pasar turno con **penalización estadística visible y fiel** (50%→~40% verificado en Firestore), caso de 1 solo miembro, orden Hora→Día→Semana→Mes, sync en vivo, timezone por dispositivo.
- **Tareas**: 8 tipos de recurrencia, emoji/icono, dificultad, rotación reordenable, onMiss, "próximas fechas" con rotación, congelar/descongelar, editar, **soft-delete con persistencia en historial y puntuaciones**.
- **Historial**: filtros Todos/Completadas/Pases/Vencidas, motivos de pase, persistencia de tareas borradas.
- **Miembros**: invitar (código+QR), expulsar, reincorporar, hacer/quitar admin, **valoraciones + notas privadas con privacidad ENFORCED en Firestore rules** (autor/evaluado), equilibrio del hogar, teléfono oculto sin leak, modo vacaciones.
- **Premium**: gating correcto (paywall, distribución inteligente, valoraciones, vacaciones, +miembros, sin ads), y **ciclo completo** active→cancelledPendingEnd→rescue→Planear downgrade→expiredFree→restorable, con la pantalla de degradado para elegir miembros/tareas a conservar.
- **Perfil/Ajustes**: foto desde galería→Cloud Storage **reflejada en Miembros e Historial (retroactivo)**, idioma es/en/ro instantáneo y persistente, notificaciones (toggles + pruebas que postean notificación real), tema Claro/Oscuro/Sistema, ajustes del hogar.
- **Onboarding**: registro→crear/unirse, crear hogar, **unirse con código (sync en vivo)**, límite de 2 hogares base ("No tienes cupos disponibles").
- **Salir/Eliminar**: abandonar hogar; eliminar cuenta con re-auth requerido y **limpieza correcta** (memberships `accountDeleted=true`, hogar propio purgado, sin fantasmas).

---

## Cambios de estado vía Admin SDK durante la sesión (constancia)
- `qa_setup_accounts.js`: reset passwords + emailVerified=true (cuentas QA).
- `qa_premium.js mAJXlAhwRV1kdy4O05hG <Sol>`: active → cancelledPendingEnd → rescue → expiredFree → restorable → active → **free** (estado final restaurado).
- `qa_set_task_field.js`: nextDueAt de "Limpiar cocina" forzado a vencida y restaurado (test de pase vencido; el dashboard no refrescó porque recomputa desde la regla).
- Cleanup final: Luna vacaciones off, Tres admin→member, Hogar Real QA → free. Cuenta de prueba `toka.qa.night1@tokatest.dev` creada y **eliminada** (test de borrado).

Estado final de dispositivos: MI_9=Sol, emulador=Luna, ambos en Hogar Real QA (free).
