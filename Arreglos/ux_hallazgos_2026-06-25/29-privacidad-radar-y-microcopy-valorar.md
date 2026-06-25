# 29 · 🟢 Bajo — Framing del radar "Puntos fuertes" + microcopy al valorar

> Lee primero `_CONVENCIONES.md`. Marca 🔄 En progreso en `INDICE.md` y ✅ al cerrar.

## Contexto del hallazgo
Dos micro-mejoras de tono/privacidad:
1. **Radar engañoso:** el gráfico se titula "Puntos fuertes" pero pinta **también las notas bajas** por tarea, de modo que un eje bajo en un gráfico de "fortalezas" expone debilidades disfrazadas — y se reutiliza en la ficha de **otros** miembros.
2. **Refuerzo de confianza al valorar:** las notas de valoración ya son privadas (reglas + cliente), pero el flujo de valorar puede reforzar esa garantía con microcopy "Solo {name} verá tu nota" junto al campo.

## Evidencia
- `lib/features/members/presentation/widgets/strengths_list_widget.dart:25-31` — incluye notas bajas.
- `lib/features/members/presentation/skins/member_profile_screen_v2.dart:261` — radar reutilizado en ficha de otros.
- ARB: `radar_chart_title: "Puntos fuertes"` (`app_es.arb:907`).
- Privacidad ya garantizada: `firestore.rules:222-229,295-300`; copy existente `reviewPrivateNoteHint` (`app_es.arb:1228`).

## Objetivo
1. Coherencia del radar: o no llamarlo solo "Puntos fuertes" si muestra el desglose completo, o mostrar a terceros únicamente agregados/fortalezas reales y dejar el desglose por tarea para la vista propia.
2. Añadir microcopy "Solo {name} verá tu nota" en el momento de escribir la valoración (no solo en el hint existente).

## Decisión de producto a confirmar
Usa `superpowers:brainstorming` para el radar: ¿renombrar el gráfico, filtrar lo que ven terceros, o ambos?

## Criterios de aceptación
- [ ] El radar deja de exponer debilidades bajo una etiqueta de "fortalezas" (renombrado o filtrado para terceros).
- [ ] El flujo de valorar muestra el microcopy de privacidad junto al campo.
- [ ] Localizado (es/en/ro). Sin cambios en el cálculo de las notas.

## Pruebas obligatorias
### Widget / Golden
- Golden del radar en vista propia vs vista de terceros (según la decisión).
- Widget test del flujo de valorar: microcopy presente.

### Verificación en dispositivo (Firebase real, dos perfiles)
1. Abre la ficha de otro miembro con notas bajas en alguna tarea (MI_9): el gráfico no debe "vender como fuerte" una debilidad. Captura.
2. Valora a un miembro (desde el evento correspondiente): el microcopy de privacidad debe verse junto al campo. Captura.
3. Confirma que la nota sigue siendo privada para terceros (el otro dispositivo, con una tercera cuenta si aplica, no la ve). Captura.

## Dependencias
- Eje de tono/privacidad junto a **07**, **08**, **12**.

## Al terminar
Actualiza `INDICE.md` (✅ + fecha + nota). Lista archivos y capturas.
