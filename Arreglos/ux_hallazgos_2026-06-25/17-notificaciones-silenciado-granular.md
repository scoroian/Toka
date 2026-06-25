# 17 · 🟡 Medio — Silenciado granular de notificaciones por tipo

> Lee primero `_CONVENCIONES.md`. Marca 🔄 En progreso en `INDICE.md` y ✅ al cerrar.

## Contexto del hallazgo
El único push de "acto de otro sobre mí" en producción es "Turno recibido", **sin toggle**: solo se silencia apagando todas las notificaciones del SO. El modelo declara `silencedTypes` (y un resumen diario) pero **ningún emisor del backend lo respeta** y no hay UI para configurarlo. Además hay un canal latente "Valoración recibida" implementado que, si se activa sin toggle, sería el caso más claro de "me están juzgando" en la barra de notificaciones.

## Evidencia
- `lib/features/notifications/domain/notification_preferences.dart:16` — `silencedTypes` declarado.
- `lib/features/notifications/.../notification_settings_screen_v2.dart` — solo 3 toggles, sin `silencedTypes`.
- Backend emisores: `functions/src/notifications/send_pass_notification.ts:35-47` (no consulta preferencias).
- Canal latente: `lib/.../notification_service.dart:297-330` ("Valoración recibida").

## Objetivo
Permitir silenciar por tipo (al menos "Turno recibido" y, si se activa, "Valoración recibida"): UI en ajustes de notificaciones que escriba `silencedTypes`, y emisores backend que **respeten** esas preferencias antes de enviar. Si se decide no implementar `silencedTypes` completo, **retirarlo** del modelo/ARB para no prometer un control inexistente.

## Decisión de producto a confirmar
Usa `superpowers:brainstorming`: ¿qué tipos son silenciables?, ¿el "resumen diario" entra en alcance o se retira? Define la lista canónica de tipos.

## Criterios de aceptación
- [ ] Existe UI para silenciar al menos "Turno recibido" por tipo.
- [ ] Los emisores backend consultan las preferencias y **no envían** los tipos silenciados.
- [ ] Si "Valoración recibida" se mantiene latente, queda con su toggle listo (no se activa sin control).
- [ ] Alternativa: si no se implementa, `silencedTypes`/resumen diario se retiran de modelo y ARB.
- [ ] Localizado (es/en/ro).

## Pruebas obligatorias
### Unit (backend) / Widget
- Test del emisor: con el tipo silenciado en preferencias → no se encola/envía.
- Widget test: el toggle persiste en `silencedTypes`.

### Verificación en dispositivo (Firebase real, dos perfiles)
1. En MI_9 silencia "Turno recibido". Desde el emulador (otra cuenta) pásale un turno → MI_9 **no** debe recibir push (verifica con la app en background). Captura/registro.
2. Reactiva el toggle y repite → ahora sí llega. Captura.
3. Si activas "Valoración recibida", repite el patrón con su toggle.

## Dependencias
- Eje de privacidad/tono (relacionado con **08**, **11**). Si tocas backend, sigue `DEPLOY.md`.

## Al terminar
Actualiza `INDICE.md` (✅ + fecha + nota: tipos soportados o decisión de retirar). Lista archivos y capturas.
