# "Sin publicidad" honesto + banner-vs-intersticial — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hacer honesto el copy de anuncios del paywall (intersticial = hogar; banner = individual) y dar una vía de entendimiento al no-pagador de un hogar Premium que sigue viendo banner.

**Architecture:** (1) Reescribir el copy en la tarjeta comparativa compartida `PlanComparisonCard` (la usan paywall binario + rescate). (2) Añadir el beneficio "sin banner" al paywall de Toka Plus. (3) Caption descartable sobre el banner en el shell, gobernada por providers nuevos (elegibilidad pura + Notifier de descarte in-memory por hogar), con su altura reservada en los 4 sitios del shell para no tapar contenido.

**Tech Stack:** Flutter 3.x, Riverpod (`riverpod_annotation`), go_router, ARB/flutter_localizations, flutter_test (widget + golden).

## Global Constraints

- **Nada de texto UI hardcodeado**: toda string visible va en `lib/l10n/app_es.arb`, `app_en.arb`, `app_ro.arb` y se accede con `l10n.<clave>`. Regenerar con `flutter gen-l10n` tras editar ARB. (template = `app_es.arb`).
- Providers: `@Riverpod(keepAlive: true)` + `part '<file>.g.dart'`; tras añadir/editar anotaciones correr `dart run build_runner build --delete-conflicting-outputs`.
- Las pantallas reales son los `*_v2.dart`. Editar esos.
- Convención de claves ARB (codebase mixto): seguir al vecino — paywall/tarjeta en snake_case (`paywall_*`), Plus en camelCase (`plus*`), banner en snake_case (`ad_banner_notice_*`).
- Gates por tarea: `flutter analyze` sin errores nuevos; tests de la tarea verde.
- Política AdMob: la caption va **separada** del banner por un gap; nunca solapada ni adyacente de forma que induzca clics accidentales.
- Correr `flutter test` en WSL **antes** de cualquier build de Windows (un `pub get` de Windows rompe `package_config.json` para WSL).

---

### Task 1: Copys ARB (es/en/ro) + regenerar localizaciones

**Files:**
- Modify: `lib/l10n/app_es.arb`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_ro.arb`
- Generated (no editar a mano): `lib/l10n/app_localizations*.dart`

**Interfaces:**
- Produces (getters en `AppLocalizations` tras gen-l10n):
  - `paywall_feature_no_ads` (reescrito), `paywall_ads_banner_note` (nuevo),
    `plusBenefitNoAdsTitle`, `plusBenefitNoAdsDesc` (nuevos),
    `plusPaywallSubtitle`, `plusAlreadyActiveBody` (reescritos),
    `ad_banner_notice_text`, `ad_banner_notice_dismiss` (nuevos).

- [ ] **Step 1: Editar `app_es.arb`**

Reemplazar el valor de `paywall_feature_no_ads` (línea ~688) y su `@description`:

```json
  "paywall_feature_no_ads": "Sin anuncios a pantalla completa",
  "@paywall_feature_no_ads": { "description": "Premium feature: no full-screen (interstitial) ads, removed home-wide" },
```

Añadir justo después de `@paywall_feature_no_ads` la nota del banner:

```json
  "paywall_ads_banner_note": "El banner inferior se quita para quien paga el plan; los demás miembros pueden quitarlo con Toka Plus.",
  "@paywall_ads_banner_note": { "description": "Footnote in the plan comparison card clarifying banner ads are removed per-payer; others use Toka Plus" },
```

Reescribir `plusPaywallSubtitle` (línea ~1295) y `plusAlreadyActiveBody` (línea ~1325):

```json
  "plusPaywallSubtitle": "Quita el banner, desbloquea aspectos exclusivos y consulta tus métricas personales.",
```

```json
  "plusAlreadyActiveBody": "Sin banner, con aspectos exclusivos y tus métricas personales.",
```

Añadir tras `@plusBenefitMetricsDesc` (línea ~1304) las claves del beneficio "sin banner":

```json
  "plusBenefitNoAdsTitle": "Sin banner de anuncios",
  "@plusBenefitNoAdsTitle": { "description": "Plus benefit: removes the banner ad title" },
  "plusBenefitNoAdsDesc": "Quita el banner inferior solo para ti, en todos tus hogares.",
  "@plusBenefitNoAdsDesc": { "description": "Plus benefit: removes the banner ad description" },
```

Añadir al final del bloque de claves (antes del cierre `}` del JSON) las del banner notice:

```json
  "ad_banner_notice_text": "Quita también el banner con Toka Plus",
  "@ad_banner_notice_text": { "description": "Dismissible caption above the banner for non-paying members of a Premium home; tapping opens the Toka Plus paywall" },
  "ad_banner_notice_dismiss": "Descartar",
  "@ad_banner_notice_dismiss": { "description": "Accessibility label for the dismiss (x) button on the banner notice caption" },
