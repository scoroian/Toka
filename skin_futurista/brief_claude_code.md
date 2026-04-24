# Tocka · Brief de implementación para Claude Code

> Pega este archivo completo en Claude Code de VS Code como prompt.
> Objetivo: añadir una nueva **skin visual "Futurista"** coexistiendo con la actual,
> con **switch en Ajustes › Aspecto** que aplica el cambio en caliente sin reiniciar.

---

## CONTEXTO DEL PROYECTO

- **Stack**: Flutter + Riverpod + MVVM (feature-first)
- **Paleta de skins ya soportada**: `lib/core/theme/app_skin.dart` con enum `AppSkin { v2 }`
- **Tema actual**: Plus Jakarta Sans + coral `#F4845F` + off-white. Light por defecto.
- **Tokens**: `lib/core/theme/app_colors_v2.dart`, `app_theme_v2.dart`
- **Switch de tema**: `lib/core/theme/theme_mode_provider.dart` (ya persiste con shared_preferences)
- **Pantallas a crear variante**: Hoy, Todas las tareas, Ficha tarea, Crear/editar tarea, Historial, Miembros, Perfil, Selector multi-hogar, Onboarding, Paywall, Rescue/downgrade, Ajustes hogar

---

## OBJETIVO

1. **No romper nada** de la skin actual (v2 coral). Se queda como está.
2. **Añadir AppSkin.futurista** (dark-first cyan/violeta/gold) como nueva opción.
3. **Crear `SkinProvider` reactivo** con persistencia (shared_preferences) que todas las pantallas escuchen.
4. **Crear sección "Aspecto"** en `settings_screen.dart` con selector visual de skin + preview.
5. **Crear variantes futuristas** de las 12 pantallas listadas bajo `presentation/skins/futurista/`.
6. **Hot-swap sin reiniciar**: al cambiar el skin, `MaterialApp` reconstruye theme + cada pantalla renderiza el widget correcto.

---

## PASO 1 · AMPLIAR `AppSkin`

**Archivo**: `lib/core/theme/app_skin.dart`

```dart
enum AppSkin {
  v2,          // actual — coral cálido, light default
  futurista,   // nuevo — cyan espacial, dark default
}

extension AppSkinX on AppSkin {
  String get label => switch (this) {
    AppSkin.v2 => 'Clásico',
    AppSkin.futurista => 'Futurista',
  };
  String get description => switch (this) {
    AppSkin.v2 => 'Cálido, luminoso, familiar',
    AppSkin.futurista => 'Oscuro, espacial, minimalista',
  };
}
```

**Eliminar** `SkinConfig` estático — ahora el skin es reactivo (paso 2).

---

## PASO 2 · PROVIDER DE SKIN (reactivo + persistente)

**Nuevo archivo**: `lib/core/theme/skin_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_skin.dart';

part 'skin_provider.g.dart';

@Riverpod(keepAlive: true)
class SkinMode extends _$SkinMode {
  static const _key = 'tocka.skin';

  @override
  AppSkin build() {
    _load();
    return AppSkin.v2;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_key);
    if (v == AppSkin.futurista.name) state = AppSkin.futurista;
    else state = AppSkin.v2;
  }

  Future<void> set(AppSkin skin) async {
    state = skin;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, skin.name);
  }
}
```

Corre `dart run build_runner build`.

---

## PASO 3 · TOKENS FUTURISTAS

**Nuevo archivo**: `lib/core/theme/futurista/futurista_colors.dart`

```dart
import 'package:flutter/material.dart';

abstract class FuturistaColors {
  // Brand
  static const primary    = Color(0xFF38BDF8);   // cyan eléctrico
  static const primaryAlt = Color(0xFFA78BFA);   // violeta
  static const premium    = Color(0xFFF5B544);   // gold
  static const onPrimary  = Color(0xFF001018);

  // Dark surfaces
  static const bg0             = Color(0xFF07090E);
  static const bg1             = Color(0xFF0B0F16);
  static const bg2             = Color(0xFF121826);
  static const bg3             = Color(0xFF1A2235);
  static const line            = Color(0x14E2E8F0);   //  8% E2E8F0
  static const lineStrong      = Color(0x29E2E8F0);   // 16%
  static const textPrimary     = Color(0xFFE8EEF7);
  static const textSecondary   = Color(0xA3E8EEF7);   // 64%
  static const textTertiary    = Color(0x6BE8EEF7);   // 42%
  static const textFaint       = Color(0x38E8EEF7);   // 22%
  static const success         = Color(0xFF34D399);
  static const warning         = Color(0xFFF5B544);
  static const error           = Color(0xFFFB7185);

  // Light alternativo (más frío que el v2)
  static const bgLight         = Color(0xFFF6F7FB);
  static const surfaceLight    = Color(0xFFFFFFFF);
  static const textPrimLight   = Color(0xFF0B1220);
}
```

