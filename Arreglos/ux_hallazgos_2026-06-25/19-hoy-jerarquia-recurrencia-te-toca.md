# 19 · 🟢 Bajo — Explicar la jerarquía Hora→Año + reforzar "lo mío" con texto

> Lee primero `_CONVENCIONES.md`. Marca 🔄 En progreso en `INDICE.md` y ✅ al cerrar.

## Contexto del hallazgo
Dos micro-problemas en la pantalla Hoy:
1. Los títulos de sección ("Hora/Día/Semana/Mes/Año") son texto diminuto (10px) y se leen como **franjas horarias del día**, no como **frecuencias de recurrencia**. Una tarea semanal con "Hoy 20:00" desconcierta.
2. "Lo mío hoy" se señala **solo con color** (borde/avatar coral). Existe la clave `today_hero_label: "TE TOCA"` pero está **huérfana** (no se referencia), por lo que falta refuerzo textual/accesible.

## Evidencia
- `lib/features/tasks/presentation/skins/today_task_section_v2.dart:48-52` — títulos 10px, peso 800, gris.
- `lib/features/tasks/presentation/.../recurrence_order.dart:9-16` — orden de recurrencias (incluye `oneTime`, sin título descriptivo).
- ARB: `today_hero_label: "TE TOCA"` (def. en `app_localizations.dart:3785`) — sin uso.
- `lib/features/tasks/presentation/skins/today_task_card_todo_v2.dart:138,256` — color coral para "mío".

## Objetivo
1. Hacer comprensible que las secciones son **frecuencias** (subtítulo/etiqueta más legible, o icono, o título tipo "Cada día"/"Cada semana"; dar título a `oneTime` p. ej. "Puntuales").
2. Conectar `today_hero_label` ("TE TOCA") en la tarjeta propia para reforzar "lo mío" más allá del color (mejor accesibilidad/daltonismo).

## Criterios de aceptación
- [ ] Las secciones comunican que son frecuencias de recurrencia, legibles, sin ambigüedad con horas del día.
- [ ] Las tareas `oneTime` tienen un encabezado descriptivo.
- [ ] La tarjeta propia muestra una señal textual ("TE TOCA" u otra) además del color.
- [ ] Localizado (es/en/ro); no rompe el orden Hora→Año (regla de producto #6).

## Pruebas obligatorias
### Widget / Golden
- Golden de la pantalla Hoy con los nuevos encabezados y la etiqueta "TE TOCA" en la tarjeta propia.
- Test de que el orden de secciones se mantiene (Hora→Año, con Puntuales donde corresponda).

### Verificación en dispositivo (Firebase real)
1. Con tareas de varias recurrencias asignadas (Admin SDK), abre Hoy en MI_9: los encabezados deben entenderse como frecuencias; la tarea propia muestra "TE TOCA". Captura.
2. Verifica con daltonismo simulado (o solo lectura del texto) que "lo mío" se distingue sin depender del color. Captura.

## Al terminar
Actualiza `INDICE.md` (✅ + fecha + nota). Lista archivos y capturas.
