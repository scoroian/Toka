# 10 · 🟠 Alto — Sacar el intersticial de la navegación core

> Lee primero `_CONVENCIONES.md`. Marca 🔄 En progreso en `INDICE.md` y ✅ al cerrar.

## Contexto del hallazgo
El anuncio intersticial se dispara con el **cambio de pestaña principal** (Hoy/Historial/Miembros/Tareas/Ajustes). En una app de tareas del hogar, cambiar de pestaña es la acción más frecuente; interrumpirla con un anuncio a pantalla completa es de los patrones más molestos posibles. Hay mitigaciones (gracia en el primer cambio de sesión, cap de 3/sesión, intervalo 210 s), pero el **trigger** sigue siendo navegación core.

## Evidencia
- `lib/features/.../main_shell_v2.dart:161` — `AdInterstitialTrigger` montado en el shell.
- `lib/features/subscription/.../ad_interstitial_trigger.dart:31-38` — dispara con el cambio de pestaña.
- `lib/features/subscription/.../ad_interstitial_controller.dart:87-91` — gracia primer cambio.
- Flags/caps: `docs/cierre-monetizacion/REMOTE_CONFIG_FLAGS.md:24`.

## Objetivo
Mover el disparo del intersticial a un momento **de cierre natural** (p. ej. tras completar una tarea, al salir de un flujo, o al volver a foreground tras X tiempo), no a la navegación entre pestañas. Mantener los caps existentes (sesión, intervalo, gracia).

## Decisión de producto a confirmar
Usa `superpowers:brainstorming` para elegir el nuevo trigger (candidatos: post-completar-tarea con frecuencia baja, post-cierre de sheet de detalle, cold-start espaciado). Evita interrumpir acciones de alto valor. Respeta que un hogar Premium no ve intersticial.

## Criterios de aceptación
- [ ] El intersticial **ya no** se dispara por cambiar de pestaña.
- [ ] Se dispara en el momento elegido, respetando caps (3/sesión, intervalo, gracia) y el flag `ad_interstitial_enabled`.
- [ ] Hogar Premium: cero intersticiales (sin regresión).
- [ ] Sin impacto en la fluidez de la navegación.

## Pruebas obligatorias
### Unit / Widget
- Tests del controller: respeta cap por sesión, intervalo mínimo y gracia con el nuevo trigger.
- Test de que el cambio de pestaña ya **no** invoca el intersticial.
- Test de que Premium nunca lo dispara.

### Verificación en dispositivo (Firebase real)
> Requiere unit IDs de AdMob reales o de test configurados; ver `STORE_CATALOG.md`/RC. Si no hay inventario real, valida la **lógica de disparo** con logs/contadores y captura el momento esperado.
1. En MI_9 (hogar Free), navega entre pestañas repetidamente → **no** debe aparecer intersticial. Captura/registro.
2. Ejecuta el nuevo trigger (p. ej. completar varias tareas) → aparece respetando el cap. Captura.
3. En el emulador con hogar Premium → cero intersticiales en cualquier acción. Captura/registro.

## Dependencias
- Relacionado con **06** (copy de ads). No cambia el banner.

## Al terminar
Actualiza `INDICE.md` (✅ + fecha + nota: nuevo trigger elegido). Lista archivos y capturas.
