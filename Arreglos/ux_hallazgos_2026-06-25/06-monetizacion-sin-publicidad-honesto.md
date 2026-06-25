# 06 · 🟠 Alto — "Sin publicidad" honesto + copy banner-vs-intersticial

> Lee primero `_CONVENCIONES.md`. Marca 🔄 En progreso en `INDICE.md` y ✅ al cerrar.

## Contexto del hallazgo
El modelo de ads tiene dos ejes que el usuario no entiende y nadie explica:
- El **intersticial** se quita si el **hogar** es Premium.
- El **banner** solo se quita **por usuario** (siendo pagador o teniendo Toka Plus).

Consecuencia vivida: en un hogar Premium, un miembro que no paga **sigue viendo banner** y no entiende por qué. Y el paywall de hogar promete `"Sin publicidad"`, que es **falso para los miembros no pagadores** (solo se les quita el intersticial). El propio doc de diseño marcó esto como "riesgo de percepción… exige copy muy claro" y ese copy no existe.

## Evidencia
- `lib/features/subscription/application/ad_visibility_provider.dart:47-55` — `computeAdVisibility`: matriz premium×pagador×Plus.
- ARB: `app_es.arb:670` `paywall_feature_no_ads: "Sin publicidad"`.
- Doc: `Arreglos/mejora_modelos_premium.md:94` — "riesgo de percepción a vigilar… exige copy muy claro".

## Objetivo
Hacer honesto y comprensible el mensaje sobre anuncios: el paywall de hogar debe decir con precisión **qué quita** (p. ej. "Sin anuncios a pantalla completa para todo el hogar") y dejar claro que **quitar el banner para ti** requiere ser el pagador o tener Toka Plus. Añadir microcopy donde el usuario ve el banner pese a "Premium".

## Criterios de aceptación
- [ ] El paywall de hogar ya no afirma un genérico "Sin publicidad" que no se cumple para no-pagadores. El copy distingue intersticial (hogar) de banner (individual).
- [ ] El paywall de Toka Plus deja claro que quita el banner **a ti**.
- [ ] Donde un usuario no-pagador de hogar Premium ve banner, hay una vía de entendimiento (microcopy/CTA "Quitar también el banner con Toka Plus"), sin ser nag agresivo.
- [ ] Todo localizado (es/en/ro). Sin afirmaciones falsas.

## Pruebas obligatorias
### Unit / Widget
- Tests de `computeAdVisibility` (función pura) para las combinaciones: hogar Free/Premium × pagador/no × Plus/no → resultado esperado banner/intersticial. (Si ya existen, amplía cobertura de los casos "Premium + no pagador".)
- Widget/golden del paywall de hogar y del de Plus con los copys nuevos.

### Verificación en dispositivo (Firebase real, dos perfiles)
1. Hogar Premium con **dos** miembros: el **pagador** en MI_9 (sin banner ni intersticial) y un **no-pagador** en el emulador (sin intersticial pero **con** banner). Captura ambos: el copy debe explicar la diferencia, no contradecirla.
2. Activa Toka Plus en la cuenta no-pagadora → el banner desaparece para ella. Captura antes/después.
3. Revisa el paywall de hogar y el de Plus: ningún texto promete "sin publicidad" de forma que el no-pagador perciba engaño. Capturas.

## Dependencias
- Coordina ARB con **05** y **16**. Relacionado con **10** (trigger del intersticial).

## Al terminar
Actualiza `INDICE.md` (✅ + fecha + nota). Lista archivos y capturas.
