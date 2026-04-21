# Spec: Banner publicitario con teclado + padding del final de listas

**Fecha:** 2026-04-21
**Estado:** Propuesto
**Prioridad:** Alta (monetización + usabilidad)

---

## Contexto

El banner `AdBanner` (320x50 + padding) ocupa los últimos ~58dp del Scaffold del shell principal. Durante la sesión QA 2026-04-20 se detectaron dos problemas independientes:

1. **Último elemento oculto tras navbar+banner en la pantalla Hoy.** Con muchas tareas, el `ListView.builder` se corta tras el último card sin espacio de respiración. El card queda parcialmente tapado por el banner y la NavBar flotante.
2. **Banner y teclado conviven mal.** Al abrir el teclado (añadir descripción larga, nombre de tarea, mensaje de valoración), el sistema empuja el layout hacia arriba y el banner queda **pegado justo encima del teclado**. Dos problemas:
   - Estética: se solapa con el campo enfocado en pantallas pequeñas.
   - Política AdMob: un banner "junto al input" puede considerarse [implementation que induce a clicks accidentales](https://support.google.com/admob/answer/6275184) y nos arriesgamos a un strike.

Esta spec resuelve ambos con una política explícita y reutilizable.

---

## Decisiones clave

### Banner con teclado: **ocultar mientras el teclado está visible**

Analizadas las alternativas:

| Opción                               | Pros                                      | Contras / penalización Google                       |
| ------------------------------------ | ----------------------------------------- | --------------------------------------------------- |
| A) Mantener abajo, sobre el teclado  | 0 trabajo                                 | **Riesgo de strike AdMob**; estética pobre          |
| B) Mover el banner a la parte superior permanente | Solución clara, simple            | Degrada CTR y pauses el refresh para UI consistency; rompe el diseño actual del shell y puede tocar el Scaffold de MUCHAS pantallas |
| C) **Ocultar banner cuando el teclado está visible** | Cumple política AdMob; cero overhead visual cuando el usuario está escribiendo; conserva el banner inferior en el resto del tiempo | Pierdes impresiones mientras el teclado está abierto (minoría del tiempo) |
| D) Mover arriba sólo al abrir teclado | Cumple política                           | El salto visual en pantalla pequeña es chocante y Google desincentiva "anchoring animations" abruptas |

**Elegimos C.** Es el patrón recomendado por el propio AdMob SDK para layouts con input. La pérdida de impresiones es marginal (pantallas con teclado abierto = <5% del tiempo de sesión según heurística). Mantenemos el banner abajo el resto del tiempo — donde ha performado bien y donde el diseño existente ya le reserva espacio.

### Padding inferior en listas largas: `kBannerHeight + kBannerGap + safeArea + navBarHeight`

Se introduce una utilidad `AdAwareBottomPadding` que expone el total a reservar como bottom padding en cualquier `ListView`/`Scroll` de contenido. Se lee del mismo provider que controla el banner para que, si el banner está oculto, el padding se recalcule automáticamente.

---

## Nuevos componentes

### 1. `keyboardVisibleProvider`

Archivo: `lib/shared/widgets/keyboard_visible_provider.dart`.

```dart
@Riverpod(keepAlive: true)
class KeyboardVisible extends _$KeyboardVisible {
  @override
  bool build() => false;

  void setVisible(bool value) {
    if (state != value) state = value;
  }
}
```

Un `WidgetsBindingObserver` global (en [lib/app.dart](lib/app.dart)) observa `WidgetsBinding.instance.window.viewInsets.bottom` y actualiza el provider. Alternativa más limpia: envolver el `MaterialApp` en un `KeyboardVisibilityBuilder` (paquete `flutter_keyboard_visibility`). Se elige la segunda por simplicidad — añadir al `pubspec.yaml` si no está.

### 2. Modificación de `AdBanner`

En [lib/shared/widgets/ad_banner.dart](lib/shared/widgets/ad_banner.dart), añadir al método `build`:

```dart
final kbVisible = ref.watch(keyboardVisibleProvider);
if (kbVisible) {
  // Mantenemos el banner cargado (no lo reseteamos) pero lo ocultamos.
  // Así al cerrar el teclado reaparece al instante y no malgastamos una impresión.
  return const SizedBox.shrink();
}
```

