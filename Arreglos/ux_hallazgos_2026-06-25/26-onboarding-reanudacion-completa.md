# 26 · 🟢 Bajo — Onboarding: reanudación completa del progreso

> Lee primero `_CONVENCIONES.md`. Marca 🔄 En progreso en `INDICE.md` y ✅ al cerrar.

## Contexto del hallazgo
`loadSavedProgress` solo persiste y rehidrata `currentStep`, `selectedLocale` y `nickname`. **Teléfono, visibilidad del teléfono y foto no se persisten**: si el usuario rellena el perfil, cierra la app y vuelve, el step se restaura pero esos campos se pierden. Cumple el mínimo de la spec ("no empezar desde 0") pero de forma parcial y algo frustrante.

## Evidencia
- `lib/features/onboarding/application/onboarding_provider.dart:84-91` — `loadSavedProgress` (solo step/locale/nickname).
- `_persistStep/_persistLocale/_persistNickname` — no hay equivalentes para teléfono/visibilidad/foto.
- Spec: `.worktrees/feature-skin-v2/specs/spec-03-onboarding.md` (reanudar onboarding).

## Objetivo
Persistir y rehidratar también teléfono, visibilidad del teléfono y referencia de la foto (o su estado de subida), para que reanudar el onboarding no pierda lo introducido. Coordinar con **18** (subida de foto diferida) para decidir cómo se restaura la foto pendiente.

## Criterios de aceptación
- [ ] Al reanudar el onboarding, el perfil ya rellenado se restaura completo (apodo, teléfono, visibilidad, foto).
- [ ] Si la foto estaba pendiente de subir (ver **18**), su estado se recupera de forma coherente.
- [ ] Sin filtrar datos sensibles de forma insegura en SharedPreferences (evaluar qué se guarda y cómo).

## Pruebas obligatorias
### Unit / Widget
- Test del provider: persistir y rehidratar todos los campos del perfil.
- Widget test: rellenar perfil → matar/relanzar → campos restaurados.

### Verificación en dispositivo (Firebase real)
1. En MI_9, rellena el perfil del onboarding (apodo + teléfono + visibilidad + foto), **fuerza cierre** de la app y relánzala → todo restaurado en el paso correcto. Captura antes/después.
2. Caso con foto pendiente (red lenta) coordinado con **18**: el estado se recupera sin duplicar ni perder la foto. Captura.

## Dependencias
- Coordinar con **18** (foto no bloqueante).

## Al terminar
Actualiza `INDICE.md` (✅ + fecha + nota). Lista archivos y capturas.
