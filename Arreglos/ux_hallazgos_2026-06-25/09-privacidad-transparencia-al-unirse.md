# 09 · 🟠 Alto — Transparencia "esto compartes con el hogar" al unirse

> Lee primero `_CONVENCIONES.md`. Marca 🔄 En progreso en `INDICE.md` y ✅ al cerrar.

## Contexto del hallazgo
Cuando un usuario se une a un hogar (por código o en onboarding), el backend copia su `nickname`, `photoUrl`, `phone` (si visible) y empieza a exponer sus estadísticas (`complianceRate`, `passedCount`, `currentStreak`) a **todos los miembros**, y `syncMemberProfile` propaga en vivo cualquier cambio futuro. **En ningún punto del flujo de unión se informa de esto.** El usuario teclea un código y aparece dentro con su PII y métricas expuestas, sin consentimiento ni vista previa.

## Evidencia
- `functions/src/homes/index.ts:331-350` — al unirse se construye el doc de miembro con perfil; `:1126-1175` `syncMemberProfile` propaga cambios.
- `firestore.rules:189` — `members/{uid}` legible por `isCurrentMember` (incluye stats y teléfono si visible).
- Flujos de unión sin aviso: `lib/features/onboarding/presentation/widgets/home_join_form.dart`, `lib/features/homes/presentation/home_selector_widget.dart` (`_AddHomeSheet`).
- Teléfono: su visibilidad ya está bien saneada en servidor (`functions/src/homes/member_factory.ts:64-69`); aquí el problema es **informar**, no una fuga.

## Objetivo
Añadir, **antes de confirmar la unión**, un aviso claro y conciso de qué verán los demás miembros (nombre, foto, y teléfono solo si lo tienes visible; estadísticas de tareas), con enlace a ajustar la visibilidad del teléfono. No bloquear, pero sí informar. Opcional: mismo aviso resumido al crear hogar.

## Criterios de aceptación
- [ ] El flujo de unión (onboarding y selector) muestra un aviso de transparencia antes de entrar: "Al unirte, los miembros verán: tu nombre, foto{y teléfono si visible}, y tus estadísticas de tareas."
- [ ] Hay acceso directo a la opción de visibilidad del teléfono desde ese aviso (o se menciona dónde cambiarla).
- [ ] No añade fricción excesiva: un solo paso ligero, no un muro de texto.
- [ ] Localizado (es/en/ro).

## Pruebas obligatorias
### Widget
- Test de que el aviso aparece antes de la confirmación en ambas entradas (onboarding y selector).
- Test de que el texto refleja el estado real de visibilidad del teléfono del usuario (si oculto, no promete mostrarlo).

### Verificación en dispositivo (Firebase real, dos perfiles)
1. Únete a un hogar desde MI_9 con teléfono **oculto** y desde el emulador con teléfono **visible**: el aviso debe diferir correctamente. Capturas.
2. Tras unirse, confirma en el otro dispositivo qué se ve realmente del recién llegado (coherencia con lo prometido). Captura.
3. Verifica el acceso a cambiar la visibilidad del teléfono desde el aviso.

## Dependencias
- Coherente con el eje de privacidad (**08**). No cambies reglas aquí; es UI/copy.

## Al terminar
Actualiza `INDICE.md` (✅ + fecha + nota). Lista archivos y capturas.