**Nuevo archivo**: `lib/core/theme/futurista/futurista_tokens.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'futurista_colors.dart';

/// Radios — la clave del look.
class FRadii {
  static const double sm = 8, md = 12, lg = 14, xl = 18, xxl = 22, hero = 26;
  static const double pill = 999;
}

/// Glows y sombras con color.
class FShadows {
  static const glowCyan = [
    BoxShadow(color: Color(0x5938BDF8), blurRadius: 40, offset: Offset(0, 20)),
  ];
  static const glowGold = [
    BoxShadow(color: Color(0x80F5B544), blurRadius: 30, offset: Offset(0, 10)),
  ];
  static const card = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 24, offset: Offset(0, 12)),
  ];
}

/// Tipografía — Inter + JetBrains Mono.
class FText {
  static TextStyle display(double size, {Color? color, FontWeight? weight}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w800,
        letterSpacing: size > 22 ? -1.2 : -0.6,
        color: color ?? FuturistaColors.textPrimary,
      );

  static TextStyle body(double size, {Color? color, FontWeight? weight}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w500,
        color: color ?? FuturistaColors.textPrimary,
      );

  static TextStyle mono(double size, {Color? color}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        color: color ?? FuturistaColors.textTertiary,
      );
}

/// Mesh background para pantallas hero.
class FMesh {
  static const Widget background = _MeshBg();
}

class _MeshBg extends StatelessWidget {
  const _MeshBg();
  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: RadialGradient(
        center: Alignment(-0.8, -1),
        radius: 1.2,
        colors: [Color(0x2E38BDF8), Color(0x0038BDF8)],
      ),
    ),
  );
}
```

**Nuevo archivo**: `lib/core/theme/futurista/futurista_theme.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'futurista_colors.dart';

abstract class FuturistaTheme {
  static ThemeData get dark {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);
    return base.copyWith(
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: FuturistaColors.primary,
        onPrimary: FuturistaColors.onPrimary,
        secondary: FuturistaColors.primaryAlt,
        onSecondary: FuturistaColors.onPrimary,
        error: FuturistaColors.error,
        onError: FuturistaColors.textPrimary,
        surface: FuturistaColors.bg1,
        onSurface: FuturistaColors.textPrimary,
      ),
      scaffoldBackgroundColor: FuturistaColors.bg0,
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: FuturistaColors.textPrimary,
        displayColor: FuturistaColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: FuturistaColors.textPrimary,
        elevation: 0, centerTitle: false,
      ),
      dividerTheme: const DividerThemeData(
        color: FuturistaColors.line, thickness: 1, space: 1,
      ),
      cardTheme: CardTheme(
        color: FuturistaColors.bg2,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FuturistaColors.primary,
          foregroundColor: FuturistaColors.onPrimary,
          shadowColor: const Color(0x5938BDF8),
          elevation: 8,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FuturistaColors.bg2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: FuturistaColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: FuturistaColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: FuturistaColors.primary, width: 1.5),
        ),
      ),
    );
  }

  static ThemeData get light {
    // (Versión light espejo — opcional, se puede posponer)
    return dark; // placeholder hasta implementar
  }
}
```

---

## PASO 4 · CABLEAR EN `MaterialApp`

**Archivo**: `lib/app.dart`

```dart
class TokaApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skin = ref.watch(skinModeProvider);
    final themeMode = ref.watch(themeModeProvider);

    final (lightTheme, darkTheme) = switch (skin) {
      AppSkin.v2 => (AppThemeV2.light, AppThemeV2.dark),
      AppSkin.futurista => (FuturistaTheme.light, FuturistaTheme.dark),
    };

    return MaterialApp.router(
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      // ...
    );
  }
}
```

---

## PASO 5 · WIDGET SELECTOR DE SKIN EN PANTALLAS

Cada pantalla usa un helper que elige el widget según skin:

**Nuevo archivo**: `lib/core/theme/skin_switcher.dart`

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'skin_provider.dart';
import 'app_skin.dart';

