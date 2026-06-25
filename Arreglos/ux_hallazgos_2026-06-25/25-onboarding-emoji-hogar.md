# 25 · 🟢 Bajo — Crear hogar: selector de emoji (decorativo)

> Lee primero `_CONVENCIONES.md`. Marca 🔄 En progreso en `INDICE.md` y ✅ al cerrar.

## Contexto del hallazgo
La spec pide un selector de emoji de casa (opcional, decorativo) al crear hogar. La callable `createHome` **ya acepta** `emoji`, pero la UI nunca lo ofrece: siempre llama `onCreateHome(name, null)`. Es una oportunidad barata de personalización/identidad del hogar (ayuda además a distinguir hogares en el selector multi-hogar — ver **15**).

## Evidencia
- `lib/features/onboarding/presentation/widgets/home_choice_step_v2.dart:162-163` — `onCreateHome(name, null)` (emoji nunca ofrecido).
- `lib/features/onboarding/data/home_creation_repository_impl.dart:13-19` — la callable acepta `emoji`.
- También aplica al crear hogar desde el selector: `lib/features/homes/presentation/home_selector_widget.dart` (`_buildCreate`).
- Spec: `.worktrees/feature-skin-v2/specs/spec-03-onboarding.md:61`.

## Objetivo
Ofrecer un selector de emoji (opcional) al crear hogar, tanto en onboarding como en el sheet de creación del selector. Mostrar el emoji elegido junto al nombre del hogar donde se renderice (selector, AppBar — coordinar con **15**).

## Criterios de aceptación
- [ ] Al crear hogar (onboarding y selector) se puede elegir un emoji opcional; sin elegir, se crea igual.
- [ ] El emoji se persiste vía `createHome` y se muestra junto al nombre del hogar donde aplique.
- [ ] No bloquea ni complica la creación. Localizado si añade texto.

## Pruebas obligatorias
### Widget / Golden
- Widget test de creación con y sin emoji.
- Golden del selector/AppBar mostrando el emoji del hogar.

### Verificación en dispositivo (Firebase real)
1. Crea un hogar con emoji desde onboarding (MI_9) → aparece junto al nombre. Captura.
2. Crea otro hogar con emoji distinto desde el selector y verifica que ayudan a distinguirlos en la lista multi-hogar. Captura.
3. Confirma que un hogar creado sin emoji se ve correctamente (sin hueco roto). Captura.

## Dependencias
- Sinergia con **15** (mostrar hogar activo) y **14** (gestión de hogares).

## Al terminar
Actualiza `INDICE.md` (✅ + fecha + nota). Lista archivos y capturas.
