# 07 · 🟠 Alto — "Equilibrio del hogar" no debe señalar a una persona

> Lee primero `_CONVENCIONES.md`. Marca 🔄 En progreso en `INDICE.md` y ✅ al cerrar.

## Contexto del hallazgo
La tarjeta "Equilibrio del hogar" de la pestaña Miembros, cuando detecta desequilibrio, **nombra al miembro que va por delante** con un marcador tipo `"{topName} +N"` y barra en color de alerta. Es el punto más "policial" de la app: convierte el reparto en un señalamiento público visible cada vez que se abre Miembros. Choca con la propuesta cooperativa del producto.

## Evidencia
- `lib/features/members/presentation/skins/members_screen_v2.dart:318-414` — `_BalanceCardV2`.
- `lib/features/members/presentation/skins/members_screen_v2.dart:342-343` — `return '${top.nickname} +$diff';`
- ARB: `app_es.arb:439` `members_balance_unbalanced: "Desequilibrado · {topName}"`; `:437` `members_balance_well_distributed: "Bien repartido"`.
- Color de alerta: `members_screen_v2.dart:367-407` (`cs.tertiary`).

## Objetivo
Reformular la tarjeta para hablar del **hogar en conjunto** y orientar a la acción positiva, **sin señalar a un individuo**. Mantener la utilidad (detectar reparto desigual) sin el marco de vigilancia/ranking.

## Decisión de producto a confirmar
Usa `superpowers:brainstorming` para elegir el encuadre: p. ej. "El reparto está algo desigual esta semana — ¿repartimos las próximas tareas?" con CTA neutro, sin nombre y sin color de alarma; o mostrar solo un indicador agregado (barra) sin texto acusatorio.

## Criterios de aceptación
- [ ] La tarjeta ya no muestra el nombre del miembro que va por delante ni un "+N" personal.
- [ ] El color deja de ser de alerta/acusación (usar neutro/informativo).
- [ ] El mensaje es cooperativo y, si procede, accionable (sugerir repartir), no evaluativo.
- [ ] Localizado (es/en/ro). El caso "Bien repartido" se mantiene positivo.

## Pruebas obligatorias
### Unit / Widget / Golden
- Test de la lógica de balance: con datos desequilibrados ya **no** se devuelve `{nickname} +N`.
- Golden de la tarjeta en estados: bien repartido, desequilibrado (nuevo copy neutro), sin datos.

### Verificación en dispositivo (Firebase real, dos perfiles)
1. Crea desequilibrio real: con la cuenta del emulador completa varias tareas; con MI_9 deja tareas sin hacer. Abre Miembros en ambos.
2. Captura la tarjeta en ambos dispositivos: no debe señalar a nadie por nombre ni usar color de alarma.
3. Verifica el estado "Bien repartido" equilibrando el reparto. Captura.

## Dependencias
- Forma parte del "reencuadre de tono cooperativo" junto a **08**, **11**, **12**. Al cerrar los cuatro, revisar coherencia global del vocabulario.

## Al terminar
Actualiza `INDICE.md` (✅ + fecha + nota). Lista archivos y capturas.
