# §9 — 🟡 Tile Ajustes → Suscripción no navega

Estado: **RESUELTO (era FALSO POSITIVO de navegación) + MEJORA: nombre del pagador** · Cliente only · Verificado end-to-end en 2 dispositivos contra prod (`toka-dd241`) · Fecha: 2026-06-18

## Bug reportado

En Ajustes, la tile "Suscripción · Plan Premium/gratuito" supuestamente no navegaba
a ninguna pantalla de gestión al tocarla (solo hacía scroll de la lista). El acceso
al flujo premium quedaba solo por los banners. Se esperaba que navegara a la pantalla
de gestión (`AppRoutes.subscription` → `SubscriptionManagementScreen`).

## Diagnóstico: falso positivo (artefacto de automatización adb)

La navegación **siempre ha estado correctamente cableada**. Evidencia de código:

- `lib/features/settings/presentation/settings_screen.dart`: el `ListTile` de la
  tile de suscripción (`Key('subscription_status_label')`) y el de "Restaurar
  compras" ya tienen `onTap: () => context.push(AppRoutes.subscription)`.
  `git log -L` confirma que ese `onTap` existe **desde el primer commit** del
  fichero (`a20fb2f feat(settings): add SettingsScreen…`); nunca se quitó ni cambió.
- `lib/core/constants/routes.dart`: `subscription = '/subscription'` existe y está
  en la lista de rutas conocidas.
- `lib/app.dart` (~L295): `GoRoute(path: AppRoutes.subscription, builder: (_, __) =>
  const SubscriptionManagementScreen())` está registrada.
- El `redirect` global (`RouterNotifier.redirect`) solo intercepta pantallas de auth
  y `splash`; para un usuario autenticado en `/subscription` devuelve `null` (no
  rebota).
- `SubscriptionManagementScreen` → `SubscriptionManagementScreenV2` renderiza
  correctamente el card de plan + las CTAs por estado.

Por qué QA lo vio como "solo hace scroll": la tile de suscripción está en mitad de
una `ListView` larga. Un `adb shell input tap` cuyo punto cae sobre el borde de la
tile (o tras un scroll que la dejó parcialmente fuera del viewport, sobre un
`Divider`/zona muerta) **no impacta el `onTap`** y la lista interpreta el gesto como
desplazamiento. Es el mismo patrón de artefacto adb descrito en §0. Se reprodujo este
matiz **en el propio widget test** (ver abajo): tras `dragUntilVisible`, la tile podía
quedar en el borde inferior con su centro fuera de pantalla y el `tap` no surtía
efecto hasta forzar `ensureVisible`.

### Relación con §5 (confirmado de paso)

El otro síntoma del reporte ("el estado mostrado en la tile dependía de reiniciar")
**ya quedó resuelto en §5** (`home-cached-object-live-refresh.md`): `currentHomeProvider`
pasó de `.get()` one-shot a stream `snapshots()`, y §5 verificó en 2 dispositivos que
la tile pasa de "Plan Premium" ↔ "Plan gratuito" en vivo al cambiar `premiumStatus`.
En esta verificación la tile mostró el estado correcto ("Plan Premium") en ambos
dispositivos sin reiniciar.

## Cambios (cliente)

No hacía falta arreglar la navegación (ya funcionaba). Cambios realizados:

1. **`lib/features/settings/presentation/settings_screen.dart`** — se añadió
   `key: const Key('settings_restore_purchases')` al `ListTile` de "Restaurar
   compras" (antes no tenía `Key`). Cambio invisible al usuario; solo mejora la
   testabilidad y deja la tile localizable de forma estable, en coherencia con la
   tile de suscripción que ya tenía `Key('subscription_status_label')`.

2. **`test/ui/features/settings/settings_subscription_navigation_test.dart`** (nuevo)
   — fija el contrato de navegación para evitar una regresión real futura.

`flutter analyze` limpio en los dos ficheros tocados ("No issues found").

## Tests

`test/ui/features/settings/settings_subscription_navigation_test.dart` con un
`GoRouter` real (`/settings` → `SettingsScreen`, `/subscription` → destino centinela)
y `settingsViewModelProvider` sobreescrito:

- **`tocar la tile de Suscripción navega a la gestión de suscripción`**: toca
  `subscription_status_label` y verifica que aparece el destino y desaparece
  `SettingsScreen`.
- **`tocar "Restaurar compras" navega a la gestión de suscripción`**: idem sobre
  `settings_restore_purchases`.

