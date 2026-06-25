# 20 · 🟢 Bajo — Onboarding: barra de progreso real + Back en sub-pasos crear/unirse

> Lee primero `_CONVENCIONES.md`. Marca 🔄 En progreso en `INDICE.md` y ✅ al cerrar.

## Contexto del hallazgo
Dos fricciones menores del onboarding:
1. **Barra de progreso engañosa:** calcula `(step+1)/4`, así que el paso "Crear/Unirse" marca 100% aunque todavía aparezca la pantalla de permisos de notificaciones. El usuario cree haber terminado.
2. **Back físico rompe los sub-pasos:** la elección crear/unirse es estado local, no navegación; el botón Back del sistema sale del onboarding entero en vez de retroceder un sub-paso.

## Evidencia
- `lib/features/onboarding/presentation/widgets/onboarding_progress_bar.dart:17` — `(currentStep+1)/totalSteps` con `totalSteps=4`; la rationale de notificaciones no cuenta.
- `lib/features/onboarding/presentation/widgets/home_choice_step_v2.dart:33-98` — elección crear/unirse como estado local `_HomeChoice`.
- `lib/features/onboarding/presentation/skins/notification_rationale_screen_v2.dart:79-110` — paso extra fuera de la barra.

## Objetivo
1. Que la barra de progreso refleje el número real de pasos (incluyendo, si procede, la rationale de notificaciones) o que no llegue a 100% antes del final.
2. Que el Back del sistema en los sub-pasos crear/unirse retroceda al selector de elección, no salga del onboarding (interceptar con `PopScope`/`WillPopScope` o convertir en navegación real).

## Criterios de aceptación
- [ ] La barra no marca 100% si aún quedan pantallas del onboarding.
- [ ] El Back físico en "crear hogar"/"unirse" vuelve a la elección, no abandona el onboarding.
- [ ] Sin regresiones en el avance normal con los botones internos.

## Pruebas obligatorias
### Widget
- Test de la barra: el porcentaje en cada paso es el esperado (no 100% prematuro).
- Test de `PopScope`: en sub-paso crear/unirse, Back vuelve a la elección.

### Verificación en dispositivo (Firebase real)
1. Recorre el onboarding completo en MI_9 observando la barra: no debe llegar a 100% antes de la última pantalla. Capturas por paso.
2. En "crear hogar" pulsa el **Back físico** del sistema → vuelve a la elección crear/unirse, no sale. Repite en "unirse". Capturas.

## Al terminar
Actualiza `INDICE.md` (✅ + fecha + nota). Lista archivos y capturas.