```

- [ ] **Step 2: Editar `app_en.arb`** (mismas claves, valores en inglés; sin bloques `@` si el archivo en no los lleva — replicar el estilo del propio `app_en.arb`)

```json
  "paywall_feature_no_ads": "No full-screen ads",
  "paywall_ads_banner_note": "The bottom banner is removed for whoever pays the plan; other members can remove it with Toka Plus.",
  "plusPaywallSubtitle": "Remove the banner, unlock exclusive looks and check your personal metrics.",
  "plusAlreadyActiveBody": "No banner, with exclusive looks and your personal metrics.",
  "plusBenefitNoAdsTitle": "No banner ads",
  "plusBenefitNoAdsDesc": "Removes the bottom banner just for you, in all your homes.",
  "ad_banner_notice_text": "Remove the banner too with Toka Plus",
  "ad_banner_notice_dismiss": "Dismiss",
```

(Sobrescribir los valores existentes de `paywall_feature_no_ads`, `plusPaywallSubtitle`, `plusAlreadyActiveBody`; añadir los nuevos junto a sus vecinos correspondientes.)

- [ ] **Step 3: Editar `app_ro.arb`**

```json
  "paywall_feature_no_ads": "Fără reclame pe tot ecranul",
  "paywall_ads_banner_note": "Bannerul de jos dispare pentru cine plătește planul; ceilalți membri îl pot elimina cu Toka Plus.",
  "plusPaywallSubtitle": "Elimină bannerul, deblochează aspecte exclusive și vezi-ți statisticile personale.",
  "plusAlreadyActiveBody": "Fără banner, cu aspecte exclusive și statisticile tale personale.",
  "plusBenefitNoAdsTitle": "Fără bannere publicitare",
  "plusBenefitNoAdsDesc": "Elimină bannerul de jos doar pentru tine, în toate casele tale.",
  "ad_banner_notice_text": "Elimină și bannerul cu Toka Plus",
  "ad_banner_notice_dismiss": "Închide",
```

- [ ] **Step 4: Regenerar localizaciones y verificar**

Run: `flutter gen-l10n`
Expected: termina sin errores; no advierte de claves faltantes en en/ro.

Run: `grep -c "paywall_ads_banner_note\|plusBenefitNoAdsTitle\|ad_banner_notice_text" lib/l10n/app_localizations_es.dart`
Expected: `3`

Run: `flutter analyze lib/l10n`
Expected: sin errores.

- [ ] **Step 5: Commit**

```bash
git add lib/l10n
git commit -m "i18n(h06): copys honestos de anuncios (intersticial/banner) + notice (es/en/ro)"
```

---

### Task 2: `PlanComparisonCard` — copy honesto + nota del banner (criterio 1)

**Files:**
- Modify: `lib/features/subscription/presentation/widgets/plan_comparison_card.dart`
- Test: `test/ui/features/subscription/plan_comparison_card_test.dart`
- Goldens: `test/ui/features/subscription/goldens/plan_comparison_card_{2,5,10}.png`

**Interfaces:**
- Consumes: `l10n.paywall_feature_no_ads` (reescrito), `l10n.paywall_ads_banner_note` (Task 1).
- Produces: `Key('plan_comparison_ads_note')` (la nota al pie).

- [ ] **Step 1: Escribir el test que falla** (añadir a `plan_comparison_card_test.dart`)

```dart
  testWidgets('feature de anuncios es precisa (intersticial), no el genérico', (t) async {
    await t.pumpWidget(_wrap(const PlanComparisonCard(premiumMemberLimit: 5)));
    await t.pumpAndSettle();
    expect(find.text('Sin anuncios a pantalla completa'), findsOneWidget);
    expect(find.text('Sin publicidad'), findsNothing);
  });

  testWidgets('muestra la nota del banner (banner se quita por pagador / Plus)', (t) async {
    await t.pumpWidget(_wrap(const PlanComparisonCard(premiumMemberLimit: 5)));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('plan_comparison_ads_note')), findsOneWidget);
    expect(
      find.textContaining('El banner inferior se quita para quien paga'),
      findsOneWidget,
    );
  });