Ambos pasan. Detalle reproducido durante el desarrollo del test: sin `ensureVisible`
previo, el `tap` sobre la tile de "Restaurar compras" (borde inferior del viewport
tras `dragUntilVisible`) **no disparaba la navegación** — exactamente el mismo
artefacto que vio QA con adb. Con `ensureVisible` (tile completamente visible) la
navegación dispara siempre. Esto es la confirmación técnica de que el reporte era un
artefacto de impacto del toque, no un fallo de la app.

Verificación sin regresiones: `test/ui/features/settings/settings_screen_test.dart`
da **`+5 -5` idéntico con y sin mi cambio** (`git stash` del fuente) — los 5 fallos
(4 casos "abandonar hogar" + 1 golden de otra máquina) son pre-existentes de los 57
conocidos, no regresiones. `flutter test test/unit/features/settings/` + el nuevo
test → **8/8 en verde**.

## Verificación en 2 dispositivos (prod `toka-dd241`)

Hogar `SMQRtCjrA09gPIr1wazD` "Hogar QA Noche" (premium `active`). En ambos:
Ajustes → scroll a sección Suscripción → tap en la tile "Plan Premium" (centro de la
tile, bien dentro del viewport — coords obtenidas con `ui.sh`).

- **MI_9 `43340fd2`** (owner N2, tema oscuro): tap en "Plan Premium" → navegó a
  **"Tu suscripción"** mostrando "Premium activo · Próxima renovación: 18 julio 2026
  · Pagador: tú" con CTAs "Gestionar facturación" / "Cancelar renovación" (estado
  `active`). ✔
- **emulador `emulator-5554`** (tema claro): tap en "Plan Premium" → navegó a
  **"Tu suscripción"** ("Premium activo · Próxima renovación: 17 julio 2026"). ✔
  Además, tap en **"Restaurar compras"** → también navegó a "Tu suscripción". ✔

(Nota: la diferencia de fecha de renovación "18 julio" en MI_9 vs "17 julio" en
emulador es solo render por zona horaria — `premiumEndsAt` cerca de medianoche UTC:
MI_9 en Madrid GMT+2 lo muestra un día después que el emulador en GMT. Mismo doc.)

### Verificación exhaustiva con DOS cuentas distintas del mismo hogar

