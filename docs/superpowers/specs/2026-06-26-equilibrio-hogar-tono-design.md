# Diseño — Hallazgo #07: "Equilibrio del hogar" no debe señalar a una persona

> Lote **UX Hallazgos 2026-06-25**. Prioridad 🟠 Alto. Forma parte del reencuadre de
> tono cooperativo (07, 08, 11, 12, 29).

## Problema

La tarjeta "Equilibrio del hogar" de la pestaña Miembros, al detectar desequilibrio,
**nombra al miembro que va por delante** con un marcador `"{nickname} +N"` y pinta icono,
porcentaje y barra en color de alerta (`cs.tertiary`). Es un señalamiento público visible
cada vez que se abre Miembros: convierte el reparto en un ranking acusatorio, en contra del
marco cooperativo del producto.

Evidencia:
- `lib/features/members/presentation/skins/members_screen_v2.dart:312-414` — `_BalanceCardV2`.
- `:333-344` — `_topDelta()` → `return '${top.nickname} +$diff';`.
- `:367,369,384,397` — color de alerta `cs.tertiary` (icono, %, barra).
- ARB `members_balance_unbalanced: "Desequilibrado · {topName}"` (es/en/ro).

## Objetivo

Reformular la tarjeta para hablar del **hogar en conjunto** y orientar a la acción positiva,
**sin señalar a un individuo** y **sin color de alarma**, conservando la utilidad de detectar
un reparto desigual.

## Decisión de producto (confirmada)

Encuadre elegido: **cooperativo + acción**. En desequilibrio la tarjeta muestra un mensaje en
plural sobre el hogar y un CTA neutro que lleva a la pestaña Tareas (donde se reparte/reasigna).
Se descartaron: "cooperativo sin CTA" (pierde accionabilidad) y "solo barra agregada" (pierde
el matiz que orienta a repartir).

## Alcance

Solo cliente Flutter. **Sin backend, sin cambios de datos, sin nuevos providers.** Se edita un
único widget privado y los tres ARB. La métrica numérica que ya se muestra (`_balance`, promedio
de `complianceRate`) **no se toca**: solo cambian texto, color y se añade el CTA.

## Cambios

### 1. Lógica (`_BalanceCardV2`)

- **Eliminar `_topDelta()` por completo** (`:333-344`). Con él desaparece toda referencia
  nominal (`nickname`) y el `+N`.
- El estado se sigue decidiendo con el umbral existente `isBalanced = percent >= 75` sobre
  `_balance`. No se rediseña la métrica (fuera de alcance); solo cambia su presentación.
- En desequilibrio, debajo del mensaje se añade un CTA (`TextButton`/`align-start`) que ejecuta
  `context.go(AppRoutes.tasks)`. La navegación entre pestañas del shell es exactamente eso
  (`main_shell_v2.dart:284`), así que no hay fontanería adicional.

### 2. Copy (ARB es/en/ro)

Se **reemplaza** `members_balance_unbalanced` (que exigía placeholder `{topName}`) por dos
claves sin placeholder, y se mantiene `members_balance_well_distributed`.

| Clave | es | en | ro |
|---|---|---|---|
| `members_balance_well_distributed` (sin cambio) | Bien repartido | Well distributed | Bine repartizat |
| `members_balance_uneven` (nueva) | El reparto está algo desigual. | Chores are a bit uneven right now. | Sarcinile sunt cam inegale acum. |
| `members_balance_share_cta` (nueva) | Repartir las tareas | Share out the tasks | Repartizează sarcinile |

- Se elimina la clave huérfana `members_balance_unbalanced` (y su `@`-metadata) en los 3 ARB.
- Sin "esta semana": la métrica es **acumulada**, no semanal; afirmar un periodo sería inexacto.
- El CTA no auto-reparte; lleva a Tareas, donde el usuario reasigna/crea.

### 3. Color (criterio "deja de ser de alerta")

Eliminar `cs.tertiary` en sus tres usos. Paleta resultante:

- **Bien repartido** → `cs.primary` (icono `Icons.balance`, % y barra): tono positivo.
- **Desigual** → neutro/informativo: icono `Icons.scale_outlined` y % en `cs.onSurfaceVariant`,
  barra en `cs.secondary`. Sin naranja/rojo. El grado lo comunica el llenado de la barra.

## Criterios de aceptación

- [ ] La tarjeta ya no muestra el nombre del miembro que va por delante ni un "+N" personal.
- [ ] El color deja de ser de alerta/acusación (sin `cs.tertiary`; neutro/informativo).
- [ ] El mensaje es cooperativo y accionable (CTA "Repartir las tareas" → pestaña Tareas), no evaluativo.
- [ ] Localizado es/en/ro. El caso "Bien repartido" se mantiene positivo.

## Pruebas

### Unit / Widget / Golden
- **Widget**: montar la pantalla (o la tarjeta) con miembros desequilibrados →
  - assert que **no** aparece ningún `nickname` ni texto `+N`;
  - assert que aparece el copy neutro `members_balance_uneven` y el CTA `members_balance_share_cta`;
  - assert que pulsar el CTA navega a `AppRoutes.tasks`.
- **Golden** de la tarjeta en 3 estados: bien repartido, desigual (copy neutro), sin datos (<2 miembros).
- Regenerar `test/ui/features/members/goldens/members_screen.png` si cambia el render.
- Gates: `flutter analyze` sin errores; `flutter test test/unit/` + tests nuevos verdes
  (documentar los ~6 fallos golden preexistentes ambientales por `google_fonts` sin red, ajenos).

### Verificación en dispositivo (Firebase real, dos perfiles)
1. Crear desequilibrio real (emulador=Ana completa tareas; MI_9=Beto deja sin hacer). Abrir Miembros en ambos.
2. Capturar la tarjeta en ambos: no debe señalar a nadie por nombre ni usar color de alarma; el CTA navega a Tareas.
3. Equilibrar el reparto → verificar estado "Bien repartido". Capturar.

## Fuera de alcance / no-objetivos

- No se rediseña la métrica de `_balance` ni el umbral del 75%.
- No se implementa auto-reparto; el CTA solo navega.
- No se tocan otras tarjetas de la pantalla Miembros.

## Riesgos

- **Goldens**: el cambio de texto/color/altura (CTA añadido) regenerará `members_screen.png`.
  Verificar el diff visual antes de aceptar el nuevo master.
- **Coherencia de tono**: al cerrar 07/08/11/12/29, repasar el vocabulario es/en/ro en conjunto.
