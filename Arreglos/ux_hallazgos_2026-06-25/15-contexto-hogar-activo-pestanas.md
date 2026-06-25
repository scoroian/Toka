# 15 · 🟡 Medio — Mostrar el hogar activo en todas las pestañas

> Lee primero `_CONVENCIONES.md`. Marca 🔄 En progreso en `INDICE.md` y ✅ al cerrar.

## Contexto del hallazgo
El nombre/avatar del hogar activo solo aparece en la AppBar de la pantalla Hoy. En Tareas, Miembros, Historial y Ajustes el título es genérico ("Tareas", "Miembros"…). Un usuario con varios hogares puede crear una tarea o invitar a alguien **sin ver en qué hogar está actuando** → riesgo de acción en el hogar equivocado.

## Evidencia
- `lib/features/homes/presentation/home_selector_widget.dart:93-99` — nombre+avatar del hogar activo (solo en Hoy).
- AppBars genéricas en las demás pestañas (Tareas/Miembros/Historial/Ajustes).
- Hogar activo: `lib/features/homes/application/current_home_provider.dart`.

## Objetivo
Mostrar de forma discreta pero constante en qué hogar se está actuando, en todas las pestañas (p. ej. subtítulo con el nombre del hogar en cada AppBar, o exponer el selector también ahí). Especialmente importante en acciones de escritura (crear tarea, invitar).

## Criterios de aceptación
- [ ] El nombre del hogar activo es visible en Tareas, Miembros, Historial y Ajustes (no solo en Hoy).
- [ ] Idealmente, el selector de hogar es accesible desde más de una pantalla (coordinar con **14**).
- [ ] Sin sobrecargar la AppBar ni romper layouts existentes. Localizado si añade texto nuevo.

## Pruebas obligatorias
### Widget / Golden
- Golden de las AppBars de cada pestaña mostrando el hogar activo.
- Test de que al cambiar de hogar, el indicador se actualiza en todas las pestañas.

### Verificación en dispositivo (Firebase real)
1. Con una cuenta con **≥2 hogares** (MI_9), recorre Tareas/Miembros/Historial/Ajustes: el hogar activo debe verse en todas. Capturas.
2. Cambia de hogar en el selector y verifica que el indicador cambia en cada pestaña. Capturas.
3. Crea una tarea estando en el hogar B y confirma (en el otro dispositivo, miembro del hogar B) que aterriza donde debe. Captura.

## Dependencias
- Coordinar con **14** (descubribilidad/selector).

## Al terminar
Actualiza `INDICE.md` (✅ + fecha + nota). Lista archivos y capturas.
