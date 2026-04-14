# Toka Skin V2 — Decisiones de diseño

> Documento generado en la sesión de brainstorming del 2026-04-14.
> Estas decisiones son la entrada para el plan de implementación de `AppSkin.v2`.

---

## Resumen ejecutivo

La skin V2 sigue el estilo **Minimal & Editorial**: fondo blanco limpio (claro) o casi negro (oscuro), tipografía Plus Jakarta Sans con pesos muy altos en los títulos, acento coral `#F4845F` heredado de la paleta actual, y animaciones expresivas con spring physics. La barra de navegación es una "pill" flotante con blur.

---

## Decisiones aprobadas

### 1. Dirección estética

**Minimal & Editorial**

- Fondo claro: `#F9F9F7` (off-white cálido)
- Fondo oscuro: `#111118` (casi negro con tinte azul)
- Acento principal: `#F4845F` (coral, heredado de la skin material)
- Acento secundario / éxito: `#81C99C` (mint, heredado)
- Sin gradientes decorativos. Sin glassmorphism en tarjetas.
- Las tarjetas de tareas propias llevan un borde izquierdo coral de 3px. Las ajenas llevan borde izquierdo neutro.

### 2. Modo de tema

**Sigue el sistema por defecto, con selector manual.**

- La preferencia se guarda en `SharedPreferences` bajo la clave `theme_mode` (valores: `"light"`, `"dark"`, `"system"`).
- Se leerá mediante un provider Riverpod `themeModeProvider`.
- La pantalla de Ajustes mostrará un selector de 3 opciones: ☀️ Claro / 🌙 Oscuro / 📱 Sistema.
- Se implementan ambos themes: `AppThemeV2.light` y `AppThemeV2.dark`.

### 3. Tipografía

**Plus Jakarta Sans** (via `google_fonts`).

Escala de pesos:
| Uso | Peso | Tamaño |
|-----|------|--------|
| Título de pantalla ("Hoy") | 900 | 28px |
| Título de sección (DIARIAS) | 800 | 10px + letter-spacing 0.15em + uppercase |
| Nombre de tarea en tarjeta | 700 | 13px |
| Texto secundario (asignado a, subtítulo) | 600 | 10px |
| Contadores (número grande) | 900 | 24px |
| Etiqueta de contador | 700 | 9px + uppercase |
| Botones | 800 | 12px |

### 4. Animaciones — nivel Expresivo

Todas las animaciones usan `CurvedAnimation` con curva `Curves.easeOutBack` (simula spring) salvo indicación contraria.

#### Obligatorias (de la spec base)

| Elemento | Tipo | Duración | Notas |
|---|---|---|---|
| Entrada de lista de tareas | Staggered slide-up + fade | 350ms por tarjeta, delay 50ms entre ellas | `AnimationController` + `TweenAnimationBuilder` |
| Completar tarea | Checkmark animado + confetti | Checkmark 350ms, confetti 800ms | `CustomPainter` para el trazo; paquete `confetti` |
| Skeleton loaders | Shimmer horizontal | Loop continuo | `AnimationController` con `Curves.easeInOut` |
| Transición entre pestañas | Fade | 200ms | `AnimatedSwitcher` en el body del shell |
| FAB nueva tarea | Scale-in con elastic bounce | 300ms | `ScaleTransition` con `Curves.elasticOut` |

#### Opcionales elegidas

- **Confetti al completar** — ~20 partículas, colores `[coral, mint, white]`, duración 800ms. Paquete: `confetti: ^0.7.0`.
- **Hero animation** entre `AllTasksScreenV2` → `TaskDetailScreenV2` sobre el emoji/icono de tarea.

#### No incluidas

- Pull-to-refresh personalizado — se usará el estándar.
- Glassmorphism — no aplica a este estilo.

### 5. Tarjeta de tarea (TodayTaskCardTodo V2)

- **Fondo**: blanco (`#FFFFFF`) en claro / `#1A1A24` en oscuro.
- **Borde izquierdo**: 3px coral si es tarea propia; 3px neutro (`#E8E8E4` / `#2A2A38`) si es ajena.
- **Radio de esquinas**: 14px.
- **Sombra**: `0 1px 6px rgba(0,0,0,0.05)` en claro; `0 2px 12px rgba(0,0,0,0.3)` en oscuro.
- **Avatar**: cuadrado redondeado (8px), fondo coral si es propio / neutro si es ajeno.
- **Chip de fecha**: rectángulo 6px radius, fondo `#F4F4F2` / `#222230`, texto secundario.
- **Chip vencida**: fondo rojo suave, texto rojo.
- **Botón "Marcar hecho"**: fondo `#1A1A1A` (claro) / `#F0F0F5` (oscuro), texto invertido, 10px radius.
- **Botón "Pasar turno"**: borde 1.5px neutro, texto gris, transparente.

### 6. Barra de navegación

**Barra flotante con blur** (`MainShellV2`).

