# 21 · 🔵 Go-live — Publicar flags RC en ambos namespaces + marcar spec-10 obsoleta

> Lee primero `_CONVENCIONES.md`. Marca 🔄 En progreso en `INDICE.md` y ✅ al cerrar.

## Contexto del hallazgo
Todo el modelo de monetización nuevo (tiers + packs + Toka Plus + ads diferenciadas) está tras flags de Remote Config con **default OFF**. Con defaults OFF el usuario ve el modelo binario legacy. Activar el modelo real exige publicar los flags en **dos namespaces** (cliente + server, este último por REST), un paso fácil de olvidar y necesario para go-live. Además, `spec-10` describe el modelo binario antiguo y ya no es fuente de verdad: cualquiera que la lea se hará un modelo equivocado.

## Evidencia
- Flags default OFF: `docs/cierre-monetizacion/REMOTE_CONFIG_FLAGS.md:9-15` (`home_tiers_enabled`, `member_packs_enabled`, `toka_plus_enabled`, `ad_differentiated_enabled`, `ad_interstitial_enabled`).
- Publicación en dos namespaces (cliente + server REST): `docs/cierre-monetizacion/REMOTE_CONFIG_FLAGS.md:70-74`.
- Caveat de over-cap al apagar `member_packs_enabled` con hogares con packs: `REMOTE_CONFIG_FLAGS.md:44-53`, `INFORME_CIERRE.md:51-53`.
- Spec obsoleta: `.worktrees/feature-skin-v2/specs/spec-10-subscription.md` (modelo binario 3,99/29,99 €).
- `PremiumFeatureGate` implementado pero sin uso (`lib/features/subscription/.../premium_feature_gate.dart`).

## Objetivo (tarea mayormente de configuración/documentación, poco código)
1. Definir y ejecutar el procedimiento de **publicar los 5 flags en ambos namespaces** de forma coordinada (cliente vía template; server vía REST — ver `qa_set_server_flag.js`/runbook), verificando **paridad**.
2. **Marcar `spec-10` como superseded** (encabezado claro apuntando al código y a los docs de cierre como fuente de verdad).
3. Decidir sobre `PremiumFeatureGate`: usarlo de forma uniforme o eliminarlo (no dejar código muerto).
4. Documentar un **guardrail/checklist** para no apagar `member_packs_enabled` con hogares over-cap.

## Criterios de aceptación
- [ ] Procedimiento de publicación de flags documentado y verificable (paridad cliente↔server comprobada).
- [ ] `spec-10` marcada como obsoleta con puntero a la fuente de verdad real.
- [ ] Decisión tomada y aplicada sobre `PremiumFeatureGate`.
- [ ] Checklist de seguridad para el toggle de packs.
- [ ] **No** se publican flags en **producción** sin OK explícito del usuario (en dev `toka-dd241` está autorizado).

## Pruebas obligatorias
### Verificación de config (Firebase real `toka-dd241`)
1. Publica los flags en dev en ambos namespaces y verifica con la app que el modelo tiered aparece (paywall tiered, packs, Plus, ads diferenciadas, intersticial). Capturas.
2. Verifica que el server template y el cliente coinciden (lee ambos; el server va por REST).
3. Prueba de seguridad: documenta (no ejecutes en prod) qué pasa al apagar `member_packs_enabled` con un hogar over-cap, según el caveat.

### Nota
- Esta tarea es de **lanzamiento**: idealmente al final del lote, cuando los copys (05, 06, 16) y el trigger del intersticial (10) ya estén corregidos, para no exponer el modelo nuevo con copys erróneos.

## Al terminar
Actualiza `INDICE.md` (✅ + fecha + nota: flags publicados, decisión sobre `PremiumFeatureGate`). Lista archivos/docs y capturas.
