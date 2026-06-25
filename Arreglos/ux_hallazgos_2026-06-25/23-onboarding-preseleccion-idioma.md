# 23 · 🟢 Bajo — Onboarding: preseleccionar el idioma del dispositivo

> Lee primero `_CONVENCIONES.md`. Marca 🔄 En progreso en `INDICE.md` y ✅ al cerrar.

## Contexto del hallazgo
La spec pide que el idioma del dispositivo aparezca **preseleccionado** si está disponible. En el código `selectedLocale` arranca `null` (viene de SharedPreferences vacío), así que ningún idioma aparece marcado al entrar al paso: el usuario debe elegir manualmente aunque su dispositivo ya esté en es/en/ro. Existe `LocaleService._resolveDeviceLocale` pero no se usa para preseleccionar aquí. Relacionado: el paso "avanza automáticamente" al tocar un idioma, lo que combinado con el botón "Siguiente" confunde.

## Evidencia
- `lib/features/onboarding/application/onboarding_provider.dart:84-91` — `selectedLocale` parte de SharedPreferences (null al inicio).
- `lib/features/onboarding/presentation/widgets/language_step_v2.dart:48` — usa `selectedLocale ?? ''` (nada marcado).
- `lib/features/onboarding/presentation/widgets/language_step_v2.dart:31-34` — selección "auto-avanza".
- `LocaleService._resolveDeviceLocale` (existe, sin usar aquí).
- Spec: `.worktrees/feature-skin-v2/specs/spec-03-onboarding.md` (idioma del dispositivo preseleccionado).

## Objetivo
Preseleccionar el idioma del dispositivo si está entre los disponibles (es/en/ro). Revisar la interacción "auto-avanza vs botón Siguiente" para que no resulte confusa (decidir un único patrón).

## Criterios de aceptación
- [ ] Al entrar al paso de idioma, el idioma del dispositivo aparece marcado si está disponible; si no, un default razonable.
- [ ] La interacción de selección es coherente (o auto-avanza, o requiere "Siguiente", no ambos de forma ambigua).
- [ ] No rompe la persistencia ni el cambio de idioma en caliente.

## Pruebas obligatorias
### Unit / Widget
- Test: con locale de dispositivo es/en/ro disponible → preseleccionado; con uno no soportado → default.
- Widget test del paso: el radio correcto aparece marcado al entrar.

### Verificación en dispositivo (Firebase real)
1. Pon el dispositivo en español, inicia onboarding nuevo → español preseleccionado. Captura.
2. Cambia el sistema a inglés y repite con cuenta nueva → inglés preseleccionado. Captura.
3. Verifica que cambiar manualmente sigue funcionando y se persiste.

## Al terminar
Actualiza `INDICE.md` (✅ + fecha + nota). Lista archivos y capturas.
