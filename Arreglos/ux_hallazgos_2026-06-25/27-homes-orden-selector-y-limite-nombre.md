# 27 · 🟡 Medio — Selector multi-hogar: ordenar por "tareas pendientes para mí" + unificar límite de nombre

> Lee primero `_CONVENCIONES.md`. Marca 🔄 En progreso en `INDICE.md` y ✅ al cerrar.

## Contexto del hallazgo
Dos inconsistencias con spec-04:
1. **Orden del selector:** la spec pide ordenar **1) último usado, 2) con tareas pendientes para mí, 3) resto por nombre**. El código solo ordena por **activo + nombre**; el criterio "con tareas pendientes para mí" no está implementado (las memberships ni cargan ese dato). El usuario con varios hogares no ve arriba el que reclama su atención.
2. **Límite de nombre de hogar inconsistente:** onboarding limita a 40 chars, el backend a 60, y el sheet de creación del selector no valida longitud en cliente. Tres límites distintos.

## Evidencia
- `lib/features/homes/presentation/home_selector_widget.dart:19-31` — `sortMembershipsForSelector` (solo activo + nombre).
- Spec: `.worktrees/feature-skin-v2/specs/spec-04-homes.md:20,204-205` (orden y test requerido).
- Límites: `onboarding_provider.dart:195` (40), `functions/src/homes/index.ts:88` (60), `home_selector_widget.dart` `_submitCreate` (sin validación).

## Objetivo
1. Implementar el orden completo del selector incluyendo "con tareas pendientes para mí" (cargar de forma barata ese flag por hogar; evitar lecturas costosas — apoyarse en el dashboard/contadores ya existentes).
2. Unificar el límite de longitud del nombre de hogar en un único valor (cliente y backend coherentes).

## Criterios de aceptación
- [ ] El selector ordena: último usado → con tareas pendientes para mí → resto por nombre.
- [ ] El cálculo de "tareas pendientes para mí" no introduce lecturas pesadas (sin listas completas; usar agregados).
- [ ] El límite de nombre de hogar es único y consistente en onboarding, selector y backend.
- [ ] Tests que cubren el orden (como pide la spec).

## Pruebas obligatorias
### Unit / Widget
- Test de `sortMembershipsForSelector` con los tres criterios (incluye empates y el caso "pendientes").
- Test de validación de nombre: mismo límite en las tres rutas.

### Verificación en dispositivo (Firebase real)
1. Con ≥3 hogares (MI_9), uno de ellos con una tarea pendiente para ti → debe subir en el selector por encima de los que no. Captura.
2. Cambia de hogar y verifica que "último usado" sigue mandando como primer criterio. Captura.
3. Intenta crear un hogar con un nombre largo por las dos vías (onboarding y selector): el límite debe coincidir. Capturas.

## Dependencias
- Sinergia con **14**/**15** (gestión y contexto de hogares).

## Al terminar
Actualiza `INDICE.md` (✅ + fecha + nota: límite de nombre acordado). Lista archivos y capturas.
