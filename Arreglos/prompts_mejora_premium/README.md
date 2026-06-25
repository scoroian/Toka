# Prompts de implementación — Mejora del modelo de monetización Premium

Este directorio contiene **8 prompts autocontenidos**. Cada uno se ejecuta en una **sesión nueva e independiente** de Claude Code sobre el repo Toka. Implementan, por fases, el rediseño del modelo Premium (tiers por tamaño de hogar, Toka Plus individual, publicidad diferenciada banner/intersticial, y packs de miembros).

## Cómo usar

1. Abre una **sesión nueva** de Claude Code en la raíz del repo.
2. Copia y pega **el archivo de la fase entero** como primer mensaje. No hace falta nada más: cada prompt trae embebido todo el *qué* (precios, topes, reglas).
3. Deja que la sesión termine la fase: tests verdes + `flutter analyze` limpio + deploy a dev + verificación en los 2 dispositivos.
4. **No empieces la fase N+1 hasta que la fase N esté verde, desplegada a dev y verificada en dispositivo.** Cada fase lee del **código** el contrato que dejó la anterior.

## Regla de oro (en los 8 prompts)

- El **código es la única fuente de verdad del estado actual**. Cada sesión analiza el código desde cero.
- Está **prohibido** que las sesiones lean documentos de análisis/spec previos (`mejora_modelos_premium.md`, `premortem.md`, `Hallazgos.md`, `Monetizacion/`, `toka_qa_session/**/*.md`, etc.). Todo el *qué* va embebido en el prompt. Sí pueden leer `CLAUDE.md` y `DEPLOY.md` (operativos).
- Verificación obligatoria en **2 dispositivos con 2 cuentas distintas** (MI_9 USB + emulador), forzando entitlements por **Admin SDK / script de QA** (no compra real con SKUs sandbox todavía), comprobando **sincronización en vivo, límites server-side y estados transitorios** (congelación, downgrade, banner/intersticial).
- **Cobertura de tests exhaustiva, no mínima**: cada fase debe probar **todos los flujos y casuísticas** (caminos felices, errores, fronteras, todas las combinaciones, idempotencia, concurrencia y reglas de seguridad). Una fase no está DONE si queda una rama, un estado o una transición sin test, y debe enumerar las casuísticas cubiertas justificando que la lista es completa.

## Orden de las fases

| # | Archivo | Eje | Capa |
|---|---------|-----|------|
| 1 | `fase-1-tiers-backend.md` | Tiers por tamaño de hogar | Functions / Firestore / rules |
| 2 | `fase-2-tiers-flutter.md` | Tiers por tamaño de hogar | Flutter (límites + paywall) |
| 3 | `fase-3-toka-plus-backend.md` | Toka Plus (entitlement individual) | Functions / Firestore / rules |
| 4 | `fase-4-toka-plus-flutter.md` | Toka Plus (skins + métricas) | Flutter |
| 5 | `fase-5-ads-diferenciadas-flutter.md` | Publicidad diferenciada + intersticial | Flutter (+ config) |
| 6 | `fase-6-packs-backend.md` | Packs de miembros | Functions / Firestore / rules |
| 7 | `fase-7-packs-flutter.md` | Packs de miembros | Flutter |
| 8 | `fase-8-qa-integral.md` | Cierre: SKUs, flags, QA end-to-end, paridad dev→prod | Transversal |

**Por qué este orden:** Toka Plus (3-4) va **antes** de la publicidad diferenciada (5) a propósito, porque la matriz de ads depende de que el entitlement individual de Plus ya exista para poder probarse de verdad en dispositivo. Los packs (6-7) van al final porque suben de prioridad la presión sobre el fan-out del dashboard (tope 25 vs 10) y se apoyan en la maquinaria de downgrade que ya consolidan las fases de tiers.

## Catálogo de productos completo (referencia humana, ya embebido en cada prompt)

| Producto | Mensual | Anual | Habilita |
|---|---|---|---|
| Toka Pareja | 2,99 € | 19,99 € | hogar Premium, ≤2 miembros |
| Toka Familia | 3,99 € | 29,99 € | hogar Premium, ≤5 miembros |
| Toka Grupo | 5,99 € | 49,99 € | hogar Premium, ≤10 miembros |
| Pack +5 miembros | 1,49 € | 9,99 € | +5 plazas sobre Grupo → 15 (requiere Grupo) |
| Pack +10 miembros | 2,49 € | 19,99 € | +10 plazas sobre Grupo → 20; con +5 → 25 (requiere Grupo) |
| Toka Plus (individual) | 1,99 € | 14,99 € | por usuario: quita banner + cosméticos + métricas personales |

Tope absoluto de miembros = 10 + 5 + 10 = **25**. Por encima → Toka Business (otro producto, fuera de alcance). Free sigue en **3 miembros**.
