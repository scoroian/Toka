# Spec: Consolidación de navegación — eliminar rutas duplicadas

**Fecha:** 2026-04-21
**Estado:** Propuesto
**Prioridad:** Media (BUG-26 y duplicidades detectadas en auditoría QA 2026-04-20)

---

## Contexto

La sesión QA 2026-04-20 auditó las pantallas de Ajustes y Ajustes del hogar y detectó que varias funciones están accesibles desde **múltiples puntos** sin justificación de producto. Esto:

- Confunde al usuario ("¿cuál es la canónica?").
- Duplica superficie de mantenimiento (los tiles se desincronizan — algunos dicen "Código de invitación", otros "Invitar").
- Rompe la heurística de Material "una acción, un lugar".

Rutas duplicadas confirmadas:

| Acción                       | Accesos actuales                                                | Canónica propuesta                           |
| ---------------------------- | --------------------------------------------------------------- | -------------------------------------------- |
| Mostrar código de invitación | Miembros (FAB) + Ajustes + Ajustes del hogar                    | **Miembros → FAB Invitar**                   |
| Gestionar suscripción        | Ajustes + Ajustes del hogar + Paywall                           | **Ajustes → Gestionar suscripción** (ruta única) |
| Miembros                     | NavBar → Miembros + Ajustes del hogar → Miembros                | **NavBar → Miembros**                        |
| Cambiar de hogar             | Ajustes + Ajustes del hogar + `HomeSelectorWidget` de cabecera  | **`HomeSelectorWidget`** (selector siempre visible) |

Adicionalmente, BUG-26 reporta que tras **salir de hogar** en Ajustes del hogar, la pantalla se queda en blanco unos instantes antes de redirigir — porque la pantalla depende de `currentHomeIdProvider` que queda `null`.

---

## Cambios propuestos

### 1. Código de invitación

**Mantener:** [lib/features/members/presentation/members_screen.dart](lib/features/members/presentation/members_screen.dart) → FAB "Invitar". Este flujo ya está diseñado para entregar código + enlace profundo + QR.

**Eliminar:**
- Tile "Código de invitación" en [lib/features/settings/presentation/settings_screen.dart](lib/features/settings/presentation/settings_screen.dart).
- Tile "Código de invitación" en [lib/features/homes/presentation/home_settings_screen.dart](lib/features/homes/presentation/home_settings_screen.dart).

**Sustituir por:** un único tile más general en Ajustes del hogar → **"Gestionar miembros"** que abre la pantalla Miembros (no la sheet directa de invitación).

### 2. Gestionar suscripción

**Mantener:** [lib/features/subscription/presentation/subscription_management_screen.dart](lib/features/subscription/presentation/subscription_management_screen.dart), accesible sólo desde *Ajustes → Gestionar suscripción*.

**Eliminar:**
- Tile "Gestionar suscripción" en `home_settings_screen.dart`. El hogar no tiene suscripción por si mismo; la tiene la cuenta del pagador. Poner un tile aquí era confuso.

**Añadir:** en `home_settings_screen.dart`, si el usuario actual **es el pagador**, un subtle info tile:

> Tu cuenta está pagando el Premium de este hogar. [Gestionar en Ajustes →]

El enlace navega a la pantalla canónica.

### 3. Miembros

**Mantener:** NavBar → Miembros.

**Eliminar:** tile "Miembros" en `home_settings_screen.dart`. Redundante con la NavBar que siempre está visible desde que aplicamos la spec `home-selector-always-visible`.

### 4. Cambiar de hogar

**Mantener:** `HomeSelectorWidget` visible en la cabecera del shell.

**Eliminar:**
- Tile "Cambiar de hogar" en `settings_screen.dart`.
- Tile "Cambiar de hogar" en `home_settings_screen.dart`.

**Excepción:** si el usuario sólo tiene 1 hogar activo, el `HomeSelectorWidget` igualmente se mantiene (para ver el nombre). El tile "Mis hogares" de Ajustes se mantiene porque es la pantalla de administración (alta/baja), no de selección.

### 5. Ajustes del hogar tras "Salir del hogar" (BUG-26)

Hoy el widget llama a `leaveHome()` y espera al próximo rebuild, que tarda 1-2 frames y muestra pantalla en blanco. Fix:

```dart
Future<void> _onLeaveHome() async {
  final confirmed = await showLeaveHomeDialog(context);
  if (!confirmed) return;
  // Navegamos ANTES de ejecutar el callable, hacia el home selector.
  // Si el callable falla, volvemos con un SnackBar en el selector.
  GoRouter.of(context).go('/homes');
  try {
    await vm.leaveHome();
  } catch (e) {
    // el selector mostrará el error vía ref.listen
  }
}
```

Alternativa más segura: mostrar un `LoadingOverlay` local mientras el callable resuelve y **sólo después** navegar — decisión de implementación. La clave es no quedar con un Scaffold cuyo `currentHomeIdProvider == null`.

---

## Router: simplificación

En los routers de feature `members/router.dart`, `homes/router.dart`, `settings/router.dart`, eliminar las rutas muertas que dejen de tener puntos de entrada. Auditoría a realizar como parte de la implementación: cualquier ruta nombrada no enlazada desde ningún `context.go`/`context.push` se retira.

---

## Tests

Los tests afectados (golden de pantallas de ajustes, tests de navegación) deben regenerar goldens o adaptarse:

- `home_settings_screen_test.dart`: goldens sin los tiles eliminados.
- `settings_screen_test.dart`: idem.
- `members_screen_test.dart`: verifica que el FAB Invitar abre la sheet de invitación (no cambia).
- Nuevo `leave_home_navigation_test.dart`: tras invocar `leaveHome`, no hay frame con Scaffold de `home_settings_screen`.

---

## Plan de migración

Dado que no hay análisis de uso de cada tile, la eliminación es directa — no hay datos que indiquen que los tiles duplicados se usen.

Despliegue en una única release; no requiere feature flag.

---

## Fuera de alcance

- Rediseño visual de las pantallas de Ajustes (tipografía, espaciado).
- Notificaciones in-app de "has salido del hogar" (se mantiene el snackbar actual).
- Permitir "deshacer" un leave home (política de producto fuera de esta spec).
