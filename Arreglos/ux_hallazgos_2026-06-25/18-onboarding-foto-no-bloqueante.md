# 18 · 🟡 Medio — Onboarding: subida de foto no bloqueante + errores localizados

> Lee primero `_CONVENCIONES.md`. Marca 🔄 En progreso en `INDICE.md` y ✅ al cerrar.

## Contexto del hallazgo
En el paso de perfil del onboarding, si el usuario elige foto, "Siguiente" sube el archivo a Storage **bloqueando el avance** con un spinner. En redes lentas esto cuelga el onboarding y, si falla, se muestra `e.toString()` crudo (texto técnico no localizado). La subida debería ser diferida/en background y los errores legibles.

## Evidencia
- `lib/features/onboarding/application/onboarding_provider.dart:169-176` — `saveProfileAndContinue` sube la foto síncrona.
- `lib/features/onboarding/data/onboarding_repository_impl.dart:29-33` — subida a Storage.
- `lib/features/onboarding/application/onboarding_provider.dart:185,213` — `state.error = e.toString()` (crudo).

## Objetivo
Permitir avanzar sin esperar a la subida de la foto (subir en background y reconciliar `photoUrl` después), y mapear cualquier error a copys localizados. Mantener consistencia: si la subida falla en background, avisar de forma no bloqueante y permitir reintentar desde el perfil.

## Criterios de aceptación
- [ ] El avance del onboarding no se bloquea por la subida de la foto.
- [ ] Los errores de guardado/subida se muestran localizados (es/en/ro), nunca `e.toString()` crudo.
- [ ] Si la subida en background falla, el usuario puede reintentar desde edición de perfil sin perder el resto del onboarding.
- [ ] El resto del perfil (apodo, teléfono, visibilidad) se guarda correctamente.

## Pruebas obligatorias
### Unit / Widget
- Test del provider: avance no espera la subida; error de subida → mensaje localizado, no crudo.
- Widget test del paso de perfil: con red lenta simulada, "Siguiente" avanza; la foto se reconcilia luego.

### Verificación en dispositivo (Firebase real)
1. Onboarding en MI_9 con una foto y red **lenta/limitada**: "Siguiente" no debe colgarse; el onboarding avanza. Captura.
2. Fuerza fallo de subida (avión un instante) → mensaje legible, no técnico; reintento desde perfil funciona. Captura.
3. Verifica que la foto acaba apareciendo en el perfil y para los demás miembros (otro dispositivo). Captura.

## Al terminar
Actualiza `INDICE.md` (✅ + fecha + nota). Lista archivos y capturas.
