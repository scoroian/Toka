# 14 · 🟡 Medio — Descubribilidad de la gestión de hogares

> Lee primero `_CONVENCIONES.md`. Marca 🔄 En progreso en `INDICE.md` y ✅ al cerrar.

## Contexto del hallazgo
Crear/cambiar/unir hogar vive **solo** en el título tappable de la AppBar de la pantalla Hoy, sin affordance cuando hay un único hogar (la flecha se oculta). Además, la pantalla "Mis hogares" (`/my-homes`) está registrada pero **ningún `push`/`go` la invoca** (código muerto de navegación), y **generar el código de invitación** está en la pestaña Miembros (FAB), no en "Ajustes del hogar" donde el usuario lo busca (la spec lo ubica en Ajustes).

## Evidencia
- `lib/features/tasks/presentation/skins/today_screen_v2.dart:82` — único montaje de `HomeSelectorWidget`.
- `lib/features/homes/presentation/home_selector_widget.dart:114` — flecha oculta con un solo hogar.
- `lib/app.dart:303` — ruta `/my-homes` registrada; sin invocaciones (grep vacío). `my_homes_screen_v2.dart` inalcanzable.
- `lib/features/members/presentation/skins/members_screen_v2.dart:81` — generar código (FAB Invitar).
- `lib/features/homes/presentation/skins/home_settings_screen_v2.dart:268-285` — solo lista invitaciones pendientes, sin botón de generar.
- Spec: `.worktrees/feature-skin-v2/specs/spec-04-homes.md:159,167`.

## Objetivo
Hacer descubrible la gestión de hogares:
1. Dar una entrada estable a "Mis hogares"/gestión de hogares desde **Ajustes** (y/o un acceso claro en la AppBar incluso con un solo hogar).
2. Reconectar o retirar deliberadamente `my_homes_screen_v2` (no dejar código muerto).
3. Añadir "Generar/compartir código de invitación" en **Ajustes del hogar** (además de, o en lugar de, el FAB de Miembros).

## Decisión de producto a confirmar
Usa `superpowers:brainstorming` para decidir la arquitectura de navegación (¿"Mis hogares" como pantalla en Ajustes? ¿affordance permanente en la AppBar?) y dónde vive canónicamente "generar código".

## Criterios de aceptación
- [ ] Un usuario con **un solo** hogar puede descubrir cómo crear/unirse a otro sin adivinar gestos.
- [ ] "Mis hogares" es alcanzable (o se elimina su código si se decide no usarla).
- [ ] "Generar código" es accesible desde Ajustes del hogar.
- [ ] Sin romper el flujo actual del selector. Localizado (es/en/ro).

## Pruebas obligatorias
### Widget
- Test de navegación: existe ruta alcanzable a gestión de hogares desde Ajustes.
- Test de que "generar código" está accesible desde Ajustes del hogar y produce un código.

### Verificación en dispositivo (Firebase real)
1. Con una cuenta de **un solo** hogar (MI_9), intenta crear un segundo hogar partiendo de cero: el camino debe ser descubrible. Captura el recorrido.
2. Abre Ajustes del hogar y genera un código desde ahí; únete con él desde el emulador (carácter a carácter). Captura sync.
3. Verifica que "Mis hogares" se abre (o ya no existe). Captura.

## Al terminar
Actualiza `INDICE.md` (✅ + fecha + nota). Lista archivos y capturas.
