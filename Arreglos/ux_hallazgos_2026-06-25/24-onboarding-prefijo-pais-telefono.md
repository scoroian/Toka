# 24 · 🟢 Bajo — Onboarding: selector de prefijo de país en el teléfono

> Lee primero `_CONVENCIONES.md`. Marca 🔄 En progreso en `INDICE.md` y ✅ al cerrar.

## Contexto del hallazgo
La spec pide un campo teléfono (opcional) **con selector de prefijo de país**. El código usa un `TextFormField` plano de tipo phone, sin prefijo. Además, pedir el teléfono en el onboarding es fricción de datos temprana: al ser opcional el daño es menor, pero conviene que el "opcional" sea visualmente claro (que el usuario no crea que es obligatorio).

## Evidencia
- `lib/features/onboarding/presentation/widgets/profile_step_v2.dart:136-145` — `TextFormField` de phone sin selector de prefijo.
- Spec: `.worktrees/feature-skin-v2/specs/spec-03-onboarding.md:48` (campo teléfono opcional con selector de prefijo de país).
- Mismo patrón debería aplicarse en edición de perfil (`edit_profile_screen_v2.dart`).

## Objetivo
Añadir un selector de prefijo de país junto al campo de teléfono (en onboarding y en edición de perfil, por consistencia), y dejar claro que es opcional. Evaluar formato/almacenamiento E.164 para coherencia.

## Criterios de aceptación
- [ ] El campo teléfono tiene selector de prefijo de país, con default razonable (locale del dispositivo).
- [ ] "Opcional" es visualmente evidente; se puede avanzar sin rellenarlo.
- [ ] El teléfono se almacena de forma consistente (decidir formato; documentar) y respeta la visibilidad existente.
- [ ] Mismo control en edición de perfil. Localizado (es/en/ro).

## Pruebas obligatorias
### Unit / Widget
- Test del campo: prefijo + número producen el valor esperado; vacío es válido (opcional).
- Widget test en onboarding y en edición de perfil.

### Verificación en dispositivo (Firebase real)
1. Onboarding en MI_9: selecciona prefijo y escribe número; avanza también dejándolo vacío. Capturas.
2. Edita el teléfono desde perfil con el nuevo selector. Captura.
3. Con teléfono **visible**, confirma en el otro dispositivo que se muestra correctamente con prefijo. Captura.

## Al terminar
Actualiza `INDICE.md` (✅ + fecha + nota: formato de almacenamiento elegido). Lista archivos y capturas.