La primera pasada tenía AMBOS dispositivos logueados como N2 (owner/pagador), así que
los dos mostraban "Pagador: tú" — no diferenciaba roles. Se rehízo entrando en el
emulador con un **miembro no-pagador real** del mismo hogar para probar la vista del
otro lado (premium es **por hogar**, no por usuario — regla de negocio #1).

Datos del hogar (auditado con `node secrets/qa_inspect_home.js SMQRtCjrA09gPIr1wazD`):
- owner/`currentPayerUid` = `wwL0OTdrNeMZs2wTt6QtRDT1nb53` = `toka.qa.n2@tokatest.dev`.
- miembro activo no-pagador = `aBne0aSLzbNaM7ZyACmibbVkPN62` = `toka.qa.n3@tokatest.dev`
  (role=member, Auth=SÍ, emailVerified). [ADMIN SDK, solo lectura]

Resultado (emulador re-logueado como **N3**, no-pagador):
- El tile de Ajustes sigue mostrando **"Plan Premium"** ✔ (premium por hogar aplica a
  N3 aunque no pague; además Hoy no muestra ads para N3).
- Tap en el tile → navega a **"Tu suscripción"** ✔.
- La tarjeta muestra **"Pagador: otro miembro"** (`subscription_payer_other`), NO "tú"
  ✔ — la lógica `isSelf = currentUserUid == currentPayerUid` de `PlanSummaryCard._payerRow`
  distingue correctamente al pagador.

| | MI_9 `43340fd2` | emulador `5554` |
|---|---|---|
| Cuenta | N2 (owner/**pagador**) | N3 (**miembro no-pagador**) |
| Tile "Plan Premium" | ✔ | ✔ (premium por hogar) |
| Navega a gestión | ✔ | ✔ |
| Campo Pagador | "Pagador: **tú**" | "Pagador: **otro miembro**" |

Conclusión: la navegación funciona con un toque real para **distintos roles/cuentas**
del mismo hogar, y el premium por hogar + el display del pagador se renderizan
correctamente según quién mira. El reporte original era un falso positivo de
automatización (impacto del `input tap` sobre borde/zona muerta de una `ListView`).
Capturas analizadas y **borradas** al terminar. No se tocó
ningún dato de producción (solo navegación de lectura).

## Mejora añadida: mostrar el NOMBRE del pagador (no "otro miembro")

A petición del usuario, cuando el pagador NO es el usuario actual, la pantalla
"Tu suscripción" ahora muestra el **nickname real del miembro que paga** (p. ej.
"Pagador: Sebas N2") en lugar del genérico `subscription_payer_other` ("otro
miembro") — es útil saber quién del hogar sostiene el premium.

Cambios (cliente, sin tocar backend/reglas/ARB):

1. **`lib/.../widgets/plan_summary_card.dart`** — nuevo parámetro opcional
   `payerName`. En `_payerRow`: `isSelf` → "tú" (sin cambios); si no soy yo y hay
   `payerName` no vacío → se muestra ese nombre; si no hay nombre → fallback a
   `subscription_payer_other`. Además el `Text` del pagador se envolvió en
   `Expanded` para que un **nombre largo** se ajuste/parta en líneas en vez de
   desbordar la fila (bug de layout latente que no se veía porque antes solo se
   pintaba "tú", corto — un test nuevo lo reprodujo: overflow de 37px).
2. **`lib/.../skins/subscription_management_screen_v2.dart`** — resuelve el nombre
   del pagador desde `homeMembersProvider(homeId)` (uid → nickname) y lo pasa a
   `PlanSummaryCard`. El `ref.watch` de los miembros es **condicional**: solo si hay
   `currentPayerUid` distinto del usuario actual y `homeId` no vacío — así no se
   fuerzan lecturas de miembros en estados sin pagador (free/expired/restorable) ni
   cuando pago yo (donde se muestra "tú"). Si el pagador no aparece en la lista de
   miembros, cae limpiamente al genérico.

Tests añadidos:
- `plan_summary_card_test.dart`: 3 tests de texto del campo Pagador — "tú" (self),
  nombre real (no-self con `payerName`), y fallback "otro miembro" (no-self sin
  nombre). Este último también cubre el caso de overflow ya corregido.
- `subscription_management_screen_test.dart`: test de integración que sobreescribe
  `homeMembersProvider('h1')` con un pagador "Sebas N2" y verifica que la pantalla
  renderiza "Pagador: Sebas N2" (no "otro miembro").

`flutter analyze` limpio. Suite `test/ui/features/subscription/` +
`test/unit/features/subscription/` → **93 passed**, 12 fallos que son **todos
goldens pre-existentes** (`golden:` de plan_summary_card / premium_state_banner /
rescue_banner / paywall — verificado con `git stash`: mismos 6 goldens de
plan_summary_card fallan en baseline; ninguno es regresión). Mi cambio no altera
ningún golden porque el caso "tú" (único que pintan los goldens existentes) no cambia.

Verificación en 2 dispositivos (APK debug recompilado e instalado):
- **emulador `5554`** logueado como **N3 (no-pagador)** → "Tu suscripción" muestra
  **"Pagador: Sebas N2"** (antes "otro miembro"). ✔
- **MI_9 `43340fd2`** logueado como **N2 (pagador)** → sigue mostrando
  **"Pagador: tú"** (caso self intacto). ✔
Capturas borradas al terminar.

## Notas / hallazgos

- No se modificó la navegación ni el router porque ya eran correctos. Resistido el
  impulso de "arreglar lo que no está roto".
- Recomendación de tooling para futuras sesiones QA: al automatizar taps sobre tiles
  en `ListView`, asegurarse con `ui.sh` de que el **centro** de la tile esté dentro
  del viewport antes del `input tap` (el helper ya da los `bounds`; usar el centro
  real, no una Y aproximada), para no confundir un toque fallido con un bug de la app.
- **Hallazgo menor (fuera de §9, no bloqueante):** en estado `active`, un miembro
  **no-pagador** (N3) ve los mismos CTAs "Gestionar facturación" / "Cancelar
  renovación" que el pagador en `SubscriptionManagementScreenV2._ActionSection` (el
  switch depende solo de `data.status`, no de si el usuario es el pagador). Ambos
  botones solo hacen `_openPlayStoreSubscriptions()` (deep-link al Play Store del
  propio usuario), así que **no hay riesgo de datos** — un no-pagador vería sus
  propias suscripciones (vacías), no las del pagador. Pero es confuso ofrecerle
  "gestionar/cancelar" una facturación que no es suya. Mejora sugerida: ocultar o
  sustituir esos CTAs cuando `currentUserUid != currentPayerUid` (p. ej. un texto
  "La gestiona <pagador>"). Se deja anotado para un fix de UX aparte.
- Estado de cuentas tras la verificación: MI_9 quedó como N2 (owner) y el emulador
  como N3 (miembro) — configuración diferenciada que coincide con la intención de §5
  (owner en un dispositivo, member en el otro). Si se prefiere el emulador de vuelta
  como N2, basta re-loguear; no se modificó ningún dato del hogar.
