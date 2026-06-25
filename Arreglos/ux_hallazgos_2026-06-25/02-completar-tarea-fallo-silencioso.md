# 02 · 🔴 Crítico — Completar tarea: el fallo del commit diferido es silencioso

> Lee primero `_CONVENCIONES.md`. Marca 🔄 En progreso en `INDICE.md` y ✅ al cerrar.

## Contexto del hallazgo
Completar una tarea usa el patrón "Gmail": se oculta optimistamente, se muestra confetti + SnackBar "Tarea completada / Deshacer" (10 s) y al expirar se hace commit al callable `applyTaskCompletion`. **Nadie escucha el error del callable.** Si el commit falla (sin red, permiso denegado, carrera de turno), pasados los 10 s la tarea **reaparece en "Por hacer" sin ningún aviso**, después de que el usuario vio confetti y "Tarea completada". El usuario jura que la completó; es el fallo que más socava la confianza en el dato compartido.

## Evidencia
- `lib/features/tasks/application/pending_completions_provider.dart:76-90` — `_commit`: llama al callable y al terminar solo hace `_pending.remove`; el `AsyncValue.error` no se observa.
- `lib/features/tasks/application/task_completion_provider.dart:16-28` — el provider expone el error (línea ~25) pero **ningún widget lo escucha**.
- `lib/features/tasks/presentation/skins/today_screen_v2.dart:27-54` — `_onDone`: programa la completación diferida y muestra el SnackBar (`persist:false`, `kUndoWindow`=10 s).
- `lib/app.dart:435` — `flush()` al ir a background (no perder el commit).

## Objetivo
Que un fallo del commit **se comunique al usuario** y el estado quede consistente: cuando `applyTaskCompletion` falla tras la ventana, mostrar un SnackBar/aviso de error ("No se pudo completar '{tarea}'. Reintentar") con acción de reintento, y dejar la tarea visible en "Por hacer" **con señal de que NO se guardó** (no en silencio).

## Criterios de aceptación
- [ ] Si el commit falla, el usuario ve un aviso claro y localizado (es/en/ro) con opción **Reintentar**.
- [ ] La tarea reaparece en "Por hacer" de forma explícita (no parece que nada pasó).
- [ ] El caso de éxito no cambia (sin doble SnackBar, sin parpadeos).
- [ ] `flush()` en background sigue funcionando y, si falla, el aviso se muestra al volver a foreground.
- [ ] No se pierde idempotencia: reintentar no crea doble evento `completed` (verifica con backend/`apply_task_completion.ts`).

## Pruebas obligatorias
### Unit / Widget
- Test del provider: simula callable que lanza → el estado de error se propaga y se consume.
- Widget test de `TodayScreenV2`: mock del callable que falla → aparece SnackBar de error + tarea visible en "Por hacer"; el de éxito no lo muestra.
- Test del SnackBar de error: `persist:false` y **desaparece** (bug Flutter 3.44).

### Verificación en dispositivo (Firebase real)
1. MI_9, una tarea propia de hoy. Completa y **pon el móvil en avión** dentro de la ventana de 10 s (o fuerza fallo cortando red). Tras expirar la ventana → debe verse el aviso de error + tarea de vuelta en "Por hacer". Captura.
2. Reintentar con red restaurada → completa de verdad; verifica en el otro dispositivo (sync en vivo) que el evento aparece una sola vez.
3. Caso carrera: en el emulador, con la cuenta del compañero, completa/pasa la misma tarea antes de que MI_9 haga commit → MI_9 debe avisar del conflicto, no fallar en silencio. Captura.
4. Caso background: completa y manda la app a background antes de 10 s; al volver, si el `flush` falló, debe avisar. Captura.

## Al terminar
Actualiza `INDICE.md` (✅ + fecha + nota). Lista archivos y capturas.
