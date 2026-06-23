# Mejora del modelo de monetización Premium — Toka

> Documento de diseño · 2026-06-21 · Estado: **propuesta para validar** (no implementado).
> Las cifras son orientativas y se apoyan en supuestos explícitos (ver §10). Faltan datos reales (ver §11).
> Este documento describe el **producto de consumo (B2C)**. El producto **B2B (Toka Business)** se describe aparte en `Monetizacion/Toka_B2B_Producto_Empresas.docx` y se referencia en §9.

---

## 1. Objetivo del cambio

El modelo actual es **Premium por hogar plano** (una cuota desbloquea el hogar entero: 10 miembros, smart distribution, vacaciones, reviews, 90 días de historial, sin ads). Funciona, pero deja sin capturar el **valor del hogar grande**: 10 personas pueden usar todo el valor pagando una sola cuota, y el ingreso es plano e independiente del tamaño.

El cambio propuesto **mantiene "Premium por hogar"** (correcto para una app cooperativa) y lo sube de marcha con cuatro piezas combinadas:

1. **Tiers por tamaño de hogar** (el precio escala con el nº de miembros).
2. **Packs de miembros** para crecer por encima de 10 (hasta un tope de **25**; más allá → Toka Business).
3. **Un producto individual unificado** (Toka Plus) por usuario: quitar banner + cosméticos + métricas personales.
4. **Publicidad diferenciada** banner/intersticial por contexto y por usuario.

Regla transversal: **todos los productos tienen ciclo mensual y anual.**

**Aclaración de encuadre (importante):** el cuello de botella de Toka **no es el coste de Firebase** (céntimos por hogar, ver §10), sino el **ARPU bajo, la conversión y los costes fijos/CAC**. Este cambio ataca el ARPU y la captura de valor; no resuelve por sí solo la conversión (eso lo hacen el trial y arreglar el cobro real, ver §8 y §12).

---

## 2. Modelo actual (punto de partida, resumido del código)

| Eje | Free | Premium (plano) |
|---|---|---|
| Miembros activos | 3 (`FREE_LIMITS.maxActiveMembers`) | 10 (`limits.maxMembers`) |
| Tareas activas | 4 | ilimitadas |
| Tareas recurrentes auto | 3 | ilimitadas |
| Admins | 1 (solo owner) | varios |
| Historial | 30 días | 90 días |
| Smart distribution / Vacaciones / Reviews | no | sí |
| Publicidad | banner (per-hogar, hoy en test IDs) | sin banner |
| Hogares por usuario | 2 base, hasta 5 con compras (slots permanentes) | — |
| Precio | — | 3,99 €/mes · 29,99 €/año |

Entitlement de hogar en `homes/{homeId}.premiumStatus` + flags denormalizados en `homes/{homeId}/views/dashboard` (`premiumFlags`, `adFlags`). Estado de cobro: `currentPayerUid`, `billingState` en memberships. **Rol operativo y facturación ya están desacoplados** (buen diseño que se conserva).

---

## 3. Modelo propuesto — catálogo de productos

Todos con **mensual y anual**. Precios orientativos (validar con tests de elasticidad).

| Producto | Mensual | Anual | Habilita |
|---|---|---|---|
| **Toka Pareja** | 2,99 € | 19,99 € | hogar Premium, ≤2 miembros |
| **Toka Familia** | 3,99 € | 29,99 € | hogar Premium, ≤5 miembros |
| **Toka Grupo** | 5,99 € | 49,99 € | hogar Premium, ≤10 miembros |
| **Pack +5 miembros** | 1,49 € | 9,99 € | sube el tope a 15 (requiere Grupo) |
| **Pack +10 miembros** | 2,49 € | 19,99 € | sube el tope a 25 (requiere Grupo) |
| **Toka Plus** (individual) | 1,99 € | 14,99 € | por usuario: quita banner + cosméticos + métricas personales |

- **Tope absoluto de miembros = 10 + 5 + 10 = 25.** Por encima → **Toka Business** (otro producto).
- Las **mismas features premium** en los tres tiers de hogar; **el tope de miembros es la palanca de precio.**
- **Toka Plus es un único SKU** (no tres productos separados): incluye quitar-banner, cosméticos/skins y métricas personales.

---

## 4. Reparto de funcionalidades por carril

