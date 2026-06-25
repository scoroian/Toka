# 01 · 🔴 Crítico — `joinHomeByCode` debe validar las plazas de cuenta del invitado

> Lee primero `_CONVENCIONES.md`. Marca esta tarea como 🔄 En progreso en `INDICE.md` antes de empezar y ✅ al cerrarla.

## Contexto del hallazgo
`createHome` valida que la cuenta tenga plazas libres (cap de 5 hogares: 2 base + hasta 3 créditos permanentes). Pero **`joinHomeByCode` (y `joinHome`) solo validan el tope de miembros del *hogar destino*, NO las plazas de la cuenta del que se une.** Resultado: un usuario que ya está en 5 hogares puede unirse a un 6º por código de invitación, **eludiendo el cap de cuenta**. Es un agujero de negocio (las plazas de hogar son el eje monetizable) y contradice la spec.

## Evidencia
- `functions/src/homes/index.ts:360-498` — `joinHomeByCode`: rate-limit + `enforceMemberCapTx` (tope del hogar) pero **ningún chequeo de plazas de la cuenta del invitado**.
- `functions/src/homes/index.ts:251` aprox — `joinHome` (mismo patrón).
- `functions/src/homes/index.ts:75-244` — `createHome`: sí cuenta memberships `active` vs `baseHomeSlots + lifetimeUnlockedHomeSlots` (cap `homeSlotCap`). Reutilizar esa misma lógica canónica.
- Regla de producto: `.worktrees/feature-skin-v2/specs/spec-04-homes.md:7` — "Un usuario sin plazas libres no puede crear **ni aceptar invitaciones**". Reglas de negocio CLAUDE.md #2 (2 base + 3 extra, máx 5).

## Objetivo
Aplicar el **mismo cómputo de plazas de cuenta** que `createHome` dentro de la transacción de `joinHomeByCode`/`joinHome`, **excepto en rejoin** (volver a un hogar del que ya eras miembro `left`: ahí no se consume plaza nueva — verificar la semántica actual de rejoin para no romperla).

## Criterios de aceptación
- [ ] Unirse a un hogar nuevo cuando la cuenta está al límite (5 hogares activos) → la callable lanza un error tipado (p. ej. `resource-exhausted`/`failed-precondition` con `code` propio como `no-account-slots`) y el cliente muestra un mensaje claro y localizado (es/en/ro), distinto de "hogar lleno".
- [ ] Unirse con plazas disponibles → sigue funcionando.
- [ ] **Rejoin** (status `left` → `active` en un hogar ya contabilizado) → NO se bloquea ni consume plaza extra.
- [ ] El cómputo es transaccional y consistente con `createHome` (misma fuente: `baseHomeSlots`/`lifetimeUnlockedHomeSlots`/`homeSlotCap`, con fallback legacy).
- [ ] El cliente (`homes_repository_impl.dart`, `onboarding_provider.dart`) mapea el nuevo error a un copy específico, no al genérico ni a "hogar lleno".

## Pruebas obligatorias
### Backend (jest/mocktail en `functions/`)
- Caso feliz: cuenta con 1 plaza libre se une → OK.
- Edge: cuenta con 5 hogares activos se une a un 6º → error `no-account-slots`.
- Edge: rejoin a hogar ya contabilizado estando "al límite" → permitido.
- Edge: concurrencia — dos joins simultáneos que cruzarían el cap (verifica que la transacción lo impide).
- Verifica que `enforceMemberCapTx` (tope del hogar) sigue intacto y que ambos límites coexisten.

### Verificación en dispositivo (Firebase real, dos perfiles)
1. Con el **Admin SDK** (`toka-sa.json`) deja una cuenta QA con 5 hogares activos.
2. En MI_9, logueado con esa cuenta, intenta unirte a un 6º hogar por código (escribe el código **carácter a carácter**). Captura el mensaje de error → debe ser específico, no "hogar lleno".
3. En el emulador, con otra cuenta con plazas libres, únete al mismo hogar → debe funcionar (sync en vivo visible).
4. Repite el caso rejoin: abandona un hogar y vuelve a unirte estando al límite → permitido. Captura.

## Notas de implementación / despliegue
- Si añades un `where`/`collectionGroup` nuevo, declara el índice `COLLECTION_GROUP` en `firestore.indexes.json` (el emulador no lo exige; prod sí).
- Deploy a `toka-dd241` autorizado en dev (sigue `DEPLOY.md` + `FUNCTIONS_DISCOVERY_TIMEOUT=120`). Cuidado con el working tree (despliega WIP).

## Al terminar
Actualiza `INDICE.md` (✅ + fecha + nota: SKUs/archivos tocados, índice nuevo si lo hubo). Lista archivos y enlaza capturas.