```

- [ ] **Step 2: Ejecutar y verificar que falla**

Run: `flutter test test/ui/features/subscription/plan_comparison_card_test.dart -n "feature de anuncios es precisa"`
Expected: FAIL (`'Sin anuncios a pantalla completa'` no encontrado / la nota no existe).

- [ ] **Step 3: Implementar la nota al pie en `PlanComparisonCard`**

En `plan_comparison_card.dart`, dentro de la `Column` de la `Card`, tras el `...features.map(...)`, añadir la nota (debe quedar dentro del `Key('plan_comparison_card')`):

```dart
            ...features.map(
              (f) => _FeatureRow(
                label: f.$1,
                hasFree: f.$2,
                hasPremium: f.$3,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.paywall_ads_banner_note,
                key: const Key('plan_comparison_ads_note'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
```

(El valor `l10n.paywall_feature_no_ads` ya se usa en la lista `features` — al haber cambiado el ARB en Task 1, la fila pasa a decir "Sin anuncios a pantalla completa" sin tocar el código de la lista.)

- [ ] **Step 4: Ejecutar y verificar que pasa (tests no-golden)**

Run: `flutter test test/ui/features/subscription/plan_comparison_card_test.dart -n "feature de anuncios|nota del banner"`
Expected: PASS.

- [ ] **Step 5: Regenerar goldens de la tarjeta**

Run: `flutter test test/ui/features/subscription/plan_comparison_card_test.dart --update-goldens`
Expected: PASS; `git status` muestra modificados `plan_comparison_card_{2,5,10}.png`.

> Nota: los 3 PNG ya existen sin commitear (de #05). Tras regenerar quedan con la nota nueva.

- [ ] **Step 6: Commit**

```bash
git add lib/features/subscription/presentation/widgets/plan_comparison_card.dart \
        test/ui/features/subscription/plan_comparison_card_test.dart \
        test/ui/features/subscription/goldens/plan_comparison_card_2.png \
        test/ui/features/subscription/goldens/plan_comparison_card_5.png \
        test/ui/features/subscription/goldens/plan_comparison_card_10.png
git commit -m "feat(h06): tarjeta comparativa honesta — intersticial + nota del banner"
```

---

### Task 3: Paywall de Toka Plus — beneficio "sin banner" (criterio 2)

**Files:**
- Modify: `lib/features/subscription/presentation/skins/plus_paywall_screen_v2.dart`
- Test: `test/ui/features/subscription/plus_paywall_screen_test.dart`
- Goldens: `test/ui/features/subscription/goldens/plus_paywall_{es,en,ro}.png`

**Interfaces:**
- Consumes: `l10n.plusBenefitNoAdsTitle`, `l10n.plusBenefitNoAdsDesc` (Task 1).

- [ ] **Step 1: Escribir el test que falla** (añadir a `plus_paywall_screen_test.dart`; usar el mismo harness/overrides que los tests existentes del archivo)

```dart
  testWidgets('lista el beneficio de quitar el banner', (t) async {
    await _pumpPlusPaywall(t); // helper existente del archivo que monta _PlansBody
    await t.pumpAndSettle();
    expect(find.text('Sin banner de anuncios'), findsOneWidget);
    expect(
      find.text('Quita el banner inferior solo para ti, en todos tus hogares.'),
      findsOneWidget,
    );
  });
```

> Si el archivo no tiene un helper `_pumpPlusPaywall`, replicar el `pumpWidget`/overrides del primer `testWidgets` del archivo (estado sin Plus → `_PlansBody`).

- [ ] **Step 2: Ejecutar y verificar que falla**

Run: `flutter test test/ui/features/subscription/plus_paywall_screen_test.dart -n "beneficio de quitar el banner"`
Expected: FAIL (texto no encontrado).

- [ ] **Step 3: Implementar el beneficio en `_PlansBody`**

En `plus_paywall_screen_v2.dart`, dentro de `_PlansBody.build`, **antes** de los dos `_Benefit` existentes (skins/métricas), añadir:

```dart
          _Benefit(
            icon: Icons.block,
            title: l10n.plusBenefitNoAdsTitle,
            description: l10n.plusBenefitNoAdsDesc,
          ),
```

(El subtítulo `l10n.plusPaywallSubtitle` y el cuerpo `_AlreadyActiveBody` → `l10n.plusAlreadyActiveBody` ya reflejan el banner por el cambio ARB de Task 1; no se toca su código.)

- [ ] **Step 4: Ejecutar y verificar que pasa**

Run: `flutter test test/ui/features/subscription/plus_paywall_screen_test.dart -n "beneficio de quitar el banner"`
Expected: PASS.

- [ ] **Step 5: Regenerar goldens del paywall de Plus**

Run: `flutter test test/ui/features/subscription/plus_paywall_screen_test.dart --update-goldens`
Expected: PASS; modificados `plus_paywall_{es,en,ro}.png`.

> Atención (memoria del lote): los goldens que dependen de `google_fonts` fallan sin red por fuente fallback. `PlusPaywallScreenV2` usa estilos del `Theme` (no `GoogleFonts` directo), así que debería regenerar limpio; si el diff fuese solo de fuente, documentarlo como ambiental.

- [ ] **Step 6: Commit**

```bash
git add lib/features/subscription/presentation/skins/plus_paywall_screen_v2.dart \
        test/ui/features/subscription/plus_paywall_screen_test.dart \
        test/ui/features/subscription/goldens/plus_paywall_es.png \
        test/ui/features/subscription/goldens/plus_paywall_en.png \
        test/ui/features/subscription/goldens/plus_paywall_ro.png
git commit -m "feat(h06): paywall de Toka Plus declara que quita el banner para ti"
```

---

### Task 4: Providers de la caption — elegibilidad pura + descarte + visibilidad

**Files:**
- Create: `lib/shared/widgets/ad_banner_notice_provider.dart`
- Generated: `lib/shared/widgets/ad_banner_notice_provider.g.dart`
- Test: `test/unit/shared/widgets/ad_banner_notice_provider_test.dart`

**Interfaces:**
- Consumes: `dashboardProvider`, `currentHomeProvider`, `authProvider`, `plusActiveProvider` (mismos imports que `ad_visibility_provider.dart`).
- Produces:
  - `bool computeBannerNoticeEligible({required bool homeIsPremium, required bool isPayer, required bool hasPlus})`
  - `adBannerNoticeEligibleProvider` (`Provider<bool>`)
  - `AdBannerNoticeDismissal` notifier + `adBannerNoticeDismissalProvider` (`NotifierProvider<.., Set<String>>`) con método `dismiss(String homeId)`
  - `adBannerNoticeVisibleProvider` (`Provider<bool>`)

- [ ] **Step 1: Escribir el test que falla**

```dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/auth/domain/auth_user.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/application/dashboard_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
import 'package:toka/features/subscription/application/plus_provider.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';
import 'package:toka/shared/widgets/ad_banner_notice_provider.dart';

const _uid = 'uid-me';

AuthState _authed(String uid) => AuthState.authenticated(AuthUser(
      uid: uid, email: 'u@u.com', displayName: 'U', photoUrl: null,
      emailVerified: true, providers: const []));

class _FakeAuth extends Auth {
  _FakeAuth(this._s);
  final AuthState _s;
  @override
  AuthState build() => _s;
}

class _FakeCurrentHome extends CurrentHome {
  _FakeCurrentHome({this.payerUid, this.id = 'h1'});
  final String? payerUid;
  final String id;
  @override
  Future<Home?> build() async => Home(
        id: id, name: 'Casa', ownerUid: 'owner', currentPayerUid: payerUid,
        lastPayerUid: null, premiumStatus: HomePremiumStatus.free,
        premiumPlan: null, premiumEndsAt: null, restoreUntil: null,
        autoRenewEnabled: false, limits: const HomeLimits(maxMembers: 5),
        createdAt: DateTime(2024), updatedAt: DateTime(2024));
  @override
  Future<void> switchHome(String i) async {}
}

HomeDashboard _dash({required bool isPremium}) => HomeDashboard.fromFirestore({
      'premiumFlags': {'isPremium': isPremium, 'showAds': !isPremium},
    });

ProviderContainer _c({
  required HomeDashboard? dashboard,
  required String? payerUid,
  required bool hasPlus,
  String id = 'h1',
}) =>
    ProviderContainer(overrides: [
      dashboardProvider.overrideWith((ref) => Stream.value(dashboard)),
      currentHomeProvider.overrideWith(() => _FakeCurrentHome(payerUid: payerUid, id: id)),
      authProvider.overrideWith(() => _FakeAuth(_authed(_uid))),
      plusActiveProvider.overrideWith((ref) => hasPlus),
    ]);

void main() {
  group('computeBannerNoticeEligible — tabla de verdad', () {
    test('elegible solo si Premium ∧ no pagador ∧ sin Plus', () {
      for (final premium in [false, true]) {
        for (final payer in [false, true]) {
          for (final plus in [false, true]) {
            final r = computeBannerNoticeEligible(
                homeIsPremium: premium, isPayer: payer, hasPlus: plus);
            expect(r, equals(premium && !payer && !plus),
                reason: 'premium=$premium payer=$payer plus=$plus');
          }
        }
      }
    });
  });

  group('adBannerNoticeVisibleProvider', () {
    test('Premium + miembro no pagador + sin Plus → visible', () async {
      final c = _c(dashboard: _dash(isPremium: true), payerUid: 'otro', hasPlus: false);
      addTearDown(c.dispose);
      await c.read(dashboardProvider.future);
      await c.read(currentHomeProvider.future);
      expect(c.read(adBannerNoticeVisibleProvider), isTrue);
    });

    test('pagador → no visible', () async {
      final c = _c(dashboard: _dash(isPremium: true), payerUid: _uid, hasPlus: false);
      addTearDown(c.dispose);
      await c.read(dashboardProvider.future);
      await c.read(currentHomeProvider.future);
      expect(c.read(adBannerNoticeVisibleProvider), isFalse);
    });

    test('hogar Free → no visible', () async {
      final c = _c(dashboard: _dash(isPremium: false), payerUid: 'otro', hasPlus: false);
      addTearDown(c.dispose);
      await c.read(dashboardProvider.future);
      await c.read(currentHomeProvider.future);
      expect(c.read(adBannerNoticeVisibleProvider), isFalse);
    });

    test('dashboard/home desconocidos → no visible (fail-safe)', () async {
      final c = _c(dashboard: null, payerUid: 'otro', hasPlus: false);
      addTearDown(c.dispose);
      expect(c.read(adBannerNoticeVisibleProvider), isFalse);
    });

    test('descartar el hogar actual lo oculta; otro hogar sigue visible', () async {
      final c = _c(dashboard: _dash(isPremium: true), payerUid: 'otro', hasPlus: false, id: 'h1');
      addTearDown(c.dispose);
      await c.read(dashboardProvider.future);
      await c.read(currentHomeProvider.future);
      expect(c.read(adBannerNoticeVisibleProvider), isTrue);

      c.read(adBannerNoticeDismissalProvider.notifier).dismiss('h1');
      expect(c.read(adBannerNoticeVisibleProvider), isFalse);
      // descartar otro hogar no afecta a h1
      expect(c.read(adBannerNoticeDismissalProvider).contains('h1'), isTrue);
    });
  });
}
```

- [ ] **Step 2: Ejecutar y verificar que falla**

Run: `flutter test test/unit/shared/widgets/ad_banner_notice_provider_test.dart`
Expected: FAIL de compilación (símbolos inexistentes).

- [ ] **Step 3: Crear el provider**

```dart
// lib/shared/widgets/ad_banner_notice_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/application/dashboard_provider.dart';
import 'package:toka/features/subscription/application/plus_provider.dart';

part 'ad_banner_notice_provider.g.dart';

/// Elegibilidad pura para la caption "tu hogar es Premium pero ves banner".
///
/// Verdadero **solo** en la única fila confusa de la matriz de anuncios: miembro
/// no-pagador de un hogar Premium sin Toka Plus (espeja la rama premium de
/// `computeAdVisibility`, donde el banner sigue visible). En cualquier otra
/// combinación no hay nada que explicar.
bool computeBannerNoticeEligible({
  required bool homeIsPremium,
  required bool isPayer,
  required bool hasPlus,
}) =>
    homeIsPremium && !isPayer && !hasPlus;

/// Elegibilidad cableada a Firestore (mismos inputs que `adVisibilityProvider`).
/// Fail-safe `false` mientras dashboard/home no se conocen.
@Riverpod(keepAlive: true)
bool adBannerNoticeEligible(AdBannerNoticeEligibleRef ref) {
  final dashboard = ref.watch(dashboardProvider).valueOrNull;
  final home = ref.watch(currentHomeProvider).valueOrNull;
  if (dashboard == null || home == null) return false;

  final uid = ref.watch(authProvider).whenOrNull(authenticated: (u) => u.uid);
  final isPayer = home.currentPayerUid != null && home.currentPayerUid == uid;
  final hasPlus = ref.watch(plusActiveProvider);

  return computeBannerNoticeEligible(
    homeIsPremium: dashboard.premiumFlags.isPremium,
    isPayer: isPayer,
    hasPlus: hasPlus,
  );
}

/// Conjunto de homeIds para los que el usuario descartó la caption en ESTA
/// sesión (in-memory: reaparece tras reiniciar la app, comportamiento suave).
@Riverpod(keepAlive: true)
class AdBannerNoticeDismissal extends _$AdBannerNoticeDismissal {
  @override
  Set<String> build() => const {};

  void dismiss(String homeId) {
    if (state.contains(homeId)) return;
    state = {...state, homeId};
  }
}

/// Visible ⇔ elegible ∧ hay homeId ∧ no descartada para ese hogar.
/// Route/teclado-agnóstico: cada consumidor lo combina con su `bannerVisible`.
@Riverpod(keepAlive: true)
bool adBannerNoticeVisible(AdBannerNoticeVisibleRef ref) {
  if (!ref.watch(adBannerNoticeEligibleProvider)) return false;
  final homeId = ref.watch(currentHomeProvider).valueOrNull?.id;
  if (homeId == null) return false;
  return !ref.watch(adBannerNoticeDismissalProvider).contains(homeId);
}
```

- [ ] **Step 4: Generar código**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: crea `ad_banner_notice_provider.g.dart` sin errores.

- [ ] **Step 5: Ejecutar y verificar que pasa**

Run: `flutter test test/unit/shared/widgets/ad_banner_notice_provider_test.dart`
Expected: PASS (6 tests).

Run: `flutter analyze lib/shared/widgets/ad_banner_notice_provider.dart`
Expected: sin errores.

- [ ] **Step 6: Commit**

```bash
git add lib/shared/widgets/ad_banner_notice_provider.dart \
        lib/shared/widgets/ad_banner_notice_provider.g.dart \
        test/unit/shared/widgets/ad_banner_notice_provider_test.dart
git commit -m "feat(h06): providers de la caption banner (elegibilidad + descarte por sesión)"
```

---

### Task 5: Widget `BannerPremiumNoticeCaption`

**Files:**
- Create: `lib/shared/widgets/banner_premium_notice_caption.dart`
- Test: `test/ui/shared/widgets/banner_premium_notice_caption_test.dart`

**Interfaces:**
- Consumes: `adBannerNoticeDismissalProvider` + `currentHomeProvider` (Task 4), `AppRoutes.plusPaywall`, `l10n.ad_banner_notice_text`, `l10n.ad_banner_notice_dismiss`.
- Produces:
  - `class BannerPremiumNoticeCaption extends ConsumerWidget` con `static const double kNoticeHeight = 34;`
  - Keys: `Key('banner_premium_notice')`, `Key('banner_premium_notice_cta')`, `Key('banner_premium_notice_dismiss')`.

- [ ] **Step 1: Escribir el test que falla**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:toka/core/constants/routes.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
import 'package:toka/l10n/app_localizations.dart';
import 'package:toka/shared/widgets/ad_banner_notice_provider.dart';
import 'package:toka/shared/widgets/banner_premium_notice_caption.dart';

class _FakeCurrentHome extends CurrentHome {
  @override
  Future<Home?> build() async => Home(
        id: 'h1', name: 'Casa', ownerUid: 'o', currentPayerUid: 'otro',
        lastPayerUid: null, premiumStatus: HomePremiumStatus.active,
        premiumPlan: null, premiumEndsAt: null, restoreUntil: null,
        autoRenewEnabled: false, limits: const HomeLimits(maxMembers: 5),
        createdAt: DateTime(2024), updatedAt: DateTime(2024));
  @override
  Future<void> switchHome(String i) async {}
}

GoRouter _router() => GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, __) =>
            const Scaffold(body: Center(child: BannerPremiumNoticeCaption())),
      ),
      GoRoute(
        path: AppRoutes.plusPaywall,
        builder: (_, __) => const Scaffold(body: Text('PLUS_PAYWALL')),
      ),
    ]);

Widget _wrap(GoRouter r) => ProviderScope(
      overrides: [currentHomeProvider.overrideWith(() => _FakeCurrentHome())],
      child: MaterialApp.router(
        routerConfig: r,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es')],
      ),
    );

void main() {
  testWidgets('renderiza texto + botón descartar', (t) async {
    await t.pumpWidget(_wrap(_router()));
    await t.pumpAndSettle();
    expect(find.text('Quita también el banner con Toka Plus'), findsOneWidget);
    expect(find.byKey(const Key('banner_premium_notice_dismiss')), findsOneWidget);
  });

  testWidgets('tap en el CTA navega al paywall de Plus', (t) async {
    await t.pumpWidget(_wrap(_router()));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('banner_premium_notice_cta')));
    await t.pumpAndSettle();
    expect(find.text('PLUS_PAYWALL'), findsOneWidget);
  });

  testWidgets('tap en ✕ descarta el hogar actual', (t) async {
    final container = ProviderContainer(
      overrides: [currentHomeProvider.overrideWith(() => _FakeCurrentHome())],
    );
    addTearDown(container.dispose);
    await container.read(currentHomeProvider.future);

    await t.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: _router(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es')],
      ),
    ));
    await t.pumpAndSettle();

    expect(container.read(adBannerNoticeDismissalProvider).contains('h1'), isFalse);
    await t.tap(find.byKey(const Key('banner_premium_notice_dismiss')));
    await t.pumpAndSettle();
    expect(container.read(adBannerNoticeDismissalProvider).contains('h1'), isTrue);
  });
}
```

- [ ] **Step 2: Ejecutar y verificar que falla**

Run: `flutter test test/ui/shared/widgets/banner_premium_notice_caption_test.dart`
Expected: FAIL de compilación (widget inexistente).

- [ ] **Step 3: Crear el widget**

```dart
// lib/shared/widgets/banner_premium_notice_caption.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/routes.dart';
import '../../core/theme/app_colors_v2.dart';
import '../../l10n/app_localizations.dart';
import '../../features/homes/application/current_home_provider.dart';
import 'ad_banner_notice_provider.dart';

/// Caption fina y descartable que se pinta encima del banner SOLO para un
/// miembro no-pagador de un hogar Premium sin Toka Plus (la fila "Premium pero
/// con banner"). Explica por qué sigue viendo banner y ofrece quitarlo con Plus.
///
/// Va separada del anuncio por el gap del shell (política AdMob: sin solape ni
/// adyacencia que induzca clics accidentales). La decide mostrar el shell vía
/// [adBannerNoticeVisibleProvider]; este widget solo se renderiza cuando procede.
class BannerPremiumNoticeCaption extends ConsumerWidget {
  const BannerPremiumNoticeCaption({super.key});

  /// Altura visual de la caption. El shell reserva este alto (+ gap) para que no
  /// tape contenido ni FABs.
  static const double kNoticeHeight = 34;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColorsV2.surfaceDark : AppColorsV2.surfaceLight;
    final bd = isDark ? AppColorsV2.borderDark : AppColorsV2.borderLight;
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          key: const Key('banner_premium_notice'),
          height: kNoticeHeight,
          decoration: BoxDecoration(
            color: bg.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: bd),
          ),
          padding: const EdgeInsets.only(left: 10, right: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Flexible(
                child: InkWell(
                  key: const Key('banner_premium_notice_cta'),
                  onTap: () => context.push(AppRoutes.plusPaywall),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          l10n.ad_banner_notice_text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 16, color: scheme.primary),
                    ],
                  ),
                ),
              ),
              IconButton(
                key: const Key('banner_premium_notice_dismiss'),
                tooltip: l10n.ad_banner_notice_dismiss,
                iconSize: 16,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.close),
                onPressed: () {
                  final id = ref.read(currentHomeProvider).valueOrNull?.id;
                  if (id != null) {
                    ref.read(adBannerNoticeDismissalProvider.notifier).dismiss(id);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Ejecutar y verificar que pasa**

Run: `flutter test test/ui/shared/widgets/banner_premium_notice_caption_test.dart`
Expected: PASS (3 tests).

Run: `flutter analyze lib/shared/widgets/banner_premium_notice_caption.dart`
Expected: sin errores.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/banner_premium_notice_caption.dart \
        test/ui/shared/widgets/banner_premium_notice_caption_test.dart
git commit -m "feat(h06): widget caption descartable banner→Toka Plus"
```

---

### Task 6: Integración en el shell + reserva de altura (4 sitios)

**Files:**
- Modify: `lib/shared/widgets/skins/main_shell_v2.dart` (helper + `build` + `bottomContentPadding` + `fabBottomPadding`)
- Modify: `lib/shared/widgets/ad_aware_bottom_padding.dart`
- Test: `test/unit/shared/widgets/main_shell_notice_slot_test.dart` (helper puro)
- Test: `test/ui/shared/widgets/ad_aware_bottom_padding_notice_test.dart` (padding incluye la caption)

**Interfaces:**
- Consumes: `BannerPremiumNoticeCaption.kNoticeHeight`, `adBannerNoticeVisibleProvider`.
- Produces: `MainShellV2.noticeSlotHeight({required bool noticeVisible}) -> double`.

- [ ] **Step 1: Escribir el test del helper puro**

```dart
// test/unit/shared/widgets/main_shell_notice_slot_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/shared/widgets/ad_banner.dart';
import 'package:toka/shared/widgets/banner_premium_notice_caption.dart';
import 'package:toka/shared/widgets/skins/main_shell_v2.dart';

void main() {
  test('noticeSlotHeight: 0 si no visible', () {
    expect(MainShellV2.noticeSlotHeight(noticeVisible: false), 0);
  });

  test('noticeSlotHeight: alto de la caption + gap si visible', () {
    expect(
      MainShellV2.noticeSlotHeight(noticeVisible: true),
      BannerPremiumNoticeCaption.kNoticeHeight + AdBanner.kBannerGap,
    );
  });
}
```

- [ ] **Step 2: Ejecutar y verificar que falla**

Run: `flutter test test/unit/shared/widgets/main_shell_notice_slot_test.dart`
Expected: FAIL (método inexistente).

- [ ] **Step 3: Añadir el helper y cablear los 3 sitios de `main_shell_v2.dart`**

Imports (parte superior del archivo, junto a los demás):

```dart
import '../ad_banner_notice_provider.dart';
import '../banner_premium_notice_caption.dart';
```

Helper estático (junto a `bannerSlotHeight`):

```dart
  // Altura reservada por la caption "Premium con banner" (#06) cuando es visible.
  static double noticeSlotHeight({required bool noticeVisible}) {
    if (!noticeVisible) return 0;
    return BannerPremiumNoticeCaption.kNoticeHeight + _kBannerGap;
  }
```

En `bottomContentPadding`, tras calcular `bannerVisible` y `navBarSlot`:

```dart
    final noticeVisible =
        bannerVisible && ref.watch(adBannerNoticeVisibleProvider);
    return safeBottom
        + navBarSlot
        + bannerSlotHeight(bannerVisible: bannerVisible)
        + noticeSlotHeight(noticeVisible: noticeVisible);
```

En `fabBottomPadding`, igual:

```dart
    final noticeVisible =
        bannerVisible && ref.watch(adBannerNoticeVisibleProvider);
    return navBarSlot
        + bannerSlotHeight(bannerVisible: bannerVisible)
        + noticeSlotHeight(noticeVisible: noticeVisible);
```

- [ ] **Step 4: Cablear el `build` de `main_shell_v2.dart`**

Tras `final bannerSlot = ...; final navBarSlot = ...;` añadir:

```dart
    final noticeVisible =
        bannerVisible && ref.watch(adBannerNoticeVisibleProvider);
    final noticeSlot = noticeSlotHeight(noticeVisible: noticeVisible);
```

Cambiar la altura del `bottomNavigationBar`:

```dart
        bottomNavigationBar: SizedBox(
          height: navBarSlot + safeBottom + bannerSlot + noticeSlot,
        ),
```

Añadir el `Positioned` de la caption en el `Stack` (justo después del `if (bannerVisible) Positioned(... AdBanner ...)`):

```dart
            if (noticeVisible)
              Positioned(
                left: 16,
                right: 16,
                bottom: navBarSlot +
                    safeBottom +
                    _kBannerGap +
                    AdBanner.kBannerHeight +
                    _kBannerGap,
                child: const BannerPremiumNoticeCaption(
                  key: Key('shell_banner_notice'),
                ),
              ),
```

- [ ] **Step 5: Cablear `adAwareBottomPadding`**

En `ad_aware_bottom_padding.dart`, añadir el import y, tras calcular `banner`/`navBar`:

```dart
import 'ad_banner_notice_provider.dart';
import 'banner_premium_notice_caption.dart';
```

```dart
  final noticeVisible =
      bannerVisible && ref.watch(adBannerNoticeVisibleProvider);
  final notice = noticeVisible
      ? BannerPremiumNoticeCaption.kNoticeHeight + metrics.bannerGap
      : 0.0;

  return banner + notice + navBar + safeArea + extra;
```

- [ ] **Step 6: Escribir el test de `adAwareBottomPadding` con la caption**

```dart
// test/ui/shared/widgets/ad_aware_bottom_padding_notice_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/shared/widgets/ad_aware_bottom_padding.dart';
import 'package:toka/shared/widgets/ad_banner.dart';
import 'package:toka/shared/widgets/ad_banner_config_provider.dart';
import 'package:toka/shared/widgets/ad_banner_notice_provider.dart';
import 'package:toka/shared/widgets/banner_premium_notice_caption.dart';
import 'package:toka/shared/widgets/keyboard_visible_provider.dart';
import 'package:toka/shared/widgets/skins/shell_presence_marker.dart';

void main() {
  testWidgets('adAwareBottomPadding suma la caption cuando es visible', (t) async {
    late double withNotice;
    late double withoutNotice;

    Widget build({required bool notice}) => ProviderScope(
          overrides: [
            adBannerConfigProvider.overrideWith(
                (ref) => const AdBannerConfig(show: true, unitId: '')),
            keyboardVisibleProvider.overrideWith((ref) => false),
            adBannerNoticeVisibleProvider.overrideWith((ref) => notice),
          ],
          child: MaterialApp(
            home: ShellPresenceMarker(
              child: Builder(builder: (context) {
                return Consumer(builder: (context, ref, _) {
                  final p = adAwareBottomPadding(context, ref);
                  if (notice) {
                    withNotice = p;
                  } else {
                    withoutNotice = p;
                  }
                  return const SizedBox();
                });
              }),
            ),
          ),
        );

    await t.pumpWidget(build(notice: false));
    await t.pumpWidget(build(notice: true));

    expect(
      withNotice - withoutNotice,
      BannerPremiumNoticeCaption.kNoticeHeight + AdBanner.kBannerGap,
    );
  });
}
```

> `ShellPresenceMarker` es necesario para que `adAwareBottomPadding` no haga el early-return de "fuera del shell". `metrics.bannerGap == AdBanner.kBannerGap` (misma fuente `MainShellV2Metrics`).

- [ ] **Step 7: Generar (por si build_runner toca .g) y ejecutar tests**

Run: `flutter test test/unit/shared/widgets/main_shell_notice_slot_test.dart test/ui/shared/widgets/ad_aware_bottom_padding_notice_test.dart`
Expected: PASS.

- [ ] **Step 8: Regresión del shell + analyze**

Run: `flutter test test/ui/shared/widgets/ test/unit/shared/widgets/`
Expected: PASS (sin regresión en `ad_aware_bottom_padding`/`main_shell`/`ad_banner_*`). Si algún golden del shell cambia por reflow, regenerar con `--update-goldens` y revisar el diff visualmente.

Run: `flutter analyze lib/shared/widgets/skins/main_shell_v2.dart lib/shared/widgets/ad_aware_bottom_padding.dart`
Expected: sin errores.

- [ ] **Step 9: Commit**

```bash
git add lib/shared/widgets/skins/main_shell_v2.dart \
        lib/shared/widgets/ad_aware_bottom_padding.dart \
        test/unit/shared/widgets/main_shell_notice_slot_test.dart \
        test/ui/shared/widgets/ad_aware_bottom_padding_notice_test.dart
git commit -m "feat(h06): caption sobre el banner en el shell + reserva de altura"
```

---

### Task 7: Gates completos + verificación

**Files:** ninguno (solo verificación; commits de fixes si surgen).

- [ ] **Step 1: Analyze global**

Run: `flutter analyze`
Expected: sin errores nuevos (pueden quedar 2 lints preexistentes en `features/tasks`, documentados en el lote).

- [ ] **Step 2: Suite unit + UI de subscription y shared/widgets**

Run: `flutter test test/unit/ test/ui/features/subscription/ test/ui/shared/widgets/`
Expected: verde. Documentar cualquier golden fallido que sea **solo** ambiental de `google_fonts` (sin red) — no del cambio.

- [ ] **Step 3: Verificación en dispositivo (Firebase real, dos perfiles)** — ver spec §Pruebas

1. Hogar Premium con pagador (MI_9) y no-pagador (emulador): el pagador sin banner; el no-pagador con banner + caption. Capturas a `C:\tmp\h06\`.
2. Activar Toka Plus en la no-pagadora → banner y caption desaparecen. Capturas antes/después.
3. Paywall de hogar (binario y, si el flag está ON, comprobar que el tiered no miente) + paywall de Plus: capturas sin afirmación engañosa.

> Build/run con `main.dart` (no `main_dev.dart`); confirmar en logcat que NO aparece `Mapping Auth Emulator host`. `pub get` en Windows antes de build; restaurar `flutter pub get` en WSL para volver a correr tests.

- [ ] **Step 4: Cierre del lote**

Actualizar `Arreglos/ux_hallazgos_2026-06-25/INDICE.md`: fila 06 → ✅ Completado, fecha 2026-06-26, nota de cierre (archivos + capturas). Listar archivos nuevos/modificados en la respuesta final.

---

## Self-Review

**Spec coverage:**
- Criterio 1 (paywall hogar no afirma genérico, distingue intersticial/banner) → Task 1 (copy) + Task 2 (tarjeta + nota). ✓
- Criterio 2 (Plus deja claro que quita el banner a ti) → Task 1 (copy) + Task 3 (beneficio). ✓
- Criterio 3 (vía de entendimiento donde se ve el banner, sin nag) → Task 4 (providers) + Task 5 (widget) + Task 6 (shell). ✓
- Criterio 4 (localizado es/en/ro, sin falsedades) → Task 1. ✓
- Pruebas: unit `computeAdVisibility` (ya existe; se conserva) + `computeBannerNoticeEligible` (Task 4) + widget/golden paywalls (Tasks 2–3) + caption (Task 5) + alturas (Task 6); device (Task 7). ✓

**Placeholder scan:** sin TBD/TODO; todo paso con código o comando concreto. ✓

**Type consistency:** `computeBannerNoticeEligible`, `adBannerNoticeEligibleProvider`, `AdBannerNoticeDismissal.dismiss`, `adBannerNoticeDismissalProvider`, `adBannerNoticeVisibleProvider`, `BannerPremiumNoticeCaption.kNoticeHeight`, `MainShellV2.noticeSlotHeight` — nombres idénticos en definición (Tasks 4–6) y uso. ✓