| Carril | Qué incluye | Quién paga | Naturaleza |
|---|---|---|---|
| **Free** | 3 miembros, 4 tareas, 30 d, banner + intersticial | nadie (lo monetiza la publicidad) | — |
| **Premium de hogar (por tier)** | features colectivas (smart, vacaciones, reviews, 90 d), tope de miembros del tier, **sin intersticial para todo el hogar** | el pagador del hogar (`currentPayerUid`) | suscripción |
| **Packs de miembros** | amplían el tope (15 / 25) | el pagador del hogar | **suscripción (no permanente — ver §6)** |
| **Toka Plus (individual)** | quita banner + cosméticos + métricas personales | cada usuario, para sí | suscripción |

Principio rector: **lo colectivo se paga por hogar; lo individual se paga por usuario.** Esto evita el *free-rider problem* del "Premium por usuario" puro (que se descarta), porque ninguna feature colectiva se vende por persona.

---

## 5. Publicidad diferenciada (banner vs intersticial)

> Nota de estado: hoy banner y suscripción usan **IDs/productos de TEST** porque la app está en **fase de desarrollo**. No es un bug; el plan de salida debe cambiar a IDs y productos reales antes de publicar (ver §8 y conflicto con premortem #05).

Matriz objetivo:

| Contexto del miembro | Banner | Intersticial |
|---|:--:|:--:|
| Hogar **Free**, sin Toka Plus | sí | sí |
| Hogar **Free**, con Toka Plus | no | no |
| Hogar **Premium**, el pagador del hogar | no | no |
| Hogar **Premium**, miembro sin Toka Plus | **sí (solo banner)** | no |
| Hogar **Premium**, miembro con Toka Plus | no | no |

Reglas que la generan:
- **Intersticial** = el hogar **no** es Premium **y** el usuario **no** tiene Toka Plus. → El Premium de hogar elimina el intersticial para **todos** sus miembros (beneficio colectivo).
- **Banner** = el usuario **no** tiene Toka Plus **y** no es el pagador del hogar Premium. → El banner solo se quita **individualmente** (siendo el pagador, o con Toka Plus).

**Riesgo de percepción a vigilar:** en un hogar Premium, un miembro que no paga seguirá viendo banner. Es defendible (le quitas la fricción gorda —el intersticial— y el banner se quita con Toka Plus), pero **exige copy muy claro**. Alternativa más amable (a decidir): que el Premium de hogar quite el banner a todos sus miembros y reservar Toka Plus solo para hogares Free; se pierde la monetización de free-riders del hogar Premium a cambio de cero fricción social.

---

## 6. Correcciones de modelo (decisiones conscientes)

**6.1. Los packs de miembros, al ser suscripción, NO son permanentes.**
La regla de producto actual dice que *los créditos de plaza son permanentes aunque canceles*. Eso aplica a los **slots de hogar** (multi-hogar, `lifetimeUnlockedHomeSlots`). Los **packs de miembros** son un eje **distinto** y, al ser suscripción mensual/anual, son **temporales**: mientras pagas el pack, tienes las plazas; si cancelas, los **miembros excedentes se congelan** reutilizando la maquinaria de `applyDowngradeJob` (status `frozen`). Hay que **separar conceptualmente**:
- **Slots de hogar** → permanentes (no cambia).
- **Plazas de miembro (packs)** → suscripción, reversibles vía congelación.

**6.2. El límite de 3 miembros Free es el verdadero motor de conversión.**
Un hogar de >3 personas **no cabe** en Free → o paga o no usa la app con todos. Por eso la conversión es muy superior en hogares grandes (estimada 30-40% vs 4% en parejas). Esto **valida cobrar por tamaño**: quien más valor obtiene es quien está obligado a pagar. No debilitar este límite.

---

## 7. Cambios técnicos necesarios

### 7.1 Firestore / modelo de datos
- **Nuevo eje de entitlement individual por usuario** (p. ej. en `users/{uid}.plus` o doc dedicado) para Toka Plus. Hoy el entitlement de ads/features vive en el **dashboard del hogar** (doc compartido) y **no puede expresar estado per-usuario**.
- `limits.maxMembers` pasa de binario (3/10) a derivarse del **tier + packs**: 2 / 5 / 10 / 15 / 25.
- `adFlags` del dashboard ya no basta para decidir ads: la visibilidad pasa a calcularse en cliente combinando **estado del hogar × entitlement individual**.

### 7.2 Cloud Functions
- `syncEntitlement`: mapear **cada productId verificado** a su efecto (tier → `maxMembers`; pack → incremento de tope; Plus → entitlement de usuario). Hoy infiere solo `monthly`/`annual`. **Depende de la verificación real de recibos (premortem #02).**
- `applyDowngradeJob` / downgrade: soportar **bajada de tier** (Grupo→Familia→Free) y **cancelación de packs** (congelar miembros excedentes), no solo Premium sí/no.
- Reconciliación con stores (renovación/cancelación/refund) por tier y por pack. **Depende de premortem #06.**

### 7.3 Flutter
- Cálculo de visibilidad de ads con las reglas de §5 (banner vs intersticial, per-usuario).
- Integrar **intersticial** de AdMob (hoy solo hay banner).
- Paywall con selector de tier por tamaño + venta de packs + Toka Plus, con **mensual/anual** en cada uno.
- Pantalla/entrada para Toka Plus (cosméticos ya existen vía `AppSkin`/`SkinSwitch`; métricas personales nuevas).

### 7.4 Tiendas (Play / App Store)
- **12 SKUs** (6 productos × mensual/anual). Las stores manejan bien productos discretos; la cantidad variable de miembros se vende como **packs**, no como cantidad continua.
- Configurar **free trial** (no existe hoy; ver premortem #14).

---

## 8. Compatibilidad con multi-hogar, downgrade, restore y roles

- **Multi-hogar:** intacto. Cada hogar tiene su tier/estado; los slots de hogar permanentes no cambian.
- **Downgrade / restore:** se **reutiliza** la maquinaria existente (congelar miembros/tareas, ventana de 30 días). El cambio es que ahora hay **más niveles** (tiers + packs) en vez de Premium binario.
- **Roles vs pago:** intacto. Toka Plus es per-usuario y no toca permisos del hogar; el pagador del hogar sigue siendo `currentPayerUid` con su protección.
- **Orden recomendado de despliegue (de menor a mayor riesgo):**
  1. **Cerrar el cobro real y la base** (no cambia el modelo): verificación de recibos (#02), quitar debug de prod (#03), AdMob real (#05), trial (#14), RTDN/downgrade automático (#06).
  2. **Tiers por tamaño** (reaprovecha `limits.maxMembers`).
  3. **Intersticiales + ads diferenciadas per-usuario.**
  4. **Packs de miembros** (tope 25) y **Toka Plus**.
  Cada paso detrás de una bandera de Remote Config para poder revertir.

---

## 9. Relación con Toka Business (B2B)

El tope de **25 miembros** es deliberado: por encima, un "hogar" deja de serlo y pasa a ser una **organización** (residencia, piso gestionado, empresa de limpieza, alojamientos). Ahí entra **Toka Business**, un **segundo producto** con panel web, multi-tenant, facturación por Stripe y licencia por unidad/cama/operario. Los **packs de miembros son la rampa natural** hacia ese producto. Detalle completo en `Monetizacion/Toka_B2B_Producto_Empresas.docx`.

---

## 10. Simulación de ingresos (1.000 hogares activos)

**Supuestos:** distribución 40% parejas(2) / 35% familias(4) / 18% pisos(7) / 5% grupos(10) / 2% extra(15); conversión diferenciada por tamaño (4% / 12% / 30% / 35% / 40%); en Free los usuarios activos se capan a 3; neto tras comisión de tienda 25%; ads: Free 3,2 €/usuario·año (banner+intersticial), Premium no-pagador 1,8 €/año (solo banner); coste Firebase 0,01–0,35 €/hogar·mes. **No incluye costes fijos (desarrollo, soporte, CAC).**

| | Base (sin trial) | Optimista (trial + ads pulidos) |
|---|--:|--:|
| Hogares premium | 138 (13,8 %) | 220 (22,0 %) |
| Suscripción hogar | 4.225 € | 6.760 € |
| Packs de miembros | 60 € | 96 € |
| Toka Plus | 991 € | 1.766 € |
| Publicidad | 8.199 € | 8.094 € |
| Coste Firebase | −365 € | −440 € |
| **Margen variable/año** | **≈ 13.110 €** | **≈ 16.276 €** |
| ARPU/usuario activo | 0,37 €/mes | 0,41 €/mes |
| Mix (subs+packs / Plus / ads) | 32 / 7 / 61 % | 41 / 11 / 48 % |

**Lecturas clave:**
- **Firebase es irrelevante** (≈2,7 % del ingreso) incluso con hogares de 25. El problema nunca fue la infra.
- **La publicidad es el mayor bloque** (48–61 %): arreglar AdMob (test→real) es la palanca de ingreso #1 a corto plazo.
- **El tope de 25 aporta poco ingreso directo** (extra-grandes = 2 %): su valor es ser rampa a B2B.
- **El número que decide la viabilidad es volumen × CAC**, no el modelo de pricing. A 1.000 hogares (~13 k €/año variable) **no se cubre un sueldo**; el punto de equilibrio realista está en **~10–15 k hogares** *si el CAC es bajo*.

---

## 11. Datos que faltan para decidir con seguridad
- Distribución real de tamaños de hogar (si los hogares grandes son <10 %, las suscripciones caen a la mitad).
- Conversión real por tamaño y elasticidad de los nuevos precios.
- eCPM real de banner vs intersticial por geografía.
- **CAC** — sin él, "margen variable +13 k" no dice si se gana o se pierde.
- % de hogares que tocan cada tope (si casi nadie llega a 10, los packs y el tier Grupo captan poco).

---

## 12. Relación con `premortem.md` — conflictos y dependencias

> Resumen del cruce con los 20 prompts de remediación. Detalle y matices en la conversación de diseño.

| Prompt premortem | Relación con este modelo | Acción |
|---|---|---|
| **#02** Verificación recibos IAP | **Pre-requisito + ampliar alcance.** Debe mapear los **nuevos productId** (3 tiers + 2 packs + Plus, ×mensual/anual) a su entitlement, no solo `monthly/annual`. Si se implementa con 2 productos, habrá que rehacerlo. | Implementar #02 **con el catálogo nuevo en mente** (tabla productId→efecto extensible). |
| **#05** AdMob unit IDs reales | **Conflicto por sub-especificación.** Solo contempla **banner per-hogar**. El modelo añade **intersticial** y **visibilidad per-usuario**. Implementar #05 tal cual quedaría incompleto. | Ampliar #05: añadir unit ID de **interstitial** y un **eje de entitlement de ads per-usuario**. |
| **#06** RTDN/refunds + downgrade auto + revocar plazas | **Conflicto conceptual.** Asume **plazas permanentes** y "decrementar `lifetimeUnlockedHomeSlots` en refund". El modelo hace los **packs de miembros = suscripción (no permanente)** y añade **downgrade multi-tier**. Hay que separar slots de hogar (permanentes) de packs de miembro (suscripción). | Reescribir el alcance de #06: reconciliación **por tier y por pack**; congelación de excedentes en cancelación de pack. |
| **#14** Free trial + límite Free no eludible | **Compatible y necesario.** El modelo asume trial. El límite Free de **tareas** sigue; añade límites por **tier de miembros** (ya enforced server-side). | Mantener; decidir si el trial es por tier. |
| **#03** debugSetPremiumStatus fuera de prod | **Sin conflicto, necesario.** | Mantener. |
| **#15 / #16** Jobs full-collection, hot document, fan-out | **Refuerzo de prioridad.** Con tope **25** (vs 10), el fan-out del dashboard O(2·miembros+tareas) y `syncHomeSnapshot` O(miembros) crecen ~2,5×, y el dashboard es **un único doc (límite 1 MB)**. | **Subir prioridad** de #15/#16 antes de habilitar hogares grandes. |
| **#08 / #09** Tareas zombi al salir/expulsar · vacaciones | **Sinergia/dependencia.** El downgrade de tier/packs **congela miembros**, reutilizando la misma lógica de reasignación/congelación que tocan #08/#09. | Hacer #08/#09 **antes o junto** al downgrade multi-tier. |
| **#04** GDPR borrado/exportación | **Interacción menor.** Las **métricas personales** de Toka Plus son datos personales que el export/borrado debe cubrir. | Incluir las métricas personales en el alcance de #04. |
| **#01, #07, #10, #11, #12, #13, #17, #18, #19, #20** | **Sin conflicto** con el modelo de monetización. | Sin cambios. |

**Conclusión del cruce:** ningún prompt queda **invalidado**, pero **tres deben ajustarse antes de implementarse** (#02 alcance, #05 sub-especificado, #06 conflicto conceptual de "permanente vs suscripción"), **dos suben de prioridad** (#15, #16 por el tope de 25) y **dos son dependencia** del downgrade multi-tier (#08, #09). El resto es independiente.