- Posición: `bottom: 12px`, márgenes laterales `16px`.
- Forma: `BorderRadius.circular(20)`.
- Fondo: `rgba(255,255,255,0.85)` con `BackdropFilter(ImageFilter.blur(10,10))` en claro.
- Fondo: `rgba(20,20,30,0.88)` con blur en oscuro.
- Borde: `1px solid rgba(255,255,255,0.6)` en claro / `rgba(255,255,255,0.06)` en oscuro.
- Tab activo: icono opaco + punto coral debajo.
- Tab inactivo: icono al 25-35% de opacidad. Sin etiquetas de texto.
- 4 tabs: Hoy / Tareas / Historial / Perfil.
- El `Scaffold` principal debe tener `extendBody: true` y `bottomNavigationBar: null`; la barra flota sobre el contenido mediante `Stack` o `Overlay`.

### 7. Cabecera de contadores (TodayHeaderCounters V2)

- Dos chips separados, cada uno con número grande (24px, peso 900) y etiqueta pequeña uppercase.
- El chip de "Pendientes" muestra el número en coral.
- El chip de "Hechas hoy" muestra el número en color primario oscuro / claro.
- Fondo de cada chip: blanco con borde neutro (claro) / `#1A1A24` con borde oscuro.
- Radio: 14px. Sin sombra extra.

### 8. Secciones de recurrencia (TodayTaskSection V2)

- Título de sección en `10px`, `fontWeight 800`, `letterSpacing 0.15em`, `uppercase`.
- Color: `#999` en claro / `#666` en oscuro.
- Línea horizontal (`Divider`) a la derecha del título, del mismo color.
- Sin icono ni decoración adicional.

### 9. Textos secundarios (subtítulos, asignados, metadatos)

- `fontSize 10`, `fontWeight 600`.
- Color: `#999` en claro / `#888` en oscuro.
- Suficientemente legibles contra el fondo de la tarjeta en ambos modos.

---

## Tokens de color V2

### Claro (`AppColorsV2Light`)

```dart
background       = #F9F9F7
surface          = #FFFFFF
surfaceVariant   = #F4F4F2   // fondo chip fecha
border           = #E8E8E4
borderStrong     = #D0D0CC
primary          = #F4845F   // coral — acento
onPrimary        = #FFFFFF
success          = #81C99C   // mint — tareas hechas
textPrimary      = #1A1A1A
textSecondary    = #999999
textTertiary     = #CCCCCC   // placeholder, disabled
error            = #EF4444
onError          = #FFFFFF
```

### Oscuro (`AppColorsV2Dark`)

```dart
background       = #111118
surface          = #1A1A24
surfaceVariant   = #222230
border           = #2A2A38
borderStrong     = #3A3A50
primary          = #F4845F
onPrimary        = #FFFFFF
success          = #4FAE7D
textPrimary      = #F0F0F5
textSecondary    = #888888
textTertiary     = #444455
error            = #F87171
onError          = #1A1A1A
```

---

## Dependencias nuevas necesarias

| Paquete | Versión | Uso |
|---|---|---|
| `confetti` | `^0.7.0` | Partículas al completar tarea |

`google_fonts` ya está en el proyecto — solo añadir `GoogleFonts.plusJakartaSansTextTheme()`.

---

## Pantallas incluidas en V2

Según la spec base `2026-04-14-attractive-skin-design.md`:

| Pantalla | Archivo V2 |
|---|---|
| Hoy | `lib/features/tasks/presentation/skins/today_screen_v2.dart` |
| Todas las tareas | `lib/features/tasks/presentation/skins/all_tasks_screen_v2.dart` |
| Detalle de tarea | `lib/features/tasks/presentation/skins/task_detail_screen_v2.dart` |
| Crear/editar tarea | `lib/features/tasks/presentation/skins/create_edit_task_screen_v2.dart` |
| Historial | `lib/features/history/presentation/skins/history_screen_v2.dart` |
| Perfil de miembro | `lib/features/members/presentation/skins/member_profile_screen_v2.dart` |
| Shell / nav bar | `lib/shared/widgets/skins/main_shell_v2.dart` |

Pantallas **no** incluidas en esta iteración: auth, onboarding, settings, subscription, my_homes.

---

## Selector de tema en Settings

Añadir en `SettingsScreen` (skin material existente, solo añadir la opción):
- Sección "Apariencia" con un `SegmentedButton` o equivalente de 3 valores: Claro / Oscuro / Sistema.
- Al cambiar, escribe en `SharedPreferences` y actualiza `themeModeProvider`.
- No requiere restart de la app — el `MaterialApp` es reactivo al provider.

---

## Criterios de aceptación (adicionales a los de la spec base)

- [ ] Plus Jakarta Sans cargada y aplicada en todos los widgets de skin V2.
- [ ] Ambos themes (`light` y `dark`) pasan `flutter analyze` sin warnings de contraste.
- [ ] El selector de tema en Settings funciona sin reiniciar la app.
- [ ] El confetti solo aparece en la skin V2, no en la material.
- [ ] Los textos secundarios tienen contraste mínimo WCAG AA (4.5:1) en ambos modos.
- [ ] La barra flotante no cubre contenido scrollable (padding bottom en el scroll principal).
