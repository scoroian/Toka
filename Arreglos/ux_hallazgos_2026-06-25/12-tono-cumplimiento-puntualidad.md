# 12 · 🟡 Medio — Unificar "Cumplimiento" → "Puntualidad" en superficies públicas

> Lee primero `_CONVENCIONES.md`. Marca 🔄 En progreso en `INDICE.md` y ✅ al cerrar.

## Contexto del hallazgo
El mismo dato se llama **"Cumplimiento"** en las pantallas que ven los demás (ficha de miembro, tarjeta de miembro) y **"Puntualidad"** en las métricas personales privadas. "Cumplimiento" connota examen aprobado/suspendido — y es justo el término duro el que se muestra **en público**. Incoherencia de tono que refuerza la sensación de vigilancia.

## Evidencia
- ARB públicos: `app_es.arb:465` `members_compliance: "Cumplimiento: {rate}%"`; `:1534` `profile_global_compliance_label: "Cumplimiento global"`.
- ARB privado (tono amable): `app_es.arb:1323` `metricPunctuality: "Puntualidad"`.
- Render público: `lib/features/members/presentation/widgets/member_card.dart:56`; ficha en `member_profile_screen_v2.dart`; `stats_section.dart`.

## Objetivo
Unificar el vocabulario hacia el término amable ya usado en privado ("Puntualidad") en **todas** las superficies públicas, manteniendo el mismo significado y cálculo. Revisar es/en/ro para que la traducción sea coherente (evitar que "compliance" reaparezca en otros idiomas).

## Criterios de aceptación
- [ ] Las superficies públicas (tarjeta y ficha de miembro, stats) usan "Puntualidad" (o el término elegido) de forma coherente con las métricas privadas.
- [ ] No queda "Cumplimiento" suelto en ninguna pantalla visible a terceros.
- [ ] Coherencia en los tres idiomas (es/en/ro).
- [ ] Sin cambios en el cálculo del dato.

## Pruebas obligatorias
### Unit / Widget / Golden
- Grep/test de que las claves públicas ya no usan "Cumplimiento" en ningún idioma.
- Golden de tarjeta y ficha de miembro con el nuevo término.

### Verificación en dispositivo (Firebase real)
1. Abre la ficha de otro miembro y la tarjeta en la pestaña Miembros (MI_9) → el término debe ser el amable. Captura.
2. Compara con las métricas personales (deben coincidir en vocabulario). Captura.
3. Cambia el idioma a en y ro y verifica coherencia. Capturas.

## Dependencias
- "Reencuadre de tono cooperativo" junto a **07**, **08**, **11**. Tras cerrar los cuatro, pasada de coherencia global del vocabulario.

## Al terminar
Actualiza `INDICE.md` (✅ + fecha + nota). Lista archivos y capturas.
