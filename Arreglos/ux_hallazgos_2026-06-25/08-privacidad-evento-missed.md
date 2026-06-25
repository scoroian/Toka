# 08 · 🟠 Alto — El evento "{name} no completó" se publica solo en el feed común

> Lee primero `_CONVENCIONES.md`. Marca 🔄 En progreso en `INDICE.md` y ✅ al cerrar.

## Contexto del hallazgo
Cuando una tarea vence sin completarse, un **cron** crea automáticamente un evento `missed` que aparece en el **feed de historial compartido** del hogar como `"{name} no completó"`, con icono de alerta, aplicando `penaltyApplied:true` y bajando `complianceRate`. Es vigilancia (registro automático) + juicio (etiqueta de fallo) + exposición (muro común) sin que ningún humano lo decida. En una app cooperativa para parejas/familias, esto erosiona la confianza.

## Evidencia
- `functions/src/jobs/process_expired_tasks.ts:197` — `eventType:"missed"`; `:206,222-223` — `penaltyApplied:true` y bajada de `complianceRate`.
- `lib/features/history/presentation/widgets/history_event_tile.dart:243-284` — `_MissedTile`.
- ARB: `app_es.arb:1106` `history_event_missed: "{name} no completó"`.
- Reglas que lo exponen a todos: `firestore.rules:218` (`taskEvents` legibles por `isCurrentMember`).

## Objetivo
Reducir el carácter de señalamiento del evento `missed`. Usa `superpowers:brainstorming` para decidir entre dos enfoques (o combinarlos):
- **A — Encuadre neutro:** cambiar el copy a estado de la tarea, no de la persona ("Tarea vencida: {task}"), color neutro, sin connotación de fallo personal.
- **B — Visibilidad privada:** que el evento `missed` sea visible solo para el responsable (y quizá el owner), no para todo el hogar — requiere tocar reglas Firestore y/o el modelo del evento.

## Criterios de aceptación
- [ ] El evento `missed` ya no se presenta como acusación personal en el feed común (según enfoque A y/o B).
- [ ] Si se opta por B, las reglas Firestore restringen la lectura coherentemente y el cliente no intenta leer lo que no debe (sin errores de permisos).
- [ ] La penalización estadística (si se mantiene) deja de exhibirse como etiqueta pública de fallo.
- [ ] Localizado (es/en/ro).

## Pruebas obligatorias
### Backend (jest)
- Test del cron `process_expired_tasks`: genera el evento con el nuevo tipo/visibilidad/copy esperado.
- Si tocas reglas: tests de reglas Firestore (un tercero NO puede leer el `missed` ajeno si se eligió B; el responsable sí).

### Verificación en dispositivo (Firebase real, dos perfiles)
1. Con Admin SDK crea una tarea con vencimiento inminente asignada a la cuenta de MI_9 y deja que el cron real la marque `missed` (o dispara el job en `toka-dd241`).
2. Abre Historial en **ambos** dispositivos:
   - Enfoque A: el copy es neutro y sin alarma en ambos. Captura.
   - Enfoque B: el compañero (emulador) **no** ve el evento; el responsable (MI_9) sí. Captura ambos.
3. Verifica que `complianceRate` cambia según lo decidido y que no hay errores de permisos en logcat.

## Dependencias
- "Reencuadre de tono cooperativo" junto a **07**, **11**, **12**. Si tocas reglas, declara índices necesarios y sigue `DEPLOY.md`.

## Al terminar
Actualiza `INDICE.md` (✅ + fecha + nota: enfoque A/B/ambos). Lista archivos y capturas.