class SkinSwitch extends ConsumerWidget {
  const SkinSwitch({super.key, required this.v2, required this.futurista});
  final Widget Function(BuildContext) v2;
  final Widget Function(BuildContext) futurista;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skin = ref.watch(skinModeProvider);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      child: KeyedSubtree(
        key: ValueKey(skin),
        child: switch (skin) {
          AppSkin.v2 => v2(context),
          AppSkin.futurista => futurista(context),
        },
      ),
    );
  }
}
```

Uso en cualquier pantalla, ejemplo `today_screen.dart`:

```dart
class TodayScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SkinSwitch(
    v2: (c) => const TodayScreenV2(),
    futurista: (c) => const TodayScreenFuturista(),
  );
}
```

El `AnimatedSwitcher` da una transición de 220ms al cambiar skin — refuerza la sensación de "sin reiniciar".

---

## PASO 6 · ESTRUCTURA DE ARCHIVOS PARA SKINS

Por cada feature, carpeta `skins/futurista/` hermana de la existente:

```
lib/features/today/presentation/
├── today_screen.dart                    # wrapper con SkinSwitch
├── skins/
│   ├── v2/today_screen_v2.dart          # tu actual
│   └── futurista/
│       ├── today_screen_futurista.dart
│       ├── hero_turn_card.dart
│       ├── task_card_futurista.dart
│       └── today_stats_strip.dart
```

Repite para: `tasks`, `history`, `members`, `profile`, `homes`, `onboarding`, `subscription`, `settings`.

---

## PASO 7 · SECCIÓN "ASPECTO" EN AJUSTES

**Archivo**: `lib/features/settings/presentation/settings_screen.dart`

Añade sección nueva debajo de las existentes (idioma, notificaciones, etc.):

```dart
// Dentro de settings_screen.dart
_SettingsSection(
  title: l10n.settingsAppearanceTitle, // "Aspecto"
  children: [
    _AppearancePicker(), // widget nuevo — ver abajo
    _ThemeModeRow(),     // si ya existe, mantener
  ],
),
```

**Nuevo widget**: `lib/features/settings/presentation/widgets/appearance_picker.dart`

```dart
class AppearancePicker extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(skinModeProvider);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          for (final skin in AppSkin.values) ...[
            Expanded(child: _SkinCard(
              skin: skin,
              selected: current == skin,
              onTap: () => ref.read(skinModeProvider.notifier).set(skin),
            )),
            if (skin != AppSkin.values.last) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}

class _SkinCard extends StatelessWidget {
  const _SkinCard({required this.skin, required this.selected, required this.onTap});
  final AppSkin skin;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? FuturistaColors.primary : Theme.of(context).dividerColor,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? FShadows.glowCyan : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mini preview: 2 swatches + glifo
            _MiniPreview(skin: skin),
            const SizedBox(height: 12),
            Text(skin.label, style: Theme.of(context).textTheme.titleMedium),
            Text(skin.description, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            if (selected) const Icon(Icons.check_circle, size: 18, color: FuturistaColors.primary),
          ],
        ),
      ),
    );
  }
}

