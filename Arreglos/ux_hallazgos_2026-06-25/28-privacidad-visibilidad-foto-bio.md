# 28 · 🟢 Bajo — Privacidad: control de visibilidad de foto y bio (paridad con teléfono)

> Lee primero `_CONVENCIONES.md`. Marca 🔄 En progreso en `INDICE.md` y ✅ al cerrar.

## Contexto del hallazgo
Solo el **teléfono** tiene control de visibilidad. Foto y bio son **siempre** visibles para los convivientes; para no exponerlas hay que dejarlas vacías. Es una asimetría de privacidad: el usuario que quiere compartir foto/bio en un hogar pero no en otro no tiene opción, y no se le advierte de que se muestran.

## Evidencia
- `lib/features/profile/presentation/skins/edit_profile_screen_v2.dart:144-172` — foto siempre visible.
- `lib/features/profile/presentation/skins/edit_profile_screen_v2.dart:189-200` — bio siempre visible.
- Referencia del control existente (teléfono): `:215-222` (`phone_visibility_switch`) + `member_factory.ts:64-69` (saneado en servidor).

## Objetivo
Como mínimo (esfuerzo bajo): **microcopy** en edición de perfil aclarando que foto y bio se muestran a los convivientes. Idealmente (esfuerzo medio): control de visibilidad para foto/bio con el mismo patrón saneado en servidor que el teléfono.

## Decisión de producto a confirmar
Usa `superpowers:brainstorming`: ¿basta con informar, o se quiere visibilidad configurable por campo? Si es configurable, definir si es global o por hogar (el teléfono actual es por campo, saneado al escribir el doc de miembro).

## Criterios de aceptación
- [ ] El usuario sabe (microcopy) que foto y bio se ven en el hogar.
- [ ] Si se implementa visibilidad: el control existe y se **sanea en servidor** (como el teléfono), no solo en cliente; default seguro.
- [ ] Localizado (es/en/ro). Tests de reglas/factory si se toca el doc de miembro.

## Pruebas obligatorias
### Unit / Widget (+ backend si aplica)
- Widget test: microcopy presente; (si aplica) el toggle persiste y el doc de miembro respeta la visibilidad.
- Si tocas `member_factory`/escritura: test de saneo server-side (oculto → no se escribe el campo), igual que el teléfono.

### Verificación en dispositivo (Firebase real, dos perfiles)
1. En MI_9 revisa el microcopy de foto/bio en edición de perfil. Captura.
2. (Si implementas visibilidad) oculta la foto y confirma en el emulador (otro miembro) que **no** se ve; muéstrala y confirma que aparece. Capturas.

## Dependencias
- Eje de privacidad junto a **09**.

## Al terminar
Actualiza `INDICE.md` (✅ + fecha + nota: solo microcopy o visibilidad completa). Lista archivos y capturas.
