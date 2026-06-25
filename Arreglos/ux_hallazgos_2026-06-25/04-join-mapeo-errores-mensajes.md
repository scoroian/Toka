# 04 · 🔴 Crítico — Mapeo de errores al unirse: "hogar lleno" falso + mensajes inconsistentes

> Lee primero `_CONVENCIONES.md`. Marca 🔄 En progreso en `INDICE.md` y ✅ al cerrar.

## Contexto del hallazgo
El cliente mapea **cualquier** `failed-precondition` del join a `MaxMembersReachedException` → "El hogar ya alcanzó el máximo de miembros", aunque la causa sea otra (rate-limit, plazas de cuenta tras el prompt 01, etc.). Además, el **mismo** error de "hogar lleno" produce mensajes distintos según la entrada: por el selector multi-hogar se ve el mensaje correcto, pero por el onboarding cae en `unexpected_error` → "Algo salió mal" genérico, perdiendo el motivo real.

## Evidencia
- `lib/features/homes/data/homes_repository_impl.dart:66-81` — mapea todo `failed-precondition`→`MaxMembersReachedException`; el rate-limit (`resource-exhausted`) se rescata solo en otra capa.
- `lib/features/onboarding/application/onboarding_provider.dart:238-244` — no maneja `failed-precondition` → cae en `unexpected_error`.
- `lib/features/homes/presentation/home_selector_widget.dart:532-540` — manejo correcto en el selector (referencia del "bueno").
- Backend que lanza estos códigos: `functions/src/homes/index.ts:360-498` (`joinHomeByCode`).

## Objetivo
Mapear los errores del join **por su `code` específico** (no por la categoría genérica) y **unificar** los mensajes entre el selector y el onboarding, en una sola fuente de verdad. Coordínalo con el prompt **01** (que introduce el error de plazas de cuenta): asegúrate de que ese nuevo error tiene su propio copy y no se confunde con "hogar lleno".

## Criterios de aceptación
- [ ] Cada motivo del backend tiene su excepción tipada y su copy: hogar lleno (`enforceMemberCapTx`), código inválido (`not-found`), expirado (`deadline-exceeded`), rate-limit (`resource-exhausted`/`too-many-join-attempts`), sin plazas de cuenta (prompt 01).
- [ ] El **mismo motivo** muestra el **mismo mensaje** tanto en el selector como en el onboarding.
- [ ] Nada cae en "Algo salió mal" si el backend dio un motivo conocido.
- [ ] Strings localizadas (es/en/ro).

## Pruebas obligatorias
### Unit
- Test de mapeo del repo: cada `FirebaseFunctionsException.code` → excepción tipada esperada.
- Test de paridad: la tabla de mensajes del onboarding == la del selector para cada motivo.

### Verificación en dispositivo (Firebase real)
1. Provoca cada caso por **ambas** entradas (selector y onboarding) y captura el mensaje:
   - Hogar realmente lleno (con Admin SDK llena el hogar al tope del tier).
   - Código inválido / expirado (genera y deja caducar, o usa uno falso — carácter a carácter).
   - Rate-limit (>10 intentos/hora del mismo usuario).
   - Sin plazas de cuenta (depende del prompt 01).
2. Verifica que el mensaje coincide entre selector y onboarding para cada motivo. Capturas comparativas.

## Dependencias
- Idealmente **después del 01** (para incluir el error de plazas de cuenta). Si se hace antes, deja el hueco preparado y anótalo en el índice.

## Al terminar
Actualiza `INDICE.md` (✅ + fecha + nota). Lista archivos y capturas.