class _MiniPreview extends StatelessWidget {
  const _MiniPreview({required this.skin});
  final AppSkin skin;
  @override
  Widget build(BuildContext context) {
    final (bg, accent, surface) = switch (skin) {
      AppSkin.v2 => (const Color(0xFFF9F9F7), const Color(0xFFF4845F), const Color(0xFFFFFFFF)),
      AppSkin.futurista => (const Color(0xFF07090E), const Color(0xFF38BDF8), const Color(0xFF121826)),
    };
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Container(width: 20, height: 20, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(height: 6, width: 40, color: surface),
              const SizedBox(height: 4),
              Container(height: 4, width: 60, color: surface.withOpacity(0.5)),
            ],
          )),
        ],
      ),
    );
  }
}
```

**Copy (i18n)** — añade a `lib/l10n/app_es.arb`:

```json
{
  "settingsAppearanceTitle": "Aspecto",
  "settingsAppearanceSubtitle": "Elige cómo se ve Tocka",
  "skinClassicLabel": "Clásico",
  "skinClassicDescription": "Cálido, luminoso, familiar",
  "skinFuturistaLabel": "Futurista",
  "skinFuturistaDescription": "Oscuro, espacial, minimalista"
}
```

---

## PASO 8 · PANTALLAS A CREAR EN VARIANTE FUTURISTA

Orden de implementación (mayor a menor impacto):

| # | Pantalla | Archivo nuevo | Referencia en canvas Tocka.html |
|---|---|---|---|
| 1 | Hoy | `features/today/presentation/skins/futurista/today_screen_futurista.dart` | `screens-hoy.jsx` → `HoyScreenA` (lista por recurrencia) |
| 2 | Todas las tareas | `features/tasks/.../tasks_list_screen_futurista.dart` | `screens-tareas.jsx` → `TareasScreen` |
| 3 | Ficha de tarea | `.../task_detail_screen_futurista.dart` | `FichaTareaScreen` |
| 4 | Crear/editar tarea | `.../task_form_screen_futurista.dart` | `CrearTareaScreen` |
| 5 | Historial | `features/history/.../history_screen_futurista.dart` | `HistorialScreen` |
| 6 | Miembros | `features/members/.../members_screen_futurista.dart` | `MiembrosScreen` |
| 7 | Perfil propio + radar | `features/profile/.../own_profile_screen_futurista.dart` | `PerfilScreen` + `Radar` component |
| 8 | Selector multi-hogar | `features/homes/.../my_homes_screen_futurista.dart` | `SelectorHogarScreen` |
| 9 | Onboarding | `features/onboarding/.../onboarding_flow_futurista.dart` | `OnboardingScreen` |
| 10 | Paywall | `features/subscription/.../paywall_screen_futurista.dart` | `PaywallScreen` |
| 11 | Rescue / downgrade | `.../rescue_screen_futurista.dart` | `RescueScreen` |
| 12 | Ajustes del hogar | `features/homes/.../home_settings_screen_futurista.dart` | `AjustesHogarScreen` |

Para cada una:
- Importa `futurista_colors.dart`, `futurista_tokens.dart`
- Consume los **mismos providers/viewmodels** que la versión v2 (no se duplica lógica)
- Sigue el design del canvas — hero cards, glifos geométricos, ring cónico en avatar activo, banner AdMob solo si Free, mono para metadata

---

## PASO 9 · WIDGETS COMPARTIDOS FUTURISTAS

**Nuevo**: `lib/shared/widgets/futurista/`

- `task_glyph.dart` — 10 glifos SVG (ring, tri, hex, square, diamond, plus, star4, arcs, dot, cross) con `CustomPainter`
- `tocka_pill.dart` — pill con icono, color opcional, glow opcional
- `progress_ring.dart` — anillo de progreso con valor central
- `tocka_avatar.dart` — avatar con gradient + ring cónico opcional
- `hero_turn_card.dart` — card hero "tu turno ahora" con glow cyan
- `ad_banner_futurista.dart` — banner AdMob 56px, radio 14, etiqueta "Anuncio" en mono
- `radar_chart.dart` — radar SVG 8 ejes con fillOpacity 0.18

---

## PASO 10 · CRITERIOS DE ACEPTACIÓN

- [ ] El toggle en Ajustes › Aspecto cambia el skin **en <300ms sin reiniciar**
- [ ] La preferencia persiste entre sesiones
- [ ] Las 12 pantallas tienen variante funcional v2 + futurista
- [ ] La skin futurista funciona con `ThemeMode.dark` (light puede posponerse marcándolo como TODO)
- [ ] No hay colores hardcodeados nuevos — todo viene de `FuturistaColors` / theme
- [ ] Ningún ViewModel/Provider se duplica — ambas skins consumen los mismos
- [ ] El banner AdMob solo aparece en plan Free en la skin futurista
- [ ] Todos los strings nuevos pasan por `l10n` (`.arb` en es/en)
- [ ] Tests existentes siguen verdes; añade test de widget para `AppearancePicker` y `SkinSwitch`

---

## REFERENCIA VISUAL

El canvas `Tocka.html` de este proyecto contiene las 14 pantallas finalizadas con el look futurista exacto, incluyendo estados Free/Premium y Dark/Light. Abre cada artboard en fullscreen (click sobre él) para tener la referencia pixel-a-pixel mientras construyes.

Tokens clave extraídos del canvas:
- Primary cyan: `#38BDF8`
- Accent violet: `#A78BFA`
- Premium gold: `#F5B544`
- Success green: `#34D399`
- Error rose: `#FB7185`
- Backgrounds dark: `#07090E` / `#0B0F16` / `#121826` / `#1A2235`
- Text: `#E8EEF7` + opacidades 64/42/22
- Fonts: Inter (w500/600/700/800) + JetBrains Mono (w400/500/700)
- Radii: 8 / 12 / 14 / 18 / 22 / 26
- Glow cyan: `rgba(56,189,248,0.35)` blur 40 offset 0,20

---

## ORDEN DE EJECUCIÓN RECOMENDADO PARA CLAUDE CODE

1. Pasos 1 → 4 (tokens + provider + theme + cableado en app.dart) — **commit 1**
2. Paso 5 + 7 (SkinSwitch + sección Aspecto en Ajustes con mini preview) — **commit 2**, ya se puede probar el toggle aunque solo cambie colores globales
3. Paso 9 (widgets compartidos futuristas) — **commit 3**
4. Paso 8 pantallas 1-4 (Hoy, Tareas, Ficha, Crear) — **commit 4**
5. Paso 8 pantallas 5-8 (Historial, Miembros, Perfil+Radar, Multi-hogar) — **commit 5**
6. Paso 8 pantallas 9-12 (Onboarding, Paywall, Rescue, Ajustes hogar) — **commit 6**
7. Pulido, animaciones, empty states, QA — **commit 7**

Al terminar cada commit, `flutter analyze` + `flutter test` deben pasar limpio.