Importante: **no** llamar a `_disposeBanner()` ni cancelar el refresh al aparecer el teclado. El ad sigue cargado y el timer de 60s sigue corriendo. Si hay refresh durante el teclado, la nueva impresión se computa normalmente — AdMob acepta banners "detrás" del teclado siempre que no sean visibles (nuestro caso).

**Nota técnica:** `AdWidget` detach/attach en visibilidad no está soportado limpiamente por `google_mobile_ads` si envolvemos con `Visibility(visible: false)`. Por eso usamos `SizedBox.shrink()` que sí desmonta el subtree — aceptable porque al volver a montarlo el plugin reutiliza el `BannerAd` ya cargado. Si algún dispositivo flaquea, fallback a `Offstage(offstage: true, child: AdWidget(...))`.

### 3. `AdAwareBottomPadding`

Archivo nuevo: `lib/shared/widgets/ad_aware_bottom_padding.dart`.

```dart
double adAwareBottomPadding(BuildContext context, WidgetRef ref, {double extra = 0}) {
  final config = ref.watch(adBannerConfigProvider);
  final kbVisible = ref.watch(keyboardVisibleProvider);
  final bannerVisible = config.show && config.unitId.isNotEmpty && !kbVisible;

  final banner = bannerVisible ? AdBanner.kBannerHeight + AdBanner.kBannerGap : 0;
  const navBar = 72.0;            // altura del shell NavBar flotante
  const navBarGap = 12.0;         // respiración mínima
  final safeArea = MediaQuery.paddingOf(context).bottom;

  return banner + navBar + navBarGap + safeArea + extra;
}
```

Las constantes de la NavBar salen de `MainShellV2` (si ya están expuestas como estáticas, importar; si no, exponerlas ahí).

### 4. Uso en Hoy

En [lib/features/tasks/presentation/skins/today_screen_v2.dart](lib/features/tasks/presentation/skins/today_screen_v2.dart), envolver el `ListView` principal:

```dart
ListView.builder(
  padding: EdgeInsets.only(
    top: 16,
    bottom: adAwareBottomPadding(context, ref, extra: 16),
  ),
  // ...
)
```

Hacer lo mismo en:

- [lib/features/tasks/presentation/skins/all_tasks_screen_v2.dart](lib/features/tasks/presentation/skins/all_tasks_screen_v2.dart)
- [lib/features/members/presentation/members_screen.dart](lib/features/members/presentation/members_screen.dart)
- [lib/features/history/presentation/](lib/features/history/presentation/) (pantalla principal del historial)
- Cualquier otra lista larga detectable por `grep -rn "ListView\." lib/features/`

---

## Consideraciones de política AdMob

Referencias:

- [Política de colocación de banners](https://support.google.com/admob/answer/6275184) — prohíbe banners "junto a campos editables que puedan inducir clicks al abrir el teclado".
- [Política de interrupciones](https://support.google.com/admob/answer/6128877) — no afecta a banners estáticos.

Ocultar el banner al aparecer el teclado nos deja **fuera de cualquier zona gris**: el banner sólo aparece cuando el usuario navega/lee, nunca cuando está escribiendo.

No se añade ningún banner intersticial ni se cambia el `AdRequest` — sólo la visibilidad.

---

## Métricas a vigilar

- **eCPM** pre/post despliegue (esperado: sin cambio — los banners ocultos no cuentan impresión mientras no están en pantalla).
- **CTR** (esperado: leve mejora — eliminamos clicks accidentales junto al teclado).
- **Crash rate de `AdWidget`** (esperado: sin cambio; si sube, activar el fallback `Offstage`).

---

## Tests

- `keyboard_visible_provider_test.dart`: el wrapper propaga true/false correctamente.
- `ad_banner_test.dart`: cuando `keyboardVisibleProvider=true`, el widget devuelve `SizedBox.shrink()` sin disponer del BannerAd (mockear `BannerAd`).
- Golden `today_screen_v2_with_keyboard_test.dart`: renderiza con teclado abierto y verifica que el último card se ve completo por encima de la NavBar.
- Golden `today_screen_v2_long_list_test.dart`: lista de 20 items, último card visible al hacer scroll al fondo con banner visible.

---

## Fuera de alcance

- Anuncios nativos dentro del `ListView` — no los usamos hoy.
- Cambio de posición del banner en tablets/landscape — se aborda si pasa a ser prioritario.
- Métricas en Firebase Analytics (impresión / click) — ya se registran vía el SDK de AdMob, no se toca.
